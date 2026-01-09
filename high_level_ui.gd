extends Control

@onready var input_nome = $VBoxNome/InputNome
@onready var ranking_list = $RankingContainer/RankingList
@onready var server_list = $ServidoresContainer/ServerList
@onready var btn_refresh = $ServidoresContainer/BtnRefresh
@onready var input_ip = $VBoxDirectConnect/InputIP
@onready var btn_direct = $VBoxDirectConnect/BtnDirectConnect

# Lista de servidores encontrados (para mapear índice -> info)
var servers_data: Array = []

func _ready():
	_update_ranking_display()
	
	# Conecta sinais de descoberta de servidores
	ServerDiscovery.servers_updated.connect(_on_servers_updated)
	
	# Conecta sinais da UI
	server_list.item_selected.connect(_on_server_selected)
	btn_refresh.pressed.connect(_on_refresh_pressed)
	btn_direct.pressed.connect(_on_direct_connect_pressed)
	
	# Inicia escuta de servidores
	ServerDiscovery.start_listening()

func _exit_tree():
	# Para a escuta ao sair do menu
	ServerDiscovery.stop_listening()

func _update_ranking_display():
	# Limpa a lista atual
	for child in ranking_list.get_children():
		child.queue_free()
	
	# Adiciona cada entrada do ranking
	var pos = 1
	for entry in GameData.ranking:
		var label = Label.new()
		label.text = "%d. %s - %d vitórias" % [pos, entry["name"], entry["wins"]]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ranking_list.add_child(label)
		pos += 1
		if pos > 10:
			break
	
	# Se o ranking estiver vazio
	if GameData.ranking.size() == 0:
		var label = Label.new()
		label.text = "Nenhum jogador ainda"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ranking_list.add_child(label)

func _on_servers_updated(servers: Array):
	servers_data = servers
	server_list.clear()
	
	for server in servers:
		var text = "%s (%s:%d)" % [server.get("host_name", "???"), server.get("ip", "???"), server.get("port", 0)]
		server_list.add_item(text)
	
	if servers.size() == 0:
		server_list.add_item("Nenhum servidor encontrado...")

func _on_server_selected(index: int):
	if index < 0 or index >= servers_data.size():
		return
	
	var server = servers_data[index]
	_connect_to_server(server.get("ip", ""), server.get("port", 42069))

func _on_refresh_pressed():
	ServerDiscovery.refresh_servers()
	server_list.clear()
	server_list.add_item("Procurando servidores...")

func _on_direct_connect_pressed():
	var ip = input_ip.text.strip_edges()
	if ip.is_empty():
		return
		
	# Usa a porta definida no input de Host (ou padrão)
	var port_text = $VboxInputHost/PortInput.text
	var port = port_text.to_int() if not port_text.is_empty() else 42069
	
	_connect_to_server(ip, port)

func _connect_to_server(ip: String, port: int):
	_save_player_name()
	GameData.reset_scores()
	
	# Para a escuta antes de conectar
	ServerDiscovery.stop_listening()
	
	HighLevelNetworkHandler.start_client(ip, port)
	get_tree().change_scene_to_file("res://Arena2D.tscn")

func _save_player_name():
	var nome = input_nome.text.strip_edges()
	if nome.is_empty():
		nome = "Jogador"
	GameData.set_player_name(nome)

func _on_btn_host_pressed() -> void:
	_save_player_name()
	GameData.reset_scores()
	
	var porta_host = $VboxInputHost/PortInput.text
	porta_host = porta_host.to_int()
	
	# Para a escuta e inicia o broadcast
	ServerDiscovery.stop_listening()
	ServerDiscovery.start_broadcasting(GameData.get_player_name(), porta_host)
	
	HighLevelNetworkHandler.start_server(porta_host)
	get_tree().change_scene_to_file("res://Arena2D.tscn")
