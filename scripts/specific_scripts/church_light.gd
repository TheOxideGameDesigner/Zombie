extends DirectionalLight3D

@export var statue : Node = null

func _process(delta):
	visible = not statue.alive or statue.undisturbed
