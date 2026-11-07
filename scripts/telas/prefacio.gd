extends Control
## Prefácio inspirado na abertura de Star Wars, mas na roça: o dia amanhecendo,
## o galo cantando, a frase "Há pouco tempo...", o título que vai embora para o
## horizonte e o texto amarelo deitado no pasto, indo em direção à casa da Vovó.
## No fim a câmera chega na casa, onde a Vovó e os netos esperam,
## e o jogo segue para os quadrinhos (cenas/quadrinhos.tscn).
## Feito para crianças de 10 anos: frases curtas, letras grandes e devagar.
## AÇÃO (ou Esc) pula a qualquer momento.

const INTRO := "Há pouco tempo, numa roça\nnão muito distante..."

const EPISODIO := "Episódio I"
const TITULO := "A FESTA DA COLHEITA"
## Uma ideia por frase. Cada frase vira um bloco no pasto.
const PARAGRAFOS := [
	"Dois netos chegaram para as férias na fazenda da Vovó Zefa.",
	"Mas a fazenda perdeu todas as cores!",
	"O poço quebrou. O trator atolou. As galinhas fugiram.",
	"Sozinho, ninguém consegue arrumar tudo.",
	"Mas juntos, os dois conseguem!",
	"Em cinco dias, eles vão trazer as cores de volta...",
	"...e fazer a grande Festa da Colheita!",
]
## Tamanho das letras no pasto (a perspectiva diminui com a distância).
const TAMANHO_TEXTO := 58

# linha do tempo (segundos). A fanfarra entra forte aos 7,4 s.
# O texto roda mais devagar que antes: a câmera só chega na casa aos 62 s.
const T_MUSICA := 0.2
const T_GALO := 1.0
const T_INTRO := [0.8, 1.6, 6.4, 7.2]   # aparece, fica, começa a sumir, sumiu
const T_LOGO := 7.4
const T_LETREIRO := 8.5
const T_CHEGAR := 62.0                   # a câmera chega na casa da Vovó
const DUR_CHEGAR := 4.0
const T_FIM := 66.0
const T_SAIR_SOZINHO := 84.0

# o chão em perspectiva (os mesmos números vão para o shader letreiro.gdshader)
const HORIZONTE := 116.0
const ESCALA := 0.62
const ALTURA_CHAO := 360.0 - HORIZONTE
const CERCA := 540.0
const PASSO_POSTE := 150.0
const CASA_MENU := Vector2(430, 234)     # onde fica a casa na paisagem do menu

const PASTA := "res://assets/sprites/menu/"
const AMARELO := Color(1.0, 0.85, 0.22)
const MARROM := Color(0.28, 0.13, 0.04)
const LARGURA := 960

var _tempo := 0.0
var _saindo := false
var _galo := false
var _musica_tocando := false
var _rolagem := -10.0
var _velocidade := 26.0
var _manha := 0.0             # 0 = amanhecendo, 1 = manhã clara
var _casa := Vector2(404, 88)
var _helice := Vector2(236, 84)
var _fumaca: Array = []
var _passaros: Array = []

var _cena: Control            # céu + chão + cerca (é essa que leva o zoom no final)
var _ceu: Control
var _campo: ColorRect
var _campo_mat: ShaderMaterial
var _cerca: Control
var _sub: SubViewport
var _coluna: VBoxContainer
var _paisagem: Paisagem
var _intro: Label
var _logo: Label
var _final: Label
var _final_mat: ShaderMaterial
var _aperte: Label
var _pular: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Sons.parar_musica()
	_ler_horizonte()
	for i in 3:
		_passaros.append({"x": randf_range(-200, 300), "y": randf_range(20, 70), "v": randf_range(12, 18), "fase": randf() * TAU})

	_cena = Control.new()
	_cena.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cena.pivot_offset = _casa
	add_child(_cena)
	_ceu = _camada(_desenhar_ceu)
	_montar_letreiro()
	_cerca = _camada(_desenhar_cerca)

	_paisagem = Paisagem.new()
	_paisagem.modulate.a = 0.0
	add_child(_paisagem)

	_intro = Fontes.rotulo(INTRO, Fontes.pixel(500), 22, Color(0.7, 0.93, 1.0), 6, Color(0.08, 0.1, 0.26))
	_intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro.position = Vector2(0, 24)
	_intro.size = Vector2(640, 60)
	_intro.modulate.a = 0.0
	add_child(_intro)

	_logo = Fontes.rotulo("Juntos\nna Roça", Fontes.titulo(), 76, AMARELO, 10, MARROM)
	_logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_logo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_logo.add_theme_constant_override("line_spacing", -18)
	_logo.size = Vector2(640, 220)
	_logo.pivot_offset = Vector2(320, 110)
	_logo.visible = false
	add_child(_logo)

	_final = Fontes.rotulo("Agora é com vocês dois!", Fontes.titulo(), 30, Color.WHITE, 9, Color(0.25, 0.11, 0.05))
	_final.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_final.position = Vector2(0, 40)
	_final.size = Vector2(640, 44)
	_final_mat = ShaderMaterial.new()
	_final_mat.shader = load("res://assets/shaders/logo_ouro.gdshader")
	_final_mat.set_shader_parameter("altura", 38.0)
	_final.material = _final_mat
	_final.modulate.a = 0.0
	add_child(_final)
	_aperte = Fontes.rotulo("Aperte Espaço ou Enter!", Fontes.pixel(500), 16, Color(1, 0.97, 0.85), 4, Color(0.2, 0.1, 0.05))
	_aperte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aperte.position = Vector2(0, 92)
	_aperte.size = Vector2(640, 20)
	_aperte.modulate.a = 0.0
	add_child(_aperte)

	_pular = Fontes.rotulo("Espaço ou Enter: pular", Fontes.pixel(500), 10, Color(1, 1, 1, 0.75), 3, Color(0.1, 0.08, 0.15))
	_pular.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_pular.position = Vector2(440, 6)
	_pular.size = Vector2(194, 14)
	_pular.modulate.a = 0.0
	add_child(_pular)

	# a altura do texto só é conhecida depois que o Godot arruma a coluna
	await get_tree().process_frame
	await get_tree().process_frame
	var altura := _coluna.get_combined_minimum_size().y
	_sub.size = Vector2i(LARGURA, int(altura) + 40)
	_campo_mat.set_shader_parameter("tamanho_texto", Vector2(_sub.size))
	# o último parágrafo chega perto do meio do pasto quando a câmera chega na casa
	var profundidade := ALTURA_CHAO / ESCALA
	_velocidade = (altura + profundidade * 0.8) / (T_CHEGAR - T_LETREIRO)


func _camada(desenho: Callable) -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(desenho)
	_cena.add_child(c)
	return c


## Onde ficam a casinha e o cata-vento no desenho do horizonte (o gerar_prefacio.py anota).
func _ler_horizonte() -> void:
	var f := FileAccess.open(PASTA + "horizonte_casa.txt", FileAccess.READ)
	if f == null:
		return
	var n := f.get_as_text().split(" ")
	if n.size() >= 4:
		var topo := HORIZONTE - 64.0
		_casa = Vector2(float(n[0]), topo + float(n[1]))
		_helice = Vector2(float(n[2]), topo + float(n[3]))


func _montar_letreiro() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(LARGURA, 2600)
	_sub.transparent_bg = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sub)
	_coluna = VBoxContainer.new()
	_coluna.custom_minimum_size = Vector2(LARGURA, 0)
	_coluna.add_theme_constant_override("separation", 34)
	_sub.add_child(_coluna)
	var ep := Fontes.rotulo(EPISODIO, Fontes.pixel(500), 44, AMARELO, 8, MARROM)
	ep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coluna.add_child(ep)
	var titulo := Fontes.rotulo(TITULO, Fontes.pixel(500), 66, AMARELO, 9, MARROM)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coluna.add_child(titulo)
	for p in PARAGRAFOS:
		var l := Fontes.rotulo(p, Fontes.pixel(500), TAMANHO_TEXTO, AMARELO, 9, MARROM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_constant_override("line_spacing", 4)
		l.custom_minimum_size = Vector2(LARGURA, 0)
		_coluna.add_child(l)
	_campo = ColorRect.new()
	_campo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_campo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_campo_mat = ShaderMaterial.new()
	_campo_mat.shader = load("res://assets/shaders/letreiro.gdshader")
	_campo_mat.set_shader_parameter("texto", _sub.get_texture())
	_campo_mat.set_shader_parameter("tamanho_texto", Vector2(_sub.size))
	_campo_mat.set_shader_parameter("horizonte", HORIZONTE)
	_campo_mat.set_shader_parameter("escala", ESCALA)
	_campo_mat.set_shader_parameter("rolagem", _rolagem)
	_campo.material = _campo_mat
	_cena.add_child(_campo)


# ------------------------------------------------------------------ cores do amanhecer
func _ceu_cores() -> Array:
	var topo := Color(0.16, 0.19, 0.42).lerp(Color(0.27, 0.45, 0.86), _manha)
	var meio := Color(0.56, 0.42, 0.64).lerp(Color(0.55, 0.71, 0.96), _manha)
	var baixo := Color(0.98, 0.62, 0.44).lerp(Color(0.96, 0.88, 0.7), _manha)
	return [topo, meio, baixo]


func _luz() -> Color:
	return Color(0.8, 0.68, 0.78).lerp(Color.WHITE, _manha)


func _neblina() -> Color:
	return (_ceu_cores()[2] as Color).lerp(Color(0.5, 0.68, 0.42), 0.55)


func _longe(c: Color, z: float) -> Color:
	var l := _luz()
	return Color(c.r * l.r, c.g * l.g, c.b * l.b, c.a).lerp(_neblina(), smoothstep(2.0, 14.0, z) * 0.75)


# ------------------------------------------------------------------ cada quadro
func _process(delta: float) -> void:
	_tempo += delta
	var t := _tempo
	if not _musica_tocando and t >= T_MUSICA:
		_musica_tocando = true
		Sons.musica("musica_prefacio", false)
	if not _galo and t >= T_GALO:
		_galo = true
		Sons.tocar("galo", -4.0)

	_manha = smoothstep(0.0, T_CHEGAR - 3.0, t)

	# 1) a frase azul
	_intro.modulate.a = _faixa(t, T_INTRO[0], T_INTRO[1], T_INTRO[2], T_INTRO[3])

	# 2) o título vai embora para o horizonte
	if t >= T_LOGO:
		var s := t - T_LOGO
		var escala := 1.25 * exp(-s * 0.5)
		_logo.visible = s < 9.0
		_logo.scale = Vector2.ONE * escala
		var centro := Vector2(320, 180).lerp(Vector2(320, HORIZONTE), 1.0 - escala / 1.25)
		_logo.position = centro - _logo.pivot_offset
		_logo.modulate.a = 1.0 - smoothstep(6.0, 8.5, s)

	# 3) o texto deitado no pasto (o chão anda junto: a câmera vai voando para a casa)
	if t >= T_LETREIRO:
		_rolagem = -10.0 + (t - T_LETREIRO) * _velocidade
	_campo_mat.set_shader_parameter("rolagem", _rolagem)
	var l := _luz()
	_campo_mat.set_shader_parameter("luz", Vector3(l.r, l.g, l.b))
	var n := _neblina()
	_campo_mat.set_shader_parameter("neblina", Vector3(n.r, n.g, n.b))

	# 4) chegando na casa da Vovó: a câmera vai até a casinha do horizonte, que cresce
	# até ficar do tamanho e no lugar da casa da paisagem do menu, e a paisagem aparece
	var chegar := smoothstep(T_CHEGAR, T_CHEGAR + DUR_CHEGAR, t)
	_cena.scale = Vector2.ONE * (1.0 + 2.8 * chegar)
	_cena.position = (CASA_MENU - _casa) * chegar
	_campo_mat.set_shader_parameter("texto_alfa", 1.0 - smoothstep(T_CHEGAR, T_CHEGAR + 1.5, t))
	_paisagem.modulate.a = smoothstep(T_CHEGAR + 2.0, T_CHEGAR + 3.4, t)

	# 5) o final
	if t >= T_FIM:
		_final.modulate.a = minf(1.0, (t - T_FIM) / 1.0)
		_final_mat.set_shader_parameter("brilho_pos", -150.0 + fmod(t - T_FIM, 4.0) * 400.0)
		if t >= T_FIM + 1.5:
			_aperte.modulate.a = 0.35 + 0.65 * absf(sin((t - T_FIM) * 2.5))
	_pular.modulate.a = 0.0 if t >= T_FIM else clampf(t - 1.0, 0.0, 1.0)

	# fumaça da chaminé e passarinhos
	if randf() < delta * 1.6:
		_fumaca.append({"p": Vector2(_casa.x + 7, _casa.y - 15), "vida": 0.0})
	for f in _fumaca:
		f["vida"] += delta
		f["p"] += Vector2(2.5, -5.0) * delta
	_fumaca = _fumaca.filter(func(f): return f["vida"] < 4.0)
	for p in _passaros:
		p["x"] += p["v"] * delta
		if p["x"] > 680:
			p["x"] = -30.0
			p["y"] = randf_range(20, 70)

	if not _saindo and t > 0.5:
		if Jogo.apertou(1) or Jogo.apertou(2) or Input.is_action_just_pressed("pausa"):
			_sair()
		elif t >= T_SAIR_SOZINHO:
			_sair()
	_ceu.queue_redraw()
	_cerca.queue_redraw()


## 0 antes de "a", sobe até 1 em "b", fica, e desce de "c" até "d".
func _faixa(t: float, a: float, b: float, c: float, d: float) -> float:
	return smoothstep(a, b, t) * (1.0 - smoothstep(c, d, t))


# ------------------------------------------------------------------ desenho: céu e horizonte
func _desenhar_ceu() -> void:
	var c := _ceu
	var cores := _ceu_cores()
	var faixas := 29
	for i in faixas:
		var y := i * 4.0
		var k := y / HORIZONTE
		var cor: Color = (cores[0] as Color).lerp(cores[1], k * 2.0) if k < 0.5 else (cores[1] as Color).lerp(cores[2], (k - 0.5) * 2.0)
		c.draw_rect(Rect2(0, y, 640, 4), cor)
	var l := _luz()
	# o sol nascendo atrás da serra
	var sol_y := lerpf(HORIZONTE + 6.0, 30.0, smoothstep(0.0, 48.0, _tempo))
	c.draw_texture(Jogo.tex(PASTA + "sol.png"), Vector2(520 - 48, sol_y - 48))
	# nuvens (rosadas no amanhecer)
	var tinta_nuvem := Color(1.0, 0.78, 0.84).lerp(Color.WHITE, _manha)
	var nuvens := Jogo.tex(PASTA + "nuvens.png")
	var x := -fmod(_tempo * 4.0, 1280.0)
	c.draw_texture(nuvens, Vector2(x, -46), tinta_nuvem)
	c.draw_texture(nuvens, Vector2(x + 1280, -46), tinta_nuvem)
	# passarinhos
	for p in _passaros:
		var asa := 2.5 * sin(_tempo * 9.0 + p["fase"])
		var b := Vector2(p["x"], p["y"])
		c.draw_line(b, b + Vector2(-4, -asa), Color(0.2, 0.15, 0.25), 1.0)
		c.draw_line(b, b + Vector2(4, -asa), Color(0.2, 0.15, 0.25), 1.0)
	# fumaça
	for f in _fumaca:
		var vida: float = f["vida"]
		c.draw_circle(f["p"], 1.5 + vida * 1.2, Color(0.95, 0.93, 0.95, 0.55 * (1.0 - vida / 4.0)))
	# o horizonte: serra, morros, casinha, galpão e cata-vento
	var tinta := Color(l.r, l.g, l.b).lerp(_neblina(), 0.2)
	c.draw_texture(Jogo.tex(PASTA + "horizonte.png"), Vector2(0, HORIZONTE - 64), tinta)
	var giro := _tempo * 2.2
	for k in 4:
		var a := giro + k * PI / 2.0
		c.draw_line(_helice, _helice + Vector2(cos(a), sin(a)) * 7.0, Color(0.93, 0.93, 0.97) * tinta, 1.0)
	c.draw_rect(Rect2(_helice - Vector2(1, 1), Vector2(2, 2)), Color(0.77, 0.33, 0.24) * tinta)


# ------------------------------------------------------------------ desenho: cerca e girassóis em perspectiva
## Do mundo (de lado X, para frente Y, em texels) para a tela. z = distância (1 = borda de baixo).
func _projetar(x_mundo: float, y_mundo: float) -> Vector3:
	var z := 1.0 + (_rolagem - y_mundo) * ESCALA / ALTURA_CHAO
	return Vector3(320.0 + x_mundo * ESCALA / z, HORIZONTE + ALTURA_CHAO / z, z)


func _desenhar_cerca() -> void:
	var coisas: Array = []
	var profundidade := ALTURA_CHAO / ESCALA
	var y_longe := _rolagem - 24.0 * profundidade
	var y_perto := _rolagem + 0.6 * profundidade
	var k0 := int(floor(y_longe / PASSO_POSTE))
	var k1 := int(ceil(y_perto / PASSO_POSTE))
	for lado in [-1.0, 1.0]:
		var anterior := Vector3.ZERO
		for k in range(k0, k1 + 1):
			var p := _projetar(lado * CERCA, k * PASSO_POSTE)
			if p.z < 0.4:
				continue
			coisas.append({"z": p.z, "tipo": "poste", "p": p})
			if anterior != Vector3.ZERO:
				coisas.append({"z": (p.z + anterior.z) * 0.5, "tipo": "tabua", "a": anterior, "b": p})
			anterior = p
		# girassóis do lado de fora da cerca
		for k in range(int(floor(y_longe / 320.0)), int(ceil(y_perto / 320.0)) + 1):
			var g := _projetar(lado * (CERCA + 70.0), k * 320.0 + (160.0 if lado > 0 else 0.0))
			if g.z >= 0.4:
				coisas.append({"z": g.z, "tipo": "girassol", "p": g})
	coisas.sort_custom(func(a, b): return a["z"] > b["z"])
	var madeira := Color(0.58, 0.4, 0.23)
	var madeira_escura := Color(0.38, 0.25, 0.14)
	for coisa in coisas:
		var z: float = coisa["z"]
		match coisa["tipo"]:
			"poste":
				var p: Vector3 = coisa["p"]
				var w := maxf(1.0, 12.0 * ESCALA / z)
				var h := 80.0 * ESCALA / z
				_cerca.draw_rect(Rect2(p.x - w * 0.5, p.y - h, w, h), _longe(madeira_escura, z))
				_cerca.draw_rect(Rect2(p.x - w * 0.5, p.y - h, maxf(1.0, w * 0.6), h), _longe(madeira, z))
			"tabua":
				var a: Vector3 = coisa["a"]
				var b: Vector3 = coisa["b"]
				for altura in [0.4, 0.75]:
					var pa := Vector2(a.x, a.y - 80.0 * altura * ESCALA / a.z)
					var pb := Vector2(b.x, b.y - 80.0 * altura * ESCALA / b.z)
					_cerca.draw_line(pa, pb, _longe(madeira, z), maxf(1.0, 7.0 * ESCALA / z))
			"girassol":
				var g: Vector3 = coisa["p"]
				var h := 100.0 * ESCALA / z
				var tex := Jogo.tex(PASTA + "girassol.png")
				_cerca.draw_texture_rect(tex, Rect2(g.x - h * 0.25, g.y - h, h * 0.5, h), false, _longe(Color.WHITE, z))


func _sair() -> void:
	_saindo = true
	var preto := ColorRect.new()
	preto.color = Color(0, 0, 0, 0)
	preto.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(preto)
	var tw := create_tween()
	tw.tween_property(preto, "color:a", 1.0, 0.6)
	await tw.finished
	Sons.parar_musica()
	get_tree().change_scene_to_file("res://cenas/quadrinhos.tscn")
