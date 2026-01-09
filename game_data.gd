extends Node

# Singleton para armazenar dados globais do jogo

# Nome do jogador local
var player_name: String = "Jogador"

# Dicionário de nomes por ID do multiplayer
var player_names: Dictionary = {}

# Pontuações atuais
var score_p1: int = 0
var score_p2: int = 0

# Constante de vitória
const SCORE_TO_WIN = 5

# Ranking (lista de dicionários com nome e vitórias)
var ranking: Array = []

func _ready():
	load_ranking()

func set_player_name(pname: String):
	player_name = pname

func get_player_name() -> String:
	return player_name

func reset_scores():
	score_p1 = 0
	score_p2 = 0

func add_score(player_id: int):
	if player_id == 1:
		score_p1 += 1
	else:
		score_p2 += 1

func check_winner() -> int:
	if score_p1 >= SCORE_TO_WIN:
		return 1
	elif score_p2 >= SCORE_TO_WIN:
		return 2
	return 0

func save_to_ranking(winner_name: String):
	# Procura se o jogador já existe no ranking
	var found = false
	for entry in ranking:
		if entry["name"] == winner_name:
			entry["wins"] += 1
			found = true
			break
	
	if not found:
		ranking.append({"name": winner_name, "wins": 1})
	
	# Ordena por vitórias (maior primeiro)
	ranking.sort_custom(func(a, b): return a["wins"] > b["wins"])
	
	# Mantém apenas os top 10
	if ranking.size() > 10:
		ranking.resize(10)
	
	save_ranking()

func save_ranking():
	var file = FileAccess.open("user://ranking.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(ranking))
		file.close()

func load_ranking():
	if FileAccess.file_exists("user://ranking.json"):
		var file = FileAccess.open("user://ranking.json", FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			if content.is_empty():
				return
			var json = JSON.new()
			var result = json.parse(content)
			if result == OK and json.data is Array:
				ranking = json.data
