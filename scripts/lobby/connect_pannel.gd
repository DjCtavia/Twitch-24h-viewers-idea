extends Panel

func _ready():
    gamestate.connect("connection_success", self, "_hide_connect_pannel")
    gamestate.connect("connection_failed", self, "_connexion_failed")

func _hide_connect_pannel() -> void:
    hide()
    get_parent().get_node("lobby_pannel").show()
    get_parent().get_node("lobby_pannel")._refresh_list()
    if !get_tree().is_network_server():
        get_parent().get_node("lobby_pannel").get_node("StartGame").disabled = true
    return

func _on_host_pressed():
    var name : LineEdit = get_node("name")
    var nameText : String

    if name == null:
        get_node("error").text = "Name node is null"
        return
    nameText = name.text
    if nameText.length() < 3 || nameText == "   ":
        get_node("error").text = "Name is too short, or invalid"
        return
    gamestate.host_server(nameText)
    return

func _on_join_pressed():
    var name : LineEdit = get_node("name")
    var ip : LineEdit = get_node("ip")
    var nameText : String

    if name == null || ip == null || !ip.text.is_valid_ip_address():
        if name == null || ip == null:
            get_node("error").text = "Name or IP node is null"
        else:
            get_node("error").text = "IP is invalid..."
        return
    nameText = name.text
    if nameText.length() < 3 || nameText == "   ":
        get_node("error").text = "Name is too short, or invalid"
        return
    gamestate.join_server(ip.text, name.text)
    return

func _connexion_failed():
    get_node("error").text = "Connection failed..."

func _on_fullscreen_pressed():
    OS.window_fullscreen = get_node("fullscreen").pressed