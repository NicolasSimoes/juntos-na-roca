class_name Estacao
extends Node2D
## Dois círculos no chão. A tarefa só começa quando cada jogador está em um círculo.
## O círculo da esquerda é o papel A, o da direita é o papel B.
## A borda colorida mostra quem a Vovó sugere para cada papel (para revezar).

signal prontos(jogador_a: Jogador, jogador_b: Jogador)

const DIST := 18.0
const RAIO := 9.0

var papel_a := ""
var papel_b := ""
var icone_a: Texture2D
var icone_b: Texture2D
var sugerir := true        # false = os dois círculos têm a mesma função
var ativa := false:
	set(valor):
		ativa = valor
		visible = valor
		_carga = 0.0

var _carga := 0.0
var _tempo := 0.0
var _a: Jogador
var _b: Jogador


func _ready() -> void:
	z_index = 6
	visible = ativa


func _process(delta: float) -> void:
	if not ativa:
		return
	_tempo += delta
	_a = _quem_esta_em(Vector2(-DIST, 0))
	_b = _quem_esta_em(Vector2(DIST, 0))
	if _a != null and _b != null and _a != _b:
		_carga += delta / 0.6
		if _carga >= 1.0:
			var a := _a
			var b := _b
			ativa = false
			Sons.tocar("acerto")
			prontos.emit(a, b)
			return
	else:
		_carga = maxf(0.0, _carga - delta * 2.0)
	queue_redraw()


func _quem_esta_em(deslocamento: Vector2) -> Jogador:
	var centro := global_position + deslocamento
	var melhor: Jogador = null
	var menor := RAIO + 4.0
	for no in get_tree().get_nodes_in_group("jogadores"):
		var j := no as Jogador
		if j.visible and j.pode_mover:
			var d := j.global_position.distance_to(centro)
			if d <= menor:
				menor = d
				melhor = j
	return melhor


func _draw() -> void:
	var sug_a := Jogo.sugerido_a()
	_circulo(Vector2(-DIST, 0), _a, sug_a, icone_a)
	_circulo(Vector2(DIST, 0), _b, 3 - sug_a, icone_b)
	var fonte := ThemeDB.fallback_font
	if papel_a == papel_b:
		_texto(fonte, Vector2(-60, RAIO + 10), papel_a, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		_texto(fonte, Vector2(-DIST + 6 - 120, RAIO + 10), papel_a, HORIZONTAL_ALIGNMENT_RIGHT)
		_texto(fonte, Vector2(DIST - 6, RAIO + 10), papel_b, HORIZONTAL_ALIGNMENT_LEFT)
	if _carga > 0.0:
		draw_arc(Vector2(0, -2), 6, -PI / 2, -PI / 2 + TAU * _carga, 24, Color.WHITE, 2.5)


func _texto(fonte: Font, pos: Vector2, texto: String, alinhamento: HorizontalAlignment) -> void:
	draw_string_outline(fonte, pos, texto, alinhamento, 120, 7, 3, Color(0, 0, 0, 0.8))
	draw_string(fonte, pos, texto, alinhamento, 120, 7, Color.WHITE)


func _circulo(centro: Vector2, ocupante: Jogador, sugerido: int, icone: Texture2D) -> void:
	var pulso := 1.0 + 0.1 * sin(_tempo * 5.0)
	if ocupante != null:
		draw_circle(centro, RAIO, Jogo.COR[ocupante.numero])
	else:
		draw_circle(centro, RAIO * pulso, Color(1, 1, 1, 0.45))
	var borda: Color = Jogo.COR[sugerido] if sugerir else Color(1, 0.95, 0.5)
	draw_arc(centro, RAIO * pulso, 0, TAU, 28, borda, 2.0)
	if icone != null:
		var tam := icone.get_size()
		var escala := minf(1.0, 16.0 / maxf(tam.x, tam.y))
		var r := Rect2(centro + Vector2(-tam.x * escala / 2, -RAIO - 4 - tam.y * escala), tam * escala)
		draw_texture_rect(icone, r, false)
