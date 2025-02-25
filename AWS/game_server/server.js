const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 8080 });

// Store connected clients
const clients = new Set();
// Store current game state
let gameState = {};

wss.on('connection', (ws) => {
  console.log('Client connected');
  clients.add(ws);
  
  // Send current game state to new client
  ws.send(JSON.stringify({
    type: 'state_update',
    data: gameState
  }));
  
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      console.log('Received:', data);
      
      if (data.type === 'state_update') {
        // Update game state
        gameState = {...gameState, ...data.data};
        
        // Broadcast to all clients
        clients.forEach((client) => {
          if (client !== ws && client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify({
              type: 'state_update',
              data: gameState
            }));
          }
        });
      }
    } catch (e) {
      console.error('Error parsing message:', e);
    }
  });
  
  ws.on('close', () => {
    console.log('Client disconnected');
    clients.delete(ws);
  });
});

console.log('Game server running on port 8080');