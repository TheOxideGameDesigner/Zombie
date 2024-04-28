extends StaticBody3D


var velocity = Vector3.ZERO
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

@export var runner_scene : PackedScene
@export var gunner_scene : PackedScene
@export var hitscanner_scene : PackedScene
@export var chaingunner_scene : PackedScene
@export var mage_scene : PackedScene
@export var bomber_scene : PackedScene
@export var aura_col : Color = Color(1, 0, 0.64)
var aura_mat = preload("res://resources/materials/aura_mat.tres").duplicate()
var bomb_scene = preload("res://scenes/props/enemies/bomber_bomb.tscn")
@export var gibs : PackedScene

# x = type, y = ang, z = dist
@export var respawn_time = 20
@export var spawn_height = 0
@export var spawns : Array[PackedVector3Array]
@export var min_difs : Array[PackedInt32Array]

@onready var hp = spawns.size()
@onready var health = hp
var alive = 1
var rising = 0
var has_died = 0
var rising_timer = 0
var fight_started = 0
var current_wave = 0

const RADIUS = 1
const TURN_SPEED = PI / 10

const GRAVE_DEPTH : float = 4
const RISE_FLICKER : float = 0.25
const RISE_TIME : float = 3.7664
const COLOR = Color(1.0, 1.0, 1.0)
const HURT_COLOR = Color(1, 0, 0)
var hurt_timer = 0

var drops = []
var servants = []
var servant_beams = []

var disable_gibs : bool = false

var diff
var is_opengl = ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility"

func update_beam(i):
	var beam_mesh = servant_beams[i]
	var from = global_position + Vector3(0, 2, 0)
	var to = servants[i].global_position + Vector3(0, servants[i].mesh.position.y - servants[i].position.y, 0)
	if servants[i].rising:
		beam_mesh.visible = 0
		servants[i].aura.visible = 0
		return
	beam_mesh.visible = 1
	servants[i].aura.visible = 1
	beam_mesh.position = (from + to) / 2
	beam_mesh.mesh.height = from.distance_to(to)
	var dir = to - from
	beam_mesh.global_rotation.y = -atan2(dir.z, dir.x) + PI / 2
	beam_mesh.global_rotation.x = -atan2(dir.y, Vector2(dir.z, dir.x).length()) + PI / 2


#type 0 = runner; type 1 = gunner
func spawn(type_f, ang, dist):
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
	new_zombie.hypnotizable = false
	new_zombie.respawn_time = 1
	new_zombie.position = Vector3.MODEL_FRONT.rotated(Vector3.UP, ang - PI / 2) * dist
	new_zombie.position.y += spawn_height
	add_child(new_zombie)
	new_zombie.spawn_ang = rotation.y
	new_zombie.global_position.y -= new_zombie.GRAVE_DEPTH
	new_zombie.rising = 1
	new_zombie.mesh.visible = 0
	new_zombie.aura.material_override = aura_mat
	servants.push_back(new_zombie)
	
	var beam = MeshInstance3D.new()
	beam.mesh = CylinderMesh.new()
	beam.mesh.material = aura_mat
	beam.mesh.height = 1
	beam.mesh.rings = 1
	beam.mesh.radial_segments = 10
	beam.mesh.bottom_radius = 0.2
	beam.mesh.top_radius = 0.2
	add_child(beam)
	beam.top_level = 1
	servant_beams.push_back(beam)
	update_beam(servant_beams.size() - 1)


func spawn_wave():
	if current_wave >= spawns.size():
		return
	for i in range(spawns[current_wave].size()):
		if min_difs[current_wave][i] <= diff:
			var s = spawns[current_wave][i]
			spawn(abs(s.x), s.y, s.z)
	current_wave += 1


func add_gibs():
	if disable_gibs or get_tree().current_scene == null:
		return
	
	var new_gibs = gibs.instantiate()
	new_gibs.position = position
	new_gibs.rotation.y = rotation.y
	get_tree().current_scene.add_child(new_gibs)
	new_gibs.dir = (position - player.position).normalized() * 5


func pain(_dmg = null):
	return

func real_pain():
	health -= 1
	health_label.text = str(health)
	hurt_timer = 1
	for c in get_children():
		if c.is_in_group("enemy"):
			c.pain(9001)
			c.queue_free()
	spawn_wave()


func is_player_in_zone():
	if not alive:
		return 0
	for i in active_zone.get_overlapping_bodies():
		if i.is_in_group("player"):
			return 1
	return 0


func rising_func(t):
	return (1 - 1 / (10 * t + 1)) * 1.1


func _ready():
	aura_mat.albedo_color = aura_col
	aura_mat.albedo_color.a = 0.11
	
	#determine at what height to put the enemy home
	ray.target_position = Vector3(0, -10, 0)
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
	
	
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	disable_gibs = config.get_value("video", "disable_gibs", false)
	
	diff = config.get_value("gameplay", "difficulty", 2)
	
	respawn.wait_time = respawn_time
	
	for c in get_children():
		if c is Area3D and not c.is_in_group("drop"):
			active_zone = c
			c.set_collision_mask_value(9, 1)
		elif c.is_in_group("drop"):
			key.visible = 1
			drops.push_back(c)
			remove_child(c)
	
	health_label.text = str(health)


func _process(delta):
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
	
	if not fight_started:
		return
	
	head.rotation.y += TURN_SPEED * delta
	
	if not alive:
		return
	
	hurt_timer = max(0, hurt_timer - delta)
	body.set_instance_shader_parameter("pain", hurt_timer)
	head.set_instance_shader_parameter("pain", hurt_timer)
	
	for i in range(servant_beams.size()):
		update_beam(i)


func _physics_process(_delta):
	if not fight_started:
		if is_player_in_zone():
			fight_started = 1
			fire_timer.start()
			spawn_wave()
		return
	if health <= 0 and alive:
		fight_started = 0
		alive = 0
		fire_timer.stop()
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
	
	var i = 0
	while i < servants.size():
		if not servants[i].alive:
			servants[i].aura.visible = 0
			servants.pop_at(i)
			servant_beams[i].queue_free()
			servant_beams.pop_at(i)
		else:
			i = i + 1
	
	if servants.is_empty():
		real_pain()


func _on_respawn_timeout():
	alive = 1
	rising = 1
	rising_timer = 0
	fight_started = 0
	current_wave = 0
	health = spawns.size()
	health_label.text = str(health)


func _on_fire_timer_timeout():
	for i in range(0, 4):
		var dir = Vector3.FORWARD.rotated(Vector3.UP, i * PI / 2 + head.rotation.y)
		var new_bomb = bomb_scene.instantiate()
		new_bomb.target = player
		new_bomb.death_message = "You were killed by a tank"
		new_bomb.position = Vector3(0, 3.45, 0)
		new_bomb.position += dir * 4.1
		new_bomb.target_pos = Vector3(position.x, player.position.y, position.z)
		new_bomb.target_pos -= dir.rotated(Vector3.UP, -PI/2) * Vector3(position.x, 0, position.z).distance_to(Vector3(player.position.x, 0, player.position.z))
		new_bomb.scale = Vector3.ONE * 1.5
		new_bomb.HVEL = 25.0
		add_child(new_bomb)
		new_bomb.top_level = 1
