extends Panel

# Server variable only
var playersReady = [] 

func _ready():
    gamestate.connect("refresh_list", self, "_refresh_list")

#============================
#       Custom signals
#============================

# Refresh player list in lobby
func _refresh_list() -> void:
    var playerList : ItemList = get_node("playerList")

    if ItemList == null:
        return
    playerList.clear()
    playerList.add_item(gamestate.pseudo + " (Vous)")
    for playerID in gamestate.players:
        playerList.add_item(gamestate.players[playerID]["pseudo"])
    refresh_player_number()
    return

func refresh_player_number() -> void:
    get_node("playerNumber").bbcode_text = "Players: " + str(gamestate.players.size()+1) + "/[color=#ff0000]" + str(gamestate.MAX_PEERS) + "[/color]"
    return

#============================
#       Button signals
#============================

    # WIP - Block player connection
func _on_CheckButton_pressed():
    var isBlocked = get_node("connectionBlock").pressed

    get_tree().set_refuse_new_network_connections(isBlocked)
    return

# Host only - Start game
func _on_StartGame_pressed():
    get_tree().set_pause(true)
    set_players_in_team()
    pre_load_world()
    pre_load_characters()
    rpc("pre_load_game")
    if gamestate.players.size() == 0:
        start_game()
    return

#============================
#       Pre-Start-Game
#============================

# Host - Set player team before beginning of the game
func set_players_in_team() -> void:
    var teamBlue = 0
    var teamRed = 0
    var playerToTeam = [1]
    var iPicked

    for idPlayer in gamestate.players:
        playerToTeam.append(idPlayer)
    while playerToTeam.size() != 0:
        iPicked = randi() % playerToTeam.size()
        if teamBlue < teamRed:
            rpc("set_team", playerToTeam[iPicked], 0)
            teamBlue += 1
        else:
            rpc("set_team", playerToTeam[iPicked], 1)
            teamRed += 1
        playerToTeam.remove(iPicked)
    return

remotesync func set_team(playerID, nTeam):
    if get_tree().get_network_unique_id() == playerID:
        gamestate.team = nTeam
        return
    gamestate.players[playerID]["team"] = nTeam

# Host - Set spawn for beginning of the game
func set_players_spawn(var level):
    var blueSpawn = level.get_node("blueSpawn").get_children()
    var redSpawn = level.get_node("redSpawn").get_children()
    var iPicked = pick_spawn(1, blueSpawn, redSpawn)

    if iPicked[0] == 0:
        blueSpawn.remove(iPicked[1])
    else:
        redSpawn.remove(iPicked[1])
    rpc("_set_position", 1, iPicked[2])
    for player in gamestate.players:
        iPicked = pick_spawn(player, blueSpawn, redSpawn)
        if iPicked[0] == 0:
            blueSpawn.remove(iPicked[1])
        else:
            redSpawn.remove(iPicked[1])
        rpc("_set_position", player, iPicked[2])
    return

func pick_spawn(id : int, blueSpawn, redSpawn) -> Array:
    var team
    var pickedIndex
    var position

    if id == 1:
        team = gamestate.team
    else:
        team = gamestate.players[id]["team"]
    if team == 0:
        pickedIndex = randi() % blueSpawn.size()
        position = blueSpawn[pickedIndex].position
    else:
        pickedIndex = randi() % redSpawn.size()
        position = redSpawn[pickedIndex].position
    return [team, pickedIndex, position]

# Host and Clients - Set spawn position
remotesync func _set_position(playerID, position):
    if get_tree().get_network_unique_id() == playerID:
        gamestate.spawn = position
        return
    print("N spawn has been savec: " + str(position))
    gamestate.players[playerID]["spawn"] = position   

# Load and create the world
func pre_load_world() -> void:
    var level = preload("res://scenes/maps/de_jungle.tscn").instance()

    get_tree().get_root().add_child(level)
    if get_tree().is_network_server():
        set_players_spawn(get_node("/root/world"))

# Load every character and add them to the world
func pre_load_characters() -> void:
    var myPlayer = preload("res://scenes/characters/fidji.tscn").instance()
    var myPeer = get_tree().get_network_unique_id()
    
    myPlayer.set_name(str(myPeer))
    myPlayer.set_team(gamestate.team)
    myPlayer.position = gamestate.spawn
    myPlayer.master_constructor()
    myPlayer.set_network_master(myPeer)
    get_node("/root/world/players").add_child(myPlayer)
    for playerID in gamestate.players:
        var otherPlayer = preload("res://scenes/characters/fidji.tscn").instance()

        otherPlayer.set_name(str(playerID))
        otherPlayer.set_team(gamestate.players[playerID]["team"])
        otherPlayer.puppet_constructor()
        otherPlayer.position = gamestate.players[playerID]["spawn"]
        otherPlayer.set_network_master(playerID)
        get_node("/root/world/players").add_child(otherPlayer)

# Client - Load and send information to server when end loading
remote func pre_load_game() -> void:
    get_tree().set_pause(true)
    pre_load_world()
    pre_load_characters()
    rpc_id(1, "finished_to_load", get_tree().get_network_unique_id())
    return

#============================
#        Start-Game
#============================

# Host - Detect when every player had load the world
remote func finished_to_load(id) -> void:
    playersReady.append(id)
    if playersReady.size() == gamestate.players.size():
        rpc("start_game")
    return

# Host and Client - Start game
remotesync func start_game() -> void:
    print("Team:" + str(gamestate.team))
    playersReady.clear()
    if has_node("/root/world"):
        get_node("/root/world").show()
    get_parent().hide()
    get_tree().set_pause(false)