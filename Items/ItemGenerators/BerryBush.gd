extends Node2D

# Load scenes
onready var resource = preload("res://Items/Berry.tscn")
onready var timer = $Timer
onready var visual = $Visual
onready var Main = get_parent().get_parent()

# General obejct info
var item_name = "berry_bush"
var resource_name = "berry"
var self_offset = Vector2(8, 12)
var interactable = true

# Specific object info
export var time_to_harvest : float = 0.5
var uses = -1 setget set_uses # Setting uses to -1 equals to infinte uses
var can_harvest = false


func set_uses(value):
	if uses == 0:
		var grid_pos = Main.Grass.world_to_map(global_position)
		Main.world_layers["resource_makers"][grid_pos.y][grid_pos.x].erase(self)
		queue_free()
	if value > 0 or value < 0:
		timer.start()
		visual.set_frame(0)
		can_harvest = false
		interactable = false
		uses = value


func _on_Timer_timeout():
	timer.stop()
	visual.set_frame(1)
	interactable = true
	can_harvest = true
