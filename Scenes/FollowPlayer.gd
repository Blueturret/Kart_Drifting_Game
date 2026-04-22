extends Camera3D

@export var offset := 40.0
@export var moveSpeed := 1.5
@export var rotationSpeed := 1.5
@onready var kart: RigidBody3D = $"../Kart"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	global_position = global_transform.origin.move_toward(Vector3(
			kart.global_position.x,
			kart.global_position.y + offset,
			kart.global_position.z), delta * moveSpeed)
			
	global_rotation.y = rotate_toward(global_rotation.y, kart.global_rotation.y + deg_to_rad(180), delta * rotationSpeed)
