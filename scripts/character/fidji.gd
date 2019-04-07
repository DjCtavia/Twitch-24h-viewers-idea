extends KinematicBody2D

# textures
var redArrowUp = preload("res://Sprites/Multiplayer/red-arrow-r.png")
var redArrowDown = preload("res://Sprites/Multiplayer/red-arrow.png")
var blueArrowUp = preload("res://Sprites/Multiplayer/blue-arrow-r.png")
var blueArrowDown = preload("res://Sprites/Multiplayer/blue-arrow.png")

onready var animation = get_node("AnimationPlayer")
onready var weaponAnimation = get_node("AnimationWeapons")

var cooldownShot : Timer = Timer.new()

func _ready():
    cooldownShot.connect("timeout", self, "_cooldown_shoot")
    killFeedTimer.connect("timeout", self, "_clean_killfeed")
    killFeedTimer.start(15)
    add_child(cooldownShot)
    add_child(killFeedTimer)

#============================
#        Constructor
#============================

func set_team(color : int) -> void:
    if color == 0:
        get_node("upper_arrow").texture = redArrowUp
        get_node("downside_arrow").texture = redArrowDown
    else:
        get_node("upper_arrow").texture = blueArrowUp
        get_node("downside_arrow").texture = blueArrowDown

func master_constructor() -> void:
    get_node("Camera2D").current = true
    get_node("overlay").show()

func puppet_constructor() ->  void:
    get_node("Camera2D").queue_free()
    get_node("overlay").hide()

#============================
#        Animation
#============================

var currentAnimation : String = "idle_front"

func changeAnimation(hasMoved, direction):
    var nAnime

    if !hasMoved:
        if currentAnimation == "run_front":
            nAnime = "idle_front"
        elif currentAnimation == "run_back":
            nAnime = "idle_back"
        elif currentAnimation == "run_left":
            nAnime = "idle_left"
        elif currentAnimation == "run_right":
            nAnime = "idle_right"
    else:
        if direction == "front":
            nAnime = "run_front"
        elif direction == "back":
            nAnime = "run_back"
        elif direction == "left":
            nAnime = "run_left"
        elif direction == "right":
            nAnime = "run_right"
    if nAnime != null && nAnime != currentAnimation:
        currentAnimation = nAnime
        animation.play(nAnime)
        rpc("playAnimation", nAnime)

puppet func playAnimation(nAnime):
    get_node("AnimationPlayer").play(nAnime)

func detect_movement(aMovement) -> void:
    if aMovement.x != 0 || aMovement.y != 0:
        if aMovement.y != 0:
            if aMovement.y > 0:
                changeAnimation(true, "front")
            elif aMovement.y < 0:
                changeAnimation(true, "back")
        if aMovement.x != 0:
            if aMovement.x < 0:
                changeAnimation(true, "left")
            elif aMovement.x > 0:
                changeAnimation(true, "right")
    else:
        changeAnimation(false, "none")
    return

#============================
#        Physic
#============================

const WALK_SPEED = 90
const RUN_SPEED = 130
var bonus_speed : float = 1
var movement : Vector2

var canMove = true

puppet var puppet_position : Vector2 = Vector2()

func _physics_process(_delta):
    if is_network_master():
        use_powerUp()
        open_fire()
        if canMove:
            move_and_animate(_delta)
    else:
        position = puppet_position

func move_and_animate(delta) -> void:
    movement = Vector2()
    if Input.is_action_pressed("move_up"):
        movement -= Vector2(0, 1)
    if Input.is_action_pressed("move_down"):
        movement += Vector2(0, 1)
    if Input.is_action_pressed("move_left"):
        movement -= Vector2(1, 0)
    if Input.is_action_pressed("move_right"):
        movement += Vector2(1, 0)
    detect_movement(movement)
    apply_movement(delta)
    return

func apply_movement(delta) -> void:
    if Input.is_action_pressed("run"):
        move_and_slide(movement * RUN_SPEED * bonus_speed)
        rset("puppet_position", position)
        return
    move_and_slide(movement * WALK_SPEED * bonus_speed)
    rset("puppet_position", position)
    return

#============================
#         Items
#============================

var item_picked
var canUsePowerUp = true
onready var coolDownPowerUp = get_node("PowerUpCoolDown")

func has_powerUp() -> bool:
    return item_picked != null

func set_powerUp(nPowerUpName, texturePath):
    var texturePreload = load(texturePath)

    item_picked = {"Name": nPowerUpName, "Texture": texturePath}
    get_node("overlay/powerUp").texture = texturePreload

func set_canUsePowerUp(nCanUsePowerUp : bool) -> void:
    canUsePowerUp = nCanUsePowerUp

func use_powerUp() -> void:
    var defaultTexturePowerUp
    if item_picked == null || !canUsePowerUp || !Input.is_action_pressed("use_power"):
        return
    defaultTexturePowerUp = preload("res://Sprites/overlay/bonus-item-empty.png")
    canUsePowerUp = false
    if item_picked["Name"] == "BananaDrunk":
        coolDownPowerUp.play("BananaDrunk")
    item_picked = null
    get_node("overlay/powerUp").texture = defaultTexturePowerUp

#============================
#         Bonus
#============================

func speed_boost(value : float):
    bonus_speed = value

#============================
#         Stats
#============================

const MAX_LIFE = 100
var life = MAX_LIFE

master func take_damage(damage, from) -> void:
    print("get damage")
    if !canTakeDamage:
        return
    life -= damage
    print("Current life: " + str(life))
    if life <= 0:
        set_dead()
        rpc("set_dead")
        print(str(get_tree().get_network_unique_id()) + " = " + str(from) + " " + str(gamestate.players))
        if from != get_tree().get_network_unique_id():
            rpc("has_been_killed_by", gamestate.players[from]["pseudo"], gamestate.pseudo, false)
            has_been_killed_by(gamestate.players[from]["pseudo"], gamestate.pseudo, false)
            return
        rpc("has_been_killed_by", gamestate.pseudo, gamestate.pseudo, true)
        has_been_killed_by(gamestate.pseudo, gamestate.pseudo, true)
    else:
        rpc("has_take_damage", damage)
    return

puppet func has_take_damage(damage) -> void:
    life -= damage
    return

# Character died, player can't move until respawn
puppet func set_dead() -> void:
    life = MAX_LIFE
    deathHandler(true)
    return

#============================
#         Shoot
#============================

var shot_index = 0
var can_shoot : bool = true

func _cooldown_shoot():
    can_shoot = true

func open_fire() -> void:
    var nDirection

    if !is_network_master() || !can_shoot:
        return
    if Input.is_action_pressed("shoot_up"):
        nDirection = Vector2(0 , -1)
    elif Input.is_action_pressed("shoot_down"):
        nDirection = Vector2(0 , 1)
    elif Input.is_action_pressed("shoot_left"):
        nDirection = Vector2(-1 , 0)
    elif Input.is_action_pressed("shoot_right"):
        nDirection = Vector2(1 , 0)
    else:
        return
    can_shoot = false
    cooldownShot.start(0.4)
    #weaponAnimation.play("shoot")
    rpc("load_projectile", get_name() + str(shot_index), nDirection, position, get_tree().get_network_unique_id())
    shot_index += 1
    return

remotesync func load_projectile(projectileName, nDirection, player_position, who) -> void:
    var projectile = preload("res://scenes/items/BananaBullet.tscn").instance()

    projectile.set_name(projectileName)
    projectile.construct_bullet(projectileName, nDirection, player_position, who)
    get_node("/root/world").add_child(projectile)

#============================
#         Death
#============================

onready var deathHandlerCooldown = get_node("deathHandler")
var spawnPoint
var canTakeDamage = true

func deathHandler(isDead : bool):
    if !isDead:
        canTakeDamage = true
        canMove = true
        can_shoot = true
        get_node("Sprite").show()
        get_node("upper_arrow").show()
        get_node("downside_arrow").show()
        collisionDetect(true)
    else:
        canTakeDamage = false
        canMove = false
        can_shoot = false
        cooldownShot.stop()
        get_node("Sprite").hide()
        get_node("upper_arrow").hide()
        get_node("downside_arrow").hide()
        collisionDetect(false)
        if is_network_master():
            deathHandlerCooldown.play("RespawnPlayer")

func collisionDetect(doCollide : bool):
    var collider = get_node("Area2D")

    if doCollide:
        collider.monitoring = true
        collider.monitorable = true
        get_node("CollisionShape2D").disabled = false
    else:
        collider.monitoring = false
        collider.monitorable = false
        get_node("CollisionShape2D").disabled = true

func getRespawnPoint() -> void:
    var arraySpawn = get_node("/root/world/redSpawn").get_children() if (gamestate.team == 1) else get_node("/root/world/blueSpawn").get_children()
    var randomPoint = randi() % arraySpawn.size()

    spawnPoint = arraySpawn[randomPoint].position

func preventRespawnPlayer():
    if is_network_master():
        getRespawnPoint()
        rpc("respawnPlayer", spawnPoint)
        respawnPlayer(spawnPoint)
    return

puppet func respawnPlayer(nSpawn):
    position = nSpawn
    deathHandler(false)

#======================================
#         Area2D Authentification
#======================================

func Area2D_type() -> String:
    return "Player"

#======================================
#              Kill Feed
#======================================

onready var killFeedRichLabel = get_node("overlay/killFeed")
var killFeedTimer : Timer = Timer.new()

func _clean_killfeed():
    killFeedRichLabel.bbcode_text = ""
    killFeedTimer.start(15)
    return

puppet func has_been_killed_by(killer : String, killed : String, isSame : bool):
    if isSame:
        killFeedRichLabel.bbcode_text = "[center]" + killer + " [color=red]commited a suicide...[/color][/center]"
        return
    killFeedRichLabel.bbcode_text = "[center]" + killer + "[color=red]killed[/color] " + killed + "[/center]"
    return