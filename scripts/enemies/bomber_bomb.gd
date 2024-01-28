extends StaticBody3D


const HVEL = 15.0
const GR_ACCEL = 9.8
const DAMAGE = 30
const SPLASH_RADIUS = 3.0

const EXPLOSION_TIME = 1
const EXPLOSION_RADIUS = 6

var player
@onready var start_pos : Vector3 = global_position
@onready var target_pos : Vector3 = player.global_position + Vector3(0, 0.5, 0)
@onready var hdir : Vector3 = Vector3(target_pos.x - start_pos.x, 0, target_pos.z - start_pos.z).normalized()
var vvel = 0.0

var timer = 0.0
var touched_surface : bool = 0
var exploded : bool = 0

var time_since_birth = 0

var hit_player = 0
@onready var sprite = $sprite
@onready var explosion = $explosion

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


func _physics_process(delta):
	if touched_surface:
		return
	vvel -= GR_ACCEL * delta
	var movement = HVEL * delta * hdir
	movement.y += vvel * delta
	move_and_collide(movement)


func _on_body_entered(body):
	if body == player:
		explosion.queue_free()
		sprite.queue_free()
		$hitbox.queue_free()
		$death_timer.queue_free()
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
	$touch_area.queue_free()
