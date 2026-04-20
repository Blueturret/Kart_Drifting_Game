extends RigidBody3D

# LINK TO TUTORIAL : https://www.youtube.com/watch?v=9MqmFSn1Rlw&list=PLiRELyH-yJivTRnpjr0nHeGWncLiMmD2D&index=14

@export var wheels : Array[RaycastWheel]

@export_category("Car Properties")
@export var acceleration := 600.0
@export var accelerationCurve : Curve
@export var deceleration := 200.0
@export var maxSpeed := 20.0
var motorInput := 0

# Input detection
func _unhandled_input(event: InputEvent) -> void:
	
	if(event.is_action_pressed("Accelerate")): motorInput = 1
	elif(event.is_action_released("Accelerate")): motorInput = 0
	
	if(event.is_action_pressed("Decelerate")): motorInput = -1
	elif(event.is_action_released("Decelerate")): motorInput = 0

func _physics_process(delta: float) -> void:
	
	var isGrounded := false
	
	# Suspension and acceleration calculation for each while every physics frame
	for wheel in wheels:
		
		if(wheel.is_colliding()): isGrounded = true
		wheel.force_raycast_update()
		DoSingleWheelSuspension(wheel)
		DoSingleWheelAcceleration(wheel)
		
	# Prevent flipping by lowering center of mass when not grounded
	if (isGrounded): center_of_mass = Vector3.ZERO
	else:
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN * 0.5
	
func _get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)
	
func DoSingleWheelAcceleration(ray: RaycastWheel) -> void:
	
	var forward := ray.global_basis.z
	var velocity := forward.dot(linear_velocity)
	
	# Wheels rotation
	ray.wheel.rotate_x(-velocity * get_process_delta_time() * 2 * PI * ray.wheelRadius)
	
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
		elif abs(velocity) > 0.05: # Deceleration when not pressing keys
			forceVector = -global_basis.z * deceleration * signf(velocity)
			apply_force(forceVector, forceOffset)
	
func DoSingleWheelSuspension(ray: RaycastWheel) -> void:
	
	if(ray.is_colliding()):
		
		# Remove car pulling force
		ray.target_position.y = -(ray.restDistance + ray.wheelRadius + ray.overExtend)
		
		# Formula variables
		var contact := ray.get_collision_point()
		var springUpDir := ray.global_transform.basis.y
		var springLength := ray.global_position.distance_to(contact) - ray.wheelRadius
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
