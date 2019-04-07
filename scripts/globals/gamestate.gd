extends Node

# --== Network Section ==--
# Default game port
const DEFAULT_PORT = 10567
# Max number of players
const MAX_PEERS = 12
var pseudo : String = "Fidji"
var team : int
var spawn : Vector2
var players = {}

signal connection_success()
signal connection_failed()
signal refresh_list()

func _ready():
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connection_failed")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	get_tree().connect("network_peer_disconnected", self, "_peer_disconnected")

func host_server(nPseudo : String) -> void:
	var peer = NetworkedMultiplayerENet.new()

	pseudo = nPseudo
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(peer)
	emit_signal("connection_success")
	return

func join_server(ipAddress : String, nPseudo : String) -> void:
	var peer = NetworkedMultiplayerENet.new()

	pseudo = nPseudo
	peer.create_client(ipAddress, DEFAULT_PORT)
	get_tree().set_network_peer(peer)
	return

# client | Connexion au serveur réussie
func _connected_ok():
	rpc("add_new_player", get_tree().get_network_unique_id(), pseudo)
	emit_signal("connection_success")
	pass

remote func add_new_player(nId : int, nPlayerPseudo : String):
	if (get_tree().is_network_server()):
		rpc_id(nId, "add_new_player", 1, pseudo)
		for playerID in players:
			rpc_id(nId, "add_new_player", playerID, players[playerID]["pseudo"])
			rpc_id(playerID, "add_new_player", nId, nPlayerPseudo)
		pass
	players[nId] = { "pseudo": nPlayerPseudo }
	emit_signal("refresh_list")

# client | Connexion failed
func _connection_failed():
	print("Failed...")
	emit_signal("connection_failed")
	return