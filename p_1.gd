extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const BASE_PUSH_FORCE = 80.0

# Referência ao Sprite. Se o seu nó tiver outro nome, mude aqui.
# Ex: $AnimatedSprite2D ou $Icon
@onready var sprite = $Sprite2D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_key_pressed(KEY_UP) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction = 0.0
	if Input.is_key_pressed(KEY_RIGHT):
		direction += 1.0
	if Input.is_key_pressed(KEY_LEFT):
		direction -= 1.0
	
	if direction:
		velocity.x = direction * SPEED
		
		# --- LÓGICA DE ESPELHAR (NOVA) ---
		# Se a direção for positiva (direita), flip_h é falso
		# Se a direção for negativa (esquerda), flip_h é verdadeiro
		if direction > 0:
			sprite.flip_h = true
		elif direction < 0:
			sprite.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# Lógica do Sumô (Empurrão)
	var current_push = BASE_PUSH_FORCE
	if Input.is_key_pressed(KEY_SPACE):
		current_push = BASE_PUSH_FORCE * 20.0
		modulate = Color(1, 0.5, 0.5) 
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
