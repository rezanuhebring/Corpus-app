import React, { useState, useEffect } from 'react';
import { 
    Paper, Typography, Table, TableBody, TableCell, TableContainer, 
    TableHead, TableRow, CircularProgress, Alert, Button, Dialog, 
    DialogTitle, DialogContent, DialogActions, TextField, Box 
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import api from '../../services/api';

export default function UserManagement() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [open, setOpen] = useState(false); // For the "Add User" dialog
  const [newUser, setNewUser] = useState({
    username: '',
    full_name: '',
    password: '',
  });

  const fetchUsers = async () => {
    try {
      const response = await api.get('/admin/users');
      setUsers(response.data);
    } catch (err) {
      setError('Could not load users. You may not have permission.');
      console.error(err);
    }
    setLoading(false);
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleOpen = () => setOpen(true);
  const handleClose = () => setOpen(false);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setNewUser(prevState => ({ ...prevState, [name]: value }));
  };

  const handleCreateUser = async () => {
    try {
      await api.post('/admin/users', newUser);
      handleClose();
      setNewUser({ username: '', full_name: '', password: '' });
      fetchUsers(); // Refresh the user list
    } catch (err) {
      setError('Failed to create user. The email may already exist.');
      console.error(err);
    }
  };

  if (loading) return <CircularProgress />;
  
  return (
    <>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" gutterBottom>
          User Management
        </Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={handleOpen}>
          Add User
        </Button>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Full Name</TableCell>
              <TableCell>Email (Username)</TableCell>
              <TableCell>Role</TableCell>
              <TableCell>Status</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {users.map((user) => (
              <TableRow key={user.username}>
                <TableCell>{user.full_name}</TableCell>
                <TableCell>{user.username}</TableCell>
                <TableCell>{user.role}</TableCell>
                <TableCell>{user.disabled ? 'Disabled' : 'Active'}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Add User Dialog */}
      <Dialog open={open} onClose={handleClose}>
        <DialogTitle>Add New User</DialogTitle>
        <DialogContent>
          <TextField autoFocus margin="dense" name="full_name" label="Full Name" type="text" fullWidth variant="standard" value={newUser.full_name} onChange={handleInputChange} />
          <TextField margin="dense" name="username" label="Email Address" type="email" fullWidth required variant="standard" value={newUser.username} onChange={handleInputChange} />
          <TextField margin="dense" name="password" label="Password" type="password" fullWidth required variant="standard" value={newUser.password} onChange={handleInputChange} />
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose}>Cancel</Button>
          <Button onClick={handleCreateUser} variant="contained">Create</Button>
        </DialogActions>
      </Dialog>
    </>
  );
}