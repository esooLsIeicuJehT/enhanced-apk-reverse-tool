import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Chip,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Divider,
  Tabs,
  Tab,
  Alert,
  AlertTitle,
  Paper
} from '@mui/material';
import {
  ExpandMore as ExpandMoreIcon,
  Warning as WarningIcon,
  Error as ErrorIcon,
  Info as InfoIcon,
  CheckCircle as CheckCircleIcon,
  Security as SecurityIcon,
  Shield as ShieldIcon,
  BugReport as BugReportIcon,
  Key as KeyIcon,
  Http as HttpIcon,
  Lock as LockIcon,
  Smartphone as SmartphoneIcon,
  Storage as StorageIcon,
  Visibility as VisibilityIcon
} from '@mui/icons-material';
import { VulnerabilityBreakdownChart, OWASPRadarChart, PermissionAnalysisChart } from './Charts';

interface ReportVisualizationProps {
  analysisResults: any;
}

export const ReportVisualization: React.FC<ReportVisualizationProps> = ({ analysisResults }) => {
  const [currentTab, setCurrentTab] = useState(0);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setCurrentTab(newValue);
  };

  if (!analysisResults) {
    return (
      <Alert severity="info">
        <AlertTitle>No Analysis Results</AlertTitle>
        Upload an APK and run analysis to see the report.
      </Alert>
    );
  }

  const owaspResults = analysisResults.owaspResults;
  const malwareResults = analysisResults.malwareResults;
  const basicInfo = analysisResults.basicInfo;

  return (
    <Box>
      <Paper sx={{ mb: 2 }}>
        <Tabs value={currentTab} onChange={handleTabChange} variant="scrollable" scrollButtons="auto">
          <Tab label="Overview" />
          <Tab label="OWASP Analysis" />
          <Tab label="Malware Detection" />
          <Tab label="Permissions" />
          <Tab label="Code Analysis" />
          <Tab label="Certificates" />
          <Tab label="Files" />
        </Tabs>
      </Paper>

      {currentTab === 0 && <OverviewSection results={analysisResults} />}
      {currentTab === 1 && <OWASPSection results={owaspResults} />}
      {currentTab === 2 && <MalwareSection results={malwareResults} />}
      {currentTab === 3 && <PermissionsSection results={analysisResults} />}
      {currentTab === 4 && <CodeAnalysisSection results={analysisResults} />}
      {currentTab === 5 && <CertificatesSection results={analysisResults} />}
      {currentTab === 6 && <FilesSection results={analysisResults} />}
    </Box>
  );
};

const OverviewSection: React.FC<{ results: any }> = ({ results }) => {
  const securityScore = results.owaspResults?.securityScore || results.basicInfo?.securityScore || 0;
  const totalVulnerabilities = results.owaspResults?.vulnerabilities?.length || 0;

  return (
    <Box>
      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Security Overview
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} md={6}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h3" color="primary">
                  {securityScore}/100
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Security Score
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} md={6}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h3" color="error">
                  {totalVulnerabilities}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Vulnerabilities Found
                </Typography>
              </Box>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Basic Information
          </Typography>
          <List dense>
            <ListItem>
              <ListItemText primary="Package Name" secondary={results.basicInfo?.manifest?.package || 'N/A'} />
            </ListItem>
            <Divider />
            <ListItem>
              <ListItemText primary="Version Name" secondary={results.basicInfo?.manifest?.versionName || 'N/A'} />
            </ListItem>
            <Divider />
            <ListItem>
              <ListItemText primary="Version Code" secondary={results.basicInfo?.manifest?.versionCode || 'N/A'} />
            </ListItem>
            <Divider />
            <ListItem>
              <ListItemText primary="Min SDK" secondary={results.basicInfo?.manifest?.minSdk || 'N/A'} />
            </ListItem>
            <Divider />
            <ListItem>
              <ListItemText primary="Target SDK" secondary={results.basicInfo?.manifest?.targetSdk || 'N/A'} />
            </ListItem>
          </List>
        </CardContent>
      </Card>

      <VulnerabilityBreakdownChart vulnerabilityBreakdown={results.owaspResults?.vulnerabilityBreakdown} />
    </Box>
  );
};

const OWASPSection: React.FC<{ results: any }> = ({ results }) => {
  if (!results || !results.vulnerabilities) {
    return (
      <Alert severity="info">
        <AlertTitle>No OWASP Analysis Results</AlertTitle>
        OWASP security analysis was not performed or returned no results.
      </Alert>
    );
  }

  return (
    <Box>
      <OWASPRadarChart owaspResults={results} />

      <Card sx={{ mt: 2 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Detailed Vulnerabilities ({results.vulnerabilities.length})
          </Typography>
          {results.vulnerabilities.map((vuln: any, index: number) => (
            <Accordion key={index}>
              <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, width: '100%' }}>
                  {getSeverityIcon(vuln.severity)}
                  <Typography variant="subtitle1">
                    {vuln.category || vuln.title}
                  </Typography>
                  <Chip
                    size="small"
                    label={vuln.severity}
                    color={getSeverityColor(vuln.severity)}
                    sx={{ ml: 'auto' }}
                  />
                </Box>
              </AccordionSummary>
              <AccordionDetails>
                <Typography variant="body2" paragraph>
                  {vuln.description}
                </Typography>
                {vuln.evidence && (
                  <Box sx={{ mt: 2 }}>
                    <Typography variant="subtitle2" gutterBottom>
                      Evidence:
                    </Typography>
                    <Paper sx={{ p: 1, bgcolor: 'grey.100', fontFamily: 'monospace', fontSize: '0.875rem' }}>
                      {vuln.evidence}
                    </Paper>
                  </Box>
                )}
                {vuln.recommendation && (
                  <Box sx={{ mt: 2 }}>
                    <Typography variant="subtitle2" gutterBottom>
                      Recommendation:
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {vuln.recommendation}
                    </Typography>
                  </Box>
                )}
              </AccordionDetails>
            </Accordion>
          ))}
        </CardContent>
      </Card>
    </Box>
  );
};

const MalwareSection: React.FC<{ results: any }> = ({ results }) => {
  if (!results) {
    return (
      <Alert severity="info">
        <AlertTitle>No Malware Analysis Results</AlertTitle>
        Malware detection was not performed or returned no results.
      </Alert>
            </Alert>
    );
  }

  const severityColors: Record<string, 'error' | 'warning' | 'info' | 'success'> = {
    'CRITICAL': 'error',
    'HIGH': 'error',
    'MEDIUM': 'warning',
    'LOW': 'info',
    'INFO': 'info',
    'SAFE': 'success'
  };

  return (
    <Box>
      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Malware Detection Results
          </Typography>
          <Alert severity={severityColors[results.classification] || 'info'} sx={{ mb: 2 }}>
            <AlertTitle>
              Classification: {results.classification}
            </AlertTitle>
            Confidence: {results.confidence}%
          </Alert>

          <Typography variant="h6" gutterBottom>
            Risk Factors
          </Typography>
          <List>
            {results.riskFactors?.map((factor: any, index: number) => (
              <ListItem key={index}>
                <ListItemIcon>
                  <WarningIcon color={factor.riskLevel === 'HIGH' ? 'error' : factor.riskLevel === 'MEDIUM' ? 'warning' : 'info'} />
                </ListItemIcon>
                <ListItemText
                  primary={factor.name}
                  secondary={`Risk Level: ${factor.riskLevel} - ${factor.description}`}
                />
              </ListItem>
            ))}
          </List>

          {results.featureImportance && (
            <Box sx={{ mt: 2 }}>
              <Typography variant="h6" gutterBottom>
                Feature Importance
              </Typography>
              {results.featureImportance.map((feature: any, index: number) => (
                <Box key={index} sx={{ mb: 1 }}>
                  <Typography variant="body2">
                    {feature.feature}: {feature.importance.toFixed(2)}
                  </Typography>
                  <Box
                    sx={{
                      height: 8,
                      bgcolor: 'grey.200',
                      borderRadius: 1,
                      overflow: 'hidden',
                      mt: 0.5
                    }}
                  >
                    <Box
                      sx={{
                        height: '100%',
                        width: `${feature.importance * 100}%`,
                        bgcolor: 'primary.main',
                        transition: 'width 0.3s ease'
                      }}
                    />
                  </Box>
                </Box>
              ))}
            </Box>
          )}
        </CardContent>
      </Card>
    </Box>
  );
};

const PermissionsSection: React.FC<{ results: any }> = ({ results }) => {
  const permissions = results.basicInfo?.permissions;
  
  if (!permissions) {
    return (
      <Alert severity="info">
        <AlertTitle>No Permission Data</AlertTitle>
        Permission analysis was not performed.
      </Alert>
    );
  }

  return (
    <Box>
      <PermissionAnalysisChart permissions={permissions} />

      <Card sx={{ mt: 2 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Permission Details
          </Typography>
          {Object.entries(permissions.permissions || {}).map(([category, perms]: [string, any], index: number) => (
            <Accordion key={index}>
              <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                <Typography>
                  {category} ({Object.keys(perms).length} permissions)
                </Typography>
              </AccordionSummary>
              <AccordionDetails>
                <List dense>
                  {Object.entries(perms).map(([perm, info]: [string, any], idx: number) => (
                    <ListItem key={idx}>
                      <ListItemText
                        primary={perm}
                        secondary={`Status: ${info.status || 'unknown'}`}
                      />
                    </ListItem>
                  ))}
                </List>
              </AccordionDetails>
            </Accordion>
          ))}
        </CardContent>
      </Card>
    </Box>
  );
};

const CodeAnalysisSection: React.FC<{ results: any }> = ({ results }) => {
  const codeAnalysis = results.basicInfo?.codeAnalysis;

  if (!codeAnalysis) {
    return (
      <Alert severity="info">
        <AlertTitle>No Code Analysis Results</AlertTitle>
        Code analysis was not performed.
      </Alert>
    );
  }

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Code Analysis
        </Typography>
        <List dense>
          <ListItem>
            <ListItemText primary="Total Classes" secondary={codeAnalysis.totalClasses || 'N/A'} />
          </ListItem>
          <Divider />
          <ListItem>
            <ListItemText primary="Total Methods" secondary={codeAnalysis.totalMethods || 'N/A'} />
          </ListItem>
          <Divider />
          <ListItem>
            <ListItemText primary="Obfuscated" secondary={codeAnalysis.isObfuscated ? 'Yes' : 'No'} />
          </ListItem>
          <Divider />
          <ListItem>
            <ListItemText primary="Programming Language" secondary={codeAnalysis.primaryLanguage || 'N/A'} />
          </ListItem>
        </List>

        {codeAnalysis.codeSmells?.length > 0 && (
          <Box sx={{ mt: 2 }}>
            <Typography variant="h6" gutterBottom>
              Code Smells ({codeAnalysis.codeSmells.length})
            </Typography>
            <List dense>
              {codeAnalysis.codeSmells.map((smell: any, index: number) => (
                <ListItem key={index}>
                  <ListItemIcon>
                    <BugReportIcon color="warning" />
                  </ListItemIcon>
                  <ListItemText
                    primary={smell.name}
                    secondary={smell.description}
                  />
                </ListItem>
              ))}
            </List>
          </Box>
        )}
      </CardContent>
    </Card>
  );
};

const CertificatesSection: React.FC<{ results: any }> = ({ results }) => {
  const certificates = results.basicInfo?.certificates;

  if (!certificates) {
    return (
      <Alert severity="info">
        <AlertTitle>No Certificate Data</AlertTitle>
        Certificate analysis was not performed.
      </Alert>
    );
  }

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Certificate Information
        </Typography>
        {certificates.map((cert: any, index: number) => (
          <Box key={index} sx={{ mb: 2 }}>
            <Typography variant="subtitle1" gutterBottom>
              Certificate {index + 1}
            </Typography>
            <List dense>
              <ListItem>
                <ListItemText primary="Issuer" secondary={cert.issuer} />
              </ListItem>
              <Divider />
              <ListItem>
                <ListItemText primary="Subject" secondary={cert.subject} />
              </ListItem>
              <Divider />
              <ListItem>
                <ListItemText primary="Serial Number" secondary={cert.serialNumber} />
              </ListItem>
              <Divider />
              <ListItem>
                <ListItemText primary="Valid From" secondary={cert.validFrom} />
              </ListItem>
              <Divider />
              <ListItem>
                <ListItemText primary="Valid Until" secondary={cert.validUntil} />
              </ListItem>
              <Divider />
              <ListItem>
                <ListItemText primary="Signature Algorithm" secondary={cert.signatureAlgorithm} />
              </ListItem>
            </List>
          </Box>
        ))}
      </CardContent>
    </Card>
  );
};

const FilesSection: React.FC<{ results: any }> = ({ results }) => {
  const files = results.basicInfo?.files;

  if (!files) {
    return (
      <Alert severity="info">
        <AlertTitle>No File Data</AlertTitle>
        File analysis was not performed.
      </Alert>
    );
  }

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          File Analysis
        </Typography>
        <Typography variant="body2" paragraph>
          Total Files: {files.totalFiles}
        </Typography>
        <Typography variant="body2" paragraph>
          Total Size: {files.totalSize}
        </Typography>

        <Typography variant="subtitle1" gutterBottom>
          File Types
        </Typography>
        <List dense>
          {Object.entries(files.fileTypes || {}).map(([type, count]: [string, any], index: number) => (
            <ListItem key={index}>
              <ListItemText
                primary={type}
                secondary={`${count} files`}
              />
            </ListItem>
          ))}
        </List>
      </CardContent>
    </Card>
  );
};

function getSeverityIcon(severity: string) {
  switch (severity?.toUpperCase()) {
    case 'CRITICAL':
      return <ErrorIcon color="error" />;
    case 'HIGH':
      return <WarningIcon color="error" />;
    case 'MEDIUM':
      return <WarningIcon color="warning" />;
    case 'LOW':
      return <InfoIcon color="info" />;
    case 'INFO':
      return <InfoIcon color="info" />;
    default:
      return <CheckCircleIcon color="success" />;
  }
}

function getSeverityColor(severity: string): 'error' | 'warning' | 'info' | 'success' | 'default' {
  switch (severity?.toUpperCase()) {
    case 'CRITICAL':
    case 'HIGH':
      return 'error';
    case 'MEDIUM':
      return 'warning';
    case 'LOW':
      return 'info';
    case 'INFO':
      return 'info';
    default:
      return 'default';
  }
}

export default ReportVisualization;