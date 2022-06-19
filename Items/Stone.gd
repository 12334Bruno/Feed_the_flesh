extends Sprite

# Information about item
var interactable = true
var item_name = "stone"
var picked_up = false setget picked_up

signal picked_up

func picked_up(value):
	emit_signal("picked_up")
