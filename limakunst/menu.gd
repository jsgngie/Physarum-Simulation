extends Control

@onready var displayed_number_of_actors_group = $Controls/LeftSide/Count/actorCountLabelDisplay
@onready var displayed_number_of_groups = $Controls/LeftSide/Group/actorGroupLabelDisplay
@onready var displayed_speed_of_actors = $Controls/LeftSide/Speed/actorSpeedLabelDisplay
@onready var displayed_sensor_distance = $"Controls/LeftSide/Sensor distance/sensorDistanceLabelDisplayed"
@onready var displayed_sensor_angle = $"Controls/LeftSide/Sensor angle/sensorAngleLabelDisplayed"
@onready var displayed_turnSpeed = $Controls/LeftSide/TurnSpeed/actorTurnSpeedLabelDisplay

#click backgrounds for focus
@onready var firstBack = $ColorPickerContainer/VBoxContainer/actorColors/firstBack
@onready var secondBack = $ColorPickerContainer/VBoxContainer/actorColors/secondBack
@onready var thirdBack = $ColorPickerContainer/VBoxContainer/actorColors/thirdBack

@onready var firstColor = $ColorPickerContainer/VBoxContainer/actorColors/firstBack/firstActorColor
@onready var secondColor = $ColorPickerContainer/VBoxContainer/actorColors/secondBack/secondActorColor
@onready var thirdColor = $ColorPickerContainer/VBoxContainer/actorColors/thirdBack/thirdActorColor

var currentlyFocusedBack = firstBack
var currentlyFocusedColor = firstColor

func _on_start_button_pressed():
	Global.firstColor = firstColor.color
	Global.secondColor = secondColor.color
	Global.thirdColor = thirdColor.color

	get_tree().change_scene_to_file("res://slimulationGPU.tscn")
	
func _on_quit_button_pressed():
	get_tree().quit()

# Updates the value of the slider label, when slider is moved
func _on_slider_actors_in_groups_value_changed(value):
	Global.number_of_actors_in_groups = value
	displayed_number_of_actors_group.text = String.num(value, 0)

func _on_slider_groups_value_changed(value):
	Global.number_of_groups = value
	displayed_number_of_groups.text = String.num(value, 0)

func _on_speed_actors_value_changed(value):
	Global.speed_of_actors = value
	displayed_speed_of_actors.text = String.num(value, 0)
	
	
func _on_sensor_distance_value_changed(value):
	Global.sensorDistance = value
	displayed_sensor_distance.text = String.num(value, 0)
	
func _on_sensor_angle_value_changed(value):
	Global.sensorAngle = value
	displayed_sensor_angle.text = String.num(value, 2)

func changeToFocus(back, color):
	if currentlyFocusedBack:
		currentlyFocusedBack.color = Color(0.248, 0.248, 0.248)
	
	if back:
		currentlyFocusedBack = back
		currentlyFocusedColor = color
		back.color = Color(0.161, 0.161, 0.161)
		
# Handles the color selectors
func _on_first_actor_color_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			changeToFocus(firstBack, firstColor)

func _on_second_actor_color_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			changeToFocus(secondBack, secondColor)


func _on_third_actor_color_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			changeToFocus(thirdBack, thirdColor)


func _on_color_picker_color_changed(color):
	if currentlyFocusedColor:
		currentlyFocusedColor.color = color
	


func _on_actor_turn_speed_slider_value_changed(value: float) -> void:
	Global.turnSpeed = value
	displayed_turnSpeed.text = String.num(value, 2)
