extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const BASE_PUSH_FORCE = 80.0

# Referência ao Sprite.
@onready var sprite = $Sprite2D

func _physics_process(delta: float) -> void:
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
		
		# --- LÓGICA DE ESPELHAR (NOVA) ---
		if direction > 0:
			sprite.flip_h = true # Olha pra direita
		elif direction < 0:
			sprite.flip_h = false  # Olha pra esquerda
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# Lógica do Sumô (Empurrão)
	var current_push = BASE_PUSH_FORCE
	if Input.is_key_pressed(KEY_ENTER):
		current_push = BASE_PUSH_FORCE * 20.0
		modulate = Color(0.5, 0.5, 1)
	else:
		modulate = Color(1, 1, 1)

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is CharacterBody2D:
			collider.velocity += -collision.get_normal() * current_push
			
			# --- REINICIAR SE CAIR ---
	# Se a posição Y for maior que 1000 (caiu da tela para baixo)
	if global_position.y > 1000:
		# Reinicia a fase atual
		get_tree().reload_current_scene()
