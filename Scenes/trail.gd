extends Line2D

var queue : Array
@export var MAX_LENGTH : int

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var pos
	
	pos = get_viewport().get_camera_3d().unproject_position(get_parent().position)
	print(pos)
	
	queue.push_front(pos)
	if queue.size() > MAX_LENGTH:
		queue.pop_back()
	
	clear_points()
	
	for point in queue: add_point(point)
