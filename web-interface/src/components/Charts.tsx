import React from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Paper
} from '@mui/material';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  ArcElement,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  RadialLinearScale
} from 'chart.js';
import { Doughnut, Bar, Radar } from 'react-chartjs-2';

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  ArcElement,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  RadialLinearScale
);

interface ChartsProps {
  securityScore?: number;
  vulnerabilityBreakdown?: {
    critical: number;
    high: number;
    medium: number;
    low: number;
    info: number;
  };
  owaspResults?: any;
  analysisResults?: any;
}

export const SecurityScoreChart: React.FC<{ score: number }> = ({ score }) => {
  const data = {
    labels: ['Security Score', 'Remaining'],
    datasets: [{
      data: [score, 100 - score],
      backgroundColor: [
        getScoreColor(score),
        '#e0e0e0'
      ],
      borderWidth: 0,
    }]
  };

  const options = {
    cutout: '70%',
    plugins: {
      legend: {
        display: false
      },
      tooltip: {
        enabled: false
      }
    },
    maintainAspectRatio: false
  };

  return (
    <Box sx={{ position: 'relative', height: 200, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Doughnut data={data} options={options} />
      <Box sx={{
        position: 'absolute',
        textAlign: 'center',
        top: '50%',
        left: '50%',
        transform: 'translate(-50%, -50%)'
      }}>
        <Typography variant="h4" component="div" fontWeight="bold">
          {score}
        </Typography>
        <Typography variant="caption" color="text.secondary">
          Score
        </Typography>
      </Box>
    </Box>
  );
};

export const VulnerabilityBreakdownChart: React.FC<ChartsProps['vulnerabilityBreakdown']> = (breakdown) => {
  if (!breakdown) return null;

  const data = {
    labels: ['Critical', 'High', 'Medium', 'Low', 'Info'],
    datasets: [{
      label: 'Vulnerabilities',
      data: [
        breakdown.critical,
        breakdown.high,
        breakdown.medium,
        breakdown.low,
        breakdown.info
      ],
      backgroundColor: [
        '#d32f2f', // Critical - Red
        '#f57c00', // High - Orange
        '#fbc02d', // Medium - Yellow
        '#388e3c', // Low - Green
        '#1976d2'  // Info - Blue
      ],
      borderWidth: 1,
    }]
  };

  const options = {
    responsive: true,
    plugins: {
      legend: {
        position: 'top' as const,
      }
    },
    scales: {
      y: {
        beginAtZero: true,
        ticks: {
          stepSize: 1
        }
      }
    }
  };

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Vulnerability Breakdown
        </Typography>
        <Box sx={{ height: 300 }}>
          <Bar data={data} options={options} />
        </Box>
      </CardContent>
    </Card>
  );
};

export const OWASPRadarChart: React.FC<ChartsProps['owaspResults']> = (owaspResults) => {
  if (!owaspResults) return null;

  // Extract scores from OWASP results
  const scores = owaspResults.vulnerabilities?.map((v: any) => v.severityScore || 0) || [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  const data = {
    labels: [
      'M01: Improper Platform Usage',
      'M02: Insecure Data Storage',
      'M03: Insecure Communication',
      'M04: Insecure Authentication',
      'M05: Insufficient Cryptography',
      'M06: Insecure Authorization',
      'M07: Client Code Quality',
      'M08: Code Tampering',
      'M09: Reverse Engineering',
      'M10: Extraneous Functionality'
    ],
    datasets: [{
      label: 'Risk Score',
      data: scores,
      backgroundColor: 'rgba(33, 150, 243, 0.2)',
      borderColor: 'rgb(33, 150, 243)',
      pointBackgroundColor: 'rgb(33, 150, 243)',
      pointBorderColor: '#fff',
      pointHoverBackgroundColor: '#fff',
      pointHoverBorderColor: 'rgb(33, 150, 243)'
    }]
  };

  const options = {
    responsive: true,
    plugins: {
      legend: {
        display: false
      }
    },
    scales: {
      r: {
        angleLines: {
          display: false
        },
        suggestedMin: 0,
        suggestedMax: 10
      }
    }
  };

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          OWASP Mobile Top 10 Risk Assessment
        </Typography>
        <Box sx={{ height: 400 }}>
          <Radar data={data} options={options} />
        </Box>
      </CardContent>
    </Card>
  );
};

export const PermissionAnalysisChart: React.FC<{ permissions?: any }> = ({ permissions }) => {
  if (!permissions) return null;

  const permissionTypes = permissions.permissions || {};
  const data = {
    labels: Object.keys(permissionTypes),
    datasets: [{
      label: 'Permissions',
      data: Object.values(permissionTypes).map((p: any) => Object.keys(p).length),
      backgroundColor: [
        'rgba(255, 99, 132, 0.5)',
        'rgba(54, 162, 235, 0.5)',
        'rgba(255, 206, 86, 0.5)',
        'rgba(75, 192, 192, 0.5)',
        'rgba(153, 102, 255, 0.5)',
      ],
      borderWidth: 1,
    }]
  };

  const options = {
    responsive: true,
    plugins: {
      legend: {
        display: false
      }
    }
  };

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Permission Distribution
        </Typography>
        <Box sx={{ height: 250 }}>
          <Doughnut data={data} options={options} />
        </Box>
      </CardContent>
    </Card>
  );
};

export const AnalysisMetricsGrid: React.FC<{ analysisResults?: any }> = ({ analysisResults }) => {
  const metrics = analysisResults?.basicInfo || {};
  const owasp = analysisResults?.owaspResults;
  const malware = analysisResults?.malwareResults;

  return (
    <Grid container spacing={2}>
      <Grid item xs={6} sm={4} md={3}>
        <Paper sx={{ p: 2, textAlign: 'center', bgcolor: 'primary.light' }}>
          <Typography variant="h4" fontWeight="bold">
            {metrics.manifest?.package || 'N/A'}
          </Typography>
          <Typography variant="caption" color="text.secondary">
            Package Name
          </Typography>
        </Paper>
      </Grid>
      <Grid item xs={6} sm={4} md={3}>
        <Paper sx={{ p: 2, textAlign: 'center', bgcolor: 'success.light' }}>
          <Typography variant="h4" fontWeight="bold">
            {metrics.manifest?.versionCode || 'N/A'}
          </Typography>
          <Typography variant="caption" color="text.secondary">
            Version Code
          </Typography>
        </Paper>
      </Grid>
      <Grid item xs={6} sm={4} md={3}>
        <Paper sx={{ p: 2, textAlign: 'center', bgcolor: 'warning.light' }}>
          <Typography variant="h4" fontWeight="bold">
            {metrics.manifest?.minSdk || 'N/A'}
          </Typography>
          <Typography variant="caption" color="text.secondary">
            Min SDK
          </Typography>
        </Paper>
      </Grid>
      <Grid item xs={6} sm={4} md={3}>
        <Paper sx={{ p: 2, textAlign: 'center', bgcolor: 'info.light' }}>
          <Typography variant="h4" fontWeight="bold">
            {metrics.manifest?.targetSdk || 'N/A'}
          </Typography>
          <Typography variant="caption" color="text.secondary">
            Target SDK
          </Typography>
        </Paper>
      </Grid>
    </Grid>
  );
};

function getScoreColor(score: number): string {
  if (score >= 80) return '#4caf50'; // Green
  if (score >= 60) return '#8bc34a'; // Light Green
  if (score >= 40) return '#ff9800'; // Orange
  if (score >= 20) return '#f44336'; // Red
  return '#d32f2f'; // Dark Red
}