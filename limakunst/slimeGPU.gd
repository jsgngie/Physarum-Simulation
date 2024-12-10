extends Node2D

@export var width : int = 320
@export var height : int = 180
@export var actorSpeed = 0.8
@export var numActors : int = 100
@export var number_of_groups = 1
@export var sensorDist : float = 6
@export var sensorAngle : float = 0.7
@export var turnSpeed = 0.3
var img
var texture
var emptyData = []
var viewPortData = []
var data = []
var actorsX = []
var actorsY = []
var actorsRot = []
var tex
var viewPortTex
var viewPortImg
var mat

var rd : RenderingDevice
var shader : RID
var work_group_size : int = 256

var actorsXBuffer : RID
var actorsYBuffer : RID
var actorsRotBuffer : RID
var trailMapBuffer : RID
var trailMapOutBuffer : RID

var uniform_set : RID
var pipeline : RID
var bindings : Array = []
var dispatchSize : int

@export var radius = 10
@export var simulate : bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#numActors = Global.number_of_actors_in_groups
	dispatchSize = ceili(float(numActors) / float(work_group_size))
	mat = $SubViewportContainer/SubViewport/TextureRect.material
	img = Image.create_empty(width, height, false, Image.FORMAT_RF)
	tex = ImageTexture.create_from_image(img)
	for i in range(numActors):
		var rot = randf_range(0.0, 2.0*PI)
		randomize()
		var idX = randi_range(0, 1)
		randomize()
		var idY = randi_range(0, 1)
		randomize()
		
		var angle = randf_range(-2*PI, 2*PI)
		#var pos = Vector2(randf_range(width/2 - radius, width/2 + radius), randf_range(height/2 - radius, height/2 + radius))
		var pos = Vector2(width/2 + radius * cos(angle) * randf(), height/2 + radius * sin(angle) * randf())
		#var pos = Vector2(randf_range(0.0, width), randf_range(0.0, height))
		#rot = (Vector2(width/2, height/2) - pos).angle()
		actorsX.append(pos.x)
		actorsY.append(pos.y)
		actorsRot.append(rot)
	
	# Create a local rendering device.
	rd = RenderingServer.create_local_rendering_device()
	
	# Load GLSL shader
	var shader_file := load("res://slimulation_compute.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	
	# Particle position and rotation buffers
	var actorsXBuffer_bytes := PackedFloat32Array(actorsX).to_byte_array()
	var actorsYBuffer_bytes := PackedFloat32Array(actorsY).to_byte_array()
	var actorsRotBuffer_bytes := PackedFloat32Array(actorsRot).to_byte_array()
	actorsXBuffer = rd.storage_buffer_create(actorsXBuffer_bytes.size(), actorsXBuffer_bytes)
	actorsYBuffer = rd.storage_buffer_create(actorsYBuffer_bytes.size(), actorsYBuffer_bytes)
	actorsRotBuffer = rd.storage_buffer_create(actorsRotBuffer_bytes.size(), actorsRotBuffer_bytes)
	
	var actorsXUniform := RDUniform.new()
	var actorsYUniform := RDUniform.new()
	var actorsRotUniform := RDUniform.new()
	
	actorsXUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	actorsXUniform.binding = 0
	actorsXUniform.add_id(actorsXBuffer)
	
	actorsYUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	actorsYUniform.binding = 1
	actorsYUniform.add_id(actorsYBuffer)
	
	actorsRotUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	actorsRotUniform.binding = 2
	actorsRotUniform.add_id(actorsRotBuffer)
	
	# Parameter buffer
	var params : PackedByteArray = PackedFloat32Array(
		[width, height, numActors, sensorAngle, sensorDist, actorSpeed, turnSpeed]
	).to_byte_array()
	var paramsBuffer = rd.storage_buffer_create(params.size(), params)
	var paramsUniform := RDUniform.new()
	paramsUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	paramsUniform.binding = 3
	paramsUniform.add_id(paramsBuffer)
	
	# Agent map buffer
	var fmt := RDTextureFormat.new()
	fmt.width = width
	fmt.height = height
	fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	var view := RDTextureView.new()
	trailMapBuffer = rd.texture_create(fmt, view, [img.get_data()])
	var trailMapUniform := RDUniform.new()
	trailMapUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	trailMapUniform.binding = 4
	trailMapUniform.add_id(trailMapBuffer)
	
	# Agent map output buffer
	trailMapOutBuffer = rd.texture_create(fmt, view, [img.get_data()])
	var trailMapOutUniform := RDUniform.new()
	trailMapOutUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	trailMapOutUniform.binding = 5
	trailMapOutUniform.add_id(trailMapOutBuffer)
	
	bindings = [actorsXUniform, actorsYUniform, actorsRotUniform, paramsUniform, trailMapUniform, trailMapOutUniform]
	uniform_set = rd.uniform_set_create(bindings, shader, 0)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	viewPortTex = $SubViewportContainer/SubViewport.get_texture()
	viewPortImg = viewPortTex.get_image()
	#viewPortImg.resize(width, height, 0)
	viewPortImg.convert(Image.FORMAT_RF)
	
	_process_compute()
	var trailMapData := rd.texture_get_data(trailMapOutBuffer, 0)
	img = Image.create_from_data(width, height, false, Image.FORMAT_RF, trailMapData)
	_updateBuffers()

	tex.update(img)
	mat.set_shader_parameter("dataTex", tex)

	#$SubViewportContainer/SubViewport/TextureRect.texture = tex
func _process_compute():
	pipeline = rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, dispatchSize, 1, 1)
	rd.compute_list_end()
	rd.submit()
	rd.sync()	
func _updateBuffers():
	var params : PackedByteArray = PackedFloat32Array(
		[float(width), float(height), float(numActors), sensorAngle, sensorDist, actorSpeed, turnSpeed]
	).to_byte_array()
	var paramsBuffer = rd.storage_buffer_create(params.size(), params)
	var paramsUniform := RDUniform.new()
	paramsUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	paramsUniform.binding = 3
	paramsUniform.add_id(paramsBuffer)
	
	var fmt := RDTextureFormat.new()
	fmt.width = width
	fmt.height = height
	fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	var view := RDTextureView.new()
	rd.free_rid(trailMapBuffer)
	trailMapBuffer = rd.texture_create(fmt, view, [viewPortImg.get_data()])
	var trailMapUniform := RDUniform.new()
	trailMapUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	trailMapUniform.binding = 4
	trailMapUniform.add_id(trailMapBuffer)
	
	var tempImg := Image.create_empty(width, height, false, Image.FORMAT_RF)
	rd.free_rid(trailMapOutBuffer)
	trailMapOutBuffer = rd.texture_create(fmt, view, [tempImg.get_data()])
	var trailMapOutUniform := RDUniform.new()
	trailMapOutUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	trailMapOutUniform.binding = 5
	trailMapOutUniform.add_id(trailMapOutBuffer)
	
	bindings[3] = paramsUniform
	bindings[4] = trailMapUniform
	bindings[5] = trailMapOutUniform
	uniform_set = rd.uniform_set_create(bindings, shader, 0)
