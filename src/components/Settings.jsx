import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Slider,
  Divider,
  Container,
  Paper,
  useTheme,
} from '@mui/material';
import { PythonInterface } from '../../node_example';

const Settings = () => {
  const theme = useTheme();
  const [settings, setSettings] = useState({
    max_parallel_chapters: 3,
    voice_settings: {
      rate: 0,
      volume: 0,
      pitch: 0
    }
  });

  // Initialiser les paramètres depuis Python
  useEffect(() => {
    const python = new PythonInterface();
    // On pourrait ajouter une méthode pour récupérer les paramètres actuels
  }, []);

  // Mettre à jour les paramètres dans Python
  const updateSettings = async (newSettings) => {
    try {
      const python = new PythonInterface();
      await python.updateSettings({
        max_parallel_chapters: newSettings.max_parallel_chapters,
        voice_settings: {
          rate: `${newSettings.voice_settings.rate}%`,
          volume: `${newSettings.voice_settings.volume}%`,
          pitch: `${newSettings.voice_settings.pitch}Hz`
        }
      });
      setSettings(newSettings);
    } catch (error) {
      console.error('Erreur lors de la mise à jour des paramètres:', error);
    }
  };

  const handleParallelChange = (event, newValue) => {
    const newSettings = {
      ...settings,
      max_parallel_chapters: newValue
    };
    updateSettings(newSettings);
  };

  const handleVoiceSettingChange = (setting) => (event, newValue) => {
    const newSettings = {
      ...settings,
      voice_settings: {
        ...settings.voice_settings,
        [setting]: newValue
      }
    };
    updateSettings(newSettings);
  };

  return (
    <Container maxWidth="md" sx={{ py: 4 }}>
      <Typography variant="h4" gutterBottom>
        Paramètres TTS
      </Typography>
      
      <Paper elevation={2} sx={{ p: 3, mb: 4 }}>
        <Typography variant="h6" gutterBottom>
          Traitement parallèle
        </Typography>
        <Box sx={{ px: 3, py: 2 }}>
          <Typography id="parallel-chapters-slider" gutterBottom>
            Nombre maximum de chapitres traités simultanément
          </Typography>
          <Slider
            value={settings.max_parallel_chapters}
            onChange={handleParallelChange}
            aria-labelledby="parallel-chapters-slider"
            valueLabelDisplay="auto"
            step={1}
            marks
            min={1}
            max={10}
            sx={{ maxWidth: 400 }}
          />
        </Box>
      </Paper>

      <Paper elevation={2} sx={{ p: 3 }}>
        <Typography variant="h6" gutterBottom>
          Paramètres de voix Edge TTS
        </Typography>
        
        <Box sx={{ px: 3, py: 2 }}>
          <Typography id="rate-slider" gutterBottom>
            Vitesse de parole
          </Typography>
          <Slider
            value={settings.voice_settings.rate}
            onChange={handleVoiceSettingChange('rate')}
            aria-labelledby="rate-slider"
            valueLabelDisplay="auto"
            valueLabelFormat={(value) => `${value}%`}
            step={5}
            marks
            min={-100}
            max={100}
            sx={{ maxWidth: 400 }}
          />
        </Box>

        <Divider sx={{ my: 2 }} />

        <Box sx={{ px: 3, py: 2 }}>
          <Typography id="volume-slider" gutterBottom>
            Volume
          </Typography>
          <Slider
            value={settings.voice_settings.volume}
            onChange={handleVoiceSettingChange('volume')}
            aria-labelledby="volume-slider"
            valueLabelDisplay="auto"
            valueLabelFormat={(value) => `${value}%`}
            step={5}
            marks
            min={-100}
            max={100}
            sx={{ maxWidth: 400 }}
          />
        </Box>

        <Divider sx={{ my: 2 }} />

        <Box sx={{ px: 3, py: 2 }}>
          <Typography id="pitch-slider" gutterBottom>
            Hauteur de la voix
          </Typography>
          <Slider
            value={settings.voice_settings.pitch}
            onChange={handleVoiceSettingChange('pitch')}
            aria-labelledby="pitch-slider"
            valueLabelDisplay="auto"
            valueLabelFormat={(value) => `${value}Hz`}
            step={5}
            marks
            min={-100}
            max={100}
            sx={{ maxWidth: 400 }}
          />
        </Box>
      </Paper>
    </Container>
  );
};

export default Settings;
