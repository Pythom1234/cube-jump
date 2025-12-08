extends Node

enum PlayerType {
	CUBE,
	PLANE, # TODO
	SPIDER,
}

enum HelperType {
	CROSS,
	POINT,
	ARROW_UP,
	ARROW_DOWN,
	ARROW_LEFT,
	ARROW_RIGHT,
}

enum OrbType {
	JUMP,
	JUMP_BIG,
	JUMP_SIDE,
	GRAVITY,
}

enum TrampolineType {
	JUMP,
	JUMP_LEFT,
	JUMP_RIGHT,
	GRAVITY,
}

const levels: = {
	"01": preload("res://levels/01.tscn"),
}
var level = "01"
var config = ConfigFile.new()

func _init() -> void:
	if not FileAccess.file_exists("user://config.ini"):
		config.save("user://config.ini")
	config.load("user://config.ini")

func sset(section, key, value):
	config.set_value(section, key, value)
	config.save("user://config.ini")

func sget(section, key):
	return config.get_value(section, key)
