extends Camera3D

var globalOffset : Vector3
@export var moveSpeed := 1.5
@onready var kart: RigidBody3D = $"../Kart"

func _ready() -> void:
	
	globalOffset = global_position - kart.global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	#global_position = global_transform.origin.move_toward(Vector3(
			#kart.global_position.x,
			#kart.global_position.y + yOffset,
			#kart.position.z), delta * moveSpeed)
			
	global_position = global_transform.origin.move_toward(
				kart.global_position + globalOffset, delta * moveSpeed)


func _on_kart_position_reset() -> void:
	get_tree().reload_current_scene()
