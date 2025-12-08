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
var jumped = []
const models = {
	Globals.PlayerType.CUBE: preload("res://assets/obj/cube.glb"),
	Globals.PlayerType.SPIDER: preload("res://assets/obj/spider.glb"),
	#Globals.PlayerType.PLANE: preload("res://assets/plane.obj"),
}
## type: [gravity1: [CameraOrigin, Camera], gravity-1: [CameraOrigin, Camera]] 
const views = {
	Globals.PlayerType.CUBE: [
		[-50, 13],
		[30, -13]
	],
	Globals.PlayerType.SPIDER: [
		[-30, 13],
		[30, -13]
	],
}

func _ready() -> void:
	set_type(Globals.PlayerType.CUBE)

func _process(delta: float) -> void:
	if length == 0:
		return
	$UI/UI/Progress.value = 100 * (position.z / length)
	time += delta
	var s: Vector2 = DisplayServer.window_get_size()
	$CameraOrigin/CameraArm.spring_length = 3 + s.y / s.x
	for i in range($CameraOrigin/CameraCollider.get_collision_count()):
		if $CameraOrigin/CameraCollider.get_collider(i).get_collision_layer_value(16):
			$CameraOrigin/CameraCollider.get_collider(i).visible = false
			$CameraOrigin/CameraCollider.get_collider(i).set_collision_layer_value(16, false)
			$CameraOrigin/CameraCollider.get_collider(i).set_collision_layer_value(17, true)
	#print(time)

func restart(practice_allow = false) -> void:
	time = 0
	jumped = []
	if practice and checkpoints and practice_allow:
		position = checkpoints[-1][0]
		velocity = checkpoints[-1][1]
		set_type(checkpoints[-1][2])
		up_direction = checkpoints[-1][3]
	else:
		position = Vector3(0, 0, 0)
		velocity = Vector3(0, 0, 0)
		set_type(Globals.PlayerType.CUBE)
		up_direction = Vector3.UP
	$CameraOrigin.rotation_degrees.x = views[type][0 if up_direction.y == 1 else 1][0]
	$CameraOrigin/CameraArm/Camera.rotation_degrees.x = views[type][0 if up_direction.y == 1 else 1][1]
	attempt += 1
	$"../Attempts".text = "Attempt: %s" % attempt
	$"../Attempts".position = position + Vector3(0, 2, 3)
	$Visible.rotation_degrees = Vector3(0, 0, 0)
	pause(false)
	if not practice_allow:
		checkpoints = []
		for i in $"../Checkpoints".get_children():
			i.queue_free()
	for i in $"../Level".get_children():
		if (i is StaticBody3D or i is Area3D) and i.get_collision_layer_value(17):
			i.visible = true
			i.set_collision_layer_value(16, true)
			i.set_collision_layer_value(17, false)

func die():
	dying = true
	$Visible.visible = false
	$DieParticles.restart()
	Globals.sset(Globals.level, "best", 100 * (position.z / length))
	await get_tree().create_timer(0.8).timeout
	restart(true)
	await get_tree().process_frame
	$Visible.visible = true
	dying = false

func set_type(t):
	type = t
	$Visible/Model.get_child(0).queue_free()
	$Visible/Model.add_child(models[type].instantiate())
	await get_tree().process_frame
	for i in $Visible/Model.get_child(0).get_children():
		if "Primary" in i.name:
			i.material_override = StandardMaterial3D.new()
			i.material_override.albedo_color = Color(0.0, 1.0, 0.0, 1.0)
		if "Secondary" in i.name:
			i.material_override = StandardMaterial3D.new()
			i.material_override.albedo_color = Color(0.0, 1.0, 1.0, 1.0)
	match t:
		Globals.PlayerType.CUBE:
			rotation_degrees = Vector3(0, 0, 0)
			position.x = round(position.x)
		#Globals.PlayerType.PLANE:
			#$Visible.rotation_degrees = Vector3(0, 0, 0)
			#velocity = Vector3(0, 0, 0)
		Globals.PlayerType.SPIDER:
			$Visible/Model.get_child(0).get_node("AnimationPlayer").play("Scene")
			rotation_degrees = Vector3(0, 0, 0)
			position.x = round(position.x)
	$CameraOrigin.rotation_degrees.x = views[type][0 if up_direction.y == 1 else 1][0]
	$CameraOrigin/CameraArm/Camera.rotation_degrees.x = views[type][0 if up_direction.y == 1 else 1][1]

func change_gravity(direction = null, duration = 0.1):
	var tween = create_tween()
	tween.set_parallel()
	if up_direction == Vector3.DOWN or direction == Vector3.UP:
		up_direction = Vector3.UP
		tween.tween_property($CameraOrigin, "rotation_degrees:x", views[type][0 if up_direction.y == 1 else 1][0], duration)
		tween.tween_property($CameraOrigin/CameraArm/Camera, "rotation_degrees:x", views[type][0 if up_direction.y == 1 else 1][1], duration)
		$Visible.rotation_degrees.z = 180
	elif up_direction == Vector3.UP or direction == Vector3.DOWN:
		up_direction = Vector3.DOWN
		tween.tween_property($CameraOrigin, "rotation_degrees:x", views[type][0 if up_direction.y == 1 else 1][0], duration)
		tween.tween_property($CameraOrigin/CameraArm/Camera, "rotation_degrees:x", views[type][0 if up_direction.y == 1 else 1][1], duration)
		$Visible.rotation_degrees.z = 0

func practice_add_checkpoint():
	if not practice:
		return
	if checkpoints and position.distance_to(checkpoints[-1][0]) < .4:
		return
	checkpoints.append([position, velocity, type, up_direction])
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
	var orb = false
	var trampoline = false
	for i in $Collider.get_overlapping_areas():
		if i.get_collision_layer_value(5):
			orb = true
		if i.get_collision_layer_value(6):
			trampoline = true
	match type:
		Globals.PlayerType.CUBE:
			if is_on_floor():
				$Visible.rotation_degrees.x = 0
				$Visible.rotation.z = atan2(up_direction.y, up_direction.x) - PI/2
				position.x = round(position.x)
				turn = 0
				$Visible/TrailParticles.emitting = true
			else:
				velocity.y -= 60 * up_direction.y * delta
				$Visible.rotation_degrees.x += 200 * delta
				$Visible.rotation_degrees.z -= 200 * delta * turn
				$Visible/TrailParticles.emitting = false
			if Input.is_action_pressed("left") and is_on_floor() and not orb and not trampoline:
				velocity.y = 14.5 * up_direction.y
				velocity.x = VELOCITY_X
				turn = 1
			if Input.is_action_pressed("right") and is_on_floor() and not orb and not trampoline:
				velocity.y = 14.5 * up_direction.y
				velocity.x = -VELOCITY_X
				turn = -1
			velocity.x = move_toward(velocity.x, 0, DRAG)
			velocity.z = SPEED
		Globals.PlayerType.SPIDER:
			$Visible/TrailParticles.emitting = false
			$Visible.rotation.z = atan2(up_direction.y, up_direction.x) - PI/2
			if is_on_floor():
				position.x = round(position.x)
			else:
				velocity.y -= 60 * up_direction.y * delta
			if Input.is_action_just_pressed("left") and is_on_floor():
				change_gravity()
				position.x += 1
				var new_pos = position
				while new_pos.distance_to(position) < 10000:
					var collision = KinematicCollision3D.new()
					if test_move(Transform3D(transform.basis, new_pos), -up_direction, collision):
						var tween = create_tween()
						tween.tween_property(self, "position:y", collision.get_position().y, 0.1)
						break
					else:
						new_pos += -up_direction
				#if new_pos.distance_to(position) >= 10000:
					#var tween = create_tween()
					#tween.tween_property(self, "position", new_pos, 0.1)
					#tween.tween_callback(die)
			if Input.is_action_just_pressed("right") and is_on_floor():
				change_gravity()
				position.x -= 1
				var new_pos = position
				while new_pos.distance_to(position) < 10000:
					var collision = KinematicCollision3D.new()
					if test_move(Transform3D(transform.basis, new_pos), -up_direction, collision):
						var tween = create_tween()
						tween.tween_property(self, "position:y", collision.get_position().y, 0.1)
						break
					else:
						new_pos += -up_direction
				#if new_pos.distance_to(position) >= 10000:
					#var tween = create_tween()
					#tween.tween_property(self, "position", new_pos, 0.1)
					#tween.tween_callback(die)
			velocity.x = move_toward(velocity.x, 0, DRAG)
			velocity.z = SPEED
		#Globals.PlayerType.PLANE:
			#if not is_on_floor():
				#rotation_degrees.x += 65 * delta
			#else:
				#rotation_degrees.x = lerp(rotation_degrees.x, 0.0, 0.3)
			#if Input.is_action_pressed("right") or Input.is_action_pressed("left"):
				#rotation_degrees.x -= 130 * delta
			#if Input.is_action_pressed("left"):
				#rotation_degrees.y += .5
			#if Input.is_action_pressed("right"):
				#rotation_degrees.y -= .5
			#rotation_degrees.x = clamp(rotation_degrees.x, -40, 40)
			#rotation_degrees.y = clamp(rotation_degrees.y, -40, 40)
			#velocity = transform.basis * Vector3(
				#0,
				#1.0 + abs(rotation_degrees.x) / 30.0
					#if rotation_degrees.x <= 0
					#else -(1.0 + abs(rotation_degrees.x) / 30.0),
				#SPEED
			#)
			#$CameraOrigin.global_rotation_degrees = Vector3(-14, 180, 0)
	for i in $Collider.get_overlapping_areas():
		if i.get_collision_layer_value(4):
			set_type(i.type)
		if i.get_collision_layer_value(5):
			if i.type == Globals.OrbType.JUMP:
					if click_buffer[1] > 0:
						click_buffer = [0, 0]
						velocity.y = 17 * up_direction.y
						i.jump()
						$Visible.rotation_degrees.z = 0
						turn = 0
			if i.type == Globals.OrbType.JUMP_BIG:
					if click_buffer[1] > 0:
						click_buffer = [0, 0]
						velocity.y = 27 * up_direction.y
						i.jump()
						$Visible.rotation_degrees.z = 0
						turn = 0
			if i.type == Globals.OrbType.JUMP_SIDE:
					if click_buffer[1] > 0:
						turn = click_buffer[0]
						click_buffer = [0, 0]
						velocity.y = 14 * up_direction.y
						velocity.x = (VELOCITY_X - .1) * turn
						i.jump()
						$Visible.rotation_degrees.x = 0
						#$Visible.rotation_degrees.z = 0
			if i.type == Globals.OrbType.GRAVITY:
					if click_buffer[1] > 0:
						click_buffer = [0, 0]
						velocity.y = 0
						$Visible.rotation_degrees.x = 0
						$Visible.rotation_degrees.z = 0
						i.jump()
						change_gravity()
						turn = 0
		if i.get_collision_layer_value(6):
			if i.type == Globals.TrampolineType.JUMP and not i in jumped:
				jumped.append(i)
				velocity.y = 20 * up_direction.y
				i.jump()
				$Visible.rotation_degrees.z = 0
			if i.type == Globals.TrampolineType.JUMP_LEFT and not i in jumped:
				jumped.append(i)
				velocity.y = 20 * up_direction.y
				velocity.x = VELOCITY_X
				turn = 1
				i.jump()
				$Visible.rotation_degrees.x = 0
			if i.type == Globals.TrampolineType.JUMP_RIGHT and not i in jumped:
				jumped.append(i)
				velocity.y = 20 * up_direction.y
				velocity.x = -VELOCITY_X
				turn = -1
				i.jump()
				$Visible.rotation_degrees.x = 0
			if i.type == Globals.TrampolineType.GRAVITY and not i in jumped:
				jumped.append(i)
				velocity.y = 0
				$Visible.rotation_degrees.x = 0
				$Visible.rotation_degrees.z = 0
				change_gravity()
				turn = 0
	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().get_collision_layer_value(3):
			die()
			return
	if position.y < -3 or position.y > 100:
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
	$UI/UI/PausePanel/Container/Container/RestartCheckpoint.visible = practice
	$UI/UI/CheckpointContainer.visible = practice
	pause(false)

func menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred("res://menu.tscn")

func practice_timer() -> void:
	if practice:
		if is_on_floor():
			practice_add_checkpoint()
		else:
			$PracticeTimer.paused = true
			while not is_on_floor():
				await get_tree().process_frame
			practice_add_checkpoint()
			$PracticeTimer.paused = false
