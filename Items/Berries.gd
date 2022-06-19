extends Sprite

# Information about item
var interactable = true
var item_name = "berry"
var picked_up = false setget picked_up

# Access to nodes
onready var text_label = $Label
onready var Main = get_parent()

signal picked_up

func picked_up(value):
	if value:
		emit_signal("picked_up")
		text_label.visible = false
	else:
		text_label.visible = true
	var grid_pos = Main.Grass.world_to_map(global_position)
	text_label.text = str(len(Main.world_layers["resources"][grid_pos.y][grid_pos.x])) 
	picked_up = value


