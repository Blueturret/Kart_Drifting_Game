extends Node3D

@export var multiplierBar : MultiplierBar

func _on_body_entered(_body: Node3D) -> void:
	
	multiplierBar.AddToScore(25)
	queue_free()
