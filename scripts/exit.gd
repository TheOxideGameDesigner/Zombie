extends Area3D


@onready var player = get_tree().get_nodes_in_group("player")[0]
@export var chapter : int
@export var level : int
@export var requires_garlic : bool = true

var end_screen_scene = preload("res://scenes/end_screen.tscn")

const CONFIG_PATH = "user://unlocked.cfg"

var levels = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))


func _physics_process(_delta : float) -> void:
	$block/block_hitbox.disabled = player.has_garlic or not requires_garlic
	$warning/warning_hitbox.disabled = player.has_garlic or not requires_garlic

func _on_body_entered(body : PhysicsBody3D) -> void:
	if body.is_in_group("player") and (player.has_garlic or not requires_garlic):
		var config = ConfigFile.new()
		config.load(CONFIG_PATH)
		config.set_value(levels[chapter][0], str(level), true)
		config.save(CONFIG_PATH)
		
		var end_screen = end_screen_scene.instantiate()
		end_screen.current_scene = get_tree().current_scene.scene_file_path
		end_screen.next_scene = "res://scenes/levels/" + levels[chapter][2][level]
		end_screen.damage_taken = player.damage_taken
		end_screen.time = player.time
		
		var root = self
		while root.get_parent_node_3d() != null:
			root = root.get_parent_node_3d()
		for c in root.get_children():
			c.queue_free()
		
		root.add_child(end_screen)
