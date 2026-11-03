class_name MinijogoOrdenha
extends Minijogo
## Papel A segura AÇÃO: dá capim e a Mimosa fica quietinha.
## Papel B aperta AÇÃO várias vezes: tira o leite. Sem capim, ela não deixa.

var leite := 0.0
var calma := 0.0
var _chute := 0.0
var _gotas: Array = []


func montar() -> void:
	titulo = "Tirar o leite da Mimosa"
	texto_a = "SEGURE %s para dar capim" % Jogo.tecla_acao(na)
	texto_b = "APERTE %s para tirar o leite" % Jogo.tecla_acao(nb)


func atualizar(delta: float) -> void:
	_chute = maxf(0.0, _chute - delta)
	if Jogo.segurando(na):
		calma = move_toward(calma, 1.0, delta * 3.0)
	else:
		calma = move_toward(calma, 0.0, delta * 1.5)
	if Jogo.apertou(nb):
		if calma > 0.6:
			leite += 0.07
			Sons.tocar("leite", 0.0, randf_range(0.9, 1.2))
			_gotas.append({"p": Vector2(262, 196), "vida": 0.35})
			acerto()
		else:
			_chute = 0.5
			Sons.tocar("vaca", -4.0, 1.2)
			erro("A Mimosa não quer! Dá capim para ela.")
	for g in _gotas:
		g["p"] += Vector2(0, 120) * delta
		g["vida"] -= delta
	_gotas = _gotas.filter(func(g): return g["vida"] > 0)
	if leite >= 1.0:
		leite = 1.0
		terminar("Leite fresquinho!")


func desenhar(c: Control) -> void:
	c.draw_rect(Rect2(0, 200, 560, 100), Color("6abe30"))
	var tremor := sin(tempo * 50.0) * 4.0 if _chute > 0.0 else 0.0
	# Mimosa
	var vaca := Jogo.tex("res://assets/sprites/personagens/vaca_mimosa.png")
	c.draw_set_transform(Vector2(230 + tremor, 190), 0.0, Vector2(6, 6))
	c.draw_texture(vaca, Vector2(-12, -14))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# quem dá o capim, perto da cabeça (lado direito)
	_jogador(c, na, Vector2(392, 214), true)
	if Jogo.segurando(na):
		textura(c, "res://assets/sprites/extras/capim.png", Vector2(352, 150 + sin(tempo * 10.0) * 2.0), 2.5)
	# quem tira o leite, embaixo
	_jogador(c, nb, Vector2(200, 244), false)
	# balde enchendo
	var balde := Rect2(244, 204, 40, 40)
	c.draw_colored_polygon(PackedVector2Array([balde.position, balde.position + Vector2(40, 0), balde.end, balde.position + Vector2(4, 40)]), Color("828894"))
	var nivel := 34.0 * leite
	c.draw_rect(Rect2(balde.position.x + 4, balde.end.y - 3 - nivel, 32, nivel), Color(0.98, 0.98, 0.96))
	for g in _gotas:
		c.draw_circle(g["p"], 2.5, Color.WHITE)
	# calma (coração) e leite
	textura(c, "res://assets/sprites/extras/coracao.png", Vector2(440, 64), 2.0, false, Color(1, 1, 1, 0.4 + 0.6 * calma))
	barra(c, Rect2(460, 58, 80, 10), calma, Color(0.95, 0.4, 0.45))
	texto_centro(c, Vector2(500, 84), "calma", 8, Color(0.15, 0.1, 0.05), 100)
	barra(c, Rect2(40, 58, 160, 10), leite, Color(0.98, 0.98, 0.96))
	texto_centro(c, Vector2(120, 84), "leite no balde", 8, Color(0.15, 0.1, 0.05), 160)


func _jogador(c: Control, n: int, pos: Vector2, virar: bool) -> void:
	var t := Jogo.tex("res://assets/sprites/personagens/p%d_lado_parado.png" % n)
	c.draw_set_transform(pos, 0.0, Vector2(-3 if virar else 3, 3))
	c.draw_texture(t, Vector2(-8, -24))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
