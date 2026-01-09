extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const BASE_PUSH_FORCE = 80.0

# --- NOVAS CONSTANTES DE BALANCEAMENTO ---
const PUSH_DURATION = 0.3  # O empurrão dura 0.3 segundos (ataque rápido)
const PUSH_COOLDOWN = 1.5  # O jogador precisa esperar 1.5s para usar de novo

@onready var sprite = $Sprite2D

# Variável sincronizada
@export var is_pushing := false

# Variáveis de controle de tempo
var current_push_timer = 0.0      # Conta quanto tempo falta para o ataque acabar
var current_cooldown_timer = 0.0  # Conta quanto tempo falta para poder atacar de novo
var can_hit_target = true         # Debounce para não acertar o mesmo alvo 2x no mesmo ataque

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _physics_process(delta: float) -> void:
	
	# === LÓGICA DO DONO (AUTHORITY) ===
	if is_multiplayer_authority():
		
		# 1. ATUALIZAÇÃO DOS TIMERS (Diminui o tempo a cada frame)
		if current_push_timer > 0:
			current_push_timer -= delta
			is_pushing = true # Enquanto tiver tempo, tá empurrando
		else:
			is_pushing = false # Acabou o tempo, desliga o empurrão
			# Reseta a capacidade de acertar alguém para o próximo ataque
			can_hit_target = true 

		if current_cooldown_timer > 0:
			current_cooldown_timer -= delta

		# 2. MOVIMENTAÇÃO (Normal)
		if not is_on_floor():
			velocity += get_gravity() * delta

		if Input.is_key_pressed(KEY_W) and is_on_floor():
			velocity.y = JUMP_VELOCITY

		var direction = 0.0
		if Input.is_key_pressed(KEY_D):
			direction += 1.0
		if Input.is_key_pressed(KEY_A):
			direction -= 1.0
		
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		# 3. INPUT DE EMPURRÃO (Com Cooldown)
		# Só entra aqui se apertar a tecla E o cooldown já tiver zerado
		if (Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_SPACE)) and current_cooldown_timer <= 0:
			# Inicia o ataque
			current_push_timer = PUSH_DURATION
			current_cooldown_timer = PUSH_COOLDOWN
			# (Opcional) Você pode tocar um som aqui

		move_and_slide()

		# 4. COLISÃO (Só empurra se estiver atacando E ainda não tiver acertado)
		# A variável 'can_hit_target' garante que cada ataque só acerte UMA vez.
		if is_pushing and can_hit_target:
			var current_push_force = BASE_PUSH_FORCE * 40.0 

			for i in get_slide_collision_count():
				var collision = get_slide_collision(i)
				var collider = collision.get_collider()
				
				if collider is CharacterBody2D:
					var push_vector = -collision.get_normal() * current_push_force
					collider.rpc("apply_knockback", push_vector)
					
					# Consome o hit. O jogador não vai empurrar mais nada neste ataque.
					can_hit_target = false 

		# Correção de queda/teto
		if global_position.y > 1000 or global_position.y < -2000:
			velocity = Vector2.ZERO
			if name == "1":
				position = Vector2(300, 300) 
			else:
				position = Vector2(800, 300) 
	
	# === LÓGICA VISUAL (PARA TODOS) ===
	update_visuals()

func update_visuals():
	if velocity.x > 0:
		sprite.flip_h = true
	elif velocity.x < 0:
		sprite.flip_h = false
	
	# O visual agora vai "piscar" vermelho só durante o tempo do PUSH_DURATION
	if is_pushing:
		modulate = Color(1, 1, 0.5) # Azulado
	else:
		# (Opcional) Feedback visual de que está em Cooldown (ficar cinza, por exemplo)
		if is_multiplayer_authority() and current_cooldown_timer > 0:
			modulate = Color(0.8, 0.8, 0.8) # Um pouco escuro indicando "cansado"
		else:
			modulate = Color(1, 1, 1)

@rpc("any_peer", "call_local")
func apply_knockback(force: Vector2):
	velocity += force
