import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Box, Typography, Grid, Paper, TextField, Button, Table, TableBody, TableCell, TableContainer, TableHead, TableRow } from '@mui/material';
import PrintIcon from '@mui/icons-material/Print';
import DownloadIcon from '@mui/icons-material/Download';
import api from '../services/api';

export default function Search() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSearch = async () => {
    setLoading(true);
    try {
      const response = await api.post('/documents/search', { query: query });
      setResults(response.data.hits);
    } catch (error) { console.error("Search failed:", error); }
    setLoading(false);
  };

  const handleDownloadCSV = async () => {
    try {
      const response = await api.post('/documents/export/csv', { query: query }, { responseType: 'blob' });
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      const disposition = response.headers['content-disposition'];
      let filename = `corpus_export.csv`;
      if (disposition && disposition.indexOf('attachment') !== -1) {
          const filenameRegex = /filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/;
          const matches = filenameRegex.exec(disposition);
          if (matches != null && matches[1]) {
            filename = matches[1].replace(/['"]/g, '');
          }
      }
      link.setAttribute('download', filename);
      document.body.appendChild(link);
      link.click();
      link.parentNode.removeChild(link);
    } catch (error) { console.error("CSV Download failed:", error); }
  };

  return (
    <>
      <Typography variant="h4" gutterBottom>Document Search</Typography>
      <Paper sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={10}><TextField fullWidth label="Search..." variant="outlined" value={query} onChange={(e) => setQuery(e.target.value)} onKeyPress={(e) => e.key === 'Enter' && handleSearch()} /></Grid>
          <Grid item xs={2}><Button fullWidth variant="contained" size="large" onClick={handleSearch} disabled={loading}>{loading ? '...' : 'Search'}</Button></Grid>
        </Grid>
      </Paper>
      <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 2, '@media print': { display: 'none' } }}>
        <Button variant="outlined" startIcon={<PrintIcon />} onClick={() => window.print()} sx={{ mr: 2 }} disabled={results.length === 0}>Print Summary</Button>
        <Button variant="contained" startIcon={<DownloadIcon />} onClick={handleDownloadCSV} disabled={results.length === 0}>Download CSV</Button>
      </Box>
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow><TableCell>Filename</TableCell><TableCell>Client/Project</TableCell><TableCell>Doc Type</TableCell><TableCell align="right">Modified Date</TableCell></TableRow>
          </TableHead>
          <TableBody>
            {results.map((hit) => (
              <TableRow key={hit._id} hover onClick={() => navigate(`/document/${hit._id}`)} sx={{ cursor: 'pointer' }}>
                <TableCell>{hit._source.metadata.filename_original}</TableCell>
                <TableCell>{hit._source.metadata.client_project_name}</TableCell>
                <TableCell>{hit._source.metadata.doc_type}</TableCell>
                <TableCell align="right">{new Date(hit._source.metadata.modified_date).toLocaleDateString()}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </>
  );
}