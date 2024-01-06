extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animated_sprite = $AnimatedSprite2D

@onready var tile_map : TileMap = $"../TileMap"
@onready var coyote_time = $CoyoteTime
@onready var jump_buffer = $JumpBuffer
var wall_jump_remaining

var syncPos = Vector2(0,0)

func _physics_process(delta):
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		if (position.y > 512):
			kill()
		animated_sprite.play()
		
		# Add the gravity.
		if not is_on_floor():
			if is_on_wall():
				velocity.y = move_toward(velocity.y, 180, gravity * delta)
			else:
				velocity.y = move_toward(velocity.y, 980, gravity * delta)
			if (velocity.y <= 0):
				animated_sprite.animation = "jump"
			else:
				if is_on_wall():
					animated_sprite.animation = "wall_jump"
				else:
					animated_sprite.animation = "fall"
		else:
			if(velocity.x == 0):
				animated_sprite.animation = "idle"
			else:
				animated_sprite.animation = "run"

		# move_and_slide() is called is_on_floor() is updated but was_on_floor keep the previous value
		var was_on_floor = is_on_floor()
		
		if is_on_floor():
			wall_jump_remaining = 1
		
		var acceleration
		if !is_on_floor():
			acceleration = 37.5
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
		
		# Handle Jump.
		if Input.is_action_just_pressed("ui_accept") and velocity.y >= 0:
			# Jump / Wall-jump
			if ((is_on_floor() or !coyote_time.is_stopped()) or (is_on_wall() and wall_jump_remaining)):
				var new_speed = velocity.x
				coyote_time.stop()
				if is_on_wall() && !is_on_floor():
					wall_jump_remaining = 1
					new_speed = SPEED * direction * -2
				velocity.x = new_speed
				velocity.y = JUMP_VELOCITY
			# Buffers jump if not on floor
			else:
				jump_buffer.start()
			
		var tile_map_pos = tile_map.local_to_map(Vector2i(position.x, position.y))

		var tile_data : TileData = tile_map.get_cell_tile_data(0, Vector2i(tile_map_pos.x,tile_map_pos.y+1))

		if tile_data:
			if(tile_data.get_custom_data("dead")):
				kill()
			if(tile_data.get_custom_data("end")):
				if(GameManager.canFinishLevel):
					rpc("arrivee", multiplayer.get_unique_id())
					for player in GameManager.Players:
						if(GameManager.Players[str(multiplayer.get_unique_id())] != GameManager.Players[player]):
							GameManager.Players[str(multiplayer.get_unique_id())].spawn = GameManager.Players[player].spawn
					kill()
				elif(GameManager.canConfirmLevel):
					rpc("arrivee2", multiplayer.get_unique_id())
						

		move_and_slide()
		
		if was_on_floor && !is_on_floor():
			coyote_time.start()
		
		# Jumps if a jump was buffered
		if is_on_floor() && !jump_buffer.is_stopped():
			jump_buffer.stop()
			velocity.y = JUMP_VELOCITY
			
		syncPos = global_position
	
	else:
		global_position = global_position.lerp(syncPos, .5)

func kill():
	velocity.x = 0
	velocity.y = 0
	if "spawn" in GameManager.Players[str(multiplayer.get_unique_id())]:
		#print(GameManager.Players[str(multiplayer.get_unique_id())].spawn) #replace this by your actual code
		position = GameManager.Players[str(multiplayer.get_unique_id())].spawn

func _on_kill_pressed():
	kill()
	
	
func _ready():
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	
@rpc("any_peer", "call_local")
func arrivee(id):
	GameManager.canFinishLevel = false
	GameManager.canConfirmLevel = true
	for player in GameManager.Players:
		if(GameManager.Players[str(id)] == GameManager.Players[player]):
			GameManager.Players[player].points += 300
		else:
			GameManager.Players[player].points += 0
			
@rpc("any_peer", "call_local")
func arrivee2(id):
	GameManager.canFinishLevel = false
	GameManager.canConfirmLevel = false
	for player in GameManager.Players:
		if(GameManager.Players[str(id)] == GameManager.Players[player]):
			if(GameManager.Players[player].points == 300):
				GameManager.Players[player].points += 100
			else:
				GameManager.Players[player].points += 200
		else:
			GameManager.Players[player].points += 0
