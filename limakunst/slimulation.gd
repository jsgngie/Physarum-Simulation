extends Node2D

@onready var texture_rect = $"Control/ShaderBox"
@onready var random_number_gen = RandomNumberGenerator.new()

var number_of_actors = 25000
var actor_coordinates = []
var max_number_of_actors = 25000

var actor_velocities = []
var max_speed = 0.5 # Pixels per second.

# This function initializes the actor_coordinates array that will be passed to the shader.
func _get_actor_coordinates():
	random_number_gen.randomize() 
	actor_velocities = []
	
	for i in range(number_of_actors):
		var shader_box_size = texture_rect.get_size()

		var random_x = random_number_gen.randf_range(0, shader_box_size[0]) / shader_box_size[0]
		var random_y = random_number_gen.randf_range(0, shader_box_size[1]) / shader_box_size[1]
		actor_coordinates.append(Vector2(random_x, random_y))
	
	# Pad the array with ZEROS if needed
	while len(actor_coordinates) < max_number_of_actors:
		actor_coordinates.append(Vector2.ZERO)

# This function initializes the array that will be passed to the shader.
func _get_actor_velocity():
	# Randomize velocity directions at the start
	for i in range(number_of_actors):
		var velocity = Vector2(random_number_gen.randf_range(-1.0, 1.0), random_number_gen.randf_range(-1.0, 1.0))
		velocity = velocity.normalized() * random_number_gen.randf_range(0, max_speed)
		actor_velocities.append(velocity)
	
	# Pad the velocity array if needed
	while len(actor_velocities) < max_number_of_actors:
		actor_velocities.append(Vector2.ZERO)

func _ready():
	_get_actor_coordinates()
	_get_actor_velocity()
	
	# Pass the uniforms to shader
	if texture_rect.material:
		var shader_material = texture_rect.material as ShaderMaterial
		shader_material.set_shader_parameter("actor_coordinates", actor_coordinates)
		shader_material.set_shader_parameter("number_of_actors", number_of_actors)

func _process(delta):
	# Randomize velocities every delta
	for i in range(number_of_actors):
		
		# Randomize the velocity on each frame
		var velocity = Vector2(random_number_gen.randf_range(-1.0, 1.0), random_number_gen.randf_range(-1.0, 1.0))
		velocity = velocity.normalized() * random_number_gen.randf_range(0, max_speed)
		actor_velocities[i] = velocity  # Update the velocity with the new random value
		
		# Update the position based on velocity
		actor_coordinates[i] += actor_velocities[i] * delta
		
		if actor_coordinates[i].x < 0.0 or actor_coordinates[i].x > 1.0:
			actor_velocities[i].x = -actor_velocities[i].x
		if actor_coordinates[i].y < 0.0 or actor_coordinates[i].y > 1.0:
			actor_velocities[i].y = -actor_velocities[i].y

	# Pass updated actor coordinates to the shader every frame
	if texture_rect.material:
		var shader_material = texture_rect.material as ShaderMaterial
		shader_material.set_shader_parameter("actor_coordinates", actor_coordinates)
