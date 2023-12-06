extends Node2D

@onready var tile_map : TileMap = $"../TileMap"
@onready var btnGrid = get_node("../Control/CanvasLayer/PanelContainer/MarginContainer/GridContainer/ToggleGrid")

var size_half = Vector2i(31,31)
var grid_size
#var grid_size = DisplayServer.screen_get_size() #Gets grid size based on the size of the screen
var cell_size = Vector2i(16,16)
var cells_amount

var draw_grid = false

func _ready():
	grid_size = tile_map.map_to_local(Vector2i(size_half.x, size_half.y))
	cells_amount = Vector2i(grid_size.x/cell_size.x+1, grid_size.y/cell_size.y+1)
	btnGrid.connect("pressed", _on_toggle_grid_pressed)

func _on_toggle_grid_pressed():
	draw_grid = !draw_grid
	queue_redraw()

func _draw():
	if draw_grid:
		# Draws vertical grid lines
		for i in cells_amount.x:
			var from = Vector2(i*cell_size.x, 0)
			var to = Vector2(from.x, grid_size.y)
			draw_line(from, to, Color(Color.BLACK,0.5))

		# Draws horizontal grid lines
		for i in cells_amount.y:
			var from = Vector2(0, cell_size.y*i)
			var to = Vector2(grid_size.x, from.y)
			draw_line(from, to, Color(Color.BLACK,0.5))
