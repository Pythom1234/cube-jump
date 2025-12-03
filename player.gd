extends CharacterBody3D

const VELOCITY_X = 5
const SPEED = 7
const DRAG = .2
var turn = 0
var time = 0
var dying = false
var type = Globals.PlayerType.CUBE
var click_buffer = [0, 0]
var practice = false
var checkpoints = []
var attempt = 1
var length = 0
const models = {
	Globals.PlayerType.CUBE: preload("res://assets/cube.obj"),
	#Globals.PlayerType.PLANE: preload("res://assets/plane.obj"),
}

##TODO: nekde je 
## E 0:00:08:055   set_axis_angle: The axis Vector3 (1.0, -0.125, 0.0) must be normalized.
## <Chyba C++>   Condition "!p_axis.is_normalized()" is true.
## <Zdroj C++>   core/math/basis.cpp:843 @ set_axis_angle()

#func _process(_delta: float) -> void:
	#if $Path.curve.get_point_count() == 0 or $Path.curve.get_point_position($Path.curve.get_point_count() - 1) != position:
		#$Path.curve.add_point(position)

func _ready() -> void:
	for i in $"../Level".get_children():
		length = max(length, i.position.z)

func _process(delta: float) -> void:
	$UI/UI/Progress.value = 100 * (position.z / length)
	time += delta
	var s: Vector2 = DisplayServer.window_get_size()
	$CameraOrigin/CameraArm.spring_length = 3 + s.y / s.x
	#print(time)

func die():
	dying = true
	$Mesh.visible = false
	$DieParticles.restart()
	time = 0
	await get_tree().create_timer(0.8).timeout
	time = 0
	$Path.curve.clear_points()
	position = Vector3(0, 0, 0)
	velocity = Vector3(0, 0, 0)
	if practice and checkpoints:
		position = checkpoints[-1][0]
		velocity = checkpoints[-1][1]
		type = checkpoints[-1][2]
	attempt += 1
	$"../Attempts".text = "Attempt: %s" % attempt
	$"../Attempts".position = position + Vector3(0, 2, 3)
	$Mesh.rotation_degrees = Vector3(0, 0, 0)
	set_type(Globals.PlayerType.CUBE)
	await get_tree().create_timer(0.001).timeout
	$Mesh.visible = true
	dying = false

func set_type(t):
	type = t
	match t:
		Globals.PlayerType.CUBE:
			rotation_degrees = Vector3(0, 0, 0)
			$CameraOrigin.global_rotation_degrees = Vector3(-50, 180, 0)
			position.x = round(position.x)
		Globals.PlayerType.PLANE:
			$CameraOrigin.global_rotation_degrees = Vector3(-14, 180, 0)
			$Mesh.rotation_degrees = Vector3(0, 0, 0)
			velocity = Vector3(0, 0, 0)

func practice_add_checkpoint():
	if checkpoints and position.distance_to(checkpoints[-1][0]) < .4:
		return
	checkpoints.append([position, velocity, type])
	var n = preload("res://checkpoint.tscn").instantiate()
	n.position = checkpoints[-1][0]
	$"../Checkpoints".add_child(n)

func practice_remove_checkpoint() -> void:
	if not checkpoints:
		return
	checkpoints.remove_at(-1)
	$"../Checkpoints".get_children()[-1].queue_free()

func _physics_process(delta: float) -> void:
	if dying:
		return
	if Input.is_action_just_pressed("left"):
		click_buffer[0] = 1
		click_buffer[1] = .2
	if Input.is_action_just_pressed("right"):
		click_buffer[0] = -1
		click_buffer[1] = .2
	click_buffer[1] = max(0, click_buffer[1] - delta)
	match type:
		Globals.PlayerType.CUBE:
			if not is_on_floor():
				velocity.y -= 60 * delta
				$Mesh.rotation_degrees.x += 200 * delta
				$Mesh.rotation_degrees.z -= 200 * delta * turn
				$TrailParticles.emitting = false
			else:
				$Mesh.rotation_degrees.x = 0
				$Mesh.rotation_degrees.z = 0
				position.x = round(position.x)
				turn = 0
				$TrailParticles.emitting = true
			if Input.is_action_pressed("left") and is_on_floor():
				if practice:
					practice_add_checkpoint()
				velocity.y = 14.5
				velocity.x = VELOCITY_X
				turn = 1
			if Input.is_action_pressed("right") and is_on_floor():
				if practice:
					practice_add_checkpoint()
				velocity.y = 14.5
				velocity.x = -VELOCITY_X
				turn = -1
			velocity.x = move_toward(velocity.x, 0, DRAG)
			velocity.z = SPEED
		Globals.PlayerType.PLANE:
			if not is_on_floor():
				rotation_degrees.x += 65 * delta
			else:
				rotation_degrees.x = lerp(rotation_degrees.x, 0.0, 0.3)
			if Input.is_action_pressed("right") or Input.is_action_pressed("left"):
				rotation_degrees.x -= 130 * delta
			if Input.is_action_pressed("left"):
				rotation_degrees.y += .5
			if Input.is_action_pressed("right"):
				rotation_degrees.y -= .5
			rotation_degrees.x = clamp(rotation_degrees.x, -40, 40)
			rotation_degrees.y = clamp(rotation_degrees.y, -40, 40)
			velocity = transform.basis * Vector3(
				0,
				1.0 + abs(rotation_degrees.x) / 30.0
					if rotation_degrees.x <= 0
					else -(1.0 + abs(rotation_degrees.x) / 30.0),
				SPEED
			)
			$CameraOrigin.global_rotation_degrees = Vector3(-14, 180, 0)
	for i in $Collider.get_overlapping_areas():
		if i.get_collision_layer_value(5):
			if i.type == Globals.OrbType.JUMP:
					if click_buffer[1] > 0 and not is_on_floor():
						click_buffer = [0, 0]
						velocity.y = 17
						i.jump()
						$Mesh.rotation_degrees.z = 0
						turn = 0
			if i.type == Globals.OrbType.JUMP_SIDE:
					if click_buffer[1] > 0 and not is_on_floor():
						turn = click_buffer[0]
						click_buffer = [0, 0]
						velocity.y = 17
						velocity.x = VELOCITY_X * turn
						i.jump()
						$Mesh.rotation_degrees.z = 0
		if i.get_collision_layer_value(6):
			if i.type == Globals.TrampolineType.JUMP:
						velocity.y = 20
						i.jump()
						$Mesh.rotation_degrees.z = 0
	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().get_collision_layer_value(3):
			die()
			return
	if position.y < -3:
			die()
			return
	if $BlockCollider.has_overlapping_bodies():
		die()
		return

func pause(yes = null) -> void:
	if yes == null:
		get_tree().paused = not get_tree().paused
	else:
		get_tree().paused = yes
	$UI/UI/PausePanel.visible = get_tree().paused

func left_down() -> void:
	Input.action_press("left")

func left_up() -> void:
	Input.action_release("left")

func right_down() -> void:
	Input.action_press("right")

func right_up() -> void:
	Input.action_release("right")

func practice_toggle() -> void:
	if practice:
		practice = false
		checkpoints = []
		restart()
		for i in $"../Checkpoints".get_children():
			i.queue_free()
	else:
		practice = true
	$UI/UI/CheckpointContainer.visible = practice
	pause(false)

func restart() -> void:
	position = Vector3(0, 0, 0)
	velocity = Vector3(0, 0, 0)
	$Mesh.rotation_degrees = Vector3(0, 0, 0)
	set_type(Globals.PlayerType.CUBE)
	pause(false)
