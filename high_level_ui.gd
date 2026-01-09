extends Control

#[.1] = Se quiser retirar os botões para colocar IP e Port, primeiro veja o high_level_network_handler

#Para não precisar dos botões veja o arquivo high_level_network_handler [.1]
func _on_btn_host_pressed() -> void:
	var porta_host = $VboxInputHost/PortInput.text # Apaga isso também[.1]
	porta_host = porta_host.to_int() # E isso [.1]
	HighLevelNetworkHandler.start_server(porta_host) # e Tira aqui o valor dos parênteses
	get_tree().change_scene_to_file("res://Arena2D.tscn")

func _on_btn_join_pressed() -> void:
	var ip_para_conectar = $VBoxContainer/InputIP.text # [.1] Apaga Isso também
	var port_para_conectar = $VBoxContainer/InputPORT.text # [.1] Apaga Isso também
	port_para_conectar = port_para_conectar.to_int() # [.1] Apaga Isso também

	HighLevelNetworkHandler.start_client(ip_para_conectar, port_para_conectar) # e Tira aqui o valor dos parênteses
	get_tree().change_scene_to_file("res://Arena2D.tscn")
