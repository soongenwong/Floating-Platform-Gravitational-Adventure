extends Node

   var socket = WebSocketPeer.new()
   var server_url = "ws://18.170.74.19:8080"  
   var _ws_url = "ws://localhost:8080"
   var game_state = {}
   var connected = false

   func _ready():
       var err = socket.connect_to_url(server_url)
       if err != OK:
           print("Unable to connect to server")

   func _process(delta):
       socket.poll()
       var state = socket.get_ready_state()
       
       if state == WebSocketPeer.STATE_OPEN:
           if !connected:
               connected = true
               print("Connected to server!")
           
           # Check for received data
           while socket.get_available_packet_count() > 0:
               var data = socket.get_packet().get_string_from_utf8()
               var json = JSON.parse_string(data)
               if json and json.has("type") and json.type == "state_update":
                   game_state = json.data
                   update_game_with_state(game_state)
                   
       elif state == WebSocketPeer.STATE_CLOSING:
           connected = false
           print("Connection is closing...")
       elif state == WebSocketPeer.STATE_CLOSED:
           connected = false
           var code = socket.get_close_code()
           var reason = socket.get_close_reason()
           print("Connection closed with code: %d, reason: %s" % [code, reason])

   func send_game_state(state_data):
       if connected:
           var data = {
               "type": "state_update",
               "data": state_data
           }
           var json_str = JSON.stringify(data)
           socket.send_text(json_str)
           
   func update_game_with_state(state):
       pass