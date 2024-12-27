import React, { useState } from 'react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { Box, IconButton } from '@mui/material';
import { Menu as MenuIcon } from '@mui/icons-material';
import AppDrawer from './components/AppDrawer';
import Settings from './components/Settings';

const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#90caf9',
    },
    secondary: {
      main: '#f48fb1',
    },
  },
});

const App = () => {
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [showSettings, setShowSettings] = useState(false);

  const handleDrawerOpen = () => {
    setDrawerOpen(true);
  };

  const handleDrawerClose = () => {
    setDrawerOpen(false);
  };

  const handleSettingsClick = () => {
    setShowSettings(true);
    setDrawerOpen(false);
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      
      <Box sx={{ display: 'flex' }}>
        {/* Bouton pour ouvrir le drawer */}
        <IconButton
          color="inherit"
          aria-label="open drawer"
          onClick={handleDrawerOpen}
          sx={{ position: 'fixed', right: 16, top: 16 }}
        >
          <MenuIcon />
        </IconButton>

        {/* Contenu principal */}
        <Box sx={{ flexGrow: 1, p: 3 }}>
          {showSettings ? (
            <Settings />
          ) : (
            <Box>
              {/* Votre contenu principal ici */}
            </Box>
          )}
        </Box>

        {/* Drawer */}
        <AppDrawer
          open={drawerOpen}
          onClose={handleDrawerClose}
          onSettingsClick={handleSettingsClick}
        />
      </Box>
    </ThemeProvider>
  );
};

export default App;
