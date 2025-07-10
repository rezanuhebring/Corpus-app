import React from 'react';
import { Typography, Grid, Paper } from '@mui/material';
import RecentFilesTable from '../components/RecentFilesTable';

export default function Dashboard() {
  return (
    <>
      <Typography variant="h4" gutterBottom>Dashboard</Typography>
      <Grid container spacing={3}>
        <Grid item xs={12} md={4}><Paper sx={{ p: 2 }}><Typography variant="h6" color="primary">Docs Today</Typography><Typography variant="h4">128</Typography></Paper></Grid>
        <Grid item xs={12} md={4}><Paper sx={{ p: 2 }}><Typography variant="h6" color="primary">Total Docs</Typography><Typography variant="h4">1,452,109</Typography></Paper></Grid>
        <Grid item xs={12} md={4}><Paper sx={{ p: 2 }}><Typography variant="h6" color="primary">Pending Review</Typography><Typography variant="h4">15</Typography></Paper></Grid>
        <Grid item xs={12}><RecentFilesTable /></Grid>
      </Grid>
    </>
  );
}