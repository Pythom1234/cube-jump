class_name Globals

enum PlayerType {
	CUBE,
	PLANE
}

enum HelperType {
	CROSS,
	POINT,
	ARROW_UP,
	ARROW_DOWN,
	ARROW_LEFT,
	ARROW_RIGHT
}

enum OrbType {
	JUMP,
	JUMP_SIDE
}

enum TrampolineType {
	JUMP
}

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
