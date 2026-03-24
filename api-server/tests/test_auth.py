import sys
import os
from pathlib import Path
from unittest.mock import MagicMock, patch

# Define custom exception classes for JWT
class ExpiredSignatureError(Exception):
    pass

class InvalidTokenError(Exception):
    pass

# Add the parent directory to sys.path to import server
api_server_path = str(Path(__file__).parent.parent)
if api_server_path not in sys.path:
    sys.path.append(api_server_path)

# Mock dependencies before importing server
mock_jwt = MagicMock()
mock_jwt.ExpiredSignatureError = ExpiredSignatureError
mock_jwt.InvalidTokenError = InvalidTokenError

sys.modules['flask'] = MagicMock()
sys.modules['flask_cors'] = MagicMock()
sys.modules['flask_socketio'] = MagicMock()
sys.modules['werkzeug'] = MagicMock()
sys.modules['werkzeug.utils'] = MagicMock()
sys.modules['werkzeug.security'] = MagicMock()
sys.modules['jwt'] = mock_jwt
sys.modules['cryptography'] = MagicMock()
sys.modules['cryptography.fernet'] = MagicMock()
sys.modules['apk_reverse_tool'] = MagicMock()

# Import server and inject MockConfig
import server

class MockConfig:
    JWT_SECRET_KEY = 'test_secret_key'
    ALLOWED_EXTENSIONS = {'apk'}
    JWT_EXPIRATION_HOURS = 24

server.Config = MockConfig

from server import verify_jwt_token, get_user_by_token, User

def test_verify_jwt_token_success():
    mock_jwt.decode.side_effect = None
    mock_jwt.decode.return_value = {'user_id': 'test_user_123'}
    result = verify_jwt_token('valid_token')
    assert result == 'test_user_123'
    mock_jwt.decode.assert_called_with('valid_token', 'test_secret_key', algorithms=['HS256'])

def test_verify_jwt_token_expired():
    mock_jwt.decode.side_effect = ExpiredSignatureError()
    result = verify_jwt_token('expired_token')
    assert result is None

def test_verify_jwt_token_invalid():
    mock_jwt.decode.side_effect = InvalidTokenError()
    result = verify_jwt_token('invalid_token')
    assert result is None

def test_get_user_by_token_success():
    user_id = 'user1'
    mock_user = User(id=user_id, username='testuser', email='test@example.com', password_hash='hash', created_at=None)
    server.user_sessions = {user_id: {'user': mock_user}}

    with patch('server.verify_jwt_token') as mock_verify:
        mock_verify.return_value = user_id
        result = get_user_by_token('some_token')
        assert result == mock_user

def test_get_user_by_token_user_not_found():
    server.user_sessions = {}

    with patch('server.verify_jwt_token') as mock_verify:
        mock_verify.return_value = 'non_existent_user'
        result = get_user_by_token('some_token')
        assert result is None

def test_get_user_by_token_invalid_token():
    with patch('server.verify_jwt_token') as mock_verify:
        mock_verify.return_value = None
        result = get_user_by_token('invalid_token')
        assert result is None
