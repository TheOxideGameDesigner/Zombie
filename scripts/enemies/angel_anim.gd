extends CollisionShape3D

@onready var left_wing = $left_wing
@onready var right_wing = $right_wing
@onready var angel_body = $body/Armature/Skeleton3D/runner_body
@onready var skel = $body/Armature/Skeleton3D
@onready var right_th = skel.find_bone("right_thigh")
@onready var right_cf = skel.find_bone("right_calf")
@onready var left_th = skel.find_bone("left_thigh")
@onready var left_cf = skel.find_bone("left_calf")
@onready var init_right_thigh_rot = skel.get_bone_pose_rotation(right_th).get_euler()
@onready var init_left_thigh_rot = skel.get_bone_pose_rotation(left_th).get_euler()
@onready var init_right_calf_rot = skel.get_bone_pose_rotation(right_cf).get_euler()
@onready var init_left_calf_rot = skel.get_bone_pose_rotation(left_cf).get_euler()
@onready var player_cam = get_tree().get_first_node_in_group("player").get_node("cam")
var anim_timer = 0.0


func anim(c):
	position.y = 0.4 * c
	left_wing.rotation.z = 0.2 * c
	right_wing.rotation.z = -left_wing.rotation.z
	skel.set_bone_pose_rotation(left_th, Quaternion.from_euler(init_left_thigh_rot + Vector3(0, 0, (c - 2) * 0.05)))
	skel.set_bone_pose_rotation(left_cf, Quaternion.from_euler(init_left_calf_rot + Vector3(0, 0, (c - 2) * 0.05)))
	skel.set_bone_pose_rotation(right_th, Quaternion.from_euler(init_right_thigh_rot + Vector3(0, 0, (c - 2) * 0.1)))
	skel.set_bone_pose_rotation(right_cf, Quaternion.from_euler(init_right_calf_rot + Vector3(0, 0, (c - 2) * 0.1)))


func _ready():
	angel_body.material_override = preload("res://resources/materials/specific_mats/angel_mat.tres")
	angel_body.cast_shadow = false


func _process(delta):
	rotation.y = -atan2(player_cam.global_position.z - global_position.z, player_cam.global_position.x - global_position.x) + PI / 2
	anim_timer = fmod(anim_timer + 2 * delta, PI * 2)
	anim(sin(anim_timer))
