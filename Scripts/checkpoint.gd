extends Node3D

@export var multiplierBar : MultiplierBar
@onready var particle_constant: GPUParticles3D = $particle_constant
@onready var particle_disappear: GPUParticles3D = $particle_disappear

func _on_body_entered(_body: Node3D) -> void:
	
	multiplierBar.progressBar.value += 25
	particle_constant.emitting = false
	particle_disappear.emitting = true
	
	GameManager.instance.checkPointsCollected += 1
	
	await get_tree().create_timer(6).timeout
	
	queue_free()
