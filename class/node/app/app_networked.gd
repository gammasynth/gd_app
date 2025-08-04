extends AppExtendable
class_name AppNetworked

signal ping_calculated
signal server_connect_failed_or_finished

var last_ping_time: float = 0.0

#region Client Parameters
var attempting_server_connect = false
var attempting_server_connect_frames = 0
var attempting_server_connect_ip = null
var attempting_server_connect_port = null

var is_client: bool = false
#endregion


#region Server Parameters

var session_user_profiles: Dictionary[int, UserProfileData] = {}

var banned_peer_ids: Array = []
var banned_usernames: Array = []
#endregion


func send_request_server_ping():
	if multiplayer != null:
		var pid = multiplayer.get_unique_id()
		if pid != null:
			server_ping_was_requested.rpc_id(1, pid)

@rpc("any_peer", "call_local", "reliable")
func server_ping_was_requested(target_id:int, first_ask:bool=true):
	ping.rpc_id(target_id, target_id, first_ask)

@rpc("any_peer", "call_local", "reliable")
func ping(target_id: int, iam_asking: bool = true):  
	if iam_asking:  
		last_ping_time = Time.get_unix_time_from_system()
		server_ping_was_requested.rpc_id(1, target_id, false)
		#ping.rpc_id(target_id, false)  
	else:  
		#var sender_id: int = multiplayer.get_remote_sender_id()
		#print_ping.rpc(sender_id)
		ping_counted()

func ping_counted():
	var ping_delay = Time.get_unix_time_from_system() - last_ping_time
	emit_signal("ping_calculated", ping_delay)

@rpc("any_peer", "call_local", "reliable")      
func print_ping():
	print(str("Ping delay: " + str(Time.get_unix_time_from_system() - last_ping_time )))




func request_disconnect(for_peer):
	#if multiplayer.get_peers().has(for_peer):
		#
	multiplayer.disconnect_peer(for_peer)


func disconnect_all_peers():
	for this_peer in multiplayer.get_peers():
		disconnect_peer(this_peer)
	return OK


func disconnect_peer(pid):
	if multiplayer.get_peers().has(pid):
		multiplayer.disconnect_peer(pid)
		peer_disconnected(pid)

func ban_player_by_name(username:String):
	var id_to_ban = -1
	
	id_to_ban = get_peer_id_from_username(username)
	
	disconnect_peer(id_to_ban)
	banned_peer_ids.append(id_to_ban)
	banned_usernames.append(username)



func peer_disconnected(peer_id):
	
	var username = "user"
	if session_user_profiles.has(peer_id):
		var peer_profile = session_user_profiles[peer_id]
		username = peer_profile.username
	
	AlertManager.create_alert("User disconnected.", str(username + " has left the server."), 2.0, 2.0)
	chat_system.spawn_chat_message(1, "res://src/assets/texture/ui/server_head.png", "server", str(player_name + " has left the server."))
	
	while clients_joining.has(peer_id):
		clients_joining.erase(peer_id)
	
	if current_level == null or not is_instance_valid(current_level):
		while peers_waiting.has(peer_id):
			peers_waiting.erase(peer_id)
	else:
		if current_level.active:
			remove_peer_from_server_world(peer_id)
			
		else:
			while peers_waiting.has(peer_id):
				peers_waiting.erase(peer_id)


func get_peer_id_from_username(playername:String):
	var pid = -1
	for player_id in player_profiles.keys():
		var this_player_profile = player_profiles[player_id]
		if this_player_profile != null and is_instance_valid(this_player_profile):
			if this_player_profile is PlayerProfileData:
				var this_player_profile_name = this_player_profile.player_name
				if this_player_profile_name == playername:
					pid = player_id
					break
	return pid


func disconnect_user_by_name(playername:String):
	var id_to_kick = -1
	
	id_to_kick = get_peer_id_from_username(playername)
	
	if id_to_kick != -1:
		disconnect_peer(id_to_kick)
	
	return OK


func stop_hosting():
	
	is_client = false
	
	if hosting:
		
		banned_peer_ids.clear()
		banned_player_names.clear()
		
		my_peer_id = -1
		
		player_profiles.clear()
		
		if server_port != -1:
			upnp.delete_port_mapping(server_port)
		if peer != null:
			peer.close()
		
		hosting = false
	
	upnp = null
	peer = null
	
	server_name = ""


func stop_client():
	is_client = false
	upnp = null
	peer = null
	
	AlertManager.create_error("Disconnected!", "You were disconnected from the server!", 5.0, 5.0)
	await get_tree().create_timer(4.0).timeout
	get_tree().paused = false
	reboot()

@rpc("any_peer", "call_local", "reliable")
func get_server_info(for_peer):
	var server_info = {}
	
	var peers_total = multiplayer.get_peers().size()
	
	server_info["SERVER_NAME"] = server_name
	server_info["PLAYERS"] = str(peers_total + 1)
	
	receive_server_info.rpc_id(for_peer, server_info)

@rpc("authority", "call_local", "reliable")
func receive_server_info(server_info:Dictionary):
	EventHandler.emit_signal("received_server_info", server_info)

func stop_multiplayer():
	multiplayer.multiplayer_peer.close()
	
	get_tree().set_multiplayer(multiplayer.create_default_interface())
	
	stop_hosting()
	
	set_multiplayer_authority(1)
















func _on_host_game_button_pressed():
	#return
	var ip = "localhost"
	var ip_address :String = ""
	
	#if OS.has_feature("windows"):
		#if OS.has_environment("COMPUTERNAME"):
			#ip_address =  IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
	#elif OS.has_feature("x11"):
		#if OS.has_environment("HOSTNAME"):
			#ip_address =  IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),1)
	#elif OS.has_feature("OSX"):
		#if OS.has_environment("HOSTNAME"):
			#ip_address =  IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),1)
			
	
	
	$LoadingLabel.show()
	await get_tree().process_frame
	await get_tree().process_frame
	
	if NodeControl.game.upnp == null:
		NodeControl.game.upnp = UPNP.new()
	var upnp = NodeControl.game.upnp
	var upnp_err = upnp.discover(2000, 2, "InternetGatewayDevice")
	#print("UPNP Discover: " + str(upnp_err))
	var external_ip = upnp.query_external_address()
	#print("UPNP external address: " + str(external_ip))
	
	if external_ip is String:
		if not external_ip.is_empty():
			ip_address = external_ip
	
	if not ip_address.is_empty():
		ip = ip_address
	
	host_ip_rich_text.text = str("IP: " + str(ip))

	
	play_multiplayer_menu.visible = false
	host_game_menu.visible = true
	NodeControl.game.hosting = true
	
	$LoadingLabel.hide()




func _on_host_ip_button_pressed():
	# Start as server.
	var ip = "localhost"
	var ip_address :String = ""
	
	#if OS.has_feature("windows"):
		#if OS.has_environment("COMPUTERNAME"):
			#ip_address =  IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
	#elif OS.has_feature("x11"):
		#if OS.has_environment("HOSTNAME"):
			#ip_address =  IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),1)
	#elif OS.has_feature("OSX"):
		#if OS.has_environment("HOSTNAME"):
			#ip_address =  IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),1)

	$LoadingLabel.show()
	await get_tree().process_frame
	await get_tree().process_frame

	if NodeControl.game.upnp == null:
		NodeControl.game.upnp = UPNP.new()
	var upnp = NodeControl.game.upnp
	var upnp_err = upnp.discover(2000, 2, "InternetGatewayDevice")
	#print("UPNP Discover: " + str(upnp_err))
	var external_ip = upnp.query_external_address()
	#print("UPNP external address: " + str(external_ip))
	
	if external_ip is String:
		if not external_ip.is_empty():
			ip_address = external_ip
	
	
	var port = host_port_line_edit.text
	if port.is_empty():
		port = 4433
	else:
		port = int(port)
	upnp.add_port_mapping(port)
	NodeControl.game.server_port = port
	
	if not ip_address.is_empty():
		ip = ip_address
	
	
	var peer = ENetMultiplayerPeer.new()
	
	var server_err = peer.create_server(port)
	
	if server_err == ERR_CANT_CREATE:
		AlertManager.create_error("Failed to create server!", "The server failed to initialize on your network!")
		#OS.alert("Failed to start multiplayer server.")
		return
	if server_err == ERR_ALREADY_IN_USE:
		AlertManager.create_error("Server already occupied!", "Cant create server, as there is already an existing server taking this place on your network.")
		return
	
	NodeControl.game.peer = peer
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(NodeControl.game.peer_connected)
	multiplayer.peer_disconnected.connect(NodeControl.game.peer_disconnected)
	NodeControl.game.set_multiplayer_authority(1, true)
	NodeControl.game.my_peer_id = multiplayer.multiplayer_peer.get_unique_id()
	
	var server_name_text = $HostGameMenu/HostGameMenuCenterBox/HostGameMenuVBoxContainer/HBoxContainer2/ServerNameLineEdit.text
	if server_name_text.is_empty():
		server_name_text = "Factory TD Server"
	
	NodeControl.game.server_name = server_name_text
	
	var ip_text = ip
	if show_ip_button.visible == true:
		ip_text = "IP HIDDEN"
	AlertManager.create_alert("Server online!", str("Hosting live game server at IP: " + ip_text + ":" + str(port)))
	
	host_game_menu.visible = false
	host_multi_player_menu.visible = true
	host_multi_player_menu.prompt_menu()
	#start_game()
	
	$LoadingLabel.hide()




func attempt_connect_to_server(ip, port):
	
	NodeControl.game.peer = ENetMultiplayerPeer.new()
	var peer = NodeControl.game.peer
	
	get_tree().paused = true
	
	var connection_err = peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
	
	
	if connection_err == OK:
		join_game_menu.visible = false
		
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
			AlertManager.create_alert("Joining Server...", "Attempting to connect to the requested server IP and port!", 3.0, 5.0)
		
		
		attempting_server_connect_frames = 0
		
		attempting_server_connect_ip = ip
		attempting_server_connect_port = port
		
		attempting_server_connect = true

func _process(delta: float) -> void:
	if attempting_server_connect:
		attempting_server_connect_frames += 1 * delta
		
		var peer = NodeControl.game.peer
		
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED or attempting_server_connect_frames > 300 * delta:
			join_game_menu.visible = true
			
			NodeControl.game.peer = null
			multiplayer.multiplayer_peer = null
			attempting_server_connect = false
			attempting_server_connect_frames = 0
			attempting_server_connect_ip = null
			attempting_server_connect_port = null
			
			get_tree().paused = false
			
			AlertManager.create_alert("Server Unavailable!", "Could not connect to the requested server IP and port!", 3.0, 5.0)
			#OS.alert("Failed to start multiplayer client.")
			return
		
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			attempting_server_connect = false
			attempting_server_connect_frames = 0
			finish_connecting_to_server(peer, attempting_server_connect_ip, attempting_server_connect_port)

func disconnect_from_server():
	
	client_connected_menu.visible = false
	
	join_game_menu.visible = true
	
	var game = NodeControl.game
	
	game.peer = null
	multiplayer.multiplayer_peer = null
	attempting_server_connect = false
	attempting_server_connect_frames = 0
	attempting_server_connect_ip = null
	attempting_server_connect_port = null
	
	game.is_client = false
	game.upnp = null
	game.peer = null
	
	AlertManager.create_error("Disconnected!", "You disconnected from the server!", 2.0, 2.0)


func finish_connecting_to_server(peer, ip, port):
	is_client = true
	app_peer_id = multiplayer.multiplayer_peer.get_unique_id()
	set_multiplayer_authority(1, true)
	
	chatf("connected to host!")
	#AlertManager.create_alert("Connected to server!", str("Connected to server at IP: " + ip + ":" + str(port)))
	
	client_connected_menu.setup_client_menu(ip)


func _on_join_ip_button_pressed():
	# Start as client.
	var ip : String = join_ip_line_edit.text
	var port = join_port_line_edit.text
	if port.is_empty():
		port = 4433
	else:
		port = int(port)
	if ip == "":
		ip = "localhost"
	
	attempt_connect_to_server(ip, port)


func _on_exit_host_game_menu_button_pressed():
	host_game_menu.visible = false
	NodeControl.game.stop_hosting()
	prompt_menu()
