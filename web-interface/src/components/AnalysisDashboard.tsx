import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  Card,
  CardContent,
  LinearProgress,
  Alert,
  Chip,
  IconButton,
  Menu,
  MenuItem,
  Button,
  Divider,
  Skeleton,
  Tabs,
  Tab,
} from '@mui/material';
import {
  Speed as SpeedIcon,
  Security as SecurityIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon,
  MoreVert as MoreVertIcon,
  Refresh as RefreshIcon,
  Share as ShareIcon,
  Download as DownloadIcon,
  Visibility as VisibilityIcon,
} from '@mui/icons-material';
import { styled } from '@mui/material/styles';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getAnalysis, getAnalysisProgress } from '../services/api';
import { AnalysisResponse, ProgressUpdate } from '../types';
import {
  DoughnutChart,
  BarChart,
  SecurityScoreGauge,
  RiskLevelBadge,
} from './charts';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`dashboard-tab-${index}`}
      aria-labelledby={`dashboard-tab-${index}`}
      {...other}
    >
      {value === index && <Box>{children}</Box>}
    </div>
  );
}

const StyledCard = styled(Card)(({ theme }) => ({
  height: '100%',
  display: 'flex',
  flexDirection: 'column',
  transition: 'all 0.3s',
  '&:hover': {
    transform: 'translateY(-2px)',
    boxShadow: theme.shadows[6],
  },
}));

const ProgressCard = styled(Card)(({ theme }) => ({
  background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.dark} 100%)`,
  color: theme.palette.primary.contrastText,
}));

const AnalysisDashboard: React.FC = () => {
  const { analysisId } = useParams<{ analysisId: string }>();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  
  const [activeTab, setActiveTab] = useState(0);
  const [menuAnchor, setMenuAnchor] = useState<null | HTMLElement>(null);
  const [autoRefresh, setAutoRefresh] = useState(true);

  const { data: analysis, isLoading: loadingAnalysis, error: analysisError } =
    useQuery({
      queryKey: ['analysis', analysisId],
      queryFn: () => getAnalysis(analysisId!),
      enabled: !!analysisId,
      refetchInterval: autoRefresh ? 2000 : false,
    });

  const { data: progress } = useQuery({
    queryKey: ['progress', analysisId],
    queryFn: () => getAnalysisProgress(analysisId!),
    enabled: !!analysisId,
    refetchInterval: autoRefresh ? 1000 : false,
  });

  const cancelMutation = useMutation({
    mutationFn: () => /* cancelAnalysis(analysisId) */ new Promise(resolve => resolve(null)),
    onSuccess: () => {
      navigate('/');
    },
  });

  useEffect(() => {
    if (analysis?.status?.code === 'COMPLETED') {
      setAutoRefresh(false);
    }
  }, [analysis?.status?.code]);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setActiveTab(newValue);
  };

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setMenuAnchor(event.currentTarget);
  };

  const handleMenuClose = () => {
    setMenuAnchor(null);
  };

  const handleRefresh = () => {
    queryClient.invalidateQueries(['analysis']);
    queryClient.invalidateQueries(['progress']);
  };

  const handleCancel = () => {
    if (window.confirm('Are you sure you want to cancel the analysis?')) {
      cancelMutation.mutate();
    }
  };

  const handleDownload = () => {
    // Implement download logic
  };

  const handleShare = () => {
    // Implement share logic
  };

  const isCompleted = analysis?.status?.code === 'COMPLETED';
  const progressValue = progress?.progress || 0;

  if (loadingAnalysis) {
    return (
      <Box sx={{ p: 3 }}>
        <Grid container spacing={2}>
          {[...Array(6)].map((_, i) => (
            <Grid item xs={12} md={6} key={i}>
              <Skeleton variant="rectangular" height={200} />
            </Grid>
          ))}
        </Grid>
      </Box>
    );
  }

  if (analysisError) {
    return (
      <Alert severity="error" sx={{ mt: 2 }}>
        Failed to load analysis. Please try again.
      </Alert>
    );
  }

  if (!analysis) {
    return null;
  }

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Paper sx={{ p: 2, mb: 2 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} md={8}>
            <Typography variant="h5" gutterBottom>
              {analysis.appName}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Package: {analysis.packageName}
              {analysis.versionName && ` • v${analysis.versionName}`}
            </Typography>
          </Grid>
          <Grid item xs={12} md={4}>
            <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 1 }}>
              {autoRefresh && (
                <IconButton onClick={handleRefresh} size="small">
                  <RefreshIcon />
                </IconButton>
              )}
              <IconButton onClick={handleMenuOpen} size="small">
                <MoreVertIcon />
              </IconButton>
            </Box>
          </Grid>
        </Grid>

        {/* Progress Bar */}
        {isCompleted ? (
          <Chip
            label="Analysis Complete"
            color="success"
            icon={<CheckCircleIcon />}
            sx={{ mt: 2 }}
          />
        ) : (
          <Box sx={{ mt: 2 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
              <Typography variant="body2" color="text.secondary">
                {progress?.currentStep || 'Analyzing...'}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {progressValue.toFixed(0)}%
              </Typography>
            </Box>
            <LinearProgress variant="determinate" value={progressValue} />
          </Box>
        )}
      </Paper>

      <Menu
        anchorEl={menuAnchor}
        open={Boolean(menuAnchor)}
        onClose={handleMenuClose}
      >
        <MenuItem onClick={handleShare}>
          <ShareIcon sx={{ mr: 1 }} />
          Share Report
        </MenuItem>
        <MenuItem onClick={handleDownload}>
          <DownloadIcon sx={{ mr: 1 }} />
          Download Report
        </MenuItem>
        {!isCompleted && (
          <MenuItem onClick={handleCancel} color="error">
            <ErrorIcon sx={{ mr: 1 }} />
            Cancel Analysis
          </MenuItem>
        )}
      </Menu>

      {/* Dashboard Tabs */}
      <Tabs
        value={activeTab}
        onChange={handleTabChange}
        variant="scrollable"
        scrollButtons="auto"
        sx={{ mb: 2 }}
      >
        <Tab label="Overview" icon={<SpeedIcon />} />
        <Tab label="Security" icon={<SecurityIcon />} />
        <Tab label="Vulnerabilities" icon={<WarningIcon />} />
      </Tabs>

      {/* Overview Tab */}
      <TabPanel value={activeTab} index={0}>
        <Grid container spacing={2}>
          <Grid item xs={12} md={6}>
            <ProgressCard>
              <CardContent>
                <SecurityScoreGauge score={analysis.security.score} />
                <Typography variant="h4" align="center" gutterBottom>
                  Security Score
                </Typography>
                <Typography variant="body2" align="center">
                  {analysis.security.score.toFixed(0)}%
                </Typography>
                <RiskLevelBadge level={analysis.security.riskLevel} />
              </CardContent>
            </ProgressCard>
擸</Grid>
          </Grid>
        </Grid>
      </TabPanel>

      {/* Security Tab */}
      <TabPanel value={activeTab} index={1}>
        <Grid container spacing={2}>
          <Grid item xs={12}>
            <StyledCard>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Security Analysis
                </Typography>
                {/* Security Details */}
              </CardContent>
            </StyledCard>
          </Grid>
        </Grid>
      </TabPanel>

      {/* Vulnerabilities Tab */}
      <TabPanel value={activeTab} index={2}>
        <Grid container spacing={2}>
          <Grid item xs={12}>
            <StyledCard>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Vulnerabilities
                </Typography>
                {/* Vulnerability Details */}
              </CardContent>
            </StyledCard>
          </Grid>
        </Grid>
      </TabPanel>
    </Box>
  );
};

export default AnalysisDashboard;