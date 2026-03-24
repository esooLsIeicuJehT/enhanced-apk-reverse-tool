import sys
from unittest.mock import MagicMock

# Mock dependencies before importing server
mock_flask = MagicMock()
mock_socketio = MagicMock()
mock_cors = MagicMock()
mock_werkzeug = MagicMock()
mock_jwt = MagicMock()
mock_cryptography = MagicMock()

sys.modules['flask'] = mock_flask
sys.modules['flask_cors'] = mock_cors
sys.modules['flask_socketio'] = mock_socketio
sys.modules['werkzeug'] = mock_werkzeug
sys.modules['werkzeug.utils'] = mock_werkzeug.utils
sys.modules['werkzeug.security'] = mock_werkzeug.security
sys.modules['jwt'] = mock_jwt
sys.modules['cryptography'] = mock_cryptography
sys.modules['cryptography.fernet'] = mock_cryptography.fernet
sys.modules['apk_reverse_tool'] = MagicMock()

import os
from pathlib import Path

# Add the parent directory to sys.path to import server
sys.path.append(str(Path(__file__).parent.parent))

import server
from server import allowed_file

# Properly inject MockConfig into the server module
class MockConfig:
    ALLOWED_EXTENSIONS = {'apk'}
    JWT_SECRET_KEY = 'test_secret_key'

server.Config = MockConfig

def test_allowed_file_valid_extension():
    assert allowed_file('test.apk') is True

def test_allowed_file_uppercase_extension():
    assert allowed_file('test.APK') is True

def test_allowed_file_invalid_extension():
    assert allowed_file('test.txt') is False
    assert allowed_file('test.exe') is False

def test_allowed_file_no_extension():
    assert allowed_file('test') is False

def test_allowed_file_multiple_dots():
    assert allowed_file('test.v1.apk') is True
    assert allowed_file('test.v1.txt') is False

def test_allowed_file_empty_filename():
    assert allowed_file('') is False

def test_allowed_file_only_extension():
    assert allowed_file('.apk') is True

def test_allowed_file_hidden_file_no_ext():
    assert allowed_file('.gitignore') is False
