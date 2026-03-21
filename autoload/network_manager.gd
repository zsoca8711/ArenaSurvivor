extends Node

signal server_created(code: String, ip: String)
signal joined_server
signal join_failed
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)

var room_code: String = ""
var is_host: bool = false
var is_online: bool = false
var connected_peers: Array[int] = []

const GAME_PORT = 7777
const BROADCAST_PORT = 7776
const BROADCAST_INTERVAL = 0.5

var _udp_broadcast: PacketPeerUDP
var _udp_listen: PacketPeerUDP
var _broadcast_timer: float = 0.0
var _searching: bool = false
var _search_code: String = ""


func create_server() -> bool:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(GAME_PORT, 4)
	if error != OK:
		return false
	multiplayer.multiplayer_peer = peer
	is_host = true
	is_online = true
	room_code = "%05d" % (randi() % 90000 + 10000)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	# Start UDP broadcast
	_udp_broadcast = PacketPeerUDP.new()
	_udp_broadcast.set_broadcast_enabled(true)
	_udp_broadcast.set_dest_address("255.255.255.255", BROADCAST_PORT)

	var local_ip = _get_local_ip()
	server_created.emit(room_code, local_ip)
	return true


func join_by_code(code: String):
	_search_code = code
	_searching = true
	_udp_listen = PacketPeerUDP.new()
	_udp_listen.bind(BROADCAST_PORT)


func _process(delta):
	# Host: broadcast room code
	if is_host and _udp_broadcast:
		_broadcast_timer -= delta
		if _broadcast_timer <= 0:
			var msg = "ARENA:%s:%d" % [room_code, GAME_PORT]
			_udp_broadcast.put_packet(msg.to_utf8_buffer())
			_broadcast_timer = BROADCAST_INTERVAL

	# Client: listen for broadcasts
	if _searching and _udp_listen:
		while _udp_listen.get_available_packet_count() > 0:
			var data = _udp_listen.get_packet().get_string_from_utf8()
			var ip = _udp_listen.get_packet_ip()
			if data.begins_with("ARENA:" + _search_code + ":"):
				var parts = data.split(":")
				var port = int(parts[2])
				_searching = false
				_udp_listen.close()
				_udp_listen = null
				_connect_to_host(ip, port)
				return


func _connect_to_host(ip: String, port: int):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error != OK:
		join_failed.emit()
		return
	multiplayer.multiplayer_peer = peer
	is_online = true
	is_host = false

	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _on_connected_to_server():
	joined_server.emit()


func _on_connection_failed():
	is_online = false
	join_failed.emit()


func _on_peer_connected(id: int):
	connected_peers.append(id)
	player_connected.emit(id)


func _on_peer_disconnected(id: int):
	connected_peers.erase(id)
	player_disconnected.emit(id)


func disconnect_from_game():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	if _udp_broadcast:
		_udp_broadcast.close()
		_udp_broadcast = null
	if _udp_listen:
		_udp_listen.close()
		_udp_listen = null
	is_host = false
	is_online = false
	_searching = false
	connected_peers.clear()
	room_code = ""


func _get_local_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	return "127.0.0.1"


func reset():
	disconnect_from_game()
