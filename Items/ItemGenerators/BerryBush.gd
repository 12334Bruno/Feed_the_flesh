extends AnimatedSprite

# Obejct info
var item_name = "berry_bush"
var resource_name = "berry"
onready var resource = preload("res://Items/Berries.tscn")
onready var Main = get_parent()
var interactable = true
export var time_to_harvest : float = 0.5
var uses = -1 setget set_uses # Setting uses to -1 equals to infinte uses

func set_uses(value):
	if uses == 0:
		var grid_pos = Main.Grass.world_to_map(global_position)
		Main.world_layers["resource_makers"][grid_pos.y][grid_pos.x].erase(self)
		queue_free()
	if value > 0:
		uses = value
