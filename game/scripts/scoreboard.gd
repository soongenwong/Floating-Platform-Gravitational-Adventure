extends Control

signal restart_game

# Variables to store player scores
var player1_score: int = 0
var player2_score: int = 0

# Called when the screen is loaded
func _ready():
    # Update the score labels
    update_score_display()
    
# Method to set scores from the main game
func set_scores(p1_score: int, p2_score: int):
    player1_score = p1_score
    player2_score = p2_score
    update_score_display()

# Update the UI with current scores
func update_score_display():
    $ScoreContainer/Player1Score.text = "Player 1: " + str(player1_score)
    $ScoreContainer/Player2Score.text = "Player 2: " + str(player2_score)
    
    # Determine the winner and update the result label
    var result_text = ""
    if player1_score > player2_score:
        result_text = "Player 1 Wins!"
    elif player2_score > player1_score:
        result_text = "Player 2 Wins!"
    else:
        result_text = "It's a Tie!"
    
    $ResultLabel.text = result_text

# Called when restart button is pressed
func _on_restart_button_pressed():
    emit_signal("restart_game")