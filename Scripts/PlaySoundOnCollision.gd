extends RigidBody3D

var audioPlayer : AudioStreamPlayer3D
var timer : SceneTreeTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	audioPlayer = get_child(2)
	
	timer = get_tree().create_timer(0.5)
	
	# Enable signal on collision
	set_contact_monitor(true)
	max_contacts_reported = 5

func _on_body_entered(_body: Node) -> void:
	
	if(timer.time_left > 0): return
	
	audioPlayer.play()
