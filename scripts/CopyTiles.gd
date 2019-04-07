tool
extends Node2D

export(bool) var reset setget active_copy
export(Vector2) var size
export(int) var test

export(bool) var const_script setget set_const_script

func _process(delta):
    if Engine.editor_hint:
        test += 1

func set_const_script(value):
    if Engine.is_editor_hint:
        const_script = value
        print("One two")


func active_copy(value):
    if value:
        reset = false
    get_tile_maps()

func get_tile_maps():
    print("Rhello")
    var tileMaps = []