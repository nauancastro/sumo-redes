extends Node2D

@onready var spawner = $MultiplayerSpawner
@onready var spawn_p1 = $SpawnPoint1
@onready var spawn_p2 = $SpawnPoint2

# UI Elements
@onready var score_label = $CanvasLayer/ScorePanel/VBoxContainer/ScoreLabel
@onready var names_label = $CanvasLayer/ScorePanel/VBoxContainer/NamesLabel
@onready var winner_panel = $CanvasLayer/WinnerPanel
@onready var winner_label = $CanvasLayer/WinnerPanel/VBoxContainer/WinnerLabel
@onready var final_score_label = $CanvasLayer/WinnerPanel/VBoxContainer/FinalScoreLabel
@onready var btn_play_again = $CanvasLayer/WinnerPanel/VBoxContainer/ButtonsContainer/BtnPlayAgain
@onready var btn_menu = $CanvasLayer/WinnerPanel/VBoxContainer/ButtonsContainer/BtnMenu

# Carregue as cenas dos personagens
const  p1_scene = preload("res://p_1.tscn")
const  p2_scene = preload("res://p_2.tscn")

# Estado do jogo
var game_over = false

# Nomes dos jogadores
var host_name: String = "P1"
var client_name: String = "P2"

func _ready():
	# Define a função customizada de spawn
	spawner.spawn_function = _spawn_custom_character
	
	# Conecta botões de fim de jogo
	btn_play_again.pressed.connect(_on_play_again)
	btn_menu.pressed.connect(_on_back_to_menu)
	
	# Atualiza UI inicial
	_update_score_display()
	
	# Se for servidor, guarda o nome do host
	if multiplayer.is_server():
		host_name = GameData.get_player_name()
		multiplayer.peer_connected.connect(_on_player_connected)
		# Spawna o Host imediatamente (ID 1)
		spawner.spawn(1)
	else:
		# Cliente aguarda conexão ser estabelecida antes de enviar nome
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	_update_names_display()

# Callback quando cliente conecta ao servidor
func _on_connected_to_server():
	# Agora que está conectado, envia o nome
	await get_tree().create_timer(0.1).timeout  # Pequeno delay para garantir
	rpc_id(1, "_receive_client_name", GameData.get_player_name())

# Recebe nome do cliente no servidor
@rpc("any_peer", "reliable")
func _receive_client_name(pname: String):
	client_name = pname
	# Envia os dois nomes para todos
	rpc("_sync_names", host_name, client_name)

@rpc("authority", "call_local", "reliable")
func _sync_names(hname: String, cname: String):
	host_name = hname
	client_name = cname
	_update_names_display()

func _update_names_display():
	names_label.text = host_name + " vs " + client_name

# --- FUNÇÃO QUE ESCOLHE O BONECO ---
# Essa função roda no servidor e o resultado é replicado para todos
func _spawn_custom_character(data):
	var player_id = data
	var character_instance
	
	# Se for o Host (ID 1), é Totodile. Se não, é Torchic.
	if player_id == 1:
		character_instance = p1_scene.instantiate()
		character_instance.global_position = spawn_p1.global_position
	else:
		character_instance = p2_scene.instantiate()
		character_instance.global_position = spawn_p2.global_position
	
	# Configurações padrão obrigatórias
	character_instance.name = str(player_id)
	character_instance.set_multiplayer_authority(player_id)
	
	# Conecta sinal de queda do personagem
	character_instance.player_fell.connect(_on_player_fell)
	
	return character_instance

# --- LÓGICA DE RESET QUANDO O CLIENT ENTRA ---
func _on_player_connected(new_player_id):
	# Spawna o novo jogador (Torchic)
	spawner.spawn(new_player_id)
	
	# RESETA POSIÇÕES:
	# Como somos o servidor, podemos mover o Host (ID 1) à força
	var host_node = get_node_or_null("1") # O nome do nó é o ID "1"
	if host_node:
		host_node.global_position = spawn_p1.global_position

# --- SISTEMA DE PONTUAÇÃO ---
func _on_player_fell(player_id: int):
	if game_over:
		return
	
	# Notifica o servidor da queda via RPC
	if multiplayer.is_server():
		_process_fall(player_id)
	else:
		rpc_id(1, "_notify_fall", player_id)

@rpc("any_peer", "reliable")
func _notify_fall(player_id: int):
	# Só o servidor processa
	if multiplayer.is_server():
		_process_fall(player_id)

func _process_fall(player_id: int):
	if game_over:
		return
		
	# O jogador que caiu dá ponto para o adversário
	if player_id == 1:
		# Host caiu, client ganha ponto
		GameData.score_p2 += 1
	else:
		# Client caiu, host ganha ponto
		GameData.score_p1 += 1
	
	# Sincroniza pontuação com todos
	rpc("_sync_score", GameData.score_p1, GameData.score_p2)
	
	# Verifica vitória
	var winner = GameData.check_winner()
	if winner > 0:
		var winner_name = host_name if winner == 1 else client_name
		rpc("_show_winner", winner, winner_name)

@rpc("authority", "call_local", "reliable")
func _sync_score(p1_score: int, p2_score: int):
	GameData.score_p1 = p1_score
	GameData.score_p2 = p2_score
	_update_score_display()

@rpc("authority", "call_local", "reliable")
func _show_winner(winner_id: int, winner_name: String):
	game_over = true
	winner_panel.visible = true
	
	winner_label.text = "🏆 " + winner_name + " VENCEU! 🏆"
	final_score_label.text = "Placar Final: %d - %d" % [GameData.score_p1, GameData.score_p2]
	
	# Salva no ranking se o jogador local venceu
	var local_is_host = multiplayer.is_server()
	var local_won = (winner_id == 1 and local_is_host) or (winner_id != 1 and not local_is_host)
	if local_won:
		GameData.save_to_ranking(GameData.get_player_name())

func _update_score_display():
	score_label.text = "%d - %d" % [GameData.score_p1, GameData.score_p2]

func _on_play_again():
	# Reseta pontuação e reinicia
	GameData.reset_scores()
	get_tree().reload_current_scene()

func _on_back_to_menu():
	# Para o broadcast se era servidor
	ServerDiscovery.stop_broadcasting()
	# Desconecta e volta ao menu
	multiplayer.multiplayer_peer = null
	# Recarrega o ranking antes de voltar
	GameData.load_ranking()
	get_tree().change_scene_to_file("res://Menu.tscn")
