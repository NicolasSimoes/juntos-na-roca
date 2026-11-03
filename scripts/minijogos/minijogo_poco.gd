class_name MinijogoPoco
extends Minijogo
## Papel A: escolhe uma tábua na pilha e encaixa no espaço de MESMO formato.
## Papel B: bate o martelo quando o marcador passa no prego.
## O prego só aparece com a tábua encaixada, e a próxima tábua só entra
## depois que a anterior foi pregada.

const FORMAS := ["quadrado", "triangulo", "circulo", "losango"]
const PREGOS_POR_TABUA := 2
const MADEIRA := Color("a66e3e")
const MADEIRA_ESCURA := Color("784a28")
const ZONA := 0.11          # metade da largura da faixa do prego (0..1)

var vagas: Array = []        # formato de cada espaço da tampa
var pilha: Array = []        # formatos na pilha ("" = já usada)
var pregos := {}             # espaço -> pregos que faltam
var cursor_pilha := 0
var cursor_vaga := 0
var segurando := ""
var _de_onde := 0            # de que posição da pilha a tábua saiu
var vaga_pregando := -1
var marcador := 0.0
var _sentido := 1.0
var _batida := 0.0
var _tremor := 0.0


func montar() -> void:
	titulo = "Consertar o poço"
	texto_a = "%s escolhe · %s encaixa" % [Jogo.teclas_lado(na), Jogo.tecla_acao(na)]
	texto_b = "%s quando passar no prego" % Jogo.tecla_acao(nb)
	vagas = FORMAS.duplicate()
	vagas.shuffle()
	pilha = FORMAS.duplicate()
	pilha.shuffle()


func _pos_vaga(i: int) -> Vector2:
	return Vector2(80 + i * 78, 98)


func _pos_pilha(i: int) -> Vector2:
	return Vector2(80 + i * 78, 196)


func atualizar(delta: float) -> void:
	_batida = maxf(0.0, _batida - delta)
	_tremor = maxf(0.0, _tremor - delta)
	_papel_a()
	_papel_b(delta)


func _papel_a() -> void:
	if segurando == "":
		if Jogo.apertou_esquerda(na):
			cursor_pilha = (cursor_pilha + 3) % 4
		if Jogo.apertou_direita(na):
			cursor_pilha = (cursor_pilha + 1) % 4
		if Jogo.apertou(na):
			if vaga_pregando >= 0:
				erro("Espere o martelo pregar!")
			elif pilha[cursor_pilha] == "":
				erro("Essa já foi usada.")
			else:
				segurando = pilha[cursor_pilha]
				_de_onde = cursor_pilha
				pilha[cursor_pilha] = ""
				Sons.tocar("pegar")
				cursor_vaga = 0
				while pregos.has(cursor_vaga) and cursor_vaga < 3:
					cursor_vaga += 1
	else:
		if Jogo.apertou_esquerda(na):
			cursor_vaga = (cursor_vaga + 3) % 4
		if Jogo.apertou_direita(na):
			cursor_vaga = (cursor_vaga + 1) % 4
		if Jogo.apertou(na):
			if pregos.has(cursor_vaga):
				erro("Esse espaço já está pronto.")
			elif vagas[cursor_vaga] == segurando:
				pregos[cursor_vaga] = PREGOS_POR_TABUA
				vaga_pregando = cursor_vaga
				segurando = ""
				Sons.tocar("encaixe")
				mensagem("Encaixou! Agora o martelo.", Color(0.8, 1, 0.7))
				acerto()
				for k in 4:
					if pilha[(cursor_pilha + k) % 4] != "":
						cursor_pilha = (cursor_pilha + k) % 4
						break
			else:
				erro("Não é esse formato!")
				pilha[_de_onde] = segurando
				segurando = ""


func _papel_b(delta: float) -> void:
	marcador += delta * 0.8 * _sentido
	if marcador >= 1.0:
		marcador = 1.0
		_sentido = -1.0
	elif marcador <= 0.0:
		marcador = 0.0
		_sentido = 1.0
	if not Jogo.apertou(nb):
		return
	if vaga_pregando < 0:
		mensagem("Espere a tábua ser encaixada!", Color(1, 0.9, 0.6))
		return
	_batida = 0.18
	if absf(marcador - 0.5) <= ZONA:
		pregos[vaga_pregando] -= 1
		Sons.tocar("toc")
		acerto()
		if pregos[vaga_pregando] <= 0:
			vaga_pregando = -1
			if pregos.size() == 4:
				terminar("Poço consertado!")
	else:
		_tremor = 0.3
		erro("Errou o prego!")


# ------------------------------------------------------------------ desenho
func desenhar(c: Control) -> void:
	# tampa do poço com os 4 espaços
	c.draw_rect(Rect2(36, 52, 312, 94), Color("8b8f99"))
	c.draw_rect(Rect2(36, 52, 312, 94), Color("5a5e68"), false, 3)
	for i in 4:
		var p := _pos_vaga(i)
		if pregos.has(i):
			_forma(c, vagas[i], p, 46, MADEIRA, MADEIRA_ESCURA)
			_desenhar_pregos(c, i, p)
		else:
			_forma(c, vagas[i], p, 46, Color(0.12, 0.1, 0.1), Color(0.3, 0.3, 0.32))
		if segurando != "" and i == cursor_vaga:
			c.draw_rect(Rect2(p - Vector2(30, 30), Vector2(60, 60)), Jogo.COR[na], false, 2.5)
	# tábua na mão do papel A
	if segurando != "":
		var p := _pos_vaga(cursor_vaga) + Vector2(0, -2 + 3 * sin(tempo * 8.0))
		_forma(c, segurando, p, 40, MADEIRA.lightened(0.15), MADEIRA_ESCURA)
	# pilha
	texto_centro(c, Vector2(192, 162), "pilha de tábuas", 8, Color(0.2, 0.15, 0.1), 200)
	for i in 4:
		var p := _pos_pilha(i)
		c.draw_rect(Rect2(p - Vector2(30, 26), Vector2(60, 52)), Color(0.45, 0.62, 0.3, 0.6))
		if pilha[i] != "":
			_forma(c, pilha[i], p, 40, MADEIRA, MADEIRA_ESCURA)
		if segurando == "" and i == cursor_pilha:
			var cor: Color = Jogo.COR[na]
			if vaga_pregando >= 0:
				cor = cor.darkened(0.5)
			c.draw_rect(Rect2(p - Vector2(31, 27), Vector2(62, 54)), cor, false, 2.5)
	if vaga_pregando >= 0 and segurando == "":
		texto_centro(c, Vector2(192, 240), "espere o martelo...", 8, Color(0.3, 0.2, 0.1), 200)
	_desenhar_martelo(c)


func _desenhar_pregos(c: Control, i: int, p: Vector2) -> void:
	var faltam: int = pregos[i]
	var posicoes := [Vector2(-12, -12), Vector2(12, 10)]
	for k in PREGOS_POR_TABUA:
		var pp: Vector2 = p + posicoes[k]
		var batido := k < PREGOS_POR_TABUA - faltam
		if batido:
			c.draw_circle(pp, 2.5, Color("545a66"))
		else:
			c.draw_rect(Rect2(pp + Vector2(-1, -9), Vector2(2, 9)), Color("9aa0aa"))
			c.draw_rect(Rect2(pp + Vector2(-3, -11), Vector2(6, 2)), Color("545a66"))


func _desenhar_martelo(c: Control) -> void:
	var area := Rect2(378, 52, 164, 190)
	c.draw_rect(area, Color(1, 1, 1, 0.25))
	texto_centro(c, Vector2(area.get_center().x, 68), "martelo", 9, Color(0.2, 0.15, 0.1), 160)
	var tremor := Vector2(sin(tempo * 80.0) * 3.0 * _tremor / 0.3, 0)
	var r := Rect2(390, 150, 140, 16)
	r.position += tremor
	c.draw_rect(r.grow(2), Color(0.15, 0.1, 0.06))
	c.draw_rect(r, Color(0.85, 0.75, 0.6))
	var zona := Rect2(r.position.x + r.size.x * (0.5 - ZONA), r.position.y, r.size.x * ZONA * 2, r.size.y)
	var cor_zona := Color(0.4, 0.8, 0.35) if vaga_pregando >= 0 else Color(0.6, 0.6, 0.6)
	c.draw_rect(zona, cor_zona)
	textura(c, "res://assets/sprites/objetos/prego.png", Vector2(zona.get_center().x, r.position.y - 10), 1.5)
	var mx := r.position.x + r.size.x * marcador
	c.draw_rect(Rect2(mx - 2, r.position.y - 4, 4, r.size.y + 8), Jogo.COR[nb])
	c.draw_rect(Rect2(mx - 2, r.position.y - 4, 4, r.size.y + 8), Color.BLACK, false, 1)
	# martelo balançando
	var ang := -0.9 if _batida <= 0.0 else 0.4
	c.draw_set_transform(Vector2(area.get_center().x + 6, 116), ang, Vector2(3, 3))
	var t := Jogo.tex("res://assets/sprites/objetos/martelo.png")
	c.draw_texture(t, Vector2(-8, -12))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if vaga_pregando < 0:
		texto_centro(c, Vector2(area.get_center().x, 200), "espere a tábua...", 8, Color(0.3, 0.2, 0.1), 160)
	else:
		texto_centro(c, Vector2(area.get_center().x, 200), "AGORA!" if absf(marcador - 0.5) <= ZONA else "", 10, Color(0.2, 0.5, 0.1), 160)


func _forma(c: Control, forma: String, centro: Vector2, tam: float, cor: Color, borda: Color) -> void:
	var m := tam / 2.0
	var pontos := PackedVector2Array()
	match forma:
		"quadrado":
			pontos = PackedVector2Array([centro + Vector2(-m, -m), centro + Vector2(m, -m), centro + Vector2(m, m), centro + Vector2(-m, m)])
		"triangulo":
			pontos = PackedVector2Array([centro + Vector2(0, -m), centro + Vector2(m, m), centro + Vector2(-m, m)])
		"losango":
			pontos = PackedVector2Array([centro + Vector2(0, -m), centro + Vector2(m, 0), centro + Vector2(0, m), centro + Vector2(-m, 0)])
		"circulo":
			for k in 24:
				pontos.append(centro + Vector2(m, 0).rotated(TAU * k / 24.0))
	c.draw_colored_polygon(pontos, cor)
	var fechado := pontos.duplicate()
	fechado.append(pontos[0])
	c.draw_polyline(fechado, borda, 2.0)
