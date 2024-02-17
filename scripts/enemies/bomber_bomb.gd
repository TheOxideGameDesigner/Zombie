extends StaticBody3D


var HVEL = 15.0
const GR_ACCEL = 9.8
const DAMAGE = 30
const SPLASH_RADIUS = 5.0

const EXPLOSION_TIME = 0.5
const EXPLOSION_RADIUS = 8
const FLICKER_TIME = 1.0
const FLICKER_FREQ = 10

var player
@onready var start_pos : Vector3 = global_position
var target_pos : Vector3
@onready var hdir : Vector3 = Vector3(target_pos.x - start_pos.x, 0, target_pos.z - start_pos.z).normalized()
@onready var roll_axis = hdir.rotated(Vector3.UP, PI / 2)
var vvel = 0.0

var timer = 0.0
var touched_surface : bool = 0
var exploded : bool = 0

var hit_player = 0
@onready var sprite = $sprite
@onready var explosion = $explosion
@onready var death_timer = $death_timer

@onready var shaded_material = preload("res://resources/materials/level_mat.tres")
@onready var unshaded_material = preload("res://resources/materials/level_unshaded_mat.tres")

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
	if not hit_player and death_timer.time_left < FLICKER_TIME:
		var flicker = int(FLICKER_FREQ * (death_timer.time_left) / FLICKER_TIME) % 2
		if flicker:
			sprite.material_override = unshaded_material
		else:
			sprite.material_override = shaded_material
	if not touched_surface:
		sprite.rotate(roll_axis, delta * 2 * PI)


func _physics_process(delta):
	if touched_surface:
		return
	vvel -= GR_ACCEL * delta
	var movement = HVEL * delta * hdir
	movement.y += vvel * delta
	move_and_collide(movement)


func _on_body_entered(body):
	if body == player:
		hit_player = 1
		explosion.queue_free()
		sprite.queue_free()
		$hitbox.queue_free()
		death_timer.queue_free()
		$touch_area.queue_free()
		player.pain(DAMAGE)
		if touched_surface:
			player.knockback((player.position - position).normalized() * 10)
		else:
			player.knockback(hdir * 10 + Vector3(0, 0.2, 0))
	if body.is_in_group("enemy") or (not body.get_collision_layer_value(1) and not body.get_collision_layer_value(9)) or touched_surface:
		return
	touched_surface = 1



func _on_death_timer_timeout():
	if exploded:
		return
	exploded = 1
	explosion.visible = 1
	sprite.queue_free()
	$hitbox.queue_free()
	death_timer.queue_free()
	$touch_area.queue_free()
	var dist = (player.position + Vector3(0, 0.5, 0)).distance_to(global_position)
	if dist < SPLASH_RADIUS:
		var effect = lerp(1.0, 0.0, dist / SPLASH_RADIUS)
		player.knockback((player.position - position).normalized() * 10 * effect)
		player.pain(DAMAGE * effect)
