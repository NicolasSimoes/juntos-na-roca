class_name CarregarJuntos
extends Node2D
## Uma coisa pesada (a tora, o jerimum gigante) que só sai do lugar com os dois.
## Os dois chegam perto e apertam AÇÃO quase juntos para pegar.
## Se os dois se afastarem demais, ela cai e é só pegar de novo.

signal entregue
signal caiu

const DISTANCIA_MAXIMA := 64.0
const PERTO := 28.0

var textura: Texture2D
var destino := Rect2()
var segurando := false
var _apertos := {1: -10.0, 2: -10.0}
var _tempo := 0.0


func configurar(caminho_textura: String, posicao: Vector2, area_destino: Rect2) -> CarregarJuntos:
	textura = Jogo.tex(caminho_textura)
	position = posicao
	destino = area_destino
	return self


func _ready() -> void:
	z_index = 11


func _jogadores() -> Array[Jogador]:
	var lista: Array[Jogador] = []
	for no in get_tree().get_nodes_in_group("jogadores"):
		lista.append(no as Jogador)
	return lista


func _process(delta: float) -> void:
	_tempo += delta
	var js := _jogadores()
	if js.size() < 2:
		return
	var agora := Time.get_ticks_msec() / 1000.0
	if not segurando:
		var todos_perto := true
		for j in js:
			if j.global_position.distance_to(global_position) > PERTO:
				todos_perto = false
			if Jogo.apertou(j.numero) and j.global_position.distance_to(global_position) <= PERTO:
				_apertos[j.numero] = agora
		if todos_perto and absf(_apertos[1] - _apertos[2]) < 0.6 and agora - _apertos[1] < 0.6:
			segurando = true
			_apertos = {1: -10.0, 2: -10.0}
			for j in js:
				j.carregando_junto = true
			Sons.tocar("pegar")
	else:
		var a := js[0].global_position
		var b := js[1].global_position
		if a.distance_to(b) > DISTANCIA_MAXIMA:
			soltar()
			Sons.tocar("toim")
			caiu.emit()
		else:
			var alvo := (a + b) / 2.0 + Vector2(0, -6)
			global_position = global_position.lerp(alvo, minf(1.0, delta * 12.0))
			if destino.has_point(global_position):
				soltar()
				Sons.tocar("acerto")
				entregue.emit()
	queue_redraw()


func soltar() -> void:
	segurando = false
	for j in _jogadores():
		j.carregando_junto = false


func _draw() -> void:
	if textura == null:
		return
	var tam := textura.get_size()
	var y := -tam.y
	if segurando:
		y -= 4.0 + 1.5 * sin(_tempo * 12.0)
	if segurando:
		var r := Rect2(destino.position - global_position, destino.size)
		var pulso := 0.5 + 0.5 * sin(_tempo * 5.0)
		draw_rect(r, Color(1, 0.95, 0.5, 0.15 + 0.15 * pulso))
		draw_rect(r, Color(1, 0.95, 0.5, 0.6 + 0.4 * pulso), false, 1.5)
	draw_set_transform(Vector2(0, 1), 0.0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, tam.x * 0.45, Color(0, 0, 0, 0.18))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_texture(textura, Vector2(-tam.x / 2.0, y))
	if not segurando:
		# mãozinhas nas duas pontas, mostrando onde cada um segura
		var pulso := 0.6 + 0.4 * sin(_tempo * 6.0)
		draw_circle(Vector2(-tam.x / 2.0 - 4, -tam.y / 2.0), 3, Color(Jogo.COR[1], pulso))
		draw_circle(Vector2(tam.x / 2.0 + 4, -tam.y / 2.0), 3, Color(Jogo.COR[2], pulso))
		var fonte := ThemeDB.fallback_font
		draw_string_outline(fonte, Vector2(-50, -tam.y - 6), "os dois: AÇÃO", HORIZONTAL_ALIGNMENT_CENTER, 100, 7, 3, Color.BLACK)
		draw_string(fonte, Vector2(-50, -tam.y - 6), "os dois: AÇÃO", HORIZONTAL_ALIGNMENT_CENTER, 100, 7, Color(1, 0.95, 0.5))
