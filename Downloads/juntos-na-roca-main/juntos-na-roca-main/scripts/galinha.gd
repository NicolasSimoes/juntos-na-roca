class_name Galinha
extends CharacterBody2D
## Galinha fujona. Sozinho ninguém pega: ela corre mais que um jogador.
## Com os dois bem pertinho dela, ela se acalma e segue a dupla.
## Ao entrar no cercado, fica guardada.

enum Estado { SOLTA, CERCADA, GUARDADA }

signal guardada

const VEL_ANDAR := 22.0
const VEL_FUGIR := 92.0
const MEDO := 44.0
const CERCO := 40.0
const ESCAPA := 64.0

var estado := Estado.SOLTA
var cercado := Rect2()
var pode_cercar := false   # só no dia de recolher as galinhas
var _alvo := Vector2.ZERO
var _casa := Vector2.ZERO      # perto de onde ela fica passeando
var _tempo_alvo := 0.0
var _fuga := 0.0          # segundos de corrida que ainda faltam
var _descanso := 0.0      # depois de correr, ela para um pouquinho
var _sprite: AnimatedSprite2D
var _tempo := 0.0


func _ready() -> void:
	z_index = 9
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(8, 5)
	forma.shape = ret
	forma.position = Vector2(0, -2)
	add_child(forma)
	_sprite = AnimatedSprite2D.new()
	var quadros := SpriteFrames.new()
	quadros.set_animation_speed("default", 6.0)
	quadros.add_frame("default", load("res://assets/sprites/personagens/galinha_1.png"))
	quadros.add_frame("default", load("res://assets/sprites/personagens/galinha_2.png"))
	_sprite.sprite_frames = quadros
	_sprite.position = Vector2(0, -8)
	_sprite.play("default")
	add_child(_sprite)
	_alvo = global_position
	_casa = global_position


func colocar_no_cercado() -> void:
	estado = Estado.GUARDADA
	global_position = cercado.get_center() + Vector2(randf_range(-30, 30), randf_range(-12, 12))
	_alvo = global_position


func _jogadores() -> Array[Jogador]:
	var lista: Array[Jogador] = []
	for no in get_tree().get_nodes_in_group("jogadores"):
		var j := no as Jogador
		if j.visible:
			lista.append(j)
	return lista


func _physics_process(delta: float) -> void:
	_tempo += delta
	var js := _jogadores()
	match estado:
		Estado.SOLTA:
			_solta(delta, js)
		Estado.CERCADA:
			_cercada(js)
		Estado.GUARDADA:
			_passear(delta, cercado.grow(-6))
	move_and_slide()
	if absf(velocity.x) > 1:
		_sprite.flip_h = velocity.x < 0
	_sprite.speed_scale = 2.0 if velocity.length() > 40 else 1.0
	queue_redraw()


func _solta(delta: float, js: Array[Jogador]) -> void:
	if pode_cercar and cercado.has_point(global_position):
		# entrou sozinha no cercado: também vale!
		estado = Estado.GUARDADA
		_alvo = global_position
		Sons.tocar("galinha", 0.0, 1.2)
		guardada.emit()
		return
	var perto := 0
	var fugir := Vector2.ZERO
	for j in js:
		var d := global_position.distance_to(j.global_position)
		if d < CERCO:
			perto += 1
		if d < MEDO:
			fugir += (global_position - j.global_position).normalized() * (1.0 - d / MEDO)
	if perto >= 2 and js.size() >= 2 and pode_cercar:
		estado = Estado.CERCADA
		Sons.tocar("galinha")
		return
	_descanso -= delta
	if fugir.length() > 0.01 and _descanso <= 0.0:
		if _fuga <= 0.0:
			_fuga = 0.7
			# foge um pouco para o lado: sozinho, ela sempre escapa pelos lados
			fugir = fugir.rotated(randf_range(-0.9, 0.9))
			_alvo = global_position + fugir.normalized() * 60.0
	if _fuga > 0.0:
		_fuga -= delta
		velocity = (global_position.direction_to(_alvo)) * VEL_FUGIR
		if _fuga <= 0.0:
			_descanso = 0.6
			velocity = Vector2.ZERO
		return
	var area := Rect2(_casa - Vector2(50, 36), Vector2(100, 72)).intersection(Rect2(16, 16, 608, 328))
	_passear(delta, area)


func _cercada(js: Array[Jogador]) -> void:
	if js.size() < 2:
		estado = Estado.SOLTA
		return
	for j in js:
		if global_position.distance_to(j.global_position) > ESCAPA:
			estado = Estado.SOLTA
			_fuga = 0.0
			_descanso = 0.0
			Sons.tocar("escapou")
			return
	var meio := (js[0].global_position + js[1].global_position) / 2.0
	var dir := meio - global_position
	velocity = dir.normalized() * minf(85.0, dir.length() * 4.0) if dir.length() > 4 else Vector2.ZERO
	if cercado.has_point(global_position):
		estado = Estado.GUARDADA
		_alvo = global_position
		Sons.tocar("galinha", 0.0, 1.2)
		guardada.emit()


func _passear(delta: float, area: Rect2) -> void:
	_tempo_alvo -= delta
	if _tempo_alvo <= 0.0 or global_position.distance_to(_alvo) < 3:
		_tempo_alvo = randf_range(1.0, 2.5)
		_alvo = global_position + Vector2(randf_range(-30, 30), randf_range(-20, 20))
		_alvo = _alvo.clamp(area.position, area.end)
	if global_position.distance_to(_alvo) > 3:
		velocity = global_position.direction_to(_alvo) * VEL_ANDAR
	else:
		velocity = Vector2.ZERO
	if estado == Estado.GUARDADA and not area.grow(8).has_point(global_position):
		velocity = global_position.direction_to(area.get_center()) * VEL_ANDAR


func _draw() -> void:
	draw_circle(Vector2(0, 0), 4, Color(0, 0, 0, 0.2))
	if estado == Estado.CERCADA:
		var y := -22.0 - 2.0 * sin(_tempo * 6.0)
		draw_texture(Jogo.tex("res://assets/sprites/extras/coracao.png"), Vector2(-8, y))
