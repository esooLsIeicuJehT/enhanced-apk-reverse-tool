import sys
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch
from datetime import datetime

# Define dummy classes to satisfy imports in server.py
class MockConfigObj:
    def from_object(self, *args, **kwargs):
        pass

class MockFlask:
    def __init__(self, *args, **kwargs):
        self.config = MockConfigObj()
    def route(self, *args, **kwargs):
        return lambda f: f

mock_flask_mod = MagicMock()
mock_flask_mod.Flask = MockFlask
mock_flask_mod.request = MagicMock()

def mock_jsonify(d, status=None):
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

# Inject MockConfig
class MockConfig:
    JWT_SECRET_KEY = 'test_secret_key'
    ALLOWED_EXTENSIONS = {'apk'}
    JWT_EXPIRATION_HOURS = 24
    UPLOAD_FOLDER = 'uploads'
    RESULTS_FOLDER = 'results'

server.Config = MockConfig
from server import User, register, login

class TestAuth(unittest.TestCase):
    def setUp(self):
        # Reset global state
        server.user_sessions.clear()
        server.username_to_id.clear()
        server.email_to_id.clear()

    @patch('server.request')
    @patch('server.generate_password_hash')
    @patch('server.generate_jwt_token')
    def test_register_success(self, mock_jwt_gen, mock_hash, mock_request):
        mock_request.get_json.return_value = {
            'username': 'testuser',
            'email': 'test@example.com',
            'password': 'password123'
        }
        mock_hash.return_value = 'hashed_password'
        mock_jwt_gen.return_value = 'test_token'

        response = register()
        res, status = response

        self.assertEqual(status, 201)
        self.assertEqual(res['user']['username'], 'testuser')
        self.assertIn('testuser', server.username_to_id)
        self.assertIn('test@example.com', server.email_to_id)

    @patch('server.request')
    def test_register_duplicate(self, mock_request):
        user_id = 'user123'
        server.username_to_id['testuser'] = user_id
        server.email_to_id['test@example.com'] = user_id

        mock_request.get_json.return_value = {
            'username': 'testuser',
            'email': 'other@example.com',
            'password': 'password123'
        }

        response = register()
        res, status = response
        self.assertEqual(status, 409)
        self.assertEqual(res['error'], 'User already exists')

    @patch('server.request')
    @patch('server.check_password_hash')
    @patch('server.generate_jwt_token')
    def test_login_success(self, mock_jwt_gen, mock_check_hash, mock_request):
        user_id = 'user123'
        user = User(id=user_id, username='testuser', email='test@example.com',
                    password_hash='hashed_password', created_at=datetime.utcnow())
        server.user_sessions[user_id] = {'user': user, 'analyses': []}
        server.username_to_id['testuser'] = user_id

        mock_request.get_json.return_value = {
            'username': 'testuser',
            'password': 'password123'
        }
        mock_check_hash.return_value = True
        mock_jwt_gen.return_value = 'test_token'

        response = login()
        self.assertEqual(response['token'], 'test_token')
        self.assertEqual(response['user']['username'], 'testuser')

    @patch('server.request')
    def test_login_fail_not_found(self, mock_request):
        mock_request.get_json.return_value = {
            'username': 'nonexistent',
            'password': 'password123'
        }

        response = login()
        res, status = response
        self.assertEqual(status, 401)
        self.assertEqual(res['error'], 'Invalid credentials')

if __name__ == '__main__':
    unittest.main()
