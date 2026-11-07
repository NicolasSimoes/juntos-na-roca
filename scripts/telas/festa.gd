extends Control
## Festa da Colheita: a mesa com tudo o que a dupla produziu,
## o álbum com uma foto de cada tarefa e a lição da Vovó.

var _foto := 0
var _tempo_foto := 0.0
var _tempo := 0.0
var _imagem: TextureRect
var _legenda: Label
var _contador: Label
var _convite: Label
var _pronto := {1: false, 2: false}
var _saindo := false
var _confete: CPUParticles2D


func _ready() -> void:
	Sons.musica("musica_festa")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var grama := TextureRect.new()
	grama.texture = load("res://assets/sprites/tiles/grama.png")
	grama.stretch_mode = TextureRect.STRETCH_TILE
	grama.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(grama)
	var enfeites := Control.new()
	enfeites.set_anchors_preset(Control.PRESET_FULL_RECT)
	enfeites.draw.connect(_bandeirinhas.bind(enfeites))
	add_child(enfeites)
	var titulo := Hud.rotulo("Festa da Colheita!", 28, Color(1, 0.88, 0.4), 6)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.position = Vector2(0, 30)
	titulo.size = Vector2(640, 40)
	add_child(titulo)
	_montar_mesa()
	_montar_album()
	var frase := Hud.rotulo("Juntos, vocês conseguiram!", 14, Color.WHITE, 4)
	frase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frase.position = Vector2(0, 306)
	frase.size = Vector2(640, 20)
	add_child(frase)
	_convite = Hud.rotulo("", 12, Color(1, 0.95, 0.6), 4)
	_convite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_convite.position = Vector2(0, 334)
	_convite.size = Vector2(640, 16)
	add_child(_convite)
	_confete = CPUParticles2D.new()
	_confete.position = Vector2(320, -10)
	_confete.amount = 60
	_confete.lifetime = 5.0
	_confete.texture = load("res://assets/sprites/extras/pixel.png")
	_confete.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_confete.emission_rect_extents = Vector2(320, 4)
	_confete.direction = Vector2(0, 1)
	_confete.spread = 20.0
	_confete.gravity = Vector2(0, 30)
	_confete.initial_velocity_min = 20.0
	_confete.initial_velocity_max = 50.0
	_confete.scale_amount_min = 1.5
	_confete.scale_amount_max = 2.5
	var cores := Gradient.new()
	cores.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	cores.colors = PackedColorArray([Color("eb8931"), Color("5b8dee"), Color("f0c846"), Color("d93c3c"), Color("ffffff")])
	_confete.color_initial_ramp = cores
	add_child(_confete)
	Sons.tocar("toca_aqui")
	await get_tree().create_timer(3.0).timeout
	_convite.text = "Jogar de novo? Os dois: Espaço e Enter!"


func _montar_mesa() -> void:
	# a dupla e a Vovó atrás da mesa
	# Aparencia decide a imagem de cada um (netos e Vovó)
	var gente := [
		[Aparencia.neto(1, "frente"), Vector2(64, 126)],
		[Aparencia.vovo(), Vector2(132, 126)],
		[Aparencia.neto(2, "frente"), Vector2(200, 126)],
	]
	for g in gente:
		var t := TextureRect.new()
		t.texture = g[0]
		t.position = g[1]
		t.size = Vector2(48, 72)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(t)
	var mesa := TextureRect.new()
	mesa.texture = load("res://assets/sprites/extras/mesa.png")
	mesa.position = Vector2(36, 166)
	mesa.size = Vector2(240, 120)
	mesa.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(mesa)
	var itens := HBoxContainer.new()
	itens.position = Vector2(44, 190)
	itens.add_theme_constant_override("separation", 1)
	add_child(itens)
	for item in Jogo.ITENS:
		var qtd: int = Jogo.cesta.get(item, 0)
		if qtd <= 0:
			continue
		var coluna := VBoxContainer.new()
		coluna.add_theme_constant_override("separation", 0)
		var icone := TextureRect.new()
		icone.texture = Jogo.tex(Jogo.ICONE_ITEM[item])
		icone.custom_minimum_size = Vector2(28, 28)
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coluna.add_child(icone)
		var n := Hud.rotulo("x%d" % qtd, 8)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		coluna.add_child(n)
		itens.add_child(coluna)
	var jer := TextureRect.new()
	jer.texture = load("res://assets/sprites/objetos/jerimum_gigante.png")
	jer.position = Vector2(240, 236)
	jer.size = Vector2(64, 64)
	jer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(jer)


func _montar_album() -> void:
	var moldura := PanelContainer.new()
	moldura.add_theme_stylebox_override("panel", Hud.estilo(Color(0.98, 0.97, 0.93), Color(0.45, 0.32, 0.2), 4))
	moldura.position = Vector2(318, 76)
	moldura.custom_minimum_size = Vector2(292, 214)
	add_child(moldura)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 2)
	moldura.add_child(coluna)
	var topo := Hud.rotulo("Nosso álbum", 11, Color(0.45, 0.3, 0.2), 0)
	topo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(topo)
	_imagem = TextureRect.new()
	_imagem.custom_minimum_size = Vector2(272, 153)
	_imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_imagem.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	coluna.add_child(_imagem)
	_legenda = Hud.rotulo("", 10, Color(0.2, 0.14, 0.08), 0)
	_legenda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_legenda)
	_contador = Hud.rotulo("", 7, Color(0.5, 0.4, 0.3), 0)
	_contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_contador)
	_mostrar_foto()


func _mostrar_foto() -> void:
	if Jogo.fotos.is_empty():
		_legenda.text = "Sem fotos desta vez"
		return
	var f: Dictionary = Jogo.fotos[_foto % Jogo.fotos.size()]
	_imagem.texture = f["textura"]
	_legenda.text = f["legenda"]
	_contador.text = "foto %d de %d" % [_foto % Jogo.fotos.size() + 1, Jogo.fotos.size()]


func _process(delta: float) -> void:
	_tempo += delta
	_tempo_foto += delta
	if _tempo_foto > 3.0:
		_tempo_foto = 0.0
		_foto += 1
		_mostrar_foto()
	if _convite.text == "" or _saindo:
		return
	for n in [1, 2]:
		if Jogo.apertou(n):
			_pronto[n] = true
	if _pronto[1] and _pronto[2]:
		_saindo = true
		Sons.tocar("acerto")
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://cenas/menu_principal.tscn")


func _bandeirinhas(c: Control) -> void:
	var cores := [Color("d93c3c"), Color("f0c846"), Color("5b8dee"), Color("eb8931"), Color("6abe30"), Color("9260aa")]
	for fileira in 2:
		var y0 := 6.0 + fileira * 14.0
		c.draw_line(Vector2(0, y0), Vector2(640, y0), Color(0.3, 0.2, 0.1), 1.0)
		for k in 32:
			var x := k * 20.0 + fileira * 10.0
			var cor: Color = cores[(k + fileira) % cores.size()]
			c.draw_colored_polygon(PackedVector2Array([Vector2(x, y0), Vector2(x + 14, y0), Vector2(x + 7, y0 + 11)]), cor)
