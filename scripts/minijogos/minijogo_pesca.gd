class_name MinijogoPesca
extends Minijogo
## Papel A aperta AÇÃO várias vezes para puxar a linha (o peixe vem chegando).
## Papel B anda pelo píer com o puçá, seguindo a sombra do peixe,
## e aperta AÇÃO quando o peixe pula. São 3 peixes.

const META := 3
const AGUA_Y := 150.0

var pegos := 0
var estado := "esperando"     # esperando, fisgado, pulando
var espera := 1.5
var dist := 1.0               # 1 = longe, 0 = colado no píer
var puca_x := 300.0
var pulo := 0.0
var _peixe_x := 400.0


func montar() -> void:
	titulo = "Pescar no píer"
	texto_a = "APERTE %s para puxar a linha" % Jogo.tecla_acao(na)
	texto_b = "%s anda · %s pega" % [Jogo.teclas_lado(nb), Jogo.tecla_acao(nb)]


func atualizar(delta: float) -> void:
	puca_x = clampf(puca_x + Jogo.direcao(nb).x * 170.0 * delta, 160.0, 540.0)
	_peixe_x = 190.0 + dist * 320.0 + sin(tempo * 2.3) * 26.0
	match estado:
		"esperando":
			espera -= delta
			if espera <= 0.0:
				estado = "fisgado"
				dist = 1.0
				Sons.tocar("splash")
				mensagem("Fisgou! Puxa a linha!", Color(1, 1, 0.7))
		"fisgado":
			if Jogo.apertou(na):
				dist -= 0.07
				Sons.tocar("forca", -8.0, 1.4)
				acerto()
			dist = minf(1.0, dist + delta * 0.06)
			if dist <= 0.22:
				estado = "pulando"
				pulo = 0.0
				Sons.tocar("splash")
				mensagem("Pulou! Pega com o puçá!", Color(1, 1, 0.7))
		"pulando":
			pulo += delta
			if Jogo.apertou(nb):
				if absf(puca_x - _peixe_x) < 30.0:
					pegos += 1
					Sons.tocar("acerto")
					acerto()
					estado = "esperando"
					espera = 1.2
					dist = 1.0
					if pegos >= META:
						terminar("3 peixes! Que almoço!")
					else:
						mensagem("Pegou! Mais %d." % (META - pegos), Color(0.8, 1, 0.7))
				else:
					erro("Errou! Siga a sombra do peixe.")
					estado = "fisgado"
					dist = 0.45
			elif pulo >= 1.2:
				estado = "fisgado"
				dist = 0.45
				erro("Ele voltou para a água!")


func desenhar(c: Control) -> void:
	# céu, água e píer comprido
	c.draw_rect(Rect2(0, 0, 560, AGUA_Y), Color(0.62, 0.84, 0.97))
	c.draw_rect(Rect2(0, AGUA_Y, 560, 150), Color("498ce6"))
	for i in 7:
		var x := fmod(i * 90.0 + tempo * 20.0, 560.0)
		c.draw_line(Vector2(x, AGUA_Y + 30 + i * 14), Vector2(x + 20, AGUA_Y + 30 + i * 14), Color("96c8fa"), 1.0)
	c.draw_rect(Rect2(0, AGUA_Y - 14, 560, 10), Color("a66e3e"))
	for x in range(0, 560, 40):
		c.draw_rect(Rect2(x + 6, AGUA_Y - 4, 6, 26), Color("784a28"))
	# quem pesca, na ponta do píer
	_jogador(c, na, Vector2(60, AGUA_Y - 14), false)
	var ponta := Vector2(120, 70)
	c.draw_line(Vector2(80, AGUA_Y - 36), ponta, Color("784a28"), 3.0)
	# peixe
	var peixe_pos := Vector2(_peixe_x, AGUA_Y + 36)
	if estado == "esperando":
		var boia := Vector2(420, AGUA_Y - 3 + sin(tempo * 4.0) * 2.0)
		c.draw_line(ponta, boia, Color(1, 1, 1, 0.7), 1.0)
		textura(c, "res://assets/sprites/extras/boia.png", boia, 2.0)
	elif estado == "fisgado":
		c.draw_line(ponta, Vector2(_peixe_x, AGUA_Y + 30), Color(1, 1, 1, 0.8), 1.0)
		textura(c, "res://assets/sprites/extras/sombra_peixe.png", peixe_pos, 3.0)
	elif estado == "pulando":
		var altura := sin(clampf(pulo / 1.2, 0.0, 1.0) * PI) * 70.0
		var p := Vector2(_peixe_x, AGUA_Y - altura)
		c.draw_line(ponta, p, Color(1, 1, 1, 0.8), 1.0)
		textura(c, "res://assets/sprites/objetos/peixe.png", p, 3.0)
		texto_centro(c, p + Vector2(0, -28), "!", 16, Color(1, 0.9, 0.3), 40)
	# quem segura o puçá
	_jogador(c, nb, Vector2(puca_x - 26, AGUA_Y - 14), false)
	c.draw_line(Vector2(puca_x - 14, AGUA_Y - 36), Vector2(puca_x, AGUA_Y - 4), Color("784a28"), 3.0)
	c.draw_arc(Vector2(puca_x, AGUA_Y), 14, 0, PI, 16, Color(0.95, 0.95, 0.95), 2.0)
	c.draw_line(Vector2(puca_x - 14, AGUA_Y), Vector2(puca_x + 14, AGUA_Y), Color("545a66"), 2.0)
	# placar
	for i in META:
		var cor := Color.WHITE if i < pegos else Color(0, 0, 0, 0.35)
		textura(c, "res://assets/sprites/objetos/peixe.png", Vector2(440 + i * 34, 52), 2.0, false, cor)
	if estado == "fisgado":
		texto_centro(c, Vector2(130, 52), "distância do peixe", 8, Color(0.15, 0.1, 0.05), 160)
		barra(c, Rect2(60, 58, 140, 10), dist, Color(0.3, 0.5, 0.95))


func _jogador(c: Control, n: int, pos: Vector2, virar: bool) -> void:
	var t := Jogo.tex("res://assets/sprites/personagens/p%d_lado_parado.png" % n)
	c.draw_set_transform(pos, 0.0, Vector2(-3 if virar else 3, 3))
	c.draw_texture(t, Vector2(-8, -24))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
