import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  IconButton,
  Chip,
  LinearProgress,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Divider,
  Avatar,
  Alert
} from '@mui/material';
import {
  Refresh as RefreshIcon,
  Storage as StorageIcon,
  Security as SecurityIcon,
  TrendingUp as TrendingUpIcon,
  Schedule as ScheduleIcon,
  Smartphone as SmartphoneIcon,
  Delete as DeleteIcon,
  CloudUpload as CloudUploadIcon,
  CheckCircle as CheckCircleIcon,
  Pending as PendingIcon,
  Error as ErrorIcon,
  Warning as WarningIcon,
  Info as InfoIcon,
  Folder as FolderIcon,
  Description as DescriptionIcon,
  Assessment as AssessmentIcon
} from '@mui/icons-material';
import { SecurityScoreChart } from './Charts';

interface RecentAnalysis {
  id: string;
  packageName: string;
  fileName: string;
  date: string;
  status: 'completed' | 'running' | 'failed' | 'queued';
  securityScore?: number;
  vulnerabilities?: number;
}

interface DashboardWidgetsProps {
  recentAnalyses?: RecentAnalysis[];
  onRefresh?: () => void;
}

export const QuickStatsWidget: React.FC<DashboardWidgetsProps> = ({ recentAnalyses, onRefresh }) => {
  const stats = {
    totalAnalyses: recentAnalyses?.length || 0,
    completed: recentAnalyses?.filter(a => a.status === 'completed').length || 0,
    running: recentAnalyses?.filter(a => a.status === 'running').length || 0,
    failed: recentAnalyses?.filter(a => a.status === 'failed').length || 0,
    avgSecurityScore: calculateAvgScore(recentAnalyses)
  };

  return (
    <Grid container spacing={2}>
      <Grid item xs={6} sm={3}>
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Box>
                <Typography variant="h4" component="div">
                  {stats.totalAnalyses}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Total Analyses
                </Typography>
              </Box>
              <Avatar sx={{ bgcolor: 'primary.main' }}>
                <AssessmentIcon />
              </Avatar>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      <Grid item xs={6} sm={3}>
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Box>
                <Typography variant="h4" component="div" color="success.main">
                  {stats.completed}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Completed
                </Typography>
              </Box>
              <Avatar sx={{ bgcolor: 'success.main' }}>
                <CheckCircleIcon />
              </Avatar>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      <Grid item xs={6} sm={3}>
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Box>
                <Typography variant="h4" component="div" color="warning.main">
                  {stats.running}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Running
                </Typography>
              </Box>
              <Avatar sx={{ bgcolor: 'warning.main' }}>
                <PendingIcon />
              </Avatar>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      <Grid item xs={6} sm={3}>
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Box>
                <Typography variant="h4" component="div" color="error.main">
                  {stats.failed}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Failed
                </Typography>
              </Box>
              <Avatar sx={{ bgcolor: 'error.main' }}>
                <ErrorIcon />
              </Avatar>
            </Box>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );
};

export const SystemStatusWidget: React.FC = () => {
  const [systemStatus, setSystemStatus] = useState({
    cpuUsage: 45,
    memoryUsage: 62,
    diskUsage: 34,
    activeAnalyses: 2,
    queueLength: 5,
    lastUpdate: new Date()
  });

  useEffect(() => {
    const interval = setInterval(() => {
      setSystemStatus(prev => ({
        ...prev,
        cpuUsage: Math.min(100, Math.max(0, prev.cpuUsage + (Math.random() - 0.5) * 10)),
        memoryUsage: Math.min(100, Math.max(0, prev.memoryUsage + (Math.random() - 0.5) * 5)),
        lastUpdate: new Date()
      }));
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  return (
    <Card>
      <CardContent>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Typography variant="h6">
            System Status
          </Typography>
          <IconButton size="small">
            <RefreshIcon />
          </IconButton>
        </Box>

        <Box sx={{ mb: 2 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
            <Typography variant="body2">CPU Usage</Typography>
            <Typography variant="body2">{systemStatus.cpuUsage.toFixed(1)}%</Typography>
          </Box>
          <LinearProgress variant="determinate" value={systemStatus.cpuUsage} color="primary" />
        </Box>

        <Box sx={{ mb: 2 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
            <Typography variant="body2">Memory Usage</Typography>
            <Typography variant="body2">{systemStatus.memoryUsage.toFixed(1)}%</Typography>
          </Box>
          <LinearProgress variant="determinate" value={systemStatus.memoryUsage} color="info" />
        </Box>

        <Box sx={{ mb: 2 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
            <Typography variant="body2">Disk Usage</Typography>
            <Typography variant="body2">{systemStatus.diskUsage.toFixed(1)}%</Typography>
          </Box>
          <LinearProgress variant="determinate" value={systemStatus.diskUsage} color="success" />
        </Box>

        <Divider sx={{ my: 2 }} />

        <Grid container spacing={2}>
          <Grid item xs={6}>
            <Box sx={{ textAlign: 'center' }}>
              <Typography variant="h5" component="div">
                {systemStatus.activeAnalyses}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                Active Analyses
              </Typography>
            </Box>
          </Grid>
          <Grid item xs={6}>
            <Box sx={{ textAlign: 'center' }}>
              <Typography variant="h5" component="div">
                {systemStatus.queueLength}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                Queued
              </Typography>
            </Box>
          </Grid>
        </Grid>

        <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 2 }}>
          Last updated: {systemStatus.lastUpdate.toLocaleTimeString()}
        </Typography>
      </CardContent>
    </Card>
  );
};

export const RecentAnalysesWidget: React.FC<DashboardWidgetsProps> = ({ recentAnalyses = [] }) => {
  return (
    <Card>
      <CardContent>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Typography variant="h6">
            Recent Analyses
          </Typography>
          <Chip label={`${recentAnalyses.length} Total`} size="small" variant="outlined" />
        </Box>

        <List dense>
          {recentAnalyses.length === 0 ? (
            <Alert severity="info" sx={{ mt: 1 }}>
              No recent analyses found. Upload an APK to get started.
            </Alert>
          ) : (
            recentAnalyses.slice(0, 5).map((analysis, index) => (
              <React.Fragment key={analysis.id}>
                <ListItem>
                  <ListItemIcon>
                    {getStatusIcon(analysis.status)}
                  </ListItemIcon>
                  <ListItemText
                    primary={analysis.packageName}
                    secondary={
                      <Box>
                        <Typography variant="caption" display="block">
                          {analysis.fileName}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {new Date(analysis.date).toLocaleString()}
                        </Typography>
                      </Box>
                    }
                  />
                  <Box sx={{ textAlign: 'right' }}>
                    {analysis.status === 'completed' && analysis.securityScore !== undefined && (
                      <Chip
                        label={`${analysis.securityScore}`}
                        size="small"
                        color={getScoreColor(analysis.securityScore)}
                      />
                    )}
                    <Chip
                      label={analysis.status}
                      size="small"
                      color={getStatusColor(analysis.status)}
                      sx={{ mt: 0.5 }}
                    />
                  </Box>
                </ListItem>
                {index < recentAnalyses.length - 1 && <Divider />}
              </React.Fragment>
            ))
          )}
        </List>
      </CardContent>
    </Card>
  );
};

export const StorageWidget: React.FC = () => {
  const [storageInfo, setStorageInfo] = useState({
    totalSpace: 500, // GB
    usedSpace: 175, // GB
    recentAnalyses: 12,
    totalFiles: 2456
  });

  const usagePercentage = (storageInfo.usedSpace / storageInfo.totalSpace) * 100;

  return (
    <Card>
      <CardContent>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Typography variant="h6">
            Storage
          </Typography>
          <StorageIcon color="primary" />
        </Box>

        <Box sx={{ mb: 3, textAlign: 'center' }}>
          <SecurityScoreChart score={Math.round(100 - usagePercentage)} />
          <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
            Available Space: {((storageInfo.totalSpace - storageInfo.usedSpace) / storageInfo.totalSpace * 100).toFixed(1)}%
          </Typography>
        </Box>

        <List dense>
          <ListItem>
            <ListItemIcon>
              <FolderIcon />
            </ListItemIcon>
            <ListItemText
              primary="Total Space"
              secondary={`${storageInfo.totalSpace} GB`}
            />
          </ListItem>
          <Divider />
          <ListItem>
            <ListItemIcon>
              <DescriptionIcon />
            </ListItemIcon>
            <ListItemText
              primary="Used Space"
              secondary={`${storageInfo.usedSpace} GB`}
            />
          </ListItem>
          <Divider />
          <ListItem>
            <ListItemIcon>
              <CloudUploadIcon />
            </ListItemIcon>
            <ListItemText
              primary="Recent Analyses"
              secondary={`${storageInfo.recentAnalyses} APKs`}
            />
          </ListItem>
          <Divider />
          <ListItem>
            <ListItemIcon>
              <AssessmentIcon />
            </ListItemIcon>
            <ListItemText
              primary="Total Files"
              secondary={`${storageInfo.totalFiles} files`}
            />
          </ListItem>
        </List>
      </CardContent>
    </Card>
  );
};

export const TrendWidget: React.FC = () => {
  const [trendData, setTrendData] = useState([
    { label: 'Mon', analyses: 5, vulnerabilities: 12 },
    { label: 'Tue', analyses: 8, vulnerabilities: 18 },
    { label: 'Wed', analyses: 6, vulnerabilities: 15 },
    { label: 'Thu', analyses: 10, vulnerabilities: 22 },
    { label: 'Fri', analyses: 7, vulnerabilities: 16 },
    { label: 'Sat', analyses: 4, vulnerabilities: 8 },
    { label: 'Sun', analyses: 3, vulnerabilities: 7 }
  ]);

  const maxAnalyses = Math.max(...trendData.map(d => d.analyses));
  const maxVulnerabilities = Math.max(...trendData.map(d => d.vulnerabilities));

  return (
    <Card>
      <CardContent>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Typography variant="h6">
            Weekly Trend
          </Typography>
          <TrendingUpIcon color="success" />
        </Box>

        <Box sx={{ mb: 3 }}>
          {trendData.map((data, index) => (
            <Box key={index} sx={{ mb: 2 }}>
              <Typography variant="caption" color="text.secondary">
                {data.label}
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Box sx={{ flexGrow: 1 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 0.5 }}>
                    <Typography variant="caption" sx={{ width: 80 }}>
                      Analyses
                    </Typography>
                    <Box sx={{ flexGrow: 1, mr: 1 }}>
                      <LinearProgress
                        variant="determinate"
                        value={(data.analyses / maxAnalyses) * 100}
                        color="primary"
                      />
                    </Box>
                    <Typography variant="caption" sx={{ minWidth: 30 }}>
                      {data.analyses}
                    </Typography>
                  </Box>
                  <Box sx={{ display: 'flex', alignItems: 'center' }}>
                    <Typography variant="caption" sx={{ width: 80 }}>
                      Vulns
                    </Typography>
                    <Box sx={{ flexGrow: 1, mr: 1 }}>
                      <LinearProgress
                        variant="determinate"
                        value={(data.vulnerabilities / maxVulnerabilities) * 100}
                        color="error"
                      />
                    </Box>
                    <Typography variant="caption" sx={{ minWidth: 30 }}>
                      {data.vulnerabilities}
                    </Typography>
                  </Box>
                </Box>
              </Box>
              <Divider />
            </Box>
          ))}
        </Box>

        <Alert severity="info" sx={{ mt: 2 }}>
          <AlertTitle>Weekly Summary</AlertTitle>
          <Typography variant="body2">
            Total analyses this week: {trendData.reduce((sum, d) => sum + d.analyses, 0)}<br />
            Total vulnerabilities found: {trendData.reduce((sum, d) => sum + d.vulnerabilities, 0)}
          </Typography>
        </Alert>
      </CardContent>
    </Card>
  );
};

export const QuickActionsWidget: React.FC = () => {
  const actions = [
    { icon: <CloudUploadIcon />, label: 'Upload APK', color: 'primary' as const },
    { icon: <FolderIcon />, label: 'Browse Files', color: 'info' as const },
    { icon: <AssessmentIcon />, label: 'New Analysis', color: 'success' as const },
    { icon: <StorageIcon />, label: 'Manage Storage', color: 'warning' as const }
  ];

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Quick Actions
        </Typography>
        <Grid container spacing={1}>
          {actions.map((action, index) => (
            <Grid item xs={6} key={index}>
              <Card
                sx={{
                  cursor: 'pointer',
                  transition: 'all 0正常运行',
                  '&:hover': {
                    boxShadow: 4,
                    transform: 'translateY(-2px)'
                  }
                }}
              >
                <CardContent sx={{ textAlign: 'center', py: 2 }}>
                  <Avatar sx={{ bgcolor: `${action.color}.main`, margin: '0 auto', mb: 1 }}>
                    {action.icon}
                  </Avatar>
                  <Typography variant="caption">
                    {action.label}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      </CardContent>
    </Card>
  );
};

function calculateAvgScore(analyses?: RecentAnalysis[]): number {
  if (!analyses || analyses.length === 0) return 0;
  const completedAnalyses = analyses.filter(a => a.status === 'completed' && a.securityScore !== undefined);
  if (completedAnalyses.length === 0) return 0;
  const total = completedAnalyses.reduce((sum, a) => sum + (a.securityScore || 0), 0);
  return Math.round(total / completedAnalyses.length);
}

function getStatusIcon(status: string) {
  switch (status) {
    case 'completed':
      return <CheckCircleIcon color="success" />;
    case 'running':
      return <PendingIcon color="warning" />;
    case 'failed':
      return <ErrorIcon color="error" />;
    case 'queued':
      return <ScheduleIcon color="info" />;
    default:
      return <InfoIcon color="info" />;
  }
}

function getStatusColor(status: string): 'success' | 'warning' | 'error' | 'info' | 'default' {
  switch (status) {
    case 'completed':
      return 'success';
    case 'running':
      return 'warning';
    case 'failed':
      return 'error';
    case 'queued':
      return 'info';
    default:
      return 'default';
  }
}

function getScoreColor(score: number): 'success' | 'warning' | 'error' | 'info' | 'default' {
  if (score >= 80) return 'success';
  if (score >= 60) return 'info';
  if (score >= 40) return 'warning';
  return 'error';
}