extends Control

func _ready() -> void:
	for i in Globals.levels.keys():
		var n = Button.new()
		n.text = i
		n.pressed.connect(
			func():
				Globals.level = i
				get_tree().change_scene_to_file.call_deferred("res://game.tscn")
		)
		n.size_flags_vertical = Control.SIZE_EXPAND_FILL
		$Levels/Container.add_child(n)
