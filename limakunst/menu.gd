extends Control

@onready var displayed_number_of_actors_group = $MarginContainer/VBoxContainer/InteractableContainer/Sliders/SliderLabelsDisplayed/DisplayedNumberOfActorsGroup
@onready var displayed_number_of_groups = $MarginContainer/VBoxContainer/InteractableContainer/Sliders/SliderLabelsDisplayed/DisplayedNumberOfGroups


func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://slimulation.tscn")
	

func _on_quit_button_pressed():
	get_tree().quit()

# Updates the value of the slider label, when slider is moved
func _on_slider_actors_in_groups_value_changed(value):
	displayed_number_of_actors_group.text = String.num(value, 0)

func _on_slider_groups_value_changed(value):
	displayed_number_of_groups.text = String.num(value, 0)


func _on_ready():
	pass
