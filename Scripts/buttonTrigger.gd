extends Node3D

@export var useTimer : bool = false
@export var timeToReset : int = 5

var triggerable := true

@export var redMat : StandardMaterial3D
@export var greenMat : StandardMaterial3D
@onready var timer: Timer = $Timer

func _on_body_entered(_body: Node3D) -> void:
	
	if(not triggerable): return
	
	get_child(0).material_override = greenMat
	
	if(useTimer):
		
		timer.wait_time = timeToReset
		timer.start()
		
	triggerable = false

func _on_timer_timeout() -> void:
	
	get_child(0).material_override = redMat
	triggerable = true
