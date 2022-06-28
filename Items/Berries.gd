extends Node2D

# Information about item
var interactable = true
var item_name = "berry"
var picked_up = false setget picked_up
var self_offset = Vector2(8, 5)

# Access to nodes
onready var text_label = $Label
onready var Main = get_parent().get_parent()

signal picked_up

func picked_up(value):
	if value:
		emit_signal("picked_up")
		text_label.visible = false
	else:
		text_label.visible = true
	var grid_pos = Main.Grass.world_to_map(global_position)
	var text = str(len(Main.world_layers["resources"][grid_pos.y][grid_pos.x])) 
	for berry in Main.world_layers["resources"][grid_pos.y][grid_pos.x]:
		berry.text_label.text = text
	picked_up = value


