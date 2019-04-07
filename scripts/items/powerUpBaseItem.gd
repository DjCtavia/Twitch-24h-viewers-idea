extends Area2D

onready var spriteTexture = get_node("object")
export (String) var defaultPowerUpName = ""
export (String) var defaultTexturePath = ""
var powerUpName : String
var texturePath : String

func _ready():
    var loadTexture = load(defaultTexturePath)

    powerUpName = defaultPowerUpName
    texturePath = defaultTexturePath

func _construct_custom(nPowerUpName : String, powerUpTexturePath : String):
    var loadTexture = load(powerUpTexturePath)

    spriteTexture.texture = loadTexture
    powerUpName = nPowerUpName
    texturePath = powerUpTexturePath

func _on_RetrievablePowerUp_area_entered(overlappedObject):
    if !is_network_master():
        return
    if overlappedObject.has_method("Area2D_type") && overlappedObject.Area2D_type() == "Player" && !overlappedObject.has_has_powerUp():
        overlappedObject.set_powerUp(powerUpName, texturePath)

func Area2D_type() -> String:
    return "PowerUp"