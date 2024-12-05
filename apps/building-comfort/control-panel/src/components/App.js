import React, { useEffect, useState } from 'react';
import { fetchBuildings } from '../api';
import Building from './Building';
import { Box } from '@mui/material';

const App = () => {
  const [buildings, setBuildings] = useState([]);

  useEffect(() => {
    fetchBuildings()
      .then((response) => {
        const sortedBuildings = response.data.sort((a, b) => a.name.localeCompare(b.name));
        setBuildings(sortedBuildings);
      })
      .catch((error) => console.error("Error fetching buildings:", error));
  }, []);

  return (
    <Box
      sx={{
        maxWidth: '90%',
        margin: '0 auto',
        padding: 4,
        backgroundColor: '#23272a',
        borderRadius: 4,
        boxShadow: '0px 4px 10px rgba(0, 0, 0, 0.5)',
      }}
    >
      {buildings.map((building) => (
        <Building key={building.id} building={building} />
      ))}
    </Box>
  );
};

export default App;
