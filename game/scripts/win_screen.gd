extends Control

@onready var text_edit =  $TextEdit

var scoreboard_scene = preload("res://win_screen.tscn")
var player1_score = 0
var player2_score = 0

# Call this when the game ends
func show_scoreboard():
    var scoreboard = scoreboard_scene.instance()
    scoreboard.set_scores(player1_score, player2_score)
    scoreboard.connect("restart_game", self, "_on_restart_game")
    add_child(scoreboard)

func _ready():
	text_edit.text = Global.winner_text

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		start_game()
	pass

func _on_restart_button_pressed() -> void:
	start_game()

func start_game():
	#print("going to start screen")
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
