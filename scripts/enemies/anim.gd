extends Node3D


@onready var anim_player = $AnimationPlayer
@onready var skel = $Armature/Skeleton3D
@onready var right_th = skel.find_bone("right_thigh")
@onready var right_cf = skel.find_bone("right_calf")
@onready var left_th = skel.find_bone("left_thigh")
@onready var left_cf = skel.find_bone("left_calf")

@onready var init_right_thigh_rot = skel.get_bone_pose_rotation(right_th).get_euler().x
@onready var init_left_thigh_rot = skel.get_bone_pose_rotation(left_th).get_euler().x

var anim_timer = 0.0
var anim_speed = 0.0
var anim_amplitude = PI / 6
var bob_amplitude = 0.1

var legs_playing = 0

var actually_legs_playing = 0.0

func _ready():
	for i in skel.get_children():
		if i is MeshInstance3D:
			i.visibility_range_end = 175

func bob_func(t: float) -> float:
	t = fmod(t, 0.5)
	return -16 * t * (t - 0.5)

func ang_func(t : float) -> float:
	return sin(t * 2 * PI) * anim_amplitude

func is_playing():
	return anim_player.is_playing()


func play(anim_name = "hitting", speed = 1.0):
	if speed > 0:
		anim_player.play(anim_name, -1, speed)
	else:
		anim_player.play(anim_name, -1, speed, true)

func _process(delta):
	position.y = bob_func(anim_timer) * bob_amplitude
	
	var prev_anim_timer = anim_timer
	anim_timer = fmod(anim_timer + anim_speed * delta, 1.0)
	if legs_playing:
		actually_legs_playing = 1
	elif prev_anim_timer > anim_timer or (prev_anim_timer < 0.5 and anim_timer > 0.5):
		actually_legs_playing = 0
	
	var ang = ang_func(anim_timer)
	if not actually_legs_playing:
		position.y = 0.0
		ang = 0.0
	skel.set_bone_pose_rotation(right_th, Quaternion.from_euler(Vector3(init_right_thigh_rot, 0, ang)))
	skel.set_bone_pose_rotation(left_th, Quaternion.from_euler(Vector3(init_left_thigh_rot, 0, -ang)))
	if is_zero_approx(ang):
		skel.set_bone_pose_rotation(right_cf, Quaternion.from_euler(Vector3(0, 0, 0)))
		skel.set_bone_pose_rotation(left_cf, Quaternion.from_euler(Vector3(0, 0, 0)))
	elif ang > 0:
		skel.set_bone_pose_rotation(right_cf, Quaternion.from_euler(Vector3(0, 0, ang)))
	else:
		skel.set_bone_pose_rotation(left_cf, Quaternion.from_euler(Vector3(0, 0, -ang)))
