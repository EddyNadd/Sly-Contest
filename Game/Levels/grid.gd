extends Node2D

# External node variables
@onready var tile_map : TileMap = $"../TileMap"
@onready var btn_grid = get_node("../Control/CanvasLayer/PanelContainer/MarginContainer/GridContainer/ToggleGrid")

var size_half = Vector2i(31,31) # Size in tiles of one half of the screen
var grid_size # Size in global values of one half of the screen
var cells_amount

var is_drawing_grid = false

func _ready():
	grid_size = tile_map.map_to_local(Vector2i(size_half.x, size_half.y))
	cells_amount = Vector2i(grid_size.x/GameManager.TILE_SIZE+1, grid_size.y/GameManager.TILE_SIZE+1)
	btn_grid.connect("pressed", _on_toggle_grid_pressed)

func _on_toggle_grid_pressed():
	is_drawing_grid = !is_drawing_grid
	queue_redraw()

func _draw():
	if is_drawing_grid && $"../MultiplayerSynchronizer".get_multiplayer_authority() == GameManager.Players[str(multiplayer.get_unique_id())].index:
		# Draws vertical grid lines
		for i in cells_amount.x:
			var from = Vector2(i*GameManager.TILE_SIZE, 0)
			var to = Vector2(from.x, grid_size.y)
			draw_line(from, to, Color(Color.BLACK,0.5))

		# Draws horizontal grid lines
		for i in cells_amount.y:
			var from = Vector2(0, GameManager.TILE_SIZE*i)
			var to = Vector2(grid_size.x, from.y)
			draw_line(from, to, Color(Color.BLACK,0.5))
			
	elif is_drawing_grid && $"../MultiplayerSynchronizer".get_multiplayer_authority() != GameManager.Players[str(multiplayer.get_unique_id())].index:
		# Draws vertical grid lines
		for i in cells_amount.x:
			var from = Vector2(i*GameManager.TILE_SIZE + GameManager.TILE_SIZE*size_half.x, 0)
			var to = Vector2(from.x, grid_size.y)
			draw_line(from, to, Color(Color.BLACK,0.5))

		# Draws horizontal grid lines
		for i in cells_amount.y:
			var from = Vector2(GameManager.TILE_SIZE*size_half.x, GameManager.TILE_SIZE*i)
			var to = Vector2(grid_size.x + GameManager.TILE_SIZE*size_half.x, from.y)
			draw_line(from, to, Color(Color.BLACK,0.5))
