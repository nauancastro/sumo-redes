extends Control



func _on_btn_host_pressed() -> void:
	var porta_host = $VboxInputHost/PortInput.text
	porta_host = porta_host.to_int()
	HighLevelNetworkHandler.start_server(porta_host)
	get_tree().change_scene_to_file("res://Arena2D.tscn")

func _on_btn_join_pressed() -> void:
	var ip_para_conectar = $VBoxContainer/InputIP.text
	var port_para_conectar = $VBoxContainer/InputPORT.text
	port_para_conectar = port_para_conectar.to_int()

	HighLevelNetworkHandler.start_client(ip_para_conectar, port_para_conectar)
	get_tree().change_scene_to_file("res://Arena2D.tscn")
