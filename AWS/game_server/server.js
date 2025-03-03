const net = require('net');

// Store connected clients
const clients = new Map(); 
// Store current game state
let gameState = {
    players: {},
    gameInProgress: false
};

const server = net.createServer((socket) => {
    console.log('Client connected');
    const clientId = generateClientId();
    clients.set(socket, clientId);
    
    let buffer = '';
    
    socket.on('data', (data) => {
        buffer += data.toString();
        
        const messages = buffer.split('\n');
        buffer = messages.pop();
        
        messages.forEach(message => {
            if (message.length > 0) {
                try {
                    const parsedData = JSON.parse(message);
                    console.log('Received:', parsedData);
                    
                    handleMessage(socket, parsedData);
                } catch (e) {
                    console.error('Error parsing message:', e);
                }
            }
        });
    });
    
    socket.on('close', () => {
        console.log('Client disconnected:', clients.get(socket));
        // Handle player disconnection
        const playerId = clients.get(socket);
        if (gameState.players[playerId]) {
            delete gameState.players[playerId];
            // Notify other players someone left
            broadcastGameState();
        }
        clients.delete(socket);
    });
    
    socket.on('error', (err) => {
        console.error('Socket error:', err);
        clients.delete(socket);
    });
});

function handleMessage(socket, message) {
    const playerId = clients.get(socket);
    
    switch (message.type) {
        case 'player_register':
            registerPlayer(socket, message.player_id);
            break;
            
        case 'player_action':
            processPlayerAction(message.player_id, message.action);
            break;
            
        case 'state_update':
            
            break;
    }
}

function registerPlayer(socket, requestedId) {
    const playerId = requestedId || generateClientId();
    clients.set(socket, playerId);
    
    // Add player to game state
    gameState.players[playerId] = {
        id: playerId,
        x: Math.floor(Math.random() * 300) + 100, 
        y: Math.floor(Math.random() * 200) + 100,
        score: 0
    };
    
    // Confirm player registration
    socket.write(JSON.stringify({
        type: 'player_assigned',
        player_id: playerId
    }) + '\n');
    
    console.log(`Player registered: ${playerId}`);
    console.log(`Total players: ${Object.keys(gameState.players).length}`);
    
    if (Object.keys(gameState.players).length >= 2 && !gameState.gameInProgress) {
        startGame();
    }
    
    broadcastGameState();
}

function processPlayerAction(playerId, action) {
    // Update game state based on player action
    if (gameState.players[playerId]) {
        switch(action.type) {
            case 'move':
                gameState.players[playerId].x = action.x;
                gameState.players[playerId].y = action.y;
                break;
            case 'attack':
                // Handle attack logic
                break;
            // Add other action types as needed
        }
        
        broadcastGameState();
    }
}

function startGame() {
    gameState.gameInProgress = true;
    const playerIds = Object.keys(gameState.players);
    
    for (const [socket, id] of clients.entries()) {
        socket.write(JSON.stringify({
            type: 'game_start',
            players: playerIds
        }) + '\n');
    }
    
    console.log('Game started with players:', playerIds);
}

function broadcastGameState() {
    const gameStateMsg = JSON.stringify({
        type: 'state_update',
        data: gameState
    }) + '\n';
    
    for (const [socket, id] of clients.entries()) {
        if (!socket.destroyed) {
            socket.write(gameStateMsg);
        }
    }
}

function generateClientId() {
    return Math.random().toString(36).substring(2, 15);
}

server.listen(8080, () => {
    console.log('Game server running on port 8080');
});