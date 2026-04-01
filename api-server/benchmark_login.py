import time
import uuid
from dataclasses import dataclass
from typing import Optional, Dict, Any
from datetime import datetime

@dataclass
class User:
    id: str
    username: str
    email: str
    password_hash: str
    created_at: datetime
    last_login: Optional[datetime] = None

user_sessions = {}
username_to_id = {} # For optimized version

def populate_users(n):
    user_sessions.clear()
    username_to_id.clear()
    for i in range(n):
        u_id = str(uuid.uuid4())
        username = f"user_{i}"
        user = User(
            id=u_id,
            username=username,
            email=f"user_{i}@example.com",
            password_hash="hash",
            created_at=datetime.utcnow()
        )
        user_sessions[u_id] = {
            'user': user,
            'analyses': []
        }
        username_to_id[username] = u_id

def original_login_search(username):
    user = None
    for session in user_sessions.values():
        if session['user'].username == username:
            user = session['user']
            break
    return user

def optimized_login_search(username):
    user_id = username_to_id.get(username)
    if user_id:
        return user_sessions[user_id]['user']
    return None

# Benchmark
N = 10000
print(f"Populating {N} users...")
populate_users(N)

target_username = f"user_{N-1}"
iterations = 1000

print(f"Running {iterations} iterations of original search...")
start_time = time.time()
for _ in range(iterations):
    original_login_search(target_username)
original_duration = time.time() - start_time
print(f"Original search took: {original_duration:.4f} seconds")

print(f"Running {iterations} iterations of optimized search...")
start_time = time.time()
for _ in range(iterations):
    optimized_login_search(target_username)
optimized_duration = time.time() - start_time
print(f"Optimized search took: {optimized_duration:.4f} seconds")

if optimized_duration > 0:
    speedup = original_duration / optimized_duration
    print(f"Speedup: {speedup:.2f}x")
else:
    print("Optimized search was too fast to measure accurately.")
