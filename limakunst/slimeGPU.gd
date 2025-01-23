extends Node2D

@export var width : int = 320
@export var height : int = 180
@export var actorSpeed = 1
@export var numActors : int = 100
@export var numberOfGroups = 1
@export var sensorDist : float = 6
@export var sensorAngle : float = 0.7
@export var turnSpeed = 0.3
@export var dissapation = 0.01
@export var debugData : bool = false

@export var actorSpeeds = Vector3(2, 2, 2)
@export var sensorDists = Vector3(8, 8, 8)
@export var sensorAngles = Vector3(0.3, 0.3, 0.3)
@export var turnSpeeds = Vector3(0.3, 0.3, 0.3)

@export var relationMult = 1.5

var img
var texture
var emptyData = []
var viewPortData = []
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
var actorsGroupsBuffer : RID
var trailMapBuffer : RID
var trailMapOutBuffer : RID
var groupParamsBuffer : RID


var uniform_set : RID
var pipeline : RID
var bindings : Array = []
var dispatchSize : int

var tempImg : Image

var firstStep = true

@export var radius = 10
@export var simulate : bool

@onready var finalShader = $FinalImage;
@onready var dissapationShader = $SubViewportContainer/SubViewport/TextureRect.material

@onready var firstPicker = $colorButtons/firstColorPicker
@onready var secondPicker = $colorButtons/secondColorPicker
@onready var thirdPicker = $colorButtons/thirdColorPicker

@onready var colorButtons = $colorButtons

@onready var speedLabel = $sliderControlContainer/Speed/actorSpeedLabelDisplay
@onready var distanceLabel = $"sliderControlContainer/Sensor distance/sensorDistanceLabelDisplayed"
@onready var angleLabel = $"sliderControlContainer/Sensor angle/sensorAngleLabelDisplayed"
@onready var groupLabel = $sliderControlContainer/Group/actorGroupLabelDisplay
@onready var turnSpeedLabel = $sliderControlContainer/TurnSpeed/actorTurnSpeedLabelDisplay
@onready var dissapationLabel = $sliderControlContainer/Dissapation2/DissapationLabelDisplayed
@onready var relationLabel = $sliderControlContainer/Dissapation/RelationSliderDisplay

@onready var sliderContainer = $sliderControlContainer
@onready var sliderBackground = $sliderControlBackground

@onready var groupSlider = $sliderControlContainer/Group/actorGroupSlider
@onready var speedSlider = $sliderControlContainer/Speed/actorSpeedSlider
@onready var distanceSlider =$"sliderControlContainer/Sensor distance/sensorDistanceSlider"
@onready var angleSlider = $"sliderControlContainer/Sensor angle/sensorAngleSlider"
@onready var turnSpeedSlider = $sliderControlContainer/TurnSpeed/actorTurnSpeedSlider
@onready var dissapationSlider = $sliderControlContainer/Dissapation2/DissapationSlider
@onready var relationSlider = $sliderControlContainer/Dissapation/RelationSlider

var isHidden = false

# Sets up the colors.
func assignColors():
	_on_color_picker_button_color_changed(Global.firstColor)
	_on_second_color_picker_color_changed(Global.secondColor)
	_on_third_color_picker_color_changed(Global.thirdColor)
	
	firstPicker.color = Global.firstColor
	secondPicker.color = Global.secondColor
	thirdPicker.color = Global.thirdColor

func updateLabels():
	angleLabel.text = String.num(sensorAngle, 2)
	distanceLabel.text = String.num(sensorDist, 0)
	speedLabel.text = String.num(actorSpeed, 0)
	groupLabel.text = String.num(numberOfGroups, 0)
	turnSpeedLabel.text = String.num(turnSpeed, 2)
	dissapationLabel.text = String.num(dissapation, 2)
	relationLabel.text = String.num(relationMult, 2)
	
	speedSlider.value = actorSpeed
	turnSpeedSlider.value = turnSpeed
	distanceSlider.value = sensorDist
	angleSlider.value = sensorAngle
	groupSlider.value = numberOfGroups
	dissapationSlider.value = dissapation
	relationSlider.value = relationMult
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	dissapationShader.set_shader_parameter("clear", false)
	
	numActors = Global.number_of_actors_in_groups
	actorSpeed = Global.speed_of_actors
	numberOfGroups = Global.number_of_groups;
	sensorDist = Global.sensorDistance
	sensorAngle = Global.sensorAngle
	turnSpeed = Global.turnSpeed
	dissapation = Global.dissapation
	relationMult = Global.realtionMult
	
	actorSpeeds = Global.actorSpeeds
	sensorDists = Global.sensorDists
	sensorAngles = Global.sensorAngles
	turnSpeeds = Global.turnSpeeds
	assignColors()
	updateLabels()
	
	dispatchSize = ceili(float(numActors) / float(work_group_size))
	mat = $SubViewportContainer/SubViewport/TextureRect.material
	img = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	tex = ImageTexture.create_from_image(img)
	tempImg = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	
	var actorGroups = []
	for i in range(numActors):
		var rot = randf_range(0.0, 2.0*PI)
		randomize()
		var idX = randi_range(0, 1)
		randomize()
		var idY = randi_range(0, 1)
		randomize()
		
		var angle = randf_range(-2*PI, 2*PI)

		var pos = Vector2(width/2 + radius * cos(angle) * randf(), height/2 + radius * sin(angle) * randf())

		actorsX.append(pos.x)
		actorsY.append(pos.y)
		actorsRot.append(rot)
		actorGroups.append(i % int(numberOfGroups));
	
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
	var actorsGroupsBuffer_bytes := PackedInt32Array(actorGroups).to_byte_array()
	
	actorsXBuffer = rd.storage_buffer_create(actorsXBuffer_bytes.size(), actorsXBuffer_bytes)
	actorsYBuffer = rd.storage_buffer_create(actorsYBuffer_bytes.size(), actorsYBuffer_bytes)
	actorsRotBuffer = rd.storage_buffer_create(actorsRotBuffer_bytes.size(), actorsRotBuffer_bytes)
	actorsGroupsBuffer = rd.storage_buffer_create(actorsGroupsBuffer_bytes.size(), actorsGroupsBuffer_bytes)
	
	var actorsXUniform := RDUniform.new()
	var actorsYUniform := RDUniform.new()
	var actorsRotUniform := RDUniform.new()
	var actorsGroupsUniform := RDUniform.new()
	
	actorsXUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	actorsXUniform.binding = 0
	actorsXUniform.add_id(actorsXBuffer)
	
	actorsYUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	actorsYUniform.binding = 1
	actorsYUniform.add_id(actorsYBuffer)
	
	actorsRotUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	actorsRotUniform.binding = 2
	actorsRotUniform.add_id(actorsRotBuffer)
	
	actorsGroupsUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	actorsGroupsUniform.binding = 6
	actorsGroupsUniform.add_id(actorsGroupsBuffer)
	
	# Parameter buffer
	var params : PackedByteArray = PackedFloat32Array(
		[width, height, numActors, sensorAngle, sensorDist, actorSpeed, turnSpeed, numberOfGroups]
	).to_byte_array()
	var paramsBuffer = rd.storage_buffer_create(params.size(), params)
	var paramsUniform := RDUniform.new()
	paramsUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	paramsUniform.binding = 3
	paramsUniform.add_id(paramsBuffer)

	var groupParams  = PackedFloat32Array(
		[actorSpeeds.x, actorSpeeds.y, actorSpeeds.z, 0.0, sensorDists.x, sensorDists.y, sensorDists.z, 0.0, sensorAngles.x, sensorAngles.y, sensorAngles.z, 0.0, turnSpeeds.x, turnSpeeds.y, turnSpeeds.z, 0.0] 
	).to_byte_array()
	groupParamsBuffer = rd.storage_buffer_create(groupParams.size(), groupParams)
	var groupParamsUniform := RDUniform.new()
	groupParamsUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	groupParamsUniform.binding = 7
	groupParamsUniform.add_id(groupParamsBuffer)
	
	# Agent map buffer
	var fmt := RDTextureFormat.new()
	fmt.width = width
	fmt.height = height
	fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
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
	
	bindings = [actorsXUniform, actorsYUniform, actorsRotUniform, paramsUniform, trailMapUniform, trailMapOutUniform, actorsGroupsUniform, groupParamsUniform]
	
	uniform_set = rd.uniform_set_create(bindings, shader, 0)
	
func hideUI():
	if isHidden:
		isHidden = false	
		colorButtons.visible = true
		sliderContainer.visible = true
		sliderBackground.visible = true
	else:
		isHidden = true
		colorButtons.visible = false
		sliderContainer.visible = false
		sliderBackground.visible = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("hide_ui"):
		hideUI()
	
	if Input.is_action_just_pressed("main_menu"):
		dissapationShader.set_shader_parameter("clear", true)
		get_tree().change_scene_to_file("res://root.tscn")
		
	if Input.is_action_just_pressed("restart"):
		dissapationShader.set_shader_parameter("clear", true)
		get_tree().reload_current_scene()
		dissapationShader.set_shader_parameter("clear", false)
	
		
	var start = Time.get_ticks_msec()
	viewPortTex = $SubViewportContainer/SubViewport.get_texture()
	
	if debugData:
		print("getting texture: " + str(Time.get_ticks_msec() - start))
		
	start = Time.get_ticks_msec()
	viewPortImg = viewPortTex.get_image()
	
	if debugData:
		print("getting image: " + str(Time.get_ticks_msec() - start))
	
	
	start = Time.get_ticks_msec()
	_process_compute()
	if debugData:
		print("process compute: " + str(Time.get_ticks_msec() - start))
		
	start = Time.get_ticks_msec()
	var trailMapData := rd.texture_get_data(trailMapOutBuffer, 0)
	if debugData:
		print("getting new data: " + str(Time.get_ticks_msec() - start))
		
	start = Time.get_ticks_msec()
	img = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, trailMapData)
	if debugData:
		print("getting new image: " + str(Time.get_ticks_msec() - start))
		
	start = Time.get_ticks_msec()
	_updateBuffers()
	if debugData:
		print("updating buffers: " + str(Time.get_ticks_msec() - start))
		
	start = Time.get_ticks_msec()
	tex.update(img)
	if debugData:
		print("updating texture: " + str(Time.get_ticks_msec() - start))
	mat.set_shader_parameter("dataTex", tex)
	mat.set_shader_parameter("dissapation", dissapation)
	if firstStep:
		mat.set_shader_parameter("clear", true)
		firstStep = false
	else:
		mat.set_shader_parameter("clear", false)
		
	var deb = rd.buffer_get_data(groupParamsBuffer).to_float32_array()
	var deb2 = rd.buffer_get_data(actorsXBuffer).to_float32_array()
	pass
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
	
	var groupParams  = PackedFloat32Array(
		[actorSpeeds.x, actorSpeeds.y, actorSpeeds.z, 0.0, sensorDists.x, sensorDists.y, sensorDists.z, 0.0, sensorAngles.x, sensorAngles.y, sensorAngles.z, 0.0, turnSpeeds.x, turnSpeeds.y, turnSpeeds.z, 0.0] 
	).to_byte_array()
	rd.buffer_update(groupParamsBuffer, 0, groupParams.size(), groupParams)
	
	var fmt := RDTextureFormat.new()
	fmt.width = width
	fmt.height = height
	fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	var view := RDTextureView.new()
	rd.free_rid(trailMapBuffer)
	trailMapBuffer = rd.texture_create(fmt, view, [viewPortImg.get_data()])
	var trailMapUniform := RDUniform.new()
	trailMapUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	trailMapUniform.binding = 4
	trailMapUniform.add_id(trailMapBuffer)
	
	
	rd.free_rid(trailMapOutBuffer)
	trailMapOutBuffer = rd.texture_create(fmt, view, [tempImg.get_data()])
	var trailMapOutUniform := RDUniform.new()
	trailMapOutUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	trailMapOutUniform.binding = 5
	trailMapOutUniform.add_id(trailMapOutBuffer)
	
	bindings[3] = paramsUniform
	#bindings[7] = groupParamsUniform
	bindings[4] = trailMapUniform
	bindings[5] = trailMapOutUniform
	uniform_set = rd.uniform_set_create(bindings, shader, 0)

#stupid workaround to not call this on initialization
var firstTime = true

func _update_groups(value):
	if firstTime:
		firstTime = false
		return
	Global.number_of_groups = value
	groupLabel.text = String.num(value, 0)
	var actorGroups = []
	for i in range(numActors):
		actorGroups.append(i % int(value))
	
	var actorsGroupsBuffer_bytes := PackedInt32Array(actorGroups).to_byte_array()
	actorsGroupsBuffer = rd.storage_buffer_create(actorsGroupsBuffer_bytes.size(), actorsGroupsBuffer_bytes)

	var actorGroupsUniform := RDUniform.new()
	actorGroupsUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	actorGroupsUniform.binding = 6
	actorGroupsUniform.add_id(actorsGroupsBuffer)
	bindings[6] = actorGroupsUniform
	uniform_set = rd.uniform_set_create(bindings, shader, 0)

func _on_color_picker_button_color_changed(color):
	Global.firstColor = color
	finalShader.material.set_shader_parameter("firstColor", color)
	
func _on_second_color_picker_color_changed(color):
	Global.secondColor = color
	finalShader.material.set_shader_parameter("secondColor", color)

func _on_third_color_picker_color_changed(color):
	Global.thirdColor = color
	finalShader.material.set_shader_parameter("thirdColor", color)

func _on_sensor_angle_slider_value_changed(value):
	Global.sensorAngle = value
	Global.sensorAngles.x = value
	Global.sensorAngles.y = value * relationMult
	Global.sensorAngles.z = value / relationMult
	sensorAngles.x = value
	sensorAngles.y = value * relationMult
	sensorAngles.z = value / relationMult
	sensorAngle = value
	angleLabel.text = String.num(value, 2)
	
func _on_sensor_distance_slider_value_changed(value):
	Global.sensorDistance = value
	Global.sensorDists.x = value
	Global.sensorDists.y = value * relationMult
	Global.sensorDists.z = value / relationMult
	sensorDists.x = value
	sensorDists.y = value * relationMult
	sensorDists.z = value / relationMult
	sensorDist = value
	distanceLabel.text = String.num(value, 0)
	
func _on_actor_speed_slider_value_changed(value):
	Global.speed_of_actors = value
	Global.actorSpeeds.x = value
	Global.actorSpeeds.y = value * relationMult
	Global.actorSpeeds.z = value / relationMult
	actorSpeeds.x = value
	actorSpeeds.y = value * relationMult
	actorSpeeds.z = value / relationMult
	actorSpeed = value
	speedLabel.text = String.num(value, 0)


func _on_actor_turn_speed_slider_value_changed(value: float) -> void:
	Global.turnSpeed = value
	Global.turnSpeeds.x = value
	Global.turnSpeeds.y = value * relationMult
	Global.turnSpeeds.z = value / relationMult
	turnSpeeds.x = value
	turnSpeeds.y = value * relationMult
	turnSpeeds.z = value / relationMult
	turnSpeed = value
	turnSpeedLabel.text = String.num(value, 2)


func _on_dissapation_slider_value_changed(value: float) -> void:
	Global.dissapation = value
	dissapation = value
	dissapationLabel.text = String.num(value, 2)


func _on_relation_slider_value_changed(value: float) -> void:
	Global.realtionMult = value
	_on_actor_speed_slider_value_changed(Global.speed_of_actors)
	_on_actor_turn_speed_slider_value_changed(Global.turnSpeed)
	_on_sensor_angle_slider_value_changed(Global.sensorAngle)
	_on_sensor_distance_slider_value_changed(Global.sensorDistance)
	relationMult = value
	relationLabel.text = String.num(value, 2)
