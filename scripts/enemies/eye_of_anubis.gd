extends StaticBody3D


var HIT_TIME = 5.0


@onready var orb = $orb
@onready var ray = $ray
@onready var init_ray_pos = $ray.position
@onready var player = get_tree().get_first_node_in_group("player")
@onready var player_cam = get_tree().get_first_node_in_group("player").get_node("cam")
@onready var ui = player.get_node("eye_of_anubis")
@onready var death_ray = $death_ray

var death_ray_mat = preload("res://resources/materials/specific_mats/death_ray_mat.tres").duplicate()
var active_zone : Area3D = null

var bob_timer = 0.0
@onready var init_orb_pos = orb.position.y
@onready var init_death_ray_pos = death_ray.position.y
var hit_timer = 0.0
var sees_player = 0

func _ready():
	$death_ray/death_ray_mesh.material_override = death_ray_mat
	for c in get_children():
		if c is Area3D:
			c.set_collision_mask_value(9, 1)
			active_zone = c
			c.collision_layer = 0
			active_zone.input_ray_pickable = false
			break

func is_player_in_zone():
	for b in active_zone.get_overlapping_bodies():
		if b.is_in_group("player"):
			return 1
	return 0


func _process(delta):
	if not is_player_in_zone():
		sees_player = 0
	else:
		ray.position = init_ray_pos.rotated(Vector3.UP, orb.global_rotation.y)
		ray.target_position = ray.to_local(player.position + Vector3(0, 1.5, 0))
		ray.force_raycast_update()
		sees_player = (ray.is_colliding() and ray.get_collider() == player)
		if hit_timer >= HIT_TIME:
			hit_timer = 0.0
			player.pain("You were killed by an Eye of Anubis", 9001)
	
	bob_timer += delta
	orb.position.y = (sin(bob_timer * 1.2) + 1) * 0.2 + init_orb_pos
	death_ray.position.y = (sin(bob_timer * 1.2) + 1) * 0.2 + init_death_ray_pos
	var dir = player_cam.global_position - orb.global_position
	orb.global_rotation.y = -atan2(dir.z, dir.x)
	orb.global_rotation.z = atan2(dir.y, Vector2(dir.z, dir.x).length())
	if not sees_player:
		hit_timer = 0.0
		death_ray_mat.albedo_color.a = 0
		return
	hit_timer += delta
	var opac = hit_timer / HIT_TIME
	ui.modulate.a = max(ui.modulate.a, opac)
	
	dir = player_cam.global_position + Vector3(0, -0.2, 0) - death_ray.global_position
	death_ray.global_rotation.y = -atan2(dir.z, dir.x)
	death_ray.global_rotation.z = atan2(dir.y, Vector2(dir.z, dir.x).length())
	death_ray_mat.albedo_color.a = opac
	death_ray.scale.x = dir.length()
