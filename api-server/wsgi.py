"""Gunicorn entrypoint for the APK analysis API."""

from server import app, start_analysis_worker

start_analysis_worker()

__all__ = ["app"]
