class_name Hud
extends CanvasLayer
## Tudo o que fica por cima do jogo: quadro de tarefas, cesta do time,
## balão da Vovó, avisos, a cortina preta entre os dias e a pausa.

var esperando_acao := false   # true quando o balão espera alguém apertar AÇÃO

var _quadro: VBoxContainer
var _cesta: HBoxContainer
var _paineis_topo: Array[Control] = []
var _balao: PanelContainer
var _texto_balao: Label
var _dica_acao: Label
var _aviso: Label
var _cortina: ColorRect
var _titulo_dia: Label
var _sub_dia: Label
var _pausa: Control
var _id_fala := 0
var _tween_aviso: Tween


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar_quadro()
	_montar_cesta()
	_montar_balao()
	_montar_aviso()
	_montar_cortina()
	_montar_pausa()
	Jogo.cesta_mudou.connect(atualizar)
	atualizar()


# ------------------------------------------------------------------ montagem
static func estilo(fundo: Color, borda: Color, raio := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.border_color = borda
	s.set_border_width_all(2)
	s.set_corner_radius_all(raio)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	return s


static func rotulo(texto: String, tamanho := 9, cor := Color.WHITE, contorno := 3) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	if contorno > 0:
		l.add_theme_constant_override("outline_size", contorno)
		l.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.05))
	return l


func _montar_quadro() -> void:
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", estilo(Color(0.42, 0.27, 0.14, 0.92), Color(0.24, 0.15, 0.08)))
	painel.position = Vector2(4, 4)
	add_child(painel)
	_paineis_topo.append(painel)
	_quadro = VBoxContainer.new()
	_quadro.add_theme_constant_override("separation", 1)
	painel.add_child(_quadro)


func _montar_cesta() -> void:
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", estilo(Color(0.42, 0.27, 0.14, 0.92), Color(0.24, 0.15, 0.08)))
	painel.anchor_left = 1.0
	painel.anchor_right = 1.0
	painel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	painel.offset_right = -4
	painel.offset_top = 4
	add_child(painel)
	_paineis_topo.append(painel)
	_cesta = HBoxContainer.new()
	_cesta.add_theme_constant_override("separation", 2)
	painel.add_child(_cesta)


func _montar_balao() -> void:
	_balao = PanelContainer.new()
	_balao.add_theme_stylebox_override("panel", estilo(Color(0.98, 0.95, 0.85), Color(0.35, 0.22, 0.12), 6))
	_balao.position = Vector2(110, 298)
	_balao.custom_minimum_size = Vector2(420, 56)
	_balao.size = Vector2(420, 56)
	_balao.visible = false
	add_child(_balao)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 6)
	_balao.add_child(linha)
	var rosto := TextureRect.new()
	rosto.texture = Aparencia.vovo()   # Aparencia decide a imagem da Vovó
	rosto.custom_minimum_size = Vector2(32, 40)
	rosto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rosto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rosto.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	linha.add_child(rosto)
	var coluna := VBoxContainer.new()
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coluna.add_theme_constant_override("separation", 0)
	linha.add_child(coluna)
	var nome := rotulo("Vovó Zefa", 8, Color(0.55, 0.3, 0.6), 0)
	coluna.add_child(nome)
	_texto_balao = rotulo("", 11, Color(0.18, 0.12, 0.08), 0)
	_texto_balao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto_balao.custom_minimum_size = Vector2(360, 0)
	coluna.add_child(_texto_balao)
	_dica_acao = rotulo("Espaço / Enter", 8, Color(0.5, 0.35, 0.2), 0)
	_dica_acao.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dica_acao.visible = false
	coluna.add_child(_dica_acao)


func _montar_aviso() -> void:
	_aviso = rotulo("", 14, Color(1, 0.95, 0.55), 5)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.position = Vector2(0, 44)
	_aviso.size = Vector2(640, 24)
	_aviso.modulate.a = 0.0
	add_child(_aviso)


func _montar_cortina() -> void:
	_cortina = ColorRect.new()
	_cortina.color = Color(0.08, 0.06, 0.1)
	_cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cortina.visible = false
	add_child(_cortina)
	_titulo_dia = rotulo("", 32, Color(1, 0.9, 0.5), 6)
	_titulo_dia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo_dia.position = Vector2(0, 130)
	_titulo_dia.size = Vector2(640, 44)
	_cortina.add_child(_titulo_dia)
	_sub_dia = rotulo("", 11, Color(0.85, 0.85, 0.9), 3)
	_sub_dia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_dia.position = Vector2(0, 180)
	_sub_dia.size = Vector2(640, 20)
	_cortina.add_child(_sub_dia)


func _montar_pausa() -> void:
	_pausa = ColorRect.new()
	(_pausa as ColorRect).color = Color(0, 0, 0, 0.6)
	_pausa.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pausa.visible = false
	add_child(_pausa)
	var t := rotulo("Pausa", 28, Color(1, 0.9, 0.5), 6)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector2(0, 140)
	t.size = Vector2(640, 40)
	_pausa.add_child(t)
	var s := rotulo("Esc: continuar", 12)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.position = Vector2(0, 186)
	s.size = Vector2(640, 20)
	_pausa.add_child(s)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("pausa"):
		get_tree().paused = not get_tree().paused
		_pausa.visible = get_tree().paused
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ quadro e cesta
func mostrar_topo(sim: bool) -> void:
	for p in _paineis_topo:
		p.visible = sim


func atualizar() -> void:
	if _quadro == null:
		return
	for filho in _quadro.get_children():
		filho.queue_free()
	_quadro.add_child(rotulo("Dia %d de %d" % [Jogo.dia, Jogo.ULTIMO_DIA], 10, Color(1, 0.9, 0.5)))
	for id in Jogo.tarefas_do_dia():
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 3)
		var icone := TextureRect.new()
		icone.texture = Jogo.tex(Jogo.ICONES[id])
		icone.custom_minimum_size = Vector2(12, 12)
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		linha.add_child(icone)
		var feita := Jogo.feita(id)
		var nome := rotulo(Jogo.NOMES[id], 8, Color(0.6, 0.95, 0.5) if feita else Color.WHITE)
		linha.add_child(nome)
		if feita:
			linha.add_child(rotulo("ok!", 8, Color(0.6, 0.95, 0.5)))
		_quadro.add_child(linha)

	for filho in _cesta.get_children():
		filho.queue_free()
	var cesto := TextureRect.new()
	cesto.texture = Jogo.tex("res://assets/sprites/objetos/cesta.png")
	cesto.custom_minimum_size = Vector2(14, 14)
	cesto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cesta.add_child(cesto)
	var algum := false
	for item in Jogo.ITENS:
		var qtd: int = Jogo.cesta.get(item, 0)
		if qtd <= 0:
			continue
		algum = true
		var icone := TextureRect.new()
		icone.texture = Jogo.tex(Jogo.ICONE_ITEM[item])
		icone.custom_minimum_size = Vector2(12, 12)
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_cesta.add_child(icone)
		_cesta.add_child(rotulo(str(qtd), 8))
	if not algum:
		_cesta.add_child(rotulo("cesta", 8, Color(0.9, 0.85, 0.7)))


# ------------------------------------------------------------------ balão da Vovó
## Mostra uma fala da Vovó. Com esperar = true, só some quando alguém aperta AÇÃO.
func falar(texto: String, esperar := false) -> void:
	_id_fala += 1
	var meu := _id_fala
	_balao.visible = true
	_dica_acao.visible = false
	_texto_balao.text = texto
	_texto_balao.visible_characters = 0
	var mostrados := 0.0
	while _texto_balao.visible_characters < texto.length():
		if not is_inside_tree():
			return
		await get_tree().process_frame
		if meu != _id_fala or not is_inside_tree():
			return
		var antes := int(mostrados)
		mostrados += get_process_delta_time() * 45.0
		if esperar and (Jogo.apertou(1) or Jogo.apertou(2)):
			mostrados = texto.length()
		_texto_balao.visible_characters = int(mostrados)
		if int(mostrados) / 3 != antes / 3:
			Sons.tocar("fala", -6.0, randf_range(0.9, 1.15))
	if esperar:
		_dica_acao.visible = true
		esperando_acao = true
		await get_tree().process_frame
		while is_inside_tree() and not (Jogo.apertou(1) or Jogo.apertou(2)):
			await get_tree().process_frame
		esperando_acao = false
		if meu == _id_fala:
			_balao.visible = false
	else:
		if not is_inside_tree():
			return
		await get_tree().create_timer(2.5 + texto.length() * 0.035).timeout
		if meu == _id_fala and is_inside_tree():
			_balao.visible = false


## Várias falas seguidas, esperando AÇÃO entre elas.
func conversa(falas: Array) -> void:
	for f in falas:
		await falar(f, true)


func aviso(texto: String, cor := Color(1, 0.95, 0.55)) -> void:
	_aviso.text = texto
	_aviso.add_theme_color_override("font_color", cor)
	if _tween_aviso:
		_tween_aviso.kill()
	_aviso.modulate.a = 1.0
	_aviso.position.y = 44
	_tween_aviso = create_tween()
	_tween_aviso.tween_interval(1.4)
	_tween_aviso.tween_property(_aviso, "modulate:a", 0.0, 0.5)


# ------------------------------------------------------------------ cortina entre os dias
func mostrar_dia(numero: int, subtitulo: String) -> void:
	_cortina.visible = true
	_cortina.modulate.a = 1.0
	_titulo_dia.text = "Dia %d" % numero
	_sub_dia.text = subtitulo
	_titulo_dia.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_titulo_dia, "modulate:a", 1.0, 0.4)
	await tw.finished
	Sons.tocar("galo")
	await get_tree().create_timer(1.4).timeout
	var tw2 := create_tween()
	tw2.tween_property(_cortina, "modulate:a", 0.0, 0.6)
	await tw2.finished
	_cortina.visible = false


func escurecer(texto := "") -> void:
	_cortina.visible = true
	_cortina.modulate.a = 0.0
	_titulo_dia.text = texto
	_titulo_dia.modulate.a = 1.0
	_sub_dia.text = ""
	var tw := create_tween()
	tw.tween_property(_cortina, "modulate:a", 1.0, 0.6)
	await tw.finished
