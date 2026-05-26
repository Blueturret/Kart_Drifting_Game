extends Area3D

@onready var kart: CarSuspension = $"../../Kart"
@onready var progressBar: MultiplierBar = $"../../Multiplier bar"

@onready var endScreen: Control = $Control

func _on_body_entered(body: Node3D) -> void:
	
	var scoreToDisplay : int
	
	# Stop kart
	kart.inputStopped = true
	kart.acceleration = 0
	
	# Stop score progression
	scoreToDisplay = progressBar.score
	progressBar.scoreIdleIncrement = 0
	
	# Display the end screen
	endScreen.visible = true
	
	print("RACE ENDED WITH SCORE OF ", scoreToDisplay, "! :3")

func _on_button_pressed() -> void:
	
	get_tree().reload_current_scene()
