extends Node

# Sistema de descoberta de servidores via UDP Broadcast
# Porta usada para broadcast (diferente da porta do jogo)
const BROADCAST_PORT = 42070
const BROADCAST_INTERVAL = 1.0  # Segundos entre broadcasts
const SERVER_TIMEOUT = 5.0  # Segundos para considerar servidor offline

# Sinais
signal server_found(server_info: Dictionary)
signal server_lost(ip: String)
signal servers_updated(servers: Array)

# Estado
var is_broadcasting = false
var is_listening = false

# Sockets UDP
var broadcast_socket: PacketPeerUDP
var listen_socket: PacketPeerUDP

# Info do servidor local (quando hospedando)
var local_server_info: Dictionary = {}

# Lista de servidores encontrados: { "ip": { info }, ... }
var found_servers: Dictionary = {}

# Timers
var broadcast_timer: float = 0.0
var cleanup_timer: float = 0.0

func _process(delta):
	if is_broadcasting:
		broadcast_timer += delta
		if broadcast_timer >= BROADCAST_INTERVAL:
			broadcast_timer = 0.0
			_send_broadcast()
	
	if is_listening:
		_receive_broadcasts()
		
		# Limpa servidores que não respondem
		cleanup_timer += delta
		if cleanup_timer >= 1.0:
			cleanup_timer = 0.0
			_cleanup_stale_servers()

# === BROADCASTER (SERVIDOR) ===

func start_broadcasting(host_name: String, game_port: int):
	if is_broadcasting:
		return
	
	# Obtém o IP local
	var local_ip = _get_local_ip()
	
	local_server_info = {
		"host_name": host_name,
		"port": game_port,
		"ip": local_ip,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	broadcast_socket = PacketPeerUDP.new()
	broadcast_socket.set_broadcast_enabled(true)
	broadcast_socket.set_dest_address("255.255.255.255", BROADCAST_PORT)
	
	is_broadcasting = true
	print("[ServerDiscovery] Broadcasting started: ", local_server_info)

func stop_broadcasting():
	if not is_broadcasting:
		return
	
	is_broadcasting = false
	if broadcast_socket:
		broadcast_socket.close()
		broadcast_socket = null
	print("[ServerDiscovery] Broadcasting stopped")

func _send_broadcast():
	if not broadcast_socket:
		return
	
	local_server_info["timestamp"] = Time.get_unix_time_from_system()
	var data = JSON.stringify(local_server_info)
	broadcast_socket.put_packet(data.to_utf8_buffer())

# === LISTENER (CLIENTE) ===

func start_listening():
	if is_listening:
		return
	
	listen_socket = PacketPeerUDP.new()
	var err = listen_socket.bind(BROADCAST_PORT)
	if err != OK:
		print("[ServerDiscovery] Failed to bind listener: ", err)
		return
	
	found_servers.clear()
	is_listening = true
	print("[ServerDiscovery] Listening started on port ", BROADCAST_PORT)

func stop_listening():
	if not is_listening:
		return
	
	is_listening = false
	if listen_socket:
		listen_socket.close()
		listen_socket = null
	found_servers.clear()
	print("[ServerDiscovery] Listening stopped")

func _receive_broadcasts():
	if not listen_socket:
		return
	
	while listen_socket.get_available_packet_count() > 0:
		var packet = listen_socket.get_packet()
		var sender_ip = listen_socket.get_packet_ip()
		
		if packet.size() == 0:
			continue
		
		var json = JSON.new()
		var result = json.parse(packet.get_string_from_utf8())
		if result != OK:
			continue
		
		var server_info = json.data
		if not server_info is Dictionary:
			continue
		
		# Usa o IP real do remetente
		server_info["ip"] = sender_ip
		server_info["last_seen"] = Time.get_unix_time_from_system()
		
		var is_new = not found_servers.has(sender_ip)
		found_servers[sender_ip] = server_info
		
		if is_new:
			server_found.emit(server_info)
			servers_updated.emit(get_server_list())

func _cleanup_stale_servers():
	var current_time = Time.get_unix_time_from_system()
	var to_remove = []
	
	for ip in found_servers:
		var server = found_servers[ip]
		if current_time - server.get("last_seen", 0) > SERVER_TIMEOUT:
			to_remove.append(ip)
	
	for ip in to_remove:
		found_servers.erase(ip)
		server_lost.emit(ip)
	
	if to_remove.size() > 0:
		servers_updated.emit(get_server_list())

# === UTILIDADES ===

func get_server_list() -> Array:
	var servers = []
	for ip in found_servers:
		servers.append(found_servers[ip])
	return servers

func refresh_servers():
	# Força limpeza e reescaneamento
	found_servers.clear()
	servers_updated.emit([])

func _get_local_ip() -> String:
	# Tenta obter o IP local da máquina
	for ip in IP.get_local_addresses():
		# Filtra IPs locais válidos (IPv4, não localhost)
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	return "127.0.0.1"

func _exit_tree():
	stop_broadcasting()
	stop_listening()
