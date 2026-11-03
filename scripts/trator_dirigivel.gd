class_name TratorDirigivel
extends CharacterBody2D
## O trator que um jogador dirige para arar. Ele para quando bate numa pedra.

signal arou(bloco: Vector2i)

var motorista := 1
var velocidade := 52.0
var area_arar := Rect2i()
var chao: TileMapLayer
var bloqueado := false
var _sprite: Sprite2D
var _cabeca: Sprite2D
var _tempo_motor := 0.0


func _ready() -> void:
	z_index = 10
	collision_layer = 1
	collision_mask = 1 | 8
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(26, 8)
	forma.shape = ret
	forma.position = Vector2(0, -4)
	add_child(forma)
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/sprites/extras/trator.png")
	_sprite.position = Vector2(0, -12)
	add_child(_sprite)
	_cabeca = Sprite2D.new()
	_cabeca.texture = load("res://assets/sprites/personagens/p%d_lado_parado.png" % motorista)
	_cabeca.region_enabled = true
	_cabeca.region_rect = Rect2(0, 1, 16, 11)
	_cabeca.position = Vector2(-5, -14)
	_cabeca.show_behind_parent = true
	_sprite.add_child(_cabeca)


func _physics_process(delta: float) -> void:
	var dir := Jogo.direcao(motorista)
	velocity = dir * velocidade
	move_and_slide()
	bloqueado = dir.length() > 0.1 and get_slide_collision_count() > 0 and _bateu_em_pedra()
	if absf(dir.x) > 0.1:
		_sprite.flip_h = dir.x < 0
		_cabeca.flip_h = dir.x < 0
		_cabeca.position.x = 5 if dir.x < 0 else -5
	if dir.length() > 0.1:
		_sprite.position.y = -12 + (1 if fmod(Time.get_ticks_msec() / 80.0, 2.0) > 1.0 else 0)
		_tempo_motor -= delta
		if _tempo_motor <= 0:
			_tempo_motor = 0.6
			Sons.tocar("motor", -12.0)
	_arar()
	queue_redraw()


func _bateu_em_pedra() -> bool:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var outro := c.get_collider()
		if outro is Node and (outro as Node).is_in_group("pedras"):
			return true
	return false


## Ara os blocos embaixo do trator (2 x 2 blocos).
func _arar() -> void:
	if chao == null:
		return
	for dx in [-8, 8]:
		for dy in [-2, -14]:
			var p := global_position + Vector2(dx, dy)
			var bloco := Vector2i(floori(p.x / 16.0), floori(p.y / 16.0))
			if area_arar.has_point(bloco) and chao.get_cell_atlas_coords(bloco) != Vector2i(2, 0):
				chao.set_cell(bloco, 0, Vector2i(2, 0))
				arou.emit(bloco)


func _draw() -> void:
	if bloqueado:
		var fonte := ThemeDB.fallback_font
		draw_string_outline(fonte, Vector2(-20, -34), "!", HORIZONTAL_ALIGNMENT_CENTER, 40, 14, 4, Color.BLACK)
		draw_string(fonte, Vector2(-20, -34), "!", HORIZONTAL_ALIGNMENT_CENTER, 40, 14, Color(1, 0.9, 0.3))
