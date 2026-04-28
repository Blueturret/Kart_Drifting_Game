extends RigidBody3D

# LINK TO TUTORIAL : https://www.youtube.com/watch?v=9MqmFSn1Rlw&list=PLiRELyH-yJivTRnpjr0nHeGWncLiMmD2D&index=14

@export var wheels : Array[RaycastWheel]

@export_category("Car acceleration")
@export var acceleration := 600.0
@export var accelerationCurve : Curve
@export var maxSpeed := 20.0

@export_category("Drifting")
@export var tireTurnSpeed := 2.0
@export var tireMaxRotation := 25.0
@export var driftingTraction := 0.08
@export var slippingTraction := 0.1

@export_category("DEBUG")
@export var defaultPosition : Node3D
signal POSITION_RESET

var motorInput := 0
var isDrifting := false
var isSlipping := false

# Input detection
func _unhandled_input(event: InputEvent) -> void:
	
	# Acceleration
	if(event.is_action_pressed("Accelerate")): motorInput = 1
	elif(event.is_action_released("Accelerate")): motorInput = 0
	
	# Deceleration
	if(event.is_action_pressed("Decelerate")): motorInput = -1
	elif(event.is_action_released("Decelerate")): motorInput = 0
	
	# Drifting
	if(event.is_action_pressed("Drift")): isDrifting = true ; isSlipping = true
	elif(event.is_action_released("Drift")): isDrifting = false
	
	### DEBUG ###
	# Reset to global position
	if(event.is_action("ResetPos")):
		global_position = defaultPosition.global_position
		linear_velocity = Vector3.ZERO
		isDrifting = false
		isSlipping = false
		global_rotation = Vector3(0, 0, 0)
		POSITION_RESET.emit()

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
	var xTraction := ray.gripCurve.sample_baked(gripFactor)
	
	# Handle slipping
	if not isDrifting and gripFactor < 0.2: isSlipping = false
	
	# Handle drifting
	if isDrifting: 
		
		xTraction = driftingTraction
		
		if(ray.get_child_count() >= 2):
			ray.get_child(1).scale = Vector3.ONE
		
	elif isSlipping:
		xTraction = slippingTraction
		
		if(ray.get_child_count() >= 2):
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
