extends Control
class_name MultiplierBar

# References
@onready var kart: RigidBody3D = $"../Kart"
@onready var progressBar: ProgressBar = $Panel/ProgressBar
@onready var multiplierLabel: Label = $Panel/Multiplier
@onready var scoreLabel: Label = $Score

@export var progressBarIdleIncrement := 0.015 ## The rate at which the progress bar increases oover time
@export var scoreIdleIncrement := 3 ## The rate at which the score increases over time
var score := 0
var scoreMultiplier := 1
var maxMultiplierValue := 32

var driftStartTime : int # The Unix time at which the player started a new drift

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	var kartVelocity = kart.global_basis.z.dot(kart.linear_velocity)
	var kartSpeedRatio = kartVelocity / kart.maxSpeed
	
	#print(kartSpeedRatio)
	
	# Progress bar indle increment
	progressBar.value += progressBarIdleIncrement * kartSpeedRatio
	score += scoreIdleIncrement * scoreMultiplier
	scoreLabel.text = str(score)
	
	# Decrease progress bar when moving too slowly
	if(kartSpeedRatio < 0.4):
		
		progressBar.value -= progressBarIdleIncrement * 4
		
	
	# Increase multiplier when bar gets full
	if(progressBar.value >= 100.0):
		progressBar.value = 0
		score += 300
		
		if(scoreMultiplier < maxMultiplierValue): 
		
			UpdateMultiplier(scoreMultiplier * 2)
	
	# Decrease multiplier when bar gets below zero
	if(progressBar.value < 0.0):
		
		if(scoreMultiplier > 1): 
		
			progressBar.value = 99.0
			print("Decreasing")
			UpdateMultiplier(scoreMultiplier / 2)
			
		else: progressBar.value = 0.0
		
## Add an integer value to the progress bar
func AddToScore(toAdd : int) -> void:
	
	progressBar.value += toAdd
	
func UpdateMultiplier(newMultiplier : int) -> void:
	
	scoreMultiplier = newMultiplier
	multiplierLabel.text = "x" + str(newMultiplier)
