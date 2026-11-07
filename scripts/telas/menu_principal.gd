extends Control
## Menu principal, no estilo dos Zelda antigos: título dourado com brilho,
## "Aperte AÇÃO", e uma caixa com borda dourada e um vaga-lume de cursor.
## Os dois jogadores podem mexer no menu.
## "Como jogar" e "Créditos" são cenas próprias (cenas/como_jogar.tscn e
## cenas/creditos.tscn) que abrem por cima do menu e avisam quando fecham.

const OPCOES := ["Jogar", "Como jogar", "Créditos"]
const CAIXA := Rect2(92, 186, 228, 98)
const CENA_TECLA := preload("res://cenas/objetos/tecla.tscn")
const PAINEIS := {
	"Como jogar": preload("res://cenas/como_jogar.tscn"),
	"Créditos": preload("res://cenas/creditos.tscn"),
}

var _estado := "titulo"        # titulo, menu, painel, saindo
var _escolha := 0
var _tempo := 0.0
var _tempo_estado := 0.0
var _paisagem: Paisagem
var _logo: Label
var _logo_mat: ShaderMaterial
var _sub: Label
var _aperte: Control
var _camada_menu: Control
var _rotulos: Array[Label] = []
var _painel: Control
var _flash: ColorRect
var _cursor_y := 0.0
var _rastro: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Jogo.novo_jogo()
	Sons.musica("musica_menu")
	_paisagem = Paisagem.new()
	add_child(_paisagem)
	_montar_logo()
	# "Aperte [Espaço] ou [Enter]" com as teclas desenhadas
	_aperte = _linha_de_teclas([["texto", "Aperte"], ["tecla", "Espaço", 50], ["texto", "ou"], ["tecla", "Enter", 40]], 14)
	_aperte.position = Vector2(0, 140)
	_aperte.size = Vector2(640, 24)
	add_child(_aperte)
	var rodape := Fontes.rotulo("Grupo AmendoBobos  ·  2026", Fontes.pixel(), 9, Color(1, 1, 1, 0.85), 3, Color(0.1, 0.1, 0.15))
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rodape.position = Vector2(0, 344)
	rodape.size = Vector2(640, 14)
	add_child(rodape)
	_montar_menu()
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	# entrada: o título desce do céu
	_logo.position.y = -90
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_logo, "position:y", 22.0, 1.1)
	_sub.modulate.a = 0.0
	create_tween().tween_property(_sub, "modulate:a", 1.0, 0.8).set_delay(0.9)


func _montar_logo() -> void:
	_logo = Fontes.rotulo("Juntos na Roça", Fontes.titulo(), 50, Color.WHITE, 12, Color(0.27, 0.12, 0.05))
	_logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_logo.position = Vector2(0, 22)
	_logo.size = Vector2(640, 70)
	_logo_mat = ShaderMaterial.new()
	_logo_mat.shader = load("res://assets/shaders/logo_ouro.gdshader")
	_logo_mat.set_shader_parameter("altura", 60.0)
	_logo.material = _logo_mat
	add_child(_logo)
	_sub = Fontes.rotulo("~ para jogar em dupla ~", Fontes.pixel(500), 13, Color(1, 0.95, 0.8), 4, Color(0.25, 0.12, 0.05))
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.position = Vector2(0, 98)
	_sub.size = Vector2(640, 20)
	add_child(_sub)


func _montar_menu() -> void:
	_camada_menu = Control.new()
	_camada_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_camada_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camada_menu.draw.connect(_desenhar_caixa)
	_camada_menu.modulate.a = 0.0
	add_child(_camada_menu)
	for i in OPCOES.size():
		var l := Fontes.rotulo(OPCOES[i], Fontes.pixel(500), 17, Color.WHITE, 3, Color(0.05, 0.05, 0.12))
		l.position = Vector2(CAIXA.position.x + 62, CAIXA.position.y + 14 + i * 26)
		_camada_menu.add_child(l)
		_rotulos.append(l)
	var dica := _linha_de_teclas([["seta", "cima"], ["seta", "baixo"], ["texto", "escolher"],
			["tecla", "Espaço", 44], ["tecla", "Enter", 36], ["texto", "entrar"]], 10)
	dica.position = Vector2(0, CAIXA.end.y + 8)
	dica.size = Vector2(412, 22)
	_camada_menu.add_child(dica)


## Uma linha centralizada misturando texto e teclas desenhadas.
## itens: ["texto", "palavra"], ["tecla", "Espaço", largura] ou ["seta", "cima"].
func _linha_de_teclas(itens: Array, tamanho: int) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 5)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for item in itens:
		match item[0]:
			"texto":
				var l := Fontes.rotulo(item[1], Fontes.pixel(500), tamanho, Color(1, 0.97, 0.85), 4, Color(0.2, 0.1, 0.05))
				linha.add_child(l)
			"tecla", "seta":
				var t: Tecla = CENA_TECLA.instantiate()
				if item[0] == "tecla":
					t.texto = item[1]
					t.custom_minimum_size = Vector2(item[2], 20)
				else:
					t.texto = ""
					t.seta = item[1]
				t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				linha.add_child(t)
	return linha


# ------------------------------------------------------------------ cada quadro
func _process(delta: float) -> void:
	_tempo += delta
	_tempo_estado += delta
	# brilho que passa no título a cada 4 segundos
	var ciclo := fmod(_tempo, 4.0)
	_logo_mat.set_shader_parameter("brilho_pos", -150.0 + ciclo * 420.0)
	if _tempo > 1.2:
		_logo.position.y = 22.0 + 2.0 * sin((_tempo - 1.2) * 1.6)
	match _estado:
		"titulo":
			_aperte.visible = true
			_aperte.modulate.a = 0.35 + 0.65 * absf(sin(_tempo * 2.5))
			if _tempo_estado > 0.8 and (Jogo.apertou(1) or Jogo.apertou(2)):
				_abrir_menu()
		"menu":
			_navegar()
		"painel":
			pass   # a cena aberta cuida dos botões e avisa com o sinal "fechou"
	var alvo := CAIXA.position.y + 24.0 + _escolha * 26.0
	_cursor_y = lerpf(_cursor_y, alvo, minf(1.0, delta * 16.0))
	for r in _rastro:
		r["vida"] -= delta
		r["p"] += r["v"] * delta
	_rastro = _rastro.filter(func(r): return r["vida"] > 0)
	if _estado == "menu" and randf() < 0.4:
		_rastro.append({"p": Vector2(CAIXA.position.x + 34, _cursor_y) + Vector2(randf_range(-3, 3), randf_range(-3, 3)),
				"v": Vector2(randf_range(-20, -6), randf_range(-8, 8)), "vida": 0.6})
	for i in _rotulos.size():
		var l := _rotulos[i]
		var sel := i == _escolha
		l.add_theme_color_override("font_color", Color(1, 0.86, 0.35) if sel else Color(0.92, 0.92, 1.0))
		l.position.x = CAIXA.position.x + 62 + (4.0 if sel else 0.0)
	_camada_menu.queue_redraw()


func _abrir_menu() -> void:
	_estado = "menu"
	_tempo_estado = 0.0
	Sons.tocar("menu_abrir")
	_flash.color.a = 0.85
	create_tween().tween_property(_flash, "color:a", 0.0, 0.5)
	create_tween().tween_property(_aperte, "modulate:a", 0.0, 0.2)
	_camada_menu.modulate.a = 0.0
	_camada_menu.scale = Vector2(1, 0.2)
	_camada_menu.pivot_offset = CAIXA.get_center()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_camada_menu, "modulate:a", 1.0, 0.25)
	tw.tween_property(_camada_menu, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_cursor_y = CAIXA.position.y + 24.0
	await get_tree().create_timer(0.2).timeout
	_aperte.visible = false


func _navegar() -> void:
	var mudou := 0
	for item in [1, 2]:
		var n: int = item
		if Input.is_action_just_pressed("p%d_baixo" % n):
			mudou = 1
		elif Input.is_action_just_pressed("p%d_cima" % n):
			mudou = -1
	if mudou != 0:
		_escolha = (_escolha + mudou + OPCOES.size()) % OPCOES.size()
		Sons.tocar("menu_mover")
	if _tempo_estado > 0.3 and (Jogo.apertou(1) or Jogo.apertou(2)):
		_escolher()


func _escolher() -> void:
	Sons.tocar("menu_ok")
	match OPCOES[_escolha]:
		"Jogar":
			# Jogar: prefácio -> quadrinhos -> tela inicial -> fazenda
			Jogo.prefacio_volta_ao_menu = false
			_sair_para("res://cenas/prefacio.tscn")
		"Como jogar", "Créditos":
			_abrir_painel(PAINEIS[OPCOES[_escolha]])


func _sair_para(cena: String) -> void:
	_estado = "saindo"
	var preto := ColorRect.new()
	preto.color = Color(0, 0, 0, 0)
	preto.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(preto)
	var tw := create_tween()
	tw.tween_property(preto, "color:a", 1.0, 0.7)
	await tw.finished
	Sons.parar_musica()
	get_tree().change_scene_to_file(cena)


# ------------------------------------------------------------------ painel (como jogar / créditos)
## Abre uma cena por cima do menu. A cena emite "fechou" quando alguém sai dela.
func _abrir_painel(cena: PackedScene) -> void:
	_estado = "painel"
	_tempo_estado = 0.0
	_painel = cena.instantiate()
	add_child(_painel)
	_painel.fechou.connect(_fechar_painel)


func _fechar_painel() -> void:
	Sons.tocar("menu_voltar")
	if _painel:
		_painel.queue_free()
		_painel = null
	_estado = "menu"
	_tempo_estado = 0.0


# ------------------------------------------------------------------ a caixa do menu
func _desenhar_caixa() -> void:
	var c := _camada_menu
	var r := CAIXA
	c.draw_rect(r.grow(4), Color(0, 0, 0, 0.35))
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.07, 0.09, 0.24, 0.9)
	fundo.border_color = Color(0.93, 0.76, 0.3)
	fundo.set_border_width_all(3)
	fundo.set_corner_radius_all(6)
	c.draw_style_box(fundo, r)
	c.draw_rect(r.grow(-6), Color(0.62, 0.45, 0.14), false, 1.0)
	for canto in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		_losango(c, canto, 7.0, Color(0.93, 0.76, 0.3))
		_losango(c, canto, 3.5, Color(1, 0.95, 0.7))
	# brilho atrás da opção escolhida
	var faixa := Rect2(r.position.x + 12, _cursor_y - 10, r.size.x - 24, 20)
	c.draw_rect(faixa, Color(1, 0.85, 0.35, 0.12 + 0.05 * sin(_tempo * 4.0)))
	# rastro e vaga-lume
	for p in _rastro:
		c.draw_circle(p["p"], 1.3, Color(1, 1, 0.6, p["vida"] / 0.6))
	var pos := Vector2(r.position.x + 38, _cursor_y + 2.0 * sin(_tempo * 5.0))
	var luz := 0.6 + 0.4 * sin(_tempo * 6.0)
	c.draw_circle(pos, 10.0, Color(1, 0.95, 0.5, 0.12 * luz))
	c.draw_circle(pos, 6.0, Color(1, 0.95, 0.5, 0.25 * luz))
	var quadro := "res://assets/sprites/menu/vagalume%d.png" % (1 + int(_tempo * 10.0) % 2)
	c.draw_texture(Jogo.tex(quadro), pos - Vector2(8, 8))


func _losango(c: Control, centro: Vector2, r: float, cor: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array([centro + Vector2(0, -r), centro + Vector2(r, 0),
			centro + Vector2(0, r), centro + Vector2(-r, 0)]), cor)
