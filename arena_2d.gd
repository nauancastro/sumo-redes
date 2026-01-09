extends Node2D

@onready var spawner = $MultiplayerSpawner
@onready var spawn_p1 = $SpawnPoint1
@onready var spawn_p2 = $SpawnPoint2

# Carregue as cenas dos personagens
const  p1_scene = preload("res://p_1.tscn")
const  p2_scene = preload("res://p_2.tscn")

func _ready():
	# Define a função customizada de spawn
	spawner.spawn_function = _spawn_custom_character

	# Conecta sinais para saber quando gente nova entra
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_player_connected)
		
		# Spawna o Host imediatamente (ID 1)
		spawner.spawn(1)

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
		# Opcional: Se tiver velocidade, zere ela também
		# host_node.velocity = Vector2.ZERO 
		
