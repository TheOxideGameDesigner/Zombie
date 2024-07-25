extends Area3D


var SPEED : float = 30.0
const DAMAGE : int = 30

const EXPLOSION_TIME : float = 1
const EXPLOSION_RADIUS : float = 6

@onready var player = get_tree().get_first_node_in_group("player")
var death_message : String = "You were killed by a fireball"
var vel : Vector3 = Vector3.ZERO
var velv : float = 0

var timer : float = 0.0
var exploded : bool = 0
var hit_player : bool = 0

var time_since_birth : float = 0

@onready var sprite = $sprite
@onready var explosion = $explosion

func set_vel(new_vel : Vector3) -> void:
	vel = new_vel.normalized() * SPEED


func _process(delta : float) -> void:
	if exploded and not hit_player:
		if timer > EXPLOSION_TIME:
			queue_free()
		timer += delta
		explosion.mesh.material.albedo_color.a = pow(1 - timer / EXPLOSION_TIME, 2)
		explosion.scale = Vector3.ONE * EXPLOSION_RADIUS * timer / EXPLOSION_TIME
	
	if exploded:
		return
	time_since_birth += delta


func _physics_process(delta : float) -> void:
	if exploded:
		return
	vel = vel.normalized()
	global_position += vel * delta * SPEED


func physics(body : PhysicsBody3D = null) -> void:
	if body != null and body.is_in_group("physics"):
		body.apply_central_impulse(5 * vel)
	for obj in get_tree().get_nodes_in_group("physics"):
		if obj == body:
			continue
		var dist : float = obj.global_position.distance_to(global_position)
		if dist < 7.5:
			obj.apply_central_impulse(10 * (obj.global_position - global_position).normalized() / (1 + dist / 3))


func _on_body_entered(body : PhysicsBody3D) -> void:
	if body == get_parent() or exploded:
		return
	exploded = 1
	physics(body)
	explosion.visible = 1
	sprite.queue_free()
	$hitbox.queue_free()
	$death_timer.queue_free()
	if body.is_in_group("player"):
		body.pain(death_message, DAMAGE)
		body.knockback(vel.normalized() * 10 + Vector3(0, 0.2, 0))
		$explosion.queue_free()
		hit_player = 1



func _on_death_timer_timeout() -> void:
	if exploded:
		return
	exploded = 1
	physics()
	explosion.visible = 1
	sprite.queue_free()
	$hitbox.queue_free()
