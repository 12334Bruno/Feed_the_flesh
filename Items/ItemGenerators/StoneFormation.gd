extends AnimatedSprite

# Obejct info
var item_name = "stone_formation"
var resource_name = "stone"
onready var resource = preload("res://Items/Stone.tscn")
onready var Main = get_parent()
var interactable = true
export var time_to_harvest : float = 0.5
var uses = 5 setget set_uses

func set_uses(value):
	print(value)
	if value == 0:
		var grid_pos = Main.Grass.world_to_map(global_position)
		Main.world_layers["resource_makers"][grid_pos.y][grid_pos.x].erase(self)
		queue_free()
	if value > 0:
		uses = value


