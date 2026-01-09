extends Node

# Para deixar as variáveis constantes, basta descomentar as variáveis abaixo
# Não esqueça de retirar da função as coisas que pede entre parênteses (esqueci o nome)
# const IP_ADRESS: String = "127.0.0.1"
# const PORT: int = 42069 # Qualquer número entre 0 e 65535


var peer: ENetMultiplayerPeer

func start_server(PORT) -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, 2)
	multiplayer.multiplayer_peer = peer

func start_client(IP_ADRESS, PORT) -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADRESS, PORT)
	multiplayer.multiplayer_peer = peer
