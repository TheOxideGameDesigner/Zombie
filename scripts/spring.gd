extends Area3D

@export var boost = 12.5
@onready var up_dir = transform.basis.y
@onready var spring_spring = $spring_spring
@onready var spring_platform = $spring_platform
@onready var init_spring_height = spring_spring.position.y
const SPRING_HEIGHT = 0.72

const ANIM_SPEED = 2
var anim_timer = 1000

func anim_func(x : float) -> float:
	var wx = 4 * (x + 0.785)
	return 4.3 * sin(wx) / (wx * wx)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	anim_timer = anim_timer + delta * ANIM_SPEED
	var anim_val = anim_func(anim_timer) * 4 + 1
	spring_platform.position.y = SPRING_HEIGHT * anim_val + init_spring_height
	spring_spring.scale.y = anim_val


func _on_body_entered(body):
	if body.is_in_group("player"):
		anim_timer = 0.0
		body.can_jump = 1
		var vn = body.velocity.project(up_dir)
		if vn.is_zero_approx():
			body.velocity += up_dir * boost
			return
		if vn.dot(up_dir) < 0:
			body.velocity = body.velocity - vn
		else:
			vn = -vn
		vn = vn.normalized() * max(boost, vn.length())
		body.velocity -= vn
