extends Node3D


const RADIUS = 1
const FLOAT = 4.5
const GRAVE_DEPTH = 8.5
const RISE_TIME = 3.7664
const RISE_FLICKER = 0.25
const HP : int = 500
const REVOLVER_HEAL = 3
var alive = true
var rising = false
var health : int = HP
var pain_col = 0.0
var rising_timer = 0.0
var active_zone : Area3D
var has_died = false

const gibs = preload("res://scenes/environment/gibs/angel.tscn")
const blood = preload("res://scenes/environment/blood_particles.tscn")
const angel_mat = preload("res://resources/materials/specific_mats/angel_explosion.tres")
@onready var player = get_tree().get_first_node_in_group("player")
@onready var mesh = $mesh
@onready var health_label = $mesh/health
@onready var key = $mesh/key
@onready var ray = $ray
@onready var home = $home
@onready var mesh_body = $mesh/body/Armature/Skeleton3D/runner_body
@onready var left_wing = $mesh/left_wing
@onready var right_wing = $mesh/right_wing
@onready var halo = $mesh/halo
@onready var dist_from_player = Vector2(player.position.x, player.position.z).distance_to(Vector2(position.x, position.z))
@onready var respawn = $respawn
@onready var raycast_area = $raycast_collision
@onready var raycast_hitbox = $raycast_collision/raycast_hitbox


@export_range(0, 4) var min_dif : int = 0
@export var respawn_time = 10

var disable_particles : bool = false
var disable_gibs : bool = false


var zombies = []
var beams = []
var drops = []


func update_beam(i):
	var beam_mesh = beams[i]
	if not alive or rising or zombies[i].rising or not zombies[i].alive:
		beam_mesh.visible = 0
		return
	var from = mesh_body.global_position
	var to = zombies[i].mesh.global_position + Vector3(0, 0.25, 0)
	beam_mesh.visible = 1
	beam_mesh.position = (from + to) / 2
	var dir = to - from
	beam_mesh.global_rotation.y = -atan2(dir.z, dir.x) + PI / 2
	beam_mesh.global_rotation.x = -atan2(dir.y, Vector2(dir.z, dir.x).length()) + PI / 2
	beam_mesh.scale.y = from.distance_to(to)


func update_healthbar():
	health_label.text = str(health)


func add_particles(edmg):
	if disable_particles:
		return
	var new_blood = blood.instantiate()
	if edmg < health:
		new_blood.dir = (position - player.position).rotated(Vector3.UP, (2 * (randi() % 2) - 1) * (PI / 2 + randf_range(-PI/3, PI/3))) + Vector3(0, 0.5, 0)
	else:
		new_blood.spread = 180
	new_blood.speed = clamp(edmg / 8, 1, 10)
	new_blood.color = Color(1, 1, 0)
	new_blood.size = 0.15
	add_child(new_blood)
	new_blood.position = position + Vector3(0, 0.25, 0) + new_blood.dir.normalized() * 0.25
	new_blood.amount = clamp(edmg / 1.5, 5, 75)


func add_gibs():
	if disable_gibs or get_tree().current_scene == null:
		return
	var new_gibs = gibs.instantiate()
	new_gibs.position = position + Vector3(0, 1.5, 0)
	get_tree().current_scene.add_child(new_gibs)


func rising_func(t):
	return (1 - 1 / (10 * t + 1)) * 1.1


func pain(dmg, noblood=false, heal_player = false):
	if rising or not alive or health <= 0:
		return
	
	if dmg >= health:
		add_gibs()
	
	if not noblood:
		add_particles(dmg)
		pain_col = 1.0
	
	health -= dmg
	update_healthbar()
	if heal_player:
		player.health = player.health + REVOLVER_HEAL


func _body_entered(body):
	if body == self or not body.is_in_group("enemy") or body.is_in_group("unhealable") or body.get_parent().is_in_group("enemy"):
		return
	print("body entered")
	zombies.push_back(body)
	var beam = MeshInstance3D.new()
	beam.mesh = CylinderMesh.new()
	beam.mesh.material = angel_mat
	beam.mesh.height = 1
	beam.mesh.rings = 1
	beam.mesh.radial_segments = 10
	beam.mesh.bottom_radius = 0.05
	beam.mesh.top_radius = 0.05
	add_child(beam)
	beam.top_level = 1
	beams.push_back(beam)
	update_beam(beams.size() - 1)


func _body_exited(body):
	if body == self or not body.is_in_group("enemy") or body.is_in_group("unhealable") or body.get_parent().is_in_group("enemy"):
		return
	print("body exited")
	zombies.erase(body)
	beams[beams.size() - 1].queue_free()
	beams.pop_back()


func _ready():
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	disable_particles = config.get_value("video", "disable_particles", false)
	disable_gibs = config.get_value("video", "disable_gibs", false)
	var diff = config.get_value("gameplay", "difficulty", 2)
	
	for c in get_children():
		if c.is_in_group("drop"):
			drops.push_back(c)
			remove_child(c)
			key.visible = 1
	
	if diff < min_dif and drops.is_empty():
		queue_free()
	
	visible = true
	
	#determine at what height to put the enemy home
	ray.target_position = Vector3(0, -100, 0)
	var max_height = -1000000
	const CHECKS = 4
	for i in range(CHECKS):
		var pos = Vector2.RIGHT.rotated(2 * PI * i / CHECKS) * RADIUS
		ray.position = Vector3(pos.x, ray.position.y, pos.y)
		ray.force_raycast_update()
		if ray.is_colliding():
			var col = ray.get_collision_point().y
			if col > max_height:
				max_height = col
	home.global_position.y = max_height
	ray.position = Vector3(0, ray.position.y, 0)
	ray.force_raycast_update()
	if ray.is_colliding():
		global_position.y = ray.get_collision_point().y + FLOAT
	
	#determine active zone
	for c in get_children():
		if c is Area3D and not c.is_in_group("drop"):
			c.set_collision_mask_value(9, 1)
			active_zone = c
			break
	
	active_zone.set_collision_layer_value(1, false)
	active_zone.set_collision_mask_value(1, false)
	active_zone.set_collision_mask_value(2, true)
	active_zone.connect("body_entered", _body_entered)
	active_zone.connect("body_exited", _body_exited)


func ai():
	if health <= 0 and alive:
		home.time_left = respawn_time
		alive = 0
		if not has_died:
			has_died = 1
			key.visible = 0
			for c in drops:
				add_child(c)
				c.top_level = 1
				c.global_position = global_position + Vector3(0, -FLOAT + 1, 0)
		respawn.start()
		position = home.position
		position.y -= GRAVE_DEPTH
		for i in range(beams.size()):
			update_beam(i)
	
	if not alive or rising:
		return
	
	var dir2player = player.global_position - global_position
	var dir2player2D = Vector2(dir2player.x, dir2player.z).normalized()
	raycast_area.rotation.y = -atan2(dir2player2D.y, dir2player2D.x) + PI / 2
	raycast_hitbox.disabled = rising or not alive


func _physics_process(_delta):
	if not alive or rising:
		return
	for i in zombies:
		if i.health > 0 and i.health < i.HP:
			i.health = i.health + 1
			i.update_healthbar()


func _process(delta):
	ai()
	
	dist_from_player = Vector2(player.position.x, player.position.z).distance_to(Vector2(position.x, position.z))
	home.cross.visible = not alive
	
	if pain_col > 0.0 or dist_from_player < player.SHOTGUN_PB_RANGE:
		pain_col = max(0, pain_col - delta * 2)
		const FADE_RANGE = 1
		var pb_col = clamp(lerp(0.0, 1.0, (player.SHOTGUN_PB_RANGE - dist_from_player) / FADE_RANGE) ,0.0, 1.0)
		var col = max(pain_col, pb_col) * 0.5
		mesh_body.set_instance_shader_parameter("pain", col)
		left_wing.set_instance_shader_parameter("pain", col)
		right_wing.set_instance_shader_parameter("pain", col)
		halo.set_instance_shader_parameter("pain", col)
	
	mesh.visible = (alive and not rising) or (rising and int(rising_timer / RISE_FLICKER) % 2 == 1)
	
	
	if rising and rising_timer < RISE_TIME:
		rising_timer += delta
		position.y = rising_func(rising_timer / RISE_TIME) * (FLOAT + GRAVE_DEPTH) + home.position.y - GRAVE_DEPTH
	else:
		rising = 0
	
	if not alive or rising:
		return
	
	for i in range(beams.size()):
		update_beam(i)
	


func _on_respawn_timeout():
	health = HP
	update_healthbar()
	alive = 1
	rising = 1
	rising_timer = 0
