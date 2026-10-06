export type AuthUser = {
  id: string;
  username: string;
  email: string;
};

export type AuthResponse = {
  token: string;
  user: AuthUser;
};

export type AnalysisStatus = {
  id: string;
  filename: string;
  status: 'queued' | 'running' | 'completed' | 'failed' | string;
  progress: number;
  current_step: string;
  created_at: string;
  started_at: string | null;
  completed_at: string | null;
  error: string | null;
};

export type HistoryItem = AnalysisStatus;

export type AnalysisOptions = {
  deep_analysis: boolean;
  vulnerability_scan: boolean;
  certificate_analysis: boolean;
  permission_analysis: boolean;
  code_analysis: boolean;
  owasp_scan: boolean;
  malware_detection: boolean;
};

type ApiErrorBody = {
  error?: string;
};

async function parseResponse<T>(response: Response): Promise<T> {
  const contentType = response.headers.get('content-type') || '';
  const body = contentType.includes('application/json')
    ? ((await response.json()) as T & ApiErrorBody)
    : ({} as T & ApiErrorBody);

  if (!response.ok) {
    throw new Error(body.error || `Request failed with status ${response.status}`);
  }

  return body;
}

function authHeaders(token: string): HeadersInit {
  return {
    Authorization: `Bearer ${token}`,
  };
}

export async function register(
  username: string,
  email: string,
  password: string,
): Promise<AuthResponse> {
  const response = await fetch('/api/auth/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, email, password }),
  });
  return parseResponse<AuthResponse>(response);
}

export async function login(username: string, password: string): Promise<AuthResponse> {
  const response = await fetch('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });
  return parseResponse<AuthResponse>(response);
}

export async function uploadApk(
  token: string,
  file: File,
  options: AnalysisOptions,
): Promise<{ analysis_id: string; status: string; message: string }> {
  const form = new FormData();
  form.append('file', file);
  form.append('options', JSON.stringify(options));

  const response = await fetch('/api/analysis/upload', {
    method: 'POST',
    headers: authHeaders(token),
    body: form,
  });
  return parseResponse(response);
}

export async function getAnalysisStatus(token: string, analysisId: string): Promise<AnalysisStatus> {
  const response = await fetch(`/api/analysis/${encodeURIComponent(analysisId)}/status`, {
    headers: authHeaders(token),
  });
  return parseResponse<AnalysisStatus>(response);
}

export async function getAnalysisResults(token: string, analysisId: string): Promise<unknown> {
  const response = await fetch(`/api/analysis/${encodeURIComponent(analysisId)}/results`, {
    headers: authHeaders(token),
  });
  return parseResponse<unknown>(response);
}

export async function getHistory(token: string): Promise<HistoryItem[]> {
  const response = await fetch('/api/analysis/history', {
    headers: authHeaders(token),
  });
  const body = await parseResponse<{ history: HistoryItem[] }>(response);
  return body.history;
}
