extends Node3D

@onready var openSound: AudioStreamPlayer3D = $DoorOpen
@onready var closeSound: AudioStreamPlayer3D = $DoorClose

func Open():
	
	openSound.play()
	
	await get_tree().create_timer(0.95).timeout
	
	queue_free()
	
func Close():
	
	print("Door closed")
	closeSound.play()
