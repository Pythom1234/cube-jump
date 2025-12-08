extends Node3D


func _ready() -> void:
	var l = Globals.levels[Globals.level].instantiate()
	l.name = "Level"
	add_child(l)
	for i in l.get_children():
		$Player.length = max($Player.length, i.position.z)
	#$Level.position = -Vector3(7, 1, 322)
	#$Level.position = -Vector3(6, 4, 385)
