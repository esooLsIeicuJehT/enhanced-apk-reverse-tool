import sys
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch
from datetime import datetime

# NOTE: The development environment lacks Flask and other dependencies.
# We mock these packages in sys.modules to allow importing and unit testing server.py.
# This follows the existing pattern found in api-server/tests/run_tests.py.

class MockConfigObj:
    def from_object(self, *args, **kwargs):
        pass

class MockFlask:
    def __init__(self, *args, **kwargs):
        self.config = MockConfigObj()
    def route(self, *args, **kwargs):
        return lambda f: f

# Setup mocks for sys.modules
mock_flask_mod = MagicMock()
mock_flask_mod.Flask = MockFlask
mock_flask_mod.request = MagicMock()

def mock_jsonify(d, status=None):
    # Simulate Flask's jsonify returning a simple dict or tuple for easy testing
    if status:
        return (d, status)
    return d
mock_flask_mod.jsonify = mock_jsonify

sys.modules['flask'] = mock_flask_mod
sys.modules['flask_cors'] = MagicMock()
sys.modules['flask_socketio'] = MagicMock()
sys.modules['werkzeug'] = MagicMock()
sys.modules['werkzeug.utils'] = MagicMock()
sys.modules['werkzeug.security'] = MagicMock()
sys.modules['jwt'] = MagicMock()
sys.modules['cryptography'] = MagicMock()
sys.modules['cryptography.fernet'] = MagicMock()
sys.modules['apk_reverse_tool'] = MagicMock()

# Add the parent directory to sys.path to import server
api_server_path = str(Path(__file__).parent.parent)
if api_server_path not in sys.path:
    sys.path.insert(0, api_server_path)

import server

# Inject MockConfig into the server module
class MockConfig:
    JWT_SECRET_KEY = 'test_secret_key'
    ALLOWED_EXTENSIONS = {'apk'}
    JWT_EXPIRATION_HOURS = 24
    UPLOAD_FOLDER = 'uploads'
    RESULTS_FOLDER = 'results'

server.Config = MockConfig

from server import get_analysis_status, AnalysisRequest, User

class TestAnalysis(unittest.TestCase):
    """
    Tests for analysis-related endpoints in server.py.
    Directly calls handler functions as Flask's test_client is unavailable
    due to missing framework dependencies in the environment.
    """

    def setUp(self):
        # Reset global state before each test
        server.active_analyses.clear()
        server.user_sessions.clear()

    @patch('server.request')
    @patch('server.get_user_by_token')
    def test_get_analysis_status_success(self, mock_get_user, mock_request):
        """Verify 200 OK and response structure for a valid analysis request."""
        # Setup mock user
        user_id = 'user123'
        user = User(id=user_id, username='testuser', email='test@example.com',
                    password_hash='hash', created_at=datetime.utcnow())
        mock_get_user.return_value = user
        mock_request.headers.get.return_value = 'Bearer valid_token'

        # Setup mock analysis
        analysis_id = 'analysis456'
        analysis = AnalysisRequest(
            id=analysis_id,
            filename='test.apk',
            file_path='/tmp/test.apk',
            user_id=user_id,
            options={},
            status='running',
            progress=45,
            current_step='Decompiling',
            started_at=datetime(2023, 1, 1, 12, 0, 0)
        )
        server.active_analyses[analysis_id] = analysis

        # Call the handler
        response = get_analysis_status(analysis_id)

        # Verify response fields
        self.assertEqual(response['id'], analysis_id)
        self.assertEqual(response['status'], 'running')
        self.assertEqual(response['progress'], 45)
        self.assertEqual(response['current_step'], 'Decompiling')
        self.assertEqual(response['started_at'], '2023-01-01T12:00:00')
        self.assertIsNone(response['completed_at'])

    @patch('server.request')
    @patch('server.get_user_by_token')
    def test_get_analysis_status_unauthenticated(self, mock_get_user, mock_request):
        """Verify 401 Unauthorized when no valid user is found for the token."""
        mock_get_user.return_value = None
        mock_request.headers.get.return_value = 'Bearer invalid_token'

        response = get_analysis_status('any_id')
        res, status = response

        self.assertEqual(status, 401)
        self.assertEqual(res['error'], 'Authentication required')

    @patch('server.request')
    @patch('server.get_user_by_token')
    def test_get_analysis_status_not_found(self, mock_get_user, mock_request):
        """Verify 404 Not Found when the analysis ID does not exist."""
        user = User(id='u1', username='u', email='e', password_hash='h', created_at=datetime.utcnow())
        mock_get_user.return_value = user
        mock_request.headers.get.return_value = 'Bearer token'

        response = get_analysis_status('nonexistent')
        res, status = response

        self.assertEqual(status, 404)
        self.assertEqual(res['error'], 'Analysis not found')

    @patch('server.request')
    @patch('server.get_user_by_token')
    def test_get_analysis_status_access_denied(self, mock_get_user, mock_request):
        """Verify 403 Forbidden when the analysis belongs to a different user."""
        # Current user
        user_id = 'user123'
        user = User(id=user_id, username='testuser', email='test@example.com',
                    password_hash='hash', created_at=datetime.utcnow())
        mock_get_user.return_value = user
        mock_request.headers.get.return_value = 'Bearer token'

        # Analysis belonging to another user
        analysis_id = 'analysis456'
        analysis = AnalysisRequest(
            id=analysis_id,
            filename='test.apk',
            file_path='/tmp/test.apk',
            user_id='other_user',
            options={}
        )
        server.active_analyses[analysis_id] = analysis

        response = get_analysis_status(analysis_id)
        res, status = response

        self.assertEqual(status, 403)
        self.assertEqual(res['error'], 'Access denied')

    @patch('server.request')
    @patch('server.get_user_by_token')
    def test_get_analysis_status_exception(self, mock_get_user, mock_request):
        """Verify 500 Internal Server Error for unexpected exceptions."""
        mock_get_user.side_effect = Exception("Database error")
        mock_request.headers.get.return_value = 'Bearer token'

        response = get_analysis_status('any_id')
        res, status = response

        self.assertEqual(status, 500)
        self.assertEqual(res['error'], 'Failed to get status')

if __name__ == '__main__':
    unittest.main()
