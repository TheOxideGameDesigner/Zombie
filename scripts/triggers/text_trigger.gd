extends Node3D


const DECAY = 2

@onready var label = $text

@export_multiline var text : String = ""
@export var time_on_screen : float = 5
@export var size : float = 1.0
@export var delay : float = 0.0
@export var low_priority : bool = 0

@export var col : Color = Color(1, 1, 1, 0.8)


var timer : float = 0
var delay_timer : float = 0.0
var inside : bool = 0
var entered : bool = 0
var just_entered : bool = 0

var target_objs = []

func update_text() -> void:
	label.text = text
	var format_dict = {}
	for i in InputMap.get_actions():
		var events = InputMap.action_get_events(i)
		if events.is_empty():
			continue
		var event = events[0]
		var evstr = "UNKNOWN"
		if event is InputEventKey:
			evstr = event.as_text_keycode()
		elif event is InputEventMouseButton:
			evstr = event.as_text()
		format_dict[i] = evstr
	label.text = label.text.format(format_dict)
	label.scale = Vector2.ONE * size
	label.modulate = col

func _ready() -> void:
	update_text()


func _process(delta : float) -> void:
	if inside and not entered:
		var ok : bool = 1
		if low_priority:
			for n in get_tree().get_nodes_in_group("text_trigger"):
				if n.label.visible and n != self:
					ok = 0
					break
		if ok or not low_priority:
			entered = 1
	if not entered:
		return
	if delay_timer < delay:
		delay_timer += delta
		return
	label.visible = 1
	if not just_entered:
		timer = DECAY + time_on_screen
		if not low_priority:
			for n in get_tree().get_nodes_in_group("text_trigger"):
				if n.label.visible and n != self:
					n.queue_free()
		label.modulate.a = col.a
		just_entered = 1
	if timer == 0:
		queue_free()
	timer = max(0, timer - delta)
	if timer < DECAY:
		label.modulate.a -= delta / DECAY
