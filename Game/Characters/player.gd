extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const MIN_JUMP = -80

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animated_sprite = $AnimatedSprite2D

@onready var tile_map : TileMap = $"../TileMap"
@onready var coyote_time = $CoyoteTime
@onready var jump_buffer = $JumpBuffer
@onready var jump_sound = $"../Jump"
var wall_jump_remaining

var is_sliding = false
var is_jumping = false
var oppositeWallDirection = 0
var xPositionSliding = null
var lastMovementDirection

var syncPos = Vector2(0,0)

func _physics_process(delta):
	if(!GameManager.is_solo and $MultiplayerSynchronizer.get_multiplayer_authority() != multiplayer.get_unique_id()):
		global_position = global_position.lerp(syncPos, .5)
	else:
		if (position.y > 512):
			kill()
		animated_sprite.play()
		
		# Add the gravity.
		if not is_on_floor():
			if is_sliding:
				velocity.x = -60 * oppositeWallDirection
				velocity.y = move_toward(velocity.y, 180, gravity * delta)
			else:
				velocity.y = move_toward(velocity.y, 980, gravity * delta)
			if (velocity.y <= 0):
				animation("jump")
			else:
				if is_sliding:
					animation("wall_jump")
				else:
					animation("fall")
		else:
			if(velocity.x == 0):
				animation("idle")
			else:
				animation("run")
		# move_and_slide() is called is_on_floor() is updated but was_on_floor keep the previous value
		var was_on_floor = is_on_floor()
		
		var acceleration
		if !is_on_floor():
			acceleration = 40.0
		else:
			acceleration = 100.0
			
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction = Input.get_axis("ui_left", "ui_right")
		
		# Movement
		if direction:
			velocity.x = move_toward(velocity.x, direction * SPEED, acceleration)
			
			if (velocity.x < 0):
				animated_sprite.flip_h = true
			elif (velocity.x > 0):
				animated_sprite.flip_h = false
		else:
			velocity.x = move_toward(velocity.x, 0, acceleration)
		
		# reset number of wall jumps remaining when touching floor
		if is_on_floor():
			wall_jump_remaining = 1
		
		# Handle Jump.
		if Input.is_action_just_pressed("ui_accept") and !is_jumping:
			# Jump / Wall-jump
			if ((is_on_floor() or !coyote_time.is_stopped()) or (is_sliding and wall_jump_remaining)):
				coyote_time.stop()
				jump()
			# Buffers jump if not on floor
			else:
				jump_buffer.start()
		
		# allows to make short jumps
		if Input.is_action_just_released("ui_accept") and velocity.y < MIN_JUMP:
			velocity.y = MIN_JUMP
			
		var tile_map_pos = tile_map.local_to_map(Vector2i(position.x, position.y))
		var tile_data : TileData = tile_map.get_cell_tile_data(0, Vector2i(tile_map_pos.x,tile_map_pos.y+1))
		if tile_data:
			if(tile_data.get_custom_data("dead")):
				kill()
			if !GameManager.is_solo:
				if(tile_data.get_custom_data("end")):
					if(GameManager.can_finish_level):
						rpc("arrivee",GameManager.players[str(multiplayer.get_unique_id())].id)
						for player in GameManager.players:
							if(GameManager.players[str(multiplayer.get_unique_id())] != GameManager.players[player]):
								GameManager.players[str(multiplayer.get_unique_id())].spawn = GameManager.players[player].spawn
						kill()
					elif(GameManager.can_confirm_level):
						rpc("arrivee2",GameManager.players[str(multiplayer.get_unique_id())].id)
					
		move_and_slide()
		
		if velocity.x:
			lastMovementDirection = sign(velocity.x)
		
		if was_on_floor && !is_on_floor():
			coyote_time.start()
		
		# Jumps if a jump was buffered
		if (is_on_floor() or is_sliding) && !jump_buffer.is_stopped():
			jump_buffer.stop()
			jump()

		if is_on_wall():
			startSlide(direction)

		if (is_on_floor() or is_on_wall()):
			is_jumping = false

		if(position.x != xPositionSliding or is_on_floor()):
			is_sliding = false
			xPositionSliding = null
		
		syncPos = global_position

func kill():
	
	velocity.x = 0
	velocity.y = 0
	if !GameManager.is_solo:
		if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
			if "spawn" in GameManager.players[str(multiplayer.get_unique_id())]:
				position = GameManager.players[str(multiplayer.get_unique_id())].spawn
	else:
		position = GameManager.solo_spawn
	
func _on_kill_pressed():
	kill()
	
func _ready():
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	
func animation(animation_string):
	if !GameManager.is_solo:
		if GameManager.players[str(multiplayer.get_unique_id())].index == 1:
			animation_string += "2"
	animated_sprite.animation = animation_string
	
func jump():
	jump_sound.play()
	is_jumping = true
	var new_speed = velocity.x
	if is_sliding:
		# decreases wall jumps remaining by one
		#wall_jump_remaining -= 1
		new_speed = SPEED * oppositeWallDirection * 2
	velocity.x = new_speed
	velocity.y = JUMP_VELOCITY
	
func startSlide(direction):
	is_sliding = true
	if direction:
		oppositeWallDirection = -direction
	else:
		oppositeWallDirection = -lastMovementDirection
	xPositionSliding = position.x
	
@rpc("any_peer", "call_local")
func arrivee(id):
	GameManager.can_finish_level = false
	GameManager.can_confirm_level = true
	for player in GameManager.players:
		if(GameManager.players[str(id)] == GameManager.players[player]):
			GameManager.players[player].completionPoints += 300
	get_node("/root/Level").graceTime()
			
@rpc("any_peer", "call_local")
func arrivee2(id):
	GameManager.can_finish_level = false
	GameManager.can_confirm_level = false
	for player in GameManager.players:
		if(GameManager.players[str(id)] == GameManager.players[player]):
			if(GameManager.players[player].completionPoints > 0):
				GameManager.players[player].validationPoints += 100
			else:
				GameManager.players[player].completionPoints += 200
	get_node("/root/Level").finishGame()
