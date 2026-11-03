class_name MinijogoSerra
extends Minijogo
## Serra de dois cabos: um puxa, depois o outro, depois o um...
## Quem aperta fora da vez faz a serra agarrar por um instante.

const CORTES := 12

var vez := 0            # 0 = papel A (esquerda), 1 = papel B (direita)
var cortes := 0
var travada := 0.0
var _serra := 0.0       # -1 = puxada para a esquerda, 1 = para a direita
var _alvo := 0.0
var _serragem: Array = []


func montar() -> void:
	titulo = "Serrar a tora"
	texto_a = "%s na sua vez (cabo da esquerda)" % Jogo.tecla_acao(na)
	texto_b = "%s na sua vez (cabo da direita)" % Jogo.tecla_acao(nb)


func atualizar(delta: float) -> void:
	travada = maxf(0.0, travada - delta)
	_serra = move_toward(_serra, _alvo, delta * 7.0)
	for p in _serragem:
		p["v"] += Vector2(0, 220) * delta
		p["p"] += p["v"] * delta
		p["vida"] -= delta
	_serragem = _serragem.filter(func(p): return p["vida"] > 0)
	var quem := [na, nb]
	for k in 2:
		if not Jogo.apertou(quem[k]):
			continue
		if travada > 0.0:
			continue
		if k == vez:
			cortes += 1
			vez = 1 - vez
			_alvo = -1.0 if k == 0 else 1.0
			Sons.tocar("serra", 0.0, randf_range(0.9, 1.1))
			acerto()
			for i in 6:
				_serragem.append({"p": Vector2(280, 140), "v": Vector2(randf_range(-80, 80), randf_range(-120, -40)), "vida": 0.6})
			if cortes >= CORTES:
				terminar("A tora está serrada!")
		else:
			travada = 0.7
			erro("A serra agarrou! Um de cada vez.")


func desenhar(c: Control) -> void:
	# chão e tora
	c.draw_rect(Rect2(0, 200, 560, 100), Color("6abe30"))
	var tora := Rect2(130, 140, 300, 66)
	c.draw_rect(tora, Color("a66e3e"))
	c.draw_rect(tora, Color("784a28"), false, 3)
	for y in [156, 172, 188]:
		c.draw_line(Vector2(140, y), Vector2(420, y), Color("cd9b64"), 1.0)
	c.draw_circle(Vector2(430, 173), 32, Color("cd9b64"))
	c.draw_arc(Vector2(430, 173), 32, 0, TAU, 32, Color("784a28"), 3)
	c.draw_arc(Vector2(430, 173), 20, 0, TAU, 24, Color("a66e3e"), 2)
	c.draw_arc(Vector2(430, 173), 9, 0, TAU, 16, Color("a66e3e"), 2)
	# corte que vai descendo
	var fundo := 66.0 * cortes / CORTES
	c.draw_rect(Rect2(277, 140, 6, fundo), Color(0.2, 0.12, 0.06))
	# serra
	var tremor := sin(tempo * 70.0) * 3.0 if travada > 0.0 else 0.0
	var dx := _serra * 34.0 + tremor
	var y := 128.0 + fundo * 0.5
	c.draw_rect(Rect2(110 + dx, y, 340, 8), Color("9aa0aa"))
	for x in range(116, 446, 8):
		c.draw_colored_polygon(PackedVector2Array([Vector2(x + dx, y + 8), Vector2(x + 4 + dx, y + 13), Vector2(x + 8 + dx, y + 8)]), Color("6d7380"))
	c.draw_rect(Rect2(86 + dx, y - 8, 26, 22), Color("784a28"))
	c.draw_rect(Rect2(448 + dx, y - 8, 26, 22), Color("784a28"))
	# os dois amigos, um em cada ponta
	_jogador(c, na, Vector2(64 + dx * 0.5, 196), false)
	_jogador(c, nb, Vector2(500 + dx * 0.5, 196), true)
	# de quem é a vez
	var px := 99.0 if vez == 0 else 461.0
	var cor: Color = Jogo.COR[na] if vez == 0 else Jogo.COR[nb]
	var pulo := 4.0 * sin(tempo * 8.0)
	textura(c, "res://assets/sprites/extras/seta.png", Vector2(px + dx, 86 + pulo), 2.0, false, cor.lightened(0.2))
	texto_centro(c, Vector2(px + dx, 62), "SUA VEZ!" if travada <= 0.0 else "agarrou...", 10, cor.lightened(0.3), 140)
	for p in _serragem:
		c.draw_rect(Rect2(p["p"], Vector2(2, 2)), Color("e8c48a"))
	barra(c, Rect2(180, 222, 200, 10), float(cortes) / CORTES, Color("eb8931"))
	texto_centro(c, Vector2(280, 244), "%d de %d puxadas" % [cortes, CORTES], 8, Color(0.15, 0.1, 0.05), 200)


func _jogador(c: Control, n: int, pos: Vector2, virar: bool) -> void:
	var t := Jogo.tex("res://assets/sprites/personagens/p%d_lado_parado.png" % n)
	c.draw_set_transform(pos, 0.0, Vector2(-3 if virar else 3, 3))
	c.draw_texture(t, Vector2(-8, -24))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
