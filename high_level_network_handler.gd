extends Node

#[.1] = Comentários para deixar as variáveis constantes se tu quiser
# Para deixar as variáveis constantes, basta descomentar as variáveis abaixo
# Não esqueça de retirar da função as coisas que pede entre parênteses (esqueci o nome)
# const IP_ADRESS: String = "127.0.0.1"
# const PORT: int = 42069 # Qualquer número entre 0 e 65535


var peer: ENetMultiplayerPeer

func start_server(PORT) -> void: #Retire o PORT AQUI [.1]
	peer = ENetMultiplayerPeer.new() 
	peer.create_server(PORT, 2) # Não precisa mexer pra deixar constante a variável
	multiplayer.multiplayer_peer = peer

func start_client(IP_ADRESS, PORT) -> void: #Retire o PORT e/ou o IP_ADRESS[.1]
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADRESS, PORT) # Não precisa mexer pra deixar constante a variável
	multiplayer.multiplayer_peer = peer
