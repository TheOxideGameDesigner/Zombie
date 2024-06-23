extends StaticBody3D


var HVEL = 15.0
const GR_ACCEL = 9.8
const DAMAGE = 30
const SPLASH_RADIUS = 5.0
const EXPLOSION_TIME = 0.5
const EXPLOSION_RADIUS = 8
const FLICKER_TIME = 1.0
const FLICKER_FREQ = 10

var target
var death_message = "You were killed by a bomb"
@onready var start_pos : Vector3 = global_position
var target_pos : Vector3
@onready var hdir : Vector3 = Vector3(target_pos.x - start_pos.x, 0, target_pos.z - start_pos.z).normalized()
@onready var roll_axis = hdir.rotated(Vector3.UP, PI / 2).normalized()
@onready var touch_area = $touch_area

var vvel = 0.0

var timer = 0.0
var touched_surface : bool = 0
var exploded : bool = 0

var hit_target = 0
@onready var sprite = $sprite
@onready var explosion = $explosion
@onready var death_timer = $death_timer

@onready var shaded_material = preload("res://resources/materials/level_mat.tres")
@onready var unshaded_material = preload("res://resources/materials/level_unshaded_mat.tres")


func physics():
	for obj in get_tree().get_nodes_in_group("physics"):
		var dist = obj.global_position.distance_to(global_position)
		if dist < 7.5:
			obj.apply_central_impulse(15 * (obj.global_position - position).normalized() / (1 + dist / 3))


func _ready():
	var tf = Vector3(target_pos.x - start_pos.x, 0, target_pos.z - start_pos.z).length() / HVEL
	vvel = (target_pos.y - start_pos.y + tf * tf * GR_ACCEL / 2) / tf

func _process(delta):
	if exploded:
		if timer > EXPLOSION_TIME:
			queue_free()
		timer += delta
		explosion.mesh.material.albedo_color.a = pow(1 - timer / EXPLOSION_TIME, 2)
		explosion.scale = Vector3.ONE * EXPLOSION_RADIUS * timer / EXPLOSION_TIME
		return
	if not hit_target and death_timer.time_left < FLICKER_TIME:
		var flicker = int(FLICKER_FREQ * (death_timer.time_left) / FLICKER_TIME) % 2
		if flicker:
			sprite.material_override = unshaded_material
		else:
			sprite.material_override = shaded_material
	if not touched_surface and not hit_target:
		sprite.rotate(roll_axis.normalized(), delta * 2 * PI)


func _physics_process(delta):
	if touched_surface:
		return
	vvel -= GR_ACCEL * delta
	var movement = HVEL * delta * hdir
	movement.y += vvel * delta
	move_and_collide(movement)


func _on_body_entered(body):
	if exploded or hit_target:
		return
	if body.is_in_group("player") or body.is_in_group("enemy"):
		hit_target = 1
		physics()
		explosion.queue_free()
		sprite.queue_free()
		$hitbox.queue_free()
		death_timer.queue_free()
		$touch_area.queue_free()
		if body.is_in_group("player"):
			body.pain(death_message, DAMAGE)
		else:
			body.pain(DAMAGE)
		var kb
		if touched_surface:
			kb = (body.position - position).normalized() * 10
		else:
			kb = hdir * 10 + Vector3(0, 0.2, 0)
		if body.is_in_group("player"):
			body.knockback(kb)
		elif body.is_in_group("lightweight"):
			body.add_vel = kb
	if body.is_in_group("enemy") or body.is_in_group("player") or touched_surface:
		return
	touched_surface = 1



func _on_death_timer_timeout():
	if exploded or hit_target:
		return
	exploded = 1
	physics()
	explosion.visible = 1
	sprite.queue_free()
	$hitbox.queue_free()
	death_timer.queue_free()
	$touch_area.queue_free()
	var dist = (target.position + Vector3(0, 0.5, 0)).distance_to(global_position)
	if dist < SPLASH_RADIUS:
		var effect = lerp(1.0, 0.0, dist / SPLASH_RADIUS)
		if target.is_in_group("player"):
			target.knockback((target.position - position).normalized() * 10 * effect)
			target.pain(death_message, DAMAGE * effect)
		else:
			target.pain(DAMAGE * effect)
			if target.is_in_group("lightweight"):
				target.add_vel = (target.position - position).normalized() * 10 * effect
