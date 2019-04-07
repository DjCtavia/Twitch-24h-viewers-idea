extends Area2D

const DAMAGE = 25
const TRAVEL_SPEED = 140
const SPACE_SHOT = 35

var direction = Vector2()
var from_player

#============================
#         Help Constructor
#============================

func construct_bullet(projectileName, nDirection, playerPosition, who) -> void:
    direction = nDirection
    from_player = who
    calculBulletRotation(nDirection)
    set_bullet_position(nDirection, playerPosition)
    return

func calculBulletRotation(nDirection) -> void:
    if nDirection.y > 0:
        rotate(rad2deg(180))
        return
    elif nDirection.x > 0:
        rotate(rad2deg(90))
        return
    elif nDirection.x < 0:
        rotate(rad2deg(270))
        return
    rotate(0)
    return


func set_bullet_position(nDirection, playerPosition) -> void:
    var nPosition = playerPosition

    if nDirection.y > 0:
        nPosition.y += SPACE_SHOT
    elif nDirection.y < 0:
        nPosition.y -= SPACE_SHOT
    elif nDirection.x > 0:
        nPosition.x += SPACE_SHOT
    elif nDirection.x < 0:
        nPosition.x -= SPACE_SHOT
    position = nPosition
    return

#============================
#         Physic
#============================
puppet var puppet_position : Vector2 = Vector2()

func _physics_process(delta):
    if is_network_master():
        position += direction * TRAVEL_SPEED * delta
        rset("puppet_position", position)
    else:
        position = puppet_position

#============================
#         Overlapping
#============================

const EXPLODEON = ["Player", "Wall"]

func isValidHit(overlappedObject) -> bool:
    var parentOverlap
    if !is_network_master():
        return false
    parentOverlap = overlappedObject.get_parent()
    if !parentOverlap || !parentOverlap.has_method("Area2D_type"):
        return false
    return true

func _on_Area2D_area_entered(overlappedObject):
    var parentOverlap

    if !isValidHit(overlappedObject):
        return
    parentOverlap = overlappedObject.get_parent()
    if parentOverlap.Area2D_type() == "Player":
        parentOverlap.rpc("take_damage", DAMAGE, from_player)
    for tag in EXPLODEON:
        if parentOverlap.Area2D_type() == tag:
            rpc("delete_item")
            return

remotesync func delete_item():
    queue_free()

func Area2D_type() -> String:
    return "Bullet"