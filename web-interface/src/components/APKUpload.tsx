import React, { useCallback, useState } from 'react';
import { useDropzone } from 'react-dropzone';
import {
  Box,
  Typography,
  Paper,
  Button,
  LinearProgress,
  Alert,
  Grid,
  Chip,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  CloudUpload as CloudUploadIcon,
  Delete as DeleteIcon,
  Description as DescriptionIcon,
  Android as AndroidIcon,
} from '@mui/icons-material';
import { styled } from '@mui/material/styles';
import { uploadAPK } from '../services/api';
import { useMutation } from '@tanstack/react-query';

const UploadArea = styled(Box)(({ theme }) => ({
  border: `2px dashed ${theme.palette.primary.main}`,
  borderRadius: theme.shape.borderRadius,
  padding: theme.spacing(4),
  textAlign: 'center',
  cursor: 'pointer',
  transition: 'all 0.3s',
  '&:hover': {
    borderColor: theme.palette.primary.dark,
    backgroundColor: theme.palette.action.hover,
  },
  '&.active': {
    borderColor: theme.palette.primary.dark,
    backgroundColor: theme.palette.action.selected,
  },
}));

interface APKUploadProps {
  onUploadComplete: (analysisId: string) => void;
}

const APKUpload: React.FC<APKUploadProps> = ({ onUploadComplete }) => {
  const [file, setFile] = useState<File | null>(null);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [isDragging, setIsDragging] = useState(false);

  const uploadMutation = useMutation({
    mutationFn: uploadAPK,
    onSuccess: (data: any) => {
      onUploadComplete(data.analysisId);
    },
    onError: (err: any) => {
      setError(err.message || 'Upload failed');
      setUploadProgress(0);
    },
  });

  const onDrop = useCallback((acceptedFiles: File[]) => {
    const uploadedFile = acceptedFiles[0];
    if (uploadedFile && uploadedFile.name.endsWith('.apk')) {
      setFile(uploadedFile);
      setError(null);
      uploadFile(uploadedFile);
    } else {
      setError('Please upload an APK file');
    }
  }, []);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'application/vnd.android.package-archive': ['.apk'],
    },
    multiple: false,
    onDragEnter: () => setIsDragging(true),
    onDragLeave: () => setIsDragging(false),
  });

  const uploadFile = async (fileToUpload: File) => {
    try {
      setError(null);
      setUploadProgress(10);
      await uploadMutation.mutateAsync(fileToUpload);
    } catch (err) {
      console.error('Upload error:', err);
    }
  };

  const handleRemoveFile = () => {
    setFile(null);
    setUploadProgress(0);
    setError(null);
  };

  const getFileIcon = () => <AndroidIcon fontSize="large" />;

  const getFileSize = (size: number): string => {
    const mb = size / (1024 * 1024);
    return `${mb.toFixed(2)} MB`;
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h5" gutterBottom>
        Upload APK for Analysis
      </Typography>
      <Typography variant="body2" color="text.secondary" gutterBottom>
        Upload an APK file to perform comprehensive security analysis, vulnerability scanning, and malware detection.
      </Typography>

      {file ? (
        <Paper sx={{ mt: 3, p: 2 }}>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={2}>
              <Box sx={{ textAlign: 'center' }}>{getFileIcon()}</Box>
            </Grid>
            <Grid item xs={8}>
              <Typography variant="body1" fontWeight="medium">
                {file.name}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {getFileSize(file.size)}
              </Typography>
              {uploadProgress > 0 && uploadProgress < 100 && (
                <Box sx={{ mt: 1 }}>
                  <LinearProgress
                    variant="determinate"
                    value={uploadProgress}
                    sx={{ mb: 0.5 }}
                  />
                  <Typography variant="body2" color="text.secondary">
                    Uploading... {uploadProgress}%
                  </Typography>
                </Box>
              )}
            </Grid>
            <Grid item xs={2}>
              <Tooltip title="Remove file">
                <IconButton
                  onClick={handleRemoveFile}
                  disabled={uploadMutation.isLoading}
                >
                  <DeleteIcon />
                </IconButton>
              </Tooltip>
            </Grid>
          </Grid>
        </Paper>
      ) : (
        <UploadArea
          {...getRootProps()}
          className={isDragActive || isDragging ? 'active' : ''}
          sx={{ mt: 3 }}
        >
          <input {...getInputProps()} />
          <CloudUploadIcon sx={{ fontSize: 64, color: 'primary.main', mb: 2 }} />
          <Typography variant="h6" gutterBottom>
            {isDragActive ? 'Drop APK file here' : 'Drag & drop APK file here'}
          </Typography>
          <Typography variant="body2" color="text.secondary" gutterBottom>
            or
          </Typography>
          <Button variant="contained" component="span" size="small">
            Browse Files
          </Button>
          <Typography
            variant="caption"
            color="text.secondary"
            sx={{ display: 'block', mt: 2 }}
          >
            Accepted format: .apk (Max: 500 MB)
          </Typography>
        </UploadArea>
      )}

      {error && (
        <Alert severity="error" sx={{ mt: 2 }}>
          {error}
        </Alert>
      )}

      <Box sx={{ mt: 3 }}>
        <Typography variant="subtitle1" gutterBottom>
          Analysis Options
        </Typography>
        <Grid container spacing={1}>
          <Chip label="Security Analysis" color="primary" variant="outlined" />
          <Chip label="Vulnerability Scanner" color="primary" variant="outlined" />
          <Chip label="Malware Detection" color="primary" variant="outlined" />
          <Chip label="Permission Analysis" color="primary" variant="outlined" />
        </Grid>
      </Box>

      <Box sx={{ mt: 3 }}>
        <Typography variant="subtitle1" gutterBottom>
          Features
        </Typography>
        <Grid container spacing={1}>
          <Chip
            icon={<DescriptionIcon />}
            label="OWASP Top 10 Scanning"
            size="small"
          />
          <Chip
            icon={<DescriptionIcon />}
            label="ML-based Malware Detection"
            size="small"
          />
          <Chip
            icon={<DescriptionIcon />}
            label="Real-time Progress Tracking"
            size="size="small""
          />
          <Chip
            icon={<DescriptionIcon />}
            label="Mobile-Optimized Reports"
            size="small"
          />
        </Grid>
      </Box>
    </Box>
  );
};

export default APKUpload;