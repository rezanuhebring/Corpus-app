import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { Typography, Paper, Box, CircularProgress, Alert, Grid, Divider, Chip, Tabs, Tab, Button } from '@mui/material';
import api from '../services/api';

function TabPanel(props) {
  const { children, value, index } = props;
  return (<div role="tabpanel" hidden={value !== index}>{value === index && <Box sx={{ p: 3 }}>{children}</Box>}</div>);
}

export default function DocumentView() {
  const { id } = useParams();
  const [document, setDocument] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [tabValue, setTabValue] = useState(0);

  useEffect(() => {
    const fetchDocument = async () => {
      setLoading(true); setError('');
      try {
        const response = await api.get(`/documents/${id}`);
        setDocument(response.data);
      } catch (err) {
        setError('Failed to fetch document.');
        console.error(err);
      }
      setLoading(false);
    };
    fetchDocument();
  }, [id]);

  if (loading) return <CircularProgress />;
  if (error) return <Alert severity="error">{error}</Alert>;
  if (!document) return <Alert severity="info">No document found.</Alert>;

  const meta = document._source.metadata;
  return (
    <Paper sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>{meta.filename_original}</Typography>
      <Grid container spacing={2} sx={{ mb: 2 }}>
        <Grid item xs={12} sm={6}><Typography variant="subtitle2" color="text.secondary">Client/Project</Typography><Typography variant="body1">{meta.client_project_name}</Typography></Grid>
        <Grid item xs={12} sm={6}><Typography variant="subtitle2" color="text.secondary">Modified Date</Typography><Typography variant="body1">{new Date(meta.modified_date).toLocaleString()}</Typography></Grid>
        <Grid item xs={12} sm={6}><Typography variant="subtitle2" color="text.secondary">Document Type</Typography><Chip label={meta.doc_type || 'N/A'} color="primary" /></Grid>
        <Grid item xs={12} sm={6}><Typography variant="subtitle2" color="text.secondary">Status</Typography><Chip label={meta.status || 'N/A'} color="secondary" /></Grid>
      </Grid>
      <Divider sx={{ my: 2 }} />
      <Box sx={{ borderBottom: 1, borderColor: 'divider' }}><Tabs value={tabValue} onChange={(e,v) => setTabValue(v)}><Tab label="HTML View" /><Tab label="Raw Text" /><Tab label="Download Original" /></Tabs></Box>
      <TabPanel value={tabValue} index={0}><Box sx={{ whiteSpace: 'pre-wrap', fontFamily: 'monospace', maxHeight: '60vh', overflowY: 'auto' }}>{document._source.content}</Box></TabPanel>
      <TabPanel value={tabValue} index={1}><Box sx={{ whiteSpace: 'pre-wrap', fontFamily: 'monospace', maxHeight: '60vh', overflowY: 'auto' }}>{document._source.content}</Box></TabPanel>
      <TabPanel value={tabValue} index={2}><Button variant="contained">Download '{meta.filename_original}'</Button></TabPanel>
    </Paper>
  );
}