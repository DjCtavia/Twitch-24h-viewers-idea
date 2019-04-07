extends Area2D

const NAME = "BananaDrunk"
const TEXTURE = "res://Sprites/overlay/bonus-item-BananaDrunk2.png"

func _on_Area2D_area_entered(overlappedObject):
    var parentOverlap

    if !is_network_master():
        return
    parentOverlap = overlappedObject.get_parent()
    if parentOverlap && parentOverlap.has_method("Area2D_type") && \
        parentOverlap.Area2D_type() == "Player" && !parentOverlap.has_powerUp():
            parentOverlap.set_powerUp(NAME, TEXTURE)
            rpc("delete_item")

remotesync func delete_item():
    queue_free()

func Area2D_type() -> String:
    return "PowerUp"