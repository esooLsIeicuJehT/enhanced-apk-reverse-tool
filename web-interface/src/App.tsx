import React, { FormEvent, useEffect, useMemo, useState } from 'react';
import {
  AnalysisOptions,
  AnalysisStatus,
  AuthResponse,
  HistoryItem,
  getAnalysisResults,
  getAnalysisStatus,
  getHistory,
  login,
  register,
  uploadApk,
} from './api';
import './styles.css';

const DEFAULT_OPTIONS: AnalysisOptions = {
  deep_analysis: false,
  vulnerability_scan: true,
  certificate_analysis: true,
  permission_analysis: true,
  code_analysis: true,
  owasp_scan: true,
  malware_detection: true,
};

const OPTION_LABELS: Record<keyof AnalysisOptions, string> = {
  deep_analysis: 'Deep analysis',
  vulnerability_scan: 'Vulnerability scan',
  certificate_analysis: 'Certificate analysis',
  permission_analysis: 'Permission analysis',
  code_analysis: 'Code analysis',
  owasp_scan: 'OWASP scan',
  malware_detection: 'Malware detection',
};

type AuthMode = 'login' | 'register';

type Session = AuthResponse;

function loadSession(): Session | null {
  try {
    const value = sessionStorage.getItem('apk-tool-session');
    return value ? (JSON.parse(value) as Session) : null;
  } catch {
    sessionStorage.removeItem('apk-tool-session');
    return null;
  }
}

function formatDate(value: string | null | undefined): string {
  if (!value) return '—';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? value : date.toLocaleString();
}

function statusTone(status: string): string {
  if (status === 'completed') return 'status completed';
  if (status === 'failed') return 'status failed';
  if (status === 'running') return 'status running';
  return 'status queued';
}

const App: React.FC = () => {
  const [session, setSession] = useState<Session | null>(() => loadSession());
  const [authMode, setAuthMode] = useState<AuthMode>('login');
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [options, setOptions] = useState<AnalysisOptions>(DEFAULT_OPTIONS);
  const [analysisId, setAnalysisId] = useState<string | null>(null);
  const [analysis, setAnalysis] = useState<AnalysisStatus | null>(null);
  const [result, setResult] = useState<unknown>(null);
  const [history, setHistory] = useState<HistoryItem[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const token = session?.token || '';
  const fileLabel = useMemo(() => {
    if (!file) return 'Choose an APK file';
    const megabytes = file.size / (1024 * 1024);
    return `${file.name} · ${megabytes.toFixed(1)} MB`;
  }, [file]);

  const persistSession = (next: Session | null) => {
    setSession(next);
    if (next) {
      sessionStorage.setItem('apk-tool-session', JSON.stringify(next));
    } else {
      sessionStorage.removeItem('apk-tool-session');
    }
  };

  const refreshHistory = async (authToken = token) => {
    if (!authToken) return;
    try {
      setHistory(await getHistory(authToken));
    } catch (historyError) {
      setError(historyError instanceof Error ? historyError.message : 'Unable to load analysis history');
    }
  };

  useEffect(() => {
    if (token) void refreshHistory(token);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token]);

  useEffect(() => {
    if (!token || !analysisId) return undefined;

    let cancelled = false;
    let timer: number | undefined;

    const poll = async () => {
      try {
        const next = await getAnalysisStatus(token, analysisId);
        if (cancelled) return;
        setAnalysis(next);

        if (next.status === 'completed') {
          const nextResult = await getAnalysisResults(token, analysisId);
          if (!cancelled) {
            setResult(nextResult);
            void refreshHistory(token);
          }
          return;
        }

        if (next.status === 'failed') {
          void refreshHistory(token);
          return;
        }

        timer = window.setTimeout(poll, 2000);
      } catch (pollError) {
        if (!cancelled) {
          setError(pollError instanceof Error ? pollError.message : 'Unable to refresh analysis status');
        }
      }
    };

    void poll();
    return () => {
      cancelled = true;
      if (timer !== undefined) window.clearTimeout(timer);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [analysisId, token]);

  const submitAuth = async (event: FormEvent) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const response = authMode === 'login'
        ? await login(username, password)
        : await register(username, email, password);
      persistSession(response);
      setPassword('');
    } catch (authError) {
      setError(authError instanceof Error ? authError.message : 'Authentication failed');
    } finally {
      setBusy(false);
    }
  };

  const submitAnalysis = async (event: FormEvent) => {
    event.preventDefault();
    if (!file || !token) return;
    if (!file.name.toLowerCase().endsWith('.apk')) {
      setError('Select a file ending in .apk');
      return;
    }

    setBusy(true);
    setError(null);
    setResult(null);
    setAnalysis(null);
    try {
      const response = await uploadApk(token, file, options);
      setAnalysisId(response.analysis_id);
      setFile(null);
      await refreshHistory(token);
    } catch (uploadError) {
      setError(uploadError instanceof Error ? uploadError.message : 'Upload failed');
    } finally {
      setBusy(false);
    }
  };

  const selectHistory = async (item: HistoryItem) => {
    setError(null);
    setResult(null);
    setAnalysis(item);
    setAnalysisId(item.id);
    if (item.status === 'completed') {
      try {
        setResult(await getAnalysisResults(token, item.id));
      } catch (resultError) {
        setError(resultError instanceof Error ? resultError.message : 'Unable to load result');
      }
    }
  };

  const logout = () => {
    persistSession(null);
    setAnalysisId(null);
    setAnalysis(null);
    setResult(null);
    setHistory([]);
    setError(null);
  };

  if (!session) {
    return (
      <main className="auth-shell">
        <section className="auth-card">
          <div className="brand-mark" aria-hidden="true">A</div>
          <p className="eyebrow">Enhanced APK Reverse Tool</p>
          <h1>APK analysis without the duct tape.</h1>
          <p className="muted">Authenticate to upload an APK and run the server-side security analysis pipeline.</p>

          <div className="tab-row" role="tablist" aria-label="Authentication mode">
            <button
              type="button"
              className={authMode === 'login' ? 'tab active' : 'tab'}
              onClick={() => setAuthMode('login')}
            >
              Sign in
            </button>
            <button
              type="button"
              className={authMode === 'register' ? 'tab active' : 'tab'}
              onClick={() => setAuthMode('register')}
            >
              Create account
            </button>
          </div>

          <form onSubmit={submitAuth} className="stack">
            <label>
              Username
              <input
                autoComplete="username"
                value={username}
                onChange={(event) => setUsername(event.target.value)}
                minLength={3}
                maxLength={64}
                required
              />
            </label>
            {authMode === 'register' && (
              <label>
                Email
                <input
                  type="email"
                  autoComplete="email"
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                  required
                />
              </label>
            )}
            <label>
              Password
              <input
                type="password"
                autoComplete={authMode === 'login' ? 'current-password' : 'new-password'}
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                minLength={authMode === 'register' ? 10 : undefined}
                required
              />
            </label>
            {error && <div className="alert error">{error}</div>}
            <button type="submit" className="primary" disabled={busy}>
              {busy ? 'Working…' : authMode === 'login' ? 'Sign in' : 'Create account'}
            </button>
          </form>
        </section>
      </main>
    );
  }

  return (
    <main className="app-shell">
      <header className="topbar">
        <div>
          <p className="eyebrow">Enhanced APK Reverse Tool</p>
          <h1>Analysis Console</h1>
        </div>
        <div className="account-actions">
          <span>{session.user.username}</span>
          <button type="button" className="secondary" onClick={logout}>Sign out</button>
        </div>
      </header>

      {error && (
        <div className="alert error dismissible">
          <span>{error}</span>
          <button type="button" onClick={() => setError(null)} aria-label="Dismiss error">×</button>
        </div>
      )}

      <div className="dashboard-grid">
        <section className="panel upload-panel">
          <div className="panel-heading">
            <div>
              <p className="eyebrow">New analysis</p>
              <h2>Upload APK</h2>
            </div>
            <span className="pill">Server validated</span>
          </div>

          <form onSubmit={submitAnalysis} className="stack">
            <label className="file-picker">
              <input
                type="file"
                accept=".apk,application/vnd.android.package-archive"
                onChange={(event) => setFile(event.target.files?.[0] || null)}
              />
              <strong>{fileLabel}</strong>
              <span>The server verifies the archive before it enters the analysis queue.</span>
            </label>

            <fieldset>
              <legend>Analysis modules</legend>
              <div className="option-grid">
                {(Object.keys(OPTION_LABELS) as Array<keyof AnalysisOptions>).map((key) => (
                  <label className="check-row" key={key}>
                    <input
                      type="checkbox"
                      checked={options[key]}
                      onChange={(event) => setOptions((current) => ({ ...current, [key]: event.target.checked }))}
                    />
                    <span>{OPTION_LABELS[key]}</span>
                  </label>
                ))}
              </div>
            </fieldset>

            <button type="submit" className="primary" disabled={!file || busy}>
              {busy ? 'Uploading…' : 'Start analysis'}
            </button>
          </form>
        </section>

        <section className="panel status-panel">
          <div className="panel-heading">
            <div>
              <p className="eyebrow">Current run</p>
              <h2>Status</h2>
            </div>
            {analysis && <span className={statusTone(analysis.status)}>{analysis.status}</span>}
          </div>

          {!analysis ? (
            <div className="empty-state">Upload an APK or select a previous run.</div>
          ) : (
            <div className="stack compact">
              <div className="progress-track" aria-label={`Analysis progress ${analysis.progress}%`}>
                <div className="progress-fill" style={{ width: `${Math.max(0, Math.min(100, analysis.progress))}%` }} />
              </div>
              <div className="metric-row"><span>Progress</span><strong>{analysis.progress}%</strong></div>
              <div className="metric-row"><span>Step</span><strong>{analysis.current_step || '—'}</strong></div>
              <div className="metric-row"><span>File</span><strong>{analysis.filename}</strong></div>
              <div className="metric-row"><span>Started</span><strong>{formatDate(analysis.started_at)}</strong></div>
              <div className="metric-row"><span>Completed</span><strong>{formatDate(analysis.completed_at)}</strong></div>
              {analysis.error && <div className="alert error">{analysis.error}</div>}
            </div>
          )}
        </section>

        <section className="panel history-panel">
          <div className="panel-heading">
            <div>
              <p className="eyebrow">Durable history</p>
              <h2>Recent analyses</h2>
            </div>
            <button type="button" className="secondary" onClick={() => void refreshHistory()}>
              Refresh
            </button>
          </div>

          <div className="history-list">
            {history.length === 0 ? (
              <div className="empty-state">No analyses yet.</div>
            ) : history.map((item) => (
              <button
                type="button"
                className={analysisId === item.id ? 'history-row selected' : 'history-row'}
                onClick={() => void selectHistory(item)}
                key={item.id}
              >
                <span className="history-main">
                  <strong>{item.filename}</strong>
                  <small>{formatDate(item.created_at)}</small>
                </span>
                <span className={statusTone(item.status)}>{item.status}</span>
              </button>
            ))}
          </div>
        </section>

        <section className="panel result-panel">
          <div className="panel-heading">
            <div>
              <p className="eyebrow">Machine-readable report</p>
              <h2>Result</h2>
            </div>
          </div>
          {result === null ? (
            <div className="empty-state">A completed analysis report will appear here.</div>
          ) : (
            <pre className="result-json">{JSON.stringify(result, null, 2)}</pre>
          )}
        </section>
      </div>
    </main>
  );
};

export default App;
