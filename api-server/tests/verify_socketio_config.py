import sys
from unittest.mock import MagicMock, patch

# Mock all dependencies to avoid side effects during import
sys.modules['flask'] = MagicMock()
sys.modules['flask_cors'] = MagicMock()
sys.modules['flask_socketio'] = MagicMock()
sys.modules['werkzeug'] = MagicMock()
sys.modules['werkzeug.utils'] = MagicMock()
sys.modules['werkzeug.security'] = MagicMock()
sys.modules['jwt'] = MagicMock()
sys.modules['cryptography'] = MagicMock()
sys.modules['cryptography.fernet'] = MagicMock()
sys.modules['apk_reverse_tool'] = MagicMock()

def test_socketio_config():
    # We want to check the call to socketio.run(app, ...)
    # Since socketio is initialized in server.py, we can patch its run method
    with patch('flask_socketio.SocketIO.run') as mock_run:
        # Import server inside the patch to trigger the __main__ block if we were running it,
        # but server.py has the run call inside `if __name__ == '__main__':`
        # So we'll have to manually call the main part or check the file content.
        # Actually, let's just check the file content as a simpler and more reliable way
        # for this specific case, or use a more sophisticated mock if we want to "run" it.

        # Given the environment, checking the file content via a script is also valid.
        import os
        server_path = os.path.join(os.path.dirname(__file__), '../server.py')
        with open(server_path, 'r') as f:
            content = f.read()

        errors = []
        if 'allow_unsafe_werkzeug=True' in content:
            errors.append("allow_unsafe_werkzeug=True is present in server.py")

        if 'cors_allowed_origins="*"' in content:
            errors.append('cors_allowed_origins="*" is present in server.py')

        if 'origins="*"' in content:
            errors.append('origins="*" is present in server.py')

        if not 'cors_allowed_origins=Config.CORS_ALLOWED_ORIGINS' in content:
            errors.append('cors_allowed_origins=Config.CORS_ALLOWED_ORIGINS is missing in server.py')

        if not 'origins=Config.CORS_ALLOWED_ORIGINS' in content:
            errors.append('origins=Config.CORS_ALLOWED_ORIGINS is missing in server.py')

        if errors:
            for error in errors:
                print(f"VULNERABILITY_FOUND: {error}")
            sys.exit(1)
        else:
            print("VULNERABILITY_FIXED: CORS is restricted and allow_unsafe_werkzeug=True is not present.")
            sys.exit(0)

if __name__ == "__main__":
    test_socketio_config()
