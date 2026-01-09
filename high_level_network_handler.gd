extends Node




var peer: ENetMultiplayerPeer

func start_server(PORT) -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, 2)
	multiplayer.multiplayer_peer = peer

func start_client(IP_ADRESS, PORT) -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADRESS, PORT)
	multiplayer.multiplayer_peer = peer
