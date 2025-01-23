extends Node

var number_of_actors_in_groups = 100
var number_of_groups = 1
var speed_of_actors = 1
var sensorAngle = 0
var sensorDistance = 1
var turnSpeed = 0.3
var dissapation = 0.01
var realtionMult = 2.0

var actorSpeeds = Vector3(2, 2, 2)
var sensorDists = Vector3(8, 8, 8)
var sensorAngles = Vector3(0.3, 0.3, 0.3)
var turnSpeeds = Vector3(0.3, 0.3, 0.3)

var firstColor = Color(1.0, 0.0, 0.0, 1.0)
var secondColor = Color(0.0, 1.0, 0.0, 1.0)
var thirdColor = Color(0.0, 0.0, 1.0, 1.0)
var bgColor = Color(0.0, 0.0, 0.0, 1.0)
