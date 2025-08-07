extends AppExtendable
class_name AppNetworked

const DEFAULT_IP = "localhost"
@export var default_server_port:int = 9600

signal connected_to_server

signal server_started

signal ping_calculated
signal server_connect_failed_or_finished

var last_ping_time: float = 0.0

#region Client Parameters
## is_client is only true if App is connected to a server.
static var is_client: bool = false

static var ip = DEFAULT_IP

var upnp:UPNP = null
var peer: ENetMultiplayerPeer:
	get: return multiplayer.multiplayer_peer
	set(p): multiplayer.multiplayer_peer = p

static var pid: int = 1:
	get: 
		if App.instance:
			return App.instance.multiplayer.get_unique_id()
		return 1

var attempting_server_connect = false
var server_connecting_delta:float = -1
#endregion


#region Server Parameters
static var is_server: bool = false
var server_name:String = "Server"
var server_ip:String = DEFAULT_IP
var server_port:int = default_server_port
var session_user_profiles: Dictionary[int, UserProfileData] = {}
var server_open:bool = true

var banned_peer_ids: Array = []
var banned_usernames: Array = []
#endregion


#region Data Transfer Parameters
var received_datasets: Dictionary[int, NetworkedData]
#endregion



func send_request_server_ping():
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


## Send data to another peer on the network, via measured Byte packets over RPC.
func send_data(to_pid:int, data:Variant, packet_pause_time:float=0.15, dataset_identifier:int=-1, dataset_name:String="") -> Error:
	
	if dataset_identifier == -1:
		if not dataset_name.is_empty():
			dataset_identifier = hash(str(dataset_name + str(randi())))
		else:
			dataset_identifier = hash(randi())
	
	var MAX_PACKET_SIZE: int = 25000
	var bytes :PackedByteArray = var_to_bytes(data).compress(FileAccess.CompressionMode.COMPRESSION_GZIP)
	
	#var sizeof := 0
	#for bit in var_to_bytes(bytes):
		#sizeof += bit
	#print("client packet bytes after compression: " + str(sizeof))
	
	var byte_count :int = bytes.size()
	#print("client packet byte count: " + str(byte_count))
	
	var packet_count :int = int(ceil(float(byte_count) / float(MAX_PACKET_SIZE)))
	#print("Splitting client packet into " + str(packet_count) + " packets!")
	
	for i in packet_count:
		var start := i * MAX_PACKET_SIZE
		var end := (i+1) * MAX_PACKET_SIZE
		
		if end > byte_count:
			end = byte_count
		
		var this_packet = bytes.slice(start, end)
		
		#var sizeofthis := 0
		#for bit in this_packet:
			#sizeofthis += bit
		#print("packet #" + str(i + 1) + "bytes: " + str(this_packet.size()))
		
		await send_packet(to_pid, this_packet, i, packet_count, dataset_identifier, dataset_name)
		await get_tree().create_timer(packet_pause_time).timeout
	
	return OK

func send_packet(to_pid:int, data: PackedByteArray, packet_number: int, total_packet_count: int, dataset_identifier:int=-1, dataset_name:String="") -> void:
	receive_data.rpc_id(to_pid, App.pid, data, packet_number, total_packet_count, dataset_identifier, dataset_name)



@rpc("any_peer", "reliable")
func receive_data(from_pid:int, data:PackedByteArray, packet_number:int, total_packet_number:int, dataset_identifier:int, dataset_name:String):
	
	var sender:String = "server"; if from_pid != 1: sender = "peer"
	AlertSystem.create_alert("Receiving Data!", 
	str("Receiving networked data from " + sender + ", packet " + str(packet_number + 1) + " out of " + str(total_packet_number) + "..."))
	
	var networked_data:NetworkedData = null
	if received_datasets.has(dataset_identifier):
		networked_data = received_datasets.get(dataset_identifier)
	else:
		networked_data = NetworkedData.new(dataset_name, dataset_identifier)
		received_datasets.set(dataset_identifier, networked_data)
	
	networked_data.received_packets[packet_number] = data
	#await get_tree().create_timer(1.5).timeout
	
	if networked_data.received_packets.size() == total_packet_number:
		#client_pulled_all_packets.rpc_id(1, client_id)
		var packets := networked_data.received_packets
		var full_data: PackedByteArray = []
		
		for i in total_packet_number:
			full_data.append_array(packets[i])
		#var sizeof := 0
		#for bit in var_to_bytes(full_data):
			#sizeof += bit
		print("client packet bytes after receiving: " + str(full_data.size()))
		
		var loaded_data = await full_data.decompress_dynamic(-1, FileAccess.CompressionMode.COMPRESSION_GZIP)
		#var sizeoffull := 0
		#for bit in var_to_bytes(loaded_data):
			#sizeoffull += bit
		#print("client packet bytes after decompress: " + str(sizeoffull))
	return



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

#func ban_player_by_name(username:String):
	#var id_to_ban = -1
	#
	#id_to_ban = get_peer_id_from_username(username)
	#
	#disconnect_peer(id_to_ban)
	#banned_peer_ids.append(id_to_ban)
	#banned_usernames.append(username)


func peer_connected(peer_id:int):
	if not server_open:
		disconnect_peer(peer_id)
		return
	
	if banned_peer_ids.has(peer_id):
		disconnect_peer(peer_id)
		return
	
	


func peer_disconnected(peer_id):
	
	var username = "user"
	if session_user_profiles.has(peer_id):
		var peer_profile = session_user_profiles[peer_id]
		username = peer_profile.username
	
	AlertSystem.create_alert("User disconnected.", str(username + " has left the server."), 2.0, 2.0)
	ChatSystem.send_message(str(username + " has left the server."), "Server")
	
	# TODO HERE you can remove the peer from any lists they may have been in
	#while clients_joining.has(peer_id):
		#clients_joining.erase(peer_id)
	#
	#if current_level == null or not is_instance_valid(current_level):
		#while peers_waiting.has(peer_id):
			#peers_waiting.erase(peer_id)
	#else:
		#if current_level.active:
			#remove_peer_from_server_world(peer_id)
			#
		#else:
			#while peers_waiting.has(peer_id):
				#peers_waiting.erase(peer_id)

# TODO HERE you can pull peer_id from a username
#func get_peer_id_from_username(username:String):
	#var pid = -1
	#for player_id in player_profiles.keys():
		#var this_player_profile = player_profiles[player_id]
		#if this_player_profile != null and is_instance_valid(this_player_profile):
			#if this_player_profile is PlayerProfileData:
				#var this_player_profile_name = this_player_profile.player_name
				#if this_player_profile_name == playername:
					#pid = player_id
					#break
	#return pid


#func disconnect_user_by_name(playername:String):
	#var id_to_kick = -1
	#
	#id_to_kick = get_peer_id_from_username(playername)
	#
	#if id_to_kick != -1:
		#disconnect_peer(id_to_kick)
	#
	#return OK



#@rpc("any_peer", "call_local", "reliable")
#func get_server_info(for_peer):
	#var server_info = {}
	#
	#var peers_total = multiplayer.get_peers().size()
	#
	#server_info["SERVER_NAME"] = server_name
	#server_info["PLAYERS"] = str(peers_total + 1)
	#
	#receive_server_info.rpc_id(for_peer, server_info)

#@rpc("authority", "call_local", "reliable")
#func receive_server_info(server_info:Dictionary):
	#EventHandler.emit_signal("received_server_info", server_info)


func stop_client():
	is_client = false
	upnp = null
	peer = null


func host_server():
	if not upnp: upnp = UPNP.new()
	var upnp_err:Error = upnp.discover(2000, 2, "InternetGatewayDevice")# TODO can check upnp error here for debugs
	var external_ip = upnp.query_external_address()
	if external_ip is String and not external_ip.is_empty(): ip = external_ip
	server_ip = ip
	
	is_server = true
	upnp.add_port_mapping(server_port)
	
	peer = ENetMultiplayerPeer.new()
	var server_err:Error = peer.create_server(server_port)# TODO can check server error here for debugs
	
	if server_err == ERR_CANT_CREATE:
		AlertSystem.create_error("Failed to create server!", "The server failed to initialize on your network!")
		#OS.alert("Failed to start multiplayer server.")
		stop_server()
		return
	if server_err == ERR_ALREADY_IN_USE:
		AlertSystem.create_error("Server already occupied!", "Cant create server, as there is already an existing server taking this place on your network.")
		stop_server()
		return
	
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	#set_multiplayer_authority(1, true)
	
	AlertSystem.create_alert("Server online!", str("Hosting live game server at IP: " + server_ip + ":" + str(server_port)))
	server_started.emit()

func stop_server():
	#banned_peer_ids.clear()
	#banned_player_names.clear()
	session_user_profiles.clear()
	
	if upnp: upnp.delete_port_mapping(server_port)
	if peer: peer.close()
	
	is_server = false
	server_name = "Server"
	
	stop_client()



func connect_to_server(to_ip:String="localhost", at_port:int=default_server_port):
	
	peer = ENetMultiplayerPeer.new()
	#get_tree().paused = true
	
	var connection_err = peer.create_client(to_ip, at_port)
	if connection_err == OK:
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
			AlertSystem.create_alert("Joining Server...", "Attempting to connect to the requested server IP and port!", 3.0, 5.0)
		
		server_ip = to_ip
		server_port = at_port
		
		attempting_server_connect = true
		server_connecting_delta = 0.0

func stop_server_connect(failed:bool=true) -> void:
	attempting_server_connect = false
	server_connecting_delta = 0
	if failed:
		server_ip = DEFAULT_IP
		server_port = default_server_port

func _process(delta: float) -> void:
	if attempting_server_connect:
		server_connecting_delta += 1 * delta
		
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED or server_connecting_delta > 60:
			stop_server_connect()
			stop_client()
			AlertSystem.create_alert("Server Unavailable!", "Could not connect to the requested server IP and port!", 3.0, 5.0)
			#OS.alert("Failed to start multiplayer client.")
			return
		
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			stop_server_connect(true)
			finish_connecting_to_server()#(peer, attempting_server_connect_ip, attempting_server_connect_port)

func finish_connecting_to_server():#(peer, ip, port):
	is_client = true
	#set_multiplayer_authority(1, true)
	
	AlertSystem.create_alert("Server", "Connected to server!")
	ChatSystem.send_message("Connected to server.", "^&")
	#AlertSystem.create_alert("Connected to server!", str("Connected to server at IP: " + ip + ":" + str(port)))
	
	connected_to_server.emit()

func disconnect_from_server():
	stop_client()
	AlertSystem.create_error("Disconnected!", "You disconnected from the server!", 2.0, 2.0)
