#!/usr/bin/env python3
"""
Enhanced APK Reverse Engineering Tool - API Server
Provides REST API and WebSocket support for mobile and web interfaces
"""

import os
import sys
import json
import uuid
import asyncio
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, asdict
from functools import lru_cache

# Flask and Web Framework
from flask import Flask, request, jsonify, send_file, send_from_directory
from flask_cors import CORS
from flask_socketio import SocketIO, emit, join_room, leave_room
from werkzeug.utils import secure_filename
from werkzeug.security import generate_password_hash, check_password_hash

# File processing
import zipfile
import tempfile
import shutil
from multiprocessing import Process, Queue

# Security
import jwt
from cryptography.fernet import Fernet
import secrets

# Analysis Tool Integration
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from apk_reverse_tool import APKAnalyzer

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('api_server.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Configuration
class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', secrets.token_urlsafe(32))
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', secrets.token_urlsafe(32))
    UPLOAD_FOLDER = 'uploads'
    RESULTS_FOLDER = 'results'
    MAX_CONTENT_LENGTH = 100 * 1024 * 1024  # 100MB max file size
    ALLOWED_EXTENSIONS = {'apk'}
    JWT_EXPIRATION_HOURS = 24
    ANALYSIS_TIMEOUT = 3600  # 1 hour

# Initialize Flask app
app = Flask(__name__)
app.config.from_object(Config)

# Enable CORS
CORS(app, origins="*")

# Initialize SocketIO
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')

# Ensure directories exist
os.makedirs(Config.UPLOAD_FOLDER, exist_ok=True)
os.makedirs(Config.RESULTS_FOLDER, exist_ok=True)

# Global state
analysis_queue = Queue()
active_analyses = {}
user_sessions = {}

# Data models
@dataclass
class AnalysisRequest:
    id: str
    filename: str
    file_path: str
    user_id: str
    options: Dict[str, Any]
    status: str = "queued"
    progress: int = 0
    current_step: str = ""
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    result: Optional[Dict[str, Any]] = None
    error: Optional[str] = None

@dataclass
class User:
    id: str
    username: str
    email: str
    password_hash: str
    created_at: datetime
    last_login: Optional[datetime] = None

# Utility functions
def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in Config.ALLOWED_EXTENSIONS

def generate_analysis_id():
    return str(uuid.uuid4())

def generate_jwt_token(user_id):
    payload = {
        'user_id': user_id,
        'exp': datetime.utcnow() + timedelta(hours=Config.JWT_EXPIRATION_HOURS),
        'iat': datetime.utcnow()
    }
    return jwt.encode(payload, Config.JWT_SECRET_KEY, algorithm='HS256')

def verify_jwt_token(token):
    try:
        payload = jwt.decode(token, Config.JWT_SECRET_KEY, algorithms=['HS256'])
        return payload['user_id']
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

def get_user_by_token(token):
    user_id = verify_jwt_token(token)
    if user_id and user_id in user_sessions:
        return user_sessions[user_id]['user']
    return None

# Analysis worker function
def analysis_worker():
    """Background worker for processing APK analysis"""
    logger.info("Analysis worker started")
    
    while True:
        try:
            analysis_id = analysis_queue.get(timeout=1)
            if analysis_id not in active_analyses:
                continue
                
            analysis = active_analyses[analysis_id]
            
            # Update status
            analysis.status = "running"
            analysis.started_at = datetime.utcnow()
            
            # Emit status update
            socketio.emit('analysis_update', {
                'analysis_id': analysis_id,
                'status': 'running',
                'progress': 0,
                'current_step': 'Initializing analysis'
            }, room=analysis_id)
            
            # Run analysis
            try:
                result = run_apk_analysis(analysis, socketio)
                
                analysis.status = "completed"
                analysis.completed_at = datetime.utcnow()
                analysis.result = result
                analysis.progress = 100
                
                # Save results
                results_path = os.path.join(Config.RESULTS_FOLDER, f"{analysis_id}_results.json")
                with open(results_path, 'w') as f:
                    json.dump(result, f, indent=2, default=str)
                
                # Emit completion
                socketio.emit('analysis_complete', {
                    'analysis_id': analysis_id,
                    'result': result
                }, room=analysis_id)
                
                logger.info(f"Analysis {analysis_id} completed successfully")
                
            except Exception as e:
                analysis.status = "failed"
                analysis.error = str(e)
                
                # Emit error
                socketio.emit('analysis_error', {
                    'analysis_id': analysis_id,
                    'error': str(e)
                }, room=analysis_id)
                
                logger.error(f"Analysis {analysis_id} failed: {e}")
                
        except Exception as e:
            logger.error(f"Worker error: {e}")

def run_apk_analysis(analysis, socketio):
    """Run the actual APK analysis"""
    
    def progress_callback(step, progress):
        analysis.current_step = step
        analysis.progress = progress
        
        socketio.emit('analysis_progress', {
            'analysis_id': analysis.id,
            'progress': progress,
            'current_step': step
        }, room=analysis.id)
    
    try:
        # Initialize analyzer (this would be the actual tool integration)
        analyzer = APKAnalyzer()
        
        # Run analysis with progress callbacks
        result = analyzer.analyze_with_progress(
            analysis.file_path,
            analysis.options,
            progress_callback
        )
        
        return result
        
    except Exception as e:
        logger.error(f"Analysis failed: {e}")
        raise

# Authentication endpoints
@app.route('/api/auth/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        username = data.get('username')
        email = data.get('email')
        password = data.get('password')
        
        if not all([username, email, password]):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Check if user already exists
        for session in user_sessions.values():
            if session['user'].email == email or session['user'].username == username:
                return jsonify({'error': 'User already exists'}), 409
        
        # Create new user
        user = User(
            id=str(uuid.uuid4()),
            username=username,
            email=email,
            password_hash=generate_password_hash(password),
            created_at=datetime.utcnow()
        )
        
        user_sessions[user.id] = {
            'user': user,
            'analyses': []
        }
        
        token = generate_jwt_token(user.id)
        
        return jsonify({
            'token': token,
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email
            }
        }), 201
        
    except Exception as e:
        logger.error(f"Registration error: {e}")
        return jsonify({'error': 'Registration failed'}), 500

@app.route('/api/auth/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        username = data.get('username')
        password = data.get('password')
        
        if not all([username, password]):
            return jsonify({'error': 'Missing username or password'}), 400
        
        # Find user
        user = None
        for session in user_sessions.values():
            if session['user'].username == username:
                user = session['user']
                break
        
        if not user or not check_password_hash(user.password_hash, password):
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Update last login
        user.last_login = datetime.utcnow()
        
        token = generate_jwt_token(user.id)
        
        return jsonify({
            'token': token,
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email
            }
        })
        
    except Exception as e:
        logger.error(f"Login error: {e}")
        return jsonify({'error': 'Login failed'}), 500

# Analysis endpoints
@app.route('/api/analysis/upload', methods=['POST'])
def upload_file():
    try:
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        user = get_user_by_token(token)
        
        if not user:
            return jsonify({'error': 'Authentication required'}), 401
        
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        if not allowed_file(file.filename):
            return jsonify({'error': 'File type not allowed'}), 400
        
        # Get analysis options
        options = request.form.get('options', '{}')
        try:
            analysis_options = json.loads(options)
        except json.JSONDecodeError:
            analysis_options = {}
        
        # Generate unique filename
        analysis_id = generate_analysis_id()
        filename = secure_filename(file.filename)
        file_path = os.path.join(Config.UPLOAD_FOLDER, f"{analysis_id}_{filename}")
        
        # Save file
        file.save(file_path)
        
        # Create analysis request
        analysis = AnalysisRequest(
            id=analysis_id,
            filename=filename,
            file_path=file_path,
            user_id=user.id,
            options=analysis_options,
            status="queued",
            started_at=datetime.utcnow()
        )
        
        active_analyses[analysis_id] = analysis
        
        # Add to user's analyses
        user_sessions[user.id]['analyses'].append(analysis_id)
        
        # Queue for analysis
        analysis_queue.put(analysis_id)
        
        return jsonify({
            'analysis_id': analysis_id,
            'status': 'queued',
            'message': 'File uploaded successfully'
        }), 201
        
    except Exception as e:
        logger.error(f"Upload error: {e}")
        return jsonify({'error': 'Upload failed'}), 500

@app.route('/api/analysis/<analysis_id>/status', methods=['GET'])
def get_analysis_status(analysis_id):
    try:
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        user = get_user_by_token(token)
        
        if not user:
            return jsonify({'error': 'Authentication required'}), 401
        
        if analysis_id not in active_analyses:
            return jsonify({'error': 'Analysis not found'}), 404
        
        analysis = active_analyses[analysis_id]
        
        if analysis.user_id != user.id:
            return jsonify({'error': 'Access denied'}), 403
        
        response = {
            'id': analysis.id,
            'status': analysis.status,
            'progress': analysis.progress,
            'current_step': analysis.current_step,
            'started_at': analysis.started_at.isoformat() if analysis.started_at else None,
            'completed_at': analysis.completed_at.isoformat() if analysis.completed_at else None
        }
        
        if analysis.error:
            response['error'] = analysis.error
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Status error: {e}")
        return jsonify({'error': 'Failed to get status'}), 500

@app.route('/api/analysis/<analysis_id>/results', methods=['GET'])
def get_analysis_results(analysis_id):
    try:
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        user = get_user_by_token(token)
        
        if not user:
            return jsonify({'error': 'Authentication required'}), 401
        
        if analysis_id not in active_analyses:
            return jsonify({'error': 'Analysis not found'}), 404
        
        analysis = active_analyses[analysis_id]
        
        if analysis.user_id != user.id:
            return jsonify({'error': 'Access denied'}), 403
        
        if analysis.status != 'completed':
            return jsonify({'error': 'Analysis not completed'}), 400
        
        return jsonify(analysis.result)
        
    except Exception as e:
        logger.error(f"Results error: {e}")
        return jsonify({'error': 'Failed to get results'}), 500

@app.route('/api/analysis/history', methods=['GET'])
def get_analysis_history():
    try:
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        user = get_user_by_token(token)
        
        if not user:
            return jsonify({'error': 'Authentication required'}), 401
        
        user_analysis_ids = user_sessions[user.id]['analyses']
        history = []
        
        for analysis_id in user_analysis_ids:
            if analysis_id in active_analyses:
                analysis = active_analyses[analysis_id]
                history.append({
                    'id': analysis.id,
                    'filename': analysis.filename,
                    'status': analysis.status,
                    'progress': analysis.progress,
                    'started_at': analysis.started_at.isoformat() if analysis.started_at else None,
                    'completed_at': analysis.completed_at.isoformat() if analysis.completed_at else None
                })
        
        # Sort by started_at descending
        history.sort(key=lambda x: x['started_at'] or '', reverse=True)
        
        return jsonify({'history': history})
        
    except Exception as e:
        logger.error(f"History error: {e}")
        return jsonify({'error': 'Failed to get history'}), 500

# WebSocket events
@socketio.on('connect')
def handle_connect():
    logger.info("Client connected")

@socketio.on('disconnect')
def handle_disconnect():
    logger.info("Client disconnected")

@socketio.on('join_analysis')
def handle_join_analysis(data):
    analysis_id = data.get('analysis_id')
    if analysis_id:
        join_room(analysis_id)
        logger.info(f"Client joined analysis room: {analysis_id}")
        emit('joined', {'analysis_id': analysis_id})

@socketio.on('leave_analysis')
def handle_leave_analysis(data):
    analysis_id = data.get('analysis_id')
    if analysis_id:
        leave_room(analysis_id)
        logger.info(f"Client left analysis room: {analysis_id}")
        emit('left', {'analysis_id': analysis_id})

# Health check
@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'active_analyses': len(active_analyses),
        'queued_analyses': analysis_queue.qsize()
    })

# Static file serving for web interface
@app.route('/')
def serve_web_interface():
    return send_from_directory('../web-interface/build', 'index.html')

@app.route('/static/<path:filename>')
def serve_static_files(filename):
    return send_from_directory('../web-interface/build/static', filename)

# Start analysis worker
def start_analysis_worker():
    worker = Process(target=analysis_worker)
    worker.daemon = True
    worker.start()
    return worker

# Main entry point
if __name__ == '__main__':
    logger.info("Starting Enhanced APK Reverse Engineering Tool API Server")
    
    # Start analysis worker
    worker = start_analysis_worker()
    
    # Start server
    socketio.run(
        app,
        host='0.0.0.0',
        port=8080,
        debug=False,
        allow_unsafe_werkzeug=True
    )