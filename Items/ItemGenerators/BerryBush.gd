extends AnimatedSprite

# Obejct info
var item_name = "berry_bush"
var resource_name = "berry"
onready var resource = preload("res://Items/Berries.tscn")
var interactable = true
export var time_to_harvest : float = 1

