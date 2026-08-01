extends RigidBody3D
class_name CarSuspension
# LINK TO TUTORIAL : https://www.youtube.com/watch?v=9MqmFSn1Rlw&list=PLiRELyH-yJivTRnpjr0nHeGWncLiMmD2D&index=14

@export var wheels : Array[RaycastWheel]
@onready var audioEmitter: AudioStreamPlayer3D = $AudioStreamPlayer3D

var inputStopped : bool = false

@export var defaultPosition : Node3D

##### CAR ACCELERATION #####
@export_category("Kart controls")
@export var acceleration := 600.0
@export var accelerationCurve : Curve
@export var maxSpeed := 20.0

@export var turnSpeed := 0.8
@export var maxRotation := 12.5
@export var slippingTraction := 0.1

var tireTurnSpeed : float
var tireMaxRotation : float

##### DRIFTING #####
@export_category("Drifting")
@export var driftTurnSpeed := 2.0
@export var driftMaxRotation := 25.0
@export var driftingTraction := 0.08

@onready var driftTimer: Timer = $"MaxDriftTimer"
@onready var driftCooldown: Timer = $"DriftCooldown"
var canDrift : bool = true

# Emitted when kart has stopped drifting to calculate points based on drift time
signal HAS_STOPPED_DRIFTING
var driftTimeLeft : float = 0

var motorInput := 0
var isDrifting := false
var isSlipping := false

# Input detection
func _unhandled_input(event: InputEvent) -> void:
	
	if(inputStopped): return
	
	# Acceleration
	if(event.is_action_pressed("Accelerate")): motorInput = 1
	elif(event.is_action_released("Accelerate")): motorInput = 0
	
	# Deceleration
	if(event.is_action_pressed("Decelerate")): motorInput = -1
	elif(event.is_action_released("Decelerate")): motorInput = 0
	
	# Reset to global position
	if(event.is_action("Reload")):
		get_tree().reload_current_scene()
	
	# Drifting
	if(canDrift):
	
		if(event.is_action_pressed("Drift")): 
			
			isDrifting = true
			isSlipping = true
			
			tireMaxRotation = driftMaxRotation
			tireTurnSpeed = driftTurnSpeed
			
			# Prevent drifting forever
			driftTimer.start()
			
		elif(event.is_action_released("Drift")): 
			
			# Check if isDrifting is true to prevent timer from
			# starting if key is pressed while in cooldown
			if(isDrifting): 
				driftTimeLeft = driftTimer.time_left
				StopDrift()

func StopDrift() -> void:
	
	isDrifting = false
		
	tireMaxRotation = maxRotation
	tireTurnSpeed = turnSpeed
	
	canDrift = false
	
	# Emit signal and stop the timer to prevent unexpected behavior
	HAS_STOPPED_DRIFTING.emit()
	driftTimer.stop()
	
	# Start the cooldown timer
	driftCooldown.start()

func _on_drift_timer_timeout() -> void:
	
	driftTimeLeft = 0.0        
	StopDrift()
	
func _on_drift_cooldown_timeout() -> void:
	
	canDrift = true
	driftCooldown.stop()

func _ready() -> void:
	
	add_to_group("Player")
	
	tireMaxRotation = maxRotation
	tireTurnSpeed = turnSpeed
	
func _physics_process(delta: float) -> void:
	
	BasicSteeringRotation(delta)
	
	# Suspension and acceleration calculation for each while every physics frame
	var isGrounded := false
	for wheel in wheels:
		
		if(wheel.is_colliding()): isGrounded = true # Ground check
		wheel.force_raycast_update()
		DoSingleWheelSuspension(wheel)
		DoSingleWheelAcceleration(wheel)
		DoSingleWheelTraction(wheel)
		
	# Prevent flipping by lowering center of mass when not grounded
	if (isGrounded): center_of_mass = Vector3.ZERO
	else:
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN * 0.5
	
func _get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)
	
func BasicSteeringRotation(delta: float) -> void:
	
	var turnInput = Input.get_axis("TurnRight", "TurnLeft") * tireTurnSpeed
	
	if turnInput:
		
		$WheelFL.rotation.y = clampf($WheelFL.rotation.y + turnInput * delta,
			deg_to_rad(-tireMaxRotation), deg_to_rad(tireMaxRotation))
		$WheelFR.rotation.y = clampf($WheelFL.rotation.y + turnInput * delta,
			deg_to_rad(-tireMaxRotation), deg_to_rad(tireMaxRotation))
	else:
		
		$WheelFL.rotation.y = move_toward($WheelFL.rotation.y, 0, tireTurnSpeed * delta)
		$WheelFR.rotation.y = move_toward($WheelFL.rotation.y, 0, tireTurnSpeed * delta)
	
func DoSingleWheelTraction(ray: RaycastWheel) -> void:
	
	if(not ray.is_colliding()): return
	
	# Handle turning
	var sideDirection := ray.global_basis.x
	var tireVelocity := _get_point_velocity(ray.wheel.global_position)
	var steeringVelocityX := sideDirection.dot(tireVelocity)
	
	var gripFactor := absf(steeringVelocityX / tireVelocity.length())
	var xTraction := clampf(ray.gripCurve.sample_baked(gripFactor), 0.0, 1.0)
	
	# Handle slipping
	if not isDrifting and gripFactor < 0.2: isSlipping = false
	
	# Handle drifting
	if isDrifting: 
		
		xTraction = driftingTraction
		
		# Add skidmarks
		ray.get_child(1).scale = Vector3.ONE
			
	else:
		
		if(isSlipping): xTraction = slippingTraction
		
		# Remove skidmarks
		ray.get_child(1).scale = Vector3.ONE * 0.001
	
	var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var xForce := -global_basis.x * steeringVelocityX * xTraction * ((mass * gravity)/4)
	
	# Traction
	var forwardVelocity := -ray.global_basis.z.dot(tireVelocity)
	var zTraction := 0.05
	var zForce := global_basis.z * forwardVelocity * zTraction * ((mass * gravity)/4)
	
	var forcePosition := ray.wheel.global_position - global_position
	apply_force(xForce, forcePosition)
	apply_force(zForce, forcePosition)
	
func DoSingleWheelAcceleration(ray: RaycastWheel) -> void:
	
	var forward := ray.global_basis.z
	var velocity := forward.dot(linear_velocity)
	
	if(ray.is_colliding() and ray.isMotor):
		
		# Formula variables
		var speedRatio := velocity / maxSpeed
		var ac := accelerationCurve.sample_baked(speedRatio)
		var contact := ray.wheel.global_position
		var forceVector := forward * acceleration * motorInput * ac
		var forceOffset := contact - global_position
		
		# Handle audio
		
		
		# Apply forces
		if(motorInput):
			apply_force(forceVector, forceOffset)
			
	
func DoSingleWheelSuspension(ray: RaycastWheel) -> void:
	
	if(ray.is_colliding()):
		
		# Remove car pulling force
		ray.target_position.y = -(ray.restDistance + ray.wheelRadius + ray.overExtend)
		
		# Formula variables
		var contact := ray.get_collision_point()
		var springUpDir := ray.global_transform.basis.y
		var springLength := maxf(0.0, ray.global_position.distance_to(contact) - ray.wheelRadius)
		var offset := ray.restDistance - springLength
		
		# Move wheel model
		ray.get_node("Wheel").position.y = -springLength
		
		# Damping force = damping * relativeVelocity
		var worldVelocity := _get_point_velocity(contact)
		var relativeVelocity := springUpDir.dot(worldVelocity)
		var dampingForce := ray.springDamping * relativeVelocity
		
		# Force vector calculation
		var springForce := ray.springStrength * offset
		var forceVector := (springForce - dampingForce) * ray.get_collision_normal()
		var forceOffset := ray.wheel.global_position - global_position
		
		# Apply the force
		apply_force(forceVector, forceOffset)
