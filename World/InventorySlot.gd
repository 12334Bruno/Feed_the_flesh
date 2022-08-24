extends TextureRect

onready var slot = $TextureRect
var item = null setget set_item


func set_item(value):
	if value != null:
		item = value
		slot.texture = item.get_node("Visual").texture
	else:
		slot.texture = null
		item = value
	
	
