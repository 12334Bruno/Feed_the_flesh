extends TextureProgress

onready var tween = $Tween

var thresholds = [10,20,30,50,100,200,300,500,1000,2000]
var threshold = thresholds[0]
var current = 0


export(Color) var state0 = Color.white
export(Color) var state1 = Color.yellow
export(Color) var state2 = Color.orange
export(Color) var filled = Color.red
var filled_zone = 1
var state0_zone = 0
var state1_zone = 0.33
var state2_zone = 0.66

func _ready():
	update_bar()

func update_bar(amount=0):
	current += amount
	var new_value = 100*(float(current)/float(threshold))
	tween.interpolate_property(self, "value", value, new_value, 0.3, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	assign_color()
	
func assign_color():
	var val = float(current)/float(threshold)
	if val >= 1:
		tint_progress = filled
	elif val >= state2_zone:
		tint_progress = state2
	elif val >= state1_zone:
		tint_progress = state1
	elif val >= state0_zone:
		tint_progress = state0
	
	
