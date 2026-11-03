class_name MinijogoTrator
extends Minijogo
## Papel A segura AÇÃO (acelera). Papel B aperta várias vezes (empurra).
## A barra de força só sobe quando os dois fazem força ao mesmo tempo.

var forca := 0.0
var _ultimo_empurrao := -10.0
var _sozinho := 0.0
var _motor := 0.0
var _empurrao := 0.0
var _respingos: Array = []
var _roda := 0.0


func montar() -> void:
	titulo = "Desatolar o trator"
	texto_a = "SEGURE %s para acelerar" % Jogo.tecla_acao(na)
	texto_b = "APERTE %s várias vezes" % Jogo.tecla_acao(nb)


func atualizar(delta: float) -> void:
	var acelerando := Jogo.segurando(na)
	_empurrao = maxf(0.0, _empurrao - delta)
	if acelerando:
		_roda += delta * 18.0
		_motor -= delta
		if _motor <= 0.0:
			_motor = 0.55
			Sons.tocar("motor", -4.0)
	if Jogo.apertou(nb):
		_empurrao = 0.15
		if acelerando:
			forca += 0.075
			_ultimo_empurrao = tempo
			Sons.tocar("forca", -4.0, 0.8 + forca)
			acerto()
		else:
			erro("O trator está desligado! Acelera aí!")
	if acelerando and tempo - _ultimo_empurrao > 1.2:
		_sozinho += delta
		if randf() < 0.5:
			_respingos.append({"p": Vector2(250 + forca * 120, 210), "v": Vector2(randf_range(-160, -40), randf_range(-160, -60)), "vida": 0.6})
		if _sozinho > 2.2:
			_sozinho = 0.0
			erro("Sozinho, a roda só gira! Empurra!")
	else:
		_sozinho = 0.0
	forca = maxf(0.0, forca - delta * 0.04)
	for r in _respingos:
		r["v"] += Vector2(0, 400) * delta
		r["p"] += r["v"] * delta
		r["vida"] -= delta
	_respingos = _respingos.filter(func(r): return r["vida"] > 0)
	if forca >= 1.0:
		forca = 1.0
		terminar("Saiu da lama!")


func desenhar(c: Control) -> void:
	c.draw_rect(Rect2(0, 200, 560, 100), Color("6abe30"))
	c.draw_rect(Rect2(140, 196, 260, 40), Color("684830"))
	c.draw_rect(Rect2(150, 202, 240, 24), Color("503622"))
	var x := 250.0 + forca * 120.0
	var tremor := sin(tempo * 60.0) * 2.0 if _empurrao > 0.0 else 0.0
	var pos := Vector2(x + tremor, 214)
	# quem empurra, atrás do trator
	var t_b := Jogo.tex("res://assets/sprites/personagens/p%d_lado_parado.png" % nb)
	c.draw_set_transform(pos + Vector2(-80 + (6 if _empurrao > 0 else 0), -2), 0.0, Vector2(3, 3))
	c.draw_texture(t_b, Vector2(-8, -24))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# trator
	var t := Jogo.tex("res://assets/sprites/extras/trator.png")
	c.draw_set_transform(pos, 0.0, Vector2(4, 4))
	c.draw_texture(t, Vector2(-16, -21))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# raios da roda girando
	for centro in [pos + Vector2(-34, -10), pos + Vector2(30, -10)]:
		for k in 3:
			var a := _roda + k * TAU / 3.0
			c.draw_line(centro, centro + Vector2(10, 0).rotated(a), Color(0.75, 0.75, 0.8), 2.0)
	# quem acelera, na cabine
	var t_a := Jogo.tex("res://assets/sprites/personagens/p%d_lado_parado.png" % na)
	c.draw_set_transform(pos + Vector2(-20, -66), 0.0, Vector2(2, 2))
	c.draw_texture_rect_region(t_a, Rect2(-8, -11, 16, 11), Rect2(0, 1, 16, 11))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for r in _respingos:
		c.draw_rect(Rect2(r["p"], Vector2(4, 4)), Color("684830"))
	texto_centro(c, Vector2(280, 58), "força da dupla", 9, Color(0.15, 0.1, 0.05), 200)
	barra(c, Rect2(160, 64, 240, 14), forca, Color(0.95, 0.55, 0.2))
	if Jogo.segurando(na):
		texto_centro(c, pos + Vector2(10, -96), "VRUM!", 10, Color(1, 0.9, 0.4), 80)
