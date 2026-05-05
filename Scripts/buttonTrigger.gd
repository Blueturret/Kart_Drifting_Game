extends Node3D

@export_category("Button trigger")
@export var toTrigger: Array[Node3D]
@export var onEnterMethod : String
@export var onTimerRunOutMethod : String
@export var onExitMethod : String

@export_category("Dependencies")
@export var redMat : StandardMaterial3D
@export var greenMat : StandardMaterial3D
@onready var timer: Timer = $Timer

@export_category("Timer settings")
@export var useTimer : bool = false
@export var timeToReset : int = 5

var triggerable := true

func _on_body_entered(_body: Node3D) -> void:
	
	if(not triggerable or onEnterMethod == "" or toTrigger == null): return
	
	# Set material to green
	get_child(0).material_override = greenMat
	
	for obj in toTrigger:
	
		if(obj.has_method(onEnterMethod)):
			
			obj.call(onEnterMethod)
			
		else:
			
			push_error("Object " + str(toTrigger) +
					" doesn't have the method " + onEnterMethod)
		
	# Set timer if button is using one
	if(useTimer):
		
		timer.wait_time = timeToReset
		timer.start()
		
	triggerable = false

func _on_body_exited(_body: Node3D) -> void:
	
	if(not triggerable or onExitMethod == "" or toTrigger == null): return
	
	for obj in toTrigger:
		
		if(obj.has_method(onExitMethod)):
			
			obj.call(onExitMethod)
		
		else:
			
			push_error("Object " + str(toTrigger) +
					" doesn't have the method " + onExitMethod)

func _on_timer_timeout() -> void:
	
	# Set material to red
	get_child(0).material_override = redMat
	triggerable = true
	
	if(onTimerRunOutMethod == ""): return
		
	for obj in toTrigger:
		
		if(obj.has_method(onTimerRunOutMethod)):
		
			obj.call(onTimerRunOutMethod)
		
		else:
		
			push_error("Object " + str(toTrigger) +
					" doesn't have the method " + onTimerRunOutMethod)
