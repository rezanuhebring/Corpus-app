import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Paper, Typography, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, CircularProgress, Alert } from '@mui/material';
import api from '../services/api';

export default function RecentFilesTable() {
  const [files, setFiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    const fetchRecentFiles = async () => {
      try {
        const response = await api.get('/documents/recent?limit=10');
        setFiles(response.data);
      } catch (err) {
        setError('Could not load recent files.');
        console.error(err);
      }
      setLoading(false);
    };
    fetchRecentFiles();
    const intervalId = setInterval(fetchRecentFiles, 30000);
    return () => clearInterval(intervalId);
  }, []);

  if (loading) return <CircularProgress />;
  if (error) return <Alert severity="error">{error}</Alert>;

  return (
    <Paper sx={{ p: 2, display: 'flex', flexDirection: 'column' }}>
      <Typography component="h2" variant="h6" color="primary" gutterBottom>Recently Received Files</Typography>
      <TableContainer>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Filename</TableCell>
              <TableCell>Client/Project</TableCell>
              <TableCell align="right">Received Date</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {files.map((hit) => (
              <TableRow key={hit._id} hover onClick={() => navigate(`/document/${hit._id}`)} sx={{ cursor: 'pointer' }}>
                <TableCell>{hit._source.metadata.filename_original}</TableCell>
                <TableCell>{hit._source.metadata.client_project_name}</TableCell>
                <TableCell align="right">{new Date(hit._source.metadata.modified_date).toLocaleString()}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Paper>
  );
}