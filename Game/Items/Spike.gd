extends "res://Game/Items/items.gd"

func _init():
	scene = load("res://Game/Items/spike.tscn")

func _on_body_entered(body):
	if body.has_method("kill"):
		body.kill()
