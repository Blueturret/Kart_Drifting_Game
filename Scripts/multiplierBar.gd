extends Control

# References
@onready var kart: RigidBody3D = $"../Kart"
@onready var progressBar: ProgressBar = $Panel/ProgressBar
@onready var multiplierLabel: Label = $Panel/Multiplier
@onready var scoreLabel: Label = $Score

@export var triggerIncrement := 10
@export var progressBarIdleIncrement := 0.015
@export var scoreIdleIncrement := 3
var score := 0
var scoreMultiplier := 1
var maxMultiplierValue := 32

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	var kartVelocity = kart.global_basis.z.dot(kart.linear_velocity)
	var kartSpeedRatio = kartVelocity / kart.maxSpeed
	
	# Progress bar indle increment
	progressBar.value += progressBarIdleIncrement * kartSpeedRatio
	score += scoreIdleIncrement * scoreMultiplier
	scoreLabel.text = str(score)
	
	# Increment when passing through arch trigger
	if(Input.is_action_just_pressed("Drift")):
		AddToScore(15)
	
	if(progressBar.value >= 100.0):
		progressBar.value = 0
		score += 300
		
		if(scoreMultiplier < maxMultiplierValue): 
		
			scoreMultiplier *= 2
			multiplierLabel.text = "x" + str(scoreMultiplier)
		
## Add an integer value to the progress bar
func AddToScore(toAdd : int):
	
	progressBar.value += toAdd
