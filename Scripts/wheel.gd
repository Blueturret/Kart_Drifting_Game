extends RayCast3D

# Class for a physics based wheel
class_name RaycastWheel

@export_category("Wheel properties")

@export var springStrength := 100.0
@export var springDamping := 2.0
@export var restDistance := 0.5
@export var overExtend := 0.2

@export var isMotor := false

@onready var wheel : Node3D = get_child(0)
@export var wheelRadius := 0.4

@export var gripCurve : Curve
