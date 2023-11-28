extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animated_sprite = $AnimatedSprite2D

@onready var tile_map : TileMap = $"../TileMap"

var syncPos = Vector2(0,0)

func _physics_process(delta):
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		if (position.y > 512):
			kill()
		animated_sprite.play()
		# Add the gravity.
		if not is_on_floor():
			velocity.y += gravity * delta
			if (velocity.y <= 0):
				animated_sprite.animation = "jump"
			else:
				animated_sprite.animation = "fall"
		else:
			if(velocity.x == 0):
				animated_sprite.animation = "idle"
			else:
				animated_sprite.animation = "run"
				
		# Handle Jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
			
			if (velocity.x < 0):
				animated_sprite.flip_h = true
			elif (velocity.x > 0):
				animated_sprite.flip_h = false
			
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
		var tile_map_pos = tile_map.local_to_map(Vector2i(position.x, position.y))

		var tile_data : TileData = tile_map.get_cell_tile_data(0, Vector2i(tile_map_pos.x,tile_map_pos.y+1))

		if tile_data:
			var current_data = tile_data.get_custom_data("dead")
			
			if (current_data):
				kill()

		move_and_slide()
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
