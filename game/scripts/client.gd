extends Node

var socket = StreamPeerTCP.new()

func _ready():
	print("Connecting to server...")
	var error = socket.connect_to_host("18.170.218.235", 12000)
	if error != OK:
		print("Error connecting: " + str(error))
	
func _process(_delta):
	socket.poll()

	# Check connection status
	var status = socket.get_status()
	#print("status:", status)
	if status == StreamPeerTCP.STATUS_CONNECTED:
		#print("CONNECTED")
		if Input.is_action_just_pressed("ui_up"):
			var message = "up\n"
			socket.put_data(message.to_utf8_buffer())
			print("Sent: up")
	elif status == StreamPeerTCP.STATUS_CONNECTING:
		print("CONNECTING")
	elif status == StreamPeerTCP.STATUS_ERROR:
		print("ERROR")
	elif status == StreamPeerTCP.STATUS_NONE:
		print("NONE")


func _exit_tree():
	socket.disconnect_from_host()
