extends Node2D

@export var width : int = 320
@export var height : int = 180
@export var actorSpeed = 0.8
@export var numActors : int = 250
@export var sensorDist : float = 6
@export var sensorAngle : float = 0.7
@export var turnSpeed = 0.3
var img
var texture
var emptyData = []
var viewPortData = []
var data = []
var actors = []
var tex
var viewPortTex
var viewPortImg
var mat
@export var radius = 10
@export var simulate : bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mat = $SubViewportContainer/SubViewport/TextureRect.material
	for y in range(height * width):
			emptyData.append(0.0)
	for i in range(numActors):
		var dir = Vector2(0, 0)
		randomize()
		var idX = randi_range(0, 1)
		randomize()
		var idY = randi_range(0, 1)
		randomize()
		dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		
		var pos = Vector2(randf_range(width/2 - radius, width/2 + radius), randf_range(height/2 - radius, height/2 + radius))
		actors.append({
			"pos" : pos,
			"dir" : dir
		})
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	viewPortTex = $SubViewportContainer/SubViewport.get_texture()
	viewPortImg = viewPortTex.get_image()
	viewPortImg.resize(width, height, 0)
	viewPortImg.convert(Image.FORMAT_R8)
	viewPortData = viewPortImg.get_data()

	data = emptyData.duplicate(true)
	data = PackedByteArray(data)
	for actor in actors:
		
		if simulate:
			actor["dir"] = updateActorDir(actor["pos"], actor["dir"], viewPortData)

		
		actor["pos"].x += actor["dir"].x * actorSpeed
		actor["pos"].y += actor["dir"].y * actorSpeed
		if actor["pos"].x >= width-10 or actor["pos"].x < 10:
			actor["dir"].x = -actor["dir"].x
		if actor["pos"].y >= height-10 or actor["pos"].y < 10:
			actor["dir"].y = -actor["dir"].y
		var actorId = round(actor["pos"].y)*width + round(actor["pos"].x)
		
		data[actorId] = 255.0
		
	img = Image.create_from_data(width, height, false, Image.FORMAT_R8, data)
	img.resize(1152, 648, 0)
	tex = ImageTexture.create_from_image(img)
	mat.set_shader_parameter("dataTex", tex)
	#$SubViewportContainer/SubViewport/TextureRect.texture = tex
func updateActorDir(pos, dir, data):

	var forwardSensor = pos + (Vector2(sensorDist, 0)).rotated(dir.angle())
	var leftSensor = pos + (Vector2(sensorDist, 0)).rotated(dir.angle() + sensorAngle)
	var rightSensor = pos + (Vector2(sensorDist, 0)).rotated(dir.angle() - sensorAngle)
	var newDir = dir
	var forwardId = round(forwardSensor.y) * width + round(forwardSensor.x)
	var leftId = round(leftSensor.y) * width + round(leftSensor.x)
	var rightId = round(rightSensor.y) * width + round(rightSensor.x)
	var forward = data[forwardId]
	var forwardLeft = data[leftId]
	var forwardRight = data[rightId]
	
	
	if forward < forwardLeft and forward < forwardRight:
		if randf() < 0.5:
			newDir = dir.rotated(turnSpeed)
		else:
			newDir = dir.rotated(-turnSpeed)
	elif forwardLeft < forwardRight:
		newDir = dir.rotated(-turnSpeed)
	elif forwardRight < forwardLeft:
		newDir = dir.rotated(turnSpeed)
	return newDir.normalized()
