extends Node

var socket = StreamPeerTCP.new()
var boolb = 1
var plat_id = 1

func _ready():
	print("Connecting to server...")
	var error = socket.connect_to_host("18.170.218.235", 12000) # Aaditya's EC2 instance IP.
	if error != OK:
		print("Error connecting: " + str(error))
	
func _process(_delta):
	socket.poll()

	# Check connection status
	var status = socket.get_status()
	if status == StreamPeerTCP.STATUS_CONNECTED:

		if boolb:
			var count = 0
			socket.put_string("Platforms\n")
			for i in GameManager.platform_pos:
				var send_string = str(i[0]) + " " + str(i[1]) + '\n'
				socket.put_string(send_string) 
				count += 1
			socket.put_string("BreakingPlatforms\n")
			
			for i in GameManager.platform_break_pos:
				var send_string = str(i[0]) + " " + str(i[1]) + '\n'
				socket.put_string(send_string) 
				count += 1
			socket.put_string("MovingPlatforms\n")
#
			for i in GameManager.platform_moving_pos:
				var send_string = str(i[0]) + " " + str(i[1]) + '\n'
				socket.put_string(send_string) 
				count += 1
			
			boolb = 0
	elif status == StreamPeerTCP.STATUS_CONNECTING:
		print("CONNECTING")
	elif status == StreamPeerTCP.STATUS_ERROR:
		print("ERROR")
	elif status == StreamPeerTCP.STATUS_NONE:
		print("NONE")


func _exit_tree():
	socket.disconnect_from_host()
