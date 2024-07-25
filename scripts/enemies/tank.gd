extends StaticBody3D


var velocity : Vector3 = Vector3.ZERO
var active_zone : Area3D
@onready var body = $body
@onready var head = $head
@onready var player = get_tree().get_first_node_in_group("player")
@onready var home = $home
@onready var respawn = $respawn
@onready var health_label = $health
@onready var key = $key
@onready var hitbox = $hitbox
@onready var ray = $ray
@onready var fire_timer = $fire_timer

var runner_scene = preload("res://scenes/props/enemies/runner.tscn")
var gunner_scene = preload("res://scenes/props/enemies/gunner.tscn")
var hitscanner_scene = preload("res://scenes/props/enemies/hitscanner.tscn")
var chaingunner_scene = preload("res://scenes/props/enemies/chaingunner.tscn")
var mage_scene = preload("res://scenes/props/enemies/mage.tscn")
var bomber_scene = preload("res://scenes/props/enemies/bomber.tscn")
var phantom_scene = preload("res://scenes/props/enemies/phantom.tscn")
var goliath_scene = preload("res://scenes/props/enemies/goliath.tscn")
var phantom_goliath_scene = preload("res://scenes/props/enemies/phantom_goliath.tscn")
@export var aura_col : Color = Color(1, 0, 0.64)
var aura_mat = preload("res://resources/materials/aura_mat.tres").duplicate()
var bomb_scene = preload("res://scenes/props/enemies/bomber_bomb.tscn")
@export var gibs : PackedScene

# x = type, y = ang, z = dist
@export var respawn_time : float = 20
@export var spawn_height : float = 0
@export var spawns : Array[PackedVector3Array]
@export var min_difs : Array[PackedInt32Array]

@onready var hp : int = spawns.size()
@onready var health : int = hp
var alive : bool = 1
var rising : bool = 0
var has_died : bool = 0
var rising_timer : float = 0
var fight_started : bool = 0
var current_wave : int = 0

const RADIUS : float = 1
const TURN_SPEED : float = PI / 10

const GRAVE_DEPTH : float = 4
const RISE_FLICKER : float = 0.25
const RISE_TIME : float = 3.7664
const COLOR : Color = Color(1.0, 1.0, 1.0)
const HURT_COLOR : Color = Color(1, 0, 0)
var hurt_timer : float = 0

var drops = []
var servants = []
var servant_beams = []
var servants_unkilled = []

var disable_gibs : bool = false

var diff : int
var is_opengl : bool = ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility"


func update_beam(i : int) -> void:
	var beam_mesh = servant_beams[i]
	servants[i].aura.visible = not servants[i].rising and servants_unkilled[i]
	if servants[i].rising or not servants[i].alive:
		beam_mesh.visible = 0
		return
	var from : Vector3 = global_position + Vector3(0, 2, 0)
	var to : Vector3 = servants[i].mesh.global_position + Vector3(0, 0.25, 0)
	beam_mesh.visible = 1
	beam_mesh.position = (from + to) / 2
	var dir : Vector3 = to - from
	beam_mesh.global_rotation.y = -atan2(dir.z, dir.x) + PI / 2
	beam_mesh.global_rotation.x = -atan2(dir.y, Vector2(dir.z, dir.x).length()) + PI / 2
	beam_mesh.scale.y = from.distance_to(to)


#type 0 = runner; type 1 = gunner
func spawn(type_f : float, ang : float, dist : float) -> void:
	ang = deg_to_rad(ang + 90)
	var type : int = roundi(type_f)
	var new_zombie
	match type:
		1:
			new_zombie = runner_scene.instantiate()
		2:
			new_zombie = gunner_scene.instantiate()
		3:
			new_zombie = hitscanner_scene.instantiate()
		4:
			new_zombie = chaingunner_scene.instantiate()
		5:
			new_zombie = mage_scene.instantiate()
		6:
			new_zombie = bomber_scene.instantiate()
		7:
			new_zombie = phantom_scene.instantiate()
		8:
			new_zombie = goliath_scene.instantiate()
		9:
			new_zombie = phantom_goliath_scene.instantiate()
	new_zombie.respawn_time = 1
	new_zombie.position = Vector3.MODEL_FRONT.rotated(Vector3.UP, ang - PI / 2) * dist
	new_zombie.position.y += spawn_height
	add_child(new_zombie)
	new_zombie.spawn_ang = rotation.y
	new_zombie.global_position.y -= new_zombie.GRAVE_DEPTH
	new_zombie.rising = 1
	new_zombie.mesh.visible = 0
	new_zombie.aura.material_override = aura_mat
	new_zombie.aura.visible = 1
	servants.push_back(new_zombie)
	servants_unkilled.push_back(true)
	
	var beam = MeshInstance3D.new()
	beam.mesh = CylinderMesh.new()
	beam.mesh.material = aura_mat
	beam.mesh.height = 1
	beam.mesh.rings = 1
	beam.mesh.radial_segments = 10
	beam.mesh.bottom_radius = 0.1
	beam.mesh.top_radius = 0.1
	add_child(beam)
	beam.top_level = 1
	servant_beams.push_back(beam)
	update_beam(servant_beams.size() - 1)


func spawn_wave() -> void:
	if current_wave >= spawns.size():
		return
	for i in range(spawns[current_wave].size()):
		if min_difs[current_wave][i] <= diff:
			var s : Vector3 = spawns[current_wave][i]
			spawn(abs(s.x), s.y, s.z)
	current_wave += 1


func add_gibs() -> void:
	if disable_gibs or get_tree().current_scene == null:
		return
	
	var new_gibs = gibs.instantiate()
	new_gibs.position = position
	new_gibs.rotation.y = rotation.y
	get_tree().current_scene.add_child(new_gibs)
	new_gibs.dir = (position - player.position).normalized() * 5


func pain(_dmg = null) -> void:
	return

func real_pain() -> void:
	health -= 1
	health_label.text = str(health)
	hurt_timer = 1
	for c in get_children():
		if c.is_in_group("enemy"):
			c.pain(9001)
			c.queue_free()
	for i in servants:
		i.queue_free()
	for i in servant_beams:
		i.queue_free()
	servants.clear()
	servant_beams.clear()
	servants_unkilled.clear()
	spawn_wave()


func is_player_in_zone() -> bool:
	if not alive:
		return 0
	for i in active_zone.get_overlapping_bodies():
		if i.is_in_group("player"):
			return 1
	return 0


func rising_func(t : float) -> float:
	return (1 - 1 / (10 * t + 1)) * 1.1


func _ready() -> void:
	if is_opengl:
		body.material_override = preload("res://resources/materials/level_mat.tres")
		head.material_override = preload("res://resources/materials/level_mat.tres")
	
	aura_mat.albedo_color = aura_col
	aura_mat.albedo_color.a = 0.11
	
	#determine at what height to put the enemy home
	ray.target_position = Vector3(0, -10, 0)
	var max_height : float = -1000000
	const CHECKS = 4
	for i in range(CHECKS):
		var pos : Vector2 = Vector2.RIGHT.rotated(2 * PI * i / CHECKS) * RADIUS
		ray.position = Vector3(pos.x, ray.position.y, pos.y)
		ray.force_raycast_update()
		if ray.is_colliding():
			var col : float = ray.get_collision_point().y
			if col > max_height:
				max_height = col
	home.global_position.y = max_height
	ray.position = Vector3(0, ray.position.y, 0)
	ray.force_raycast_update()
	
	
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	disable_gibs = config.get_value("video", "disable_gibs", false)
	
	diff = config.get_value("gameplay", "difficulty", 2)
	
	respawn.wait_time = respawn_time
	
	for c in get_children():
		if c is Area3D and not c.is_in_group("drop"):
			active_zone = c
			c.set_collision_mask_value(9, 1)
			c.collision_layer = 0
		elif c.is_in_group("drop"):
			key.visible = 1
			drops.push_back(c)
			remove_child(c)
	
	health_label.text = str(health)


func _process(delta : float) -> void:
	ai()
	
	body.visible = (alive and not rising) or (rising and int(rising_timer / RISE_FLICKER) % 2 == 1)
	head.visible = body.visible
	home.visible = not alive
	hitbox.disabled = not alive
	health_label.visible = fight_started and alive
	if rising:
		rising_timer += delta
		body.position.y = rising_func(rising_timer / RISE_TIME) * GRAVE_DEPTH - GRAVE_DEPTH
		head.position.y = body.position.y
		if rising_timer > RISE_TIME:
			rising = 0
			fire_timer.start()
	
	if not fight_started:
		return
	
	head.rotation.y += TURN_SPEED * delta
	
	if not alive:
		return
	
	if hurt_timer > 0.0:
		hurt_timer = max(0, hurt_timer - delta)
		body.set_instance_shader_parameter("pain", hurt_timer)
		head.set_instance_shader_parameter("pain", hurt_timer)
	
	for i in range(servant_beams.size()):
		update_beam(i)


func ai() -> void:
	if not fight_started:
		if is_player_in_zone():
			fight_started = 1
			spawn_wave()
		fire_timer.start()
		return
	if health <= 0 and alive:
		fight_started = 0
		fire_timer.stop()
		alive = 0
		home.time_left = respawn_time
		respawn.start()
		add_gibs()
		if not has_died:
			key.visible = 0
			has_died = 1
			for c in drops:
				add_child(c)
				c.top_level = 1
				c.global_position = global_position + Vector3(0, 2, 0)
	
	var l : int = servants.size()
	for i in range(l):
		if not servants[i].alive:
			servants_unkilled[i] = 0
		if not servants_unkilled[i]:
			l -= 1
	
	if l == 0:
		real_pain()


func _on_respawn_timeout() -> void:
	hurt_timer = 0.0
	alive = 1
	rising = 1
	rising_timer = 0
	fight_started = 0
	current_wave = 0
	health = spawns.size()
	health_label.text = str(health)


func _on_fire_timer_timeout() -> void:
	for i in range(0, 4):
		var dir : Vector3 = Vector3.FORWARD.rotated(Vector3.UP, i * PI / 2 + head.rotation.y)
		var new_bomb = bomb_scene.instantiate()
		new_bomb.death_message = "You were killed by a tank"
		new_bomb.position = Vector3(0, 3.45, 0)
		new_bomb.position += dir * 4.1
		new_bomb.target_pos = Vector3(position.x, player.position.y, position.z)
		new_bomb.target_pos -= dir.rotated(Vector3.UP, PI/2) * Vector3(position.x, 0, position.z).distance_to(Vector3(player.position.x, 0, player.position.z))
		new_bomb.scale = Vector3.ONE * 1.5
		new_bomb.HVEL = 25.0
		add_child(new_bomb)
		new_bomb.top_level = 1
