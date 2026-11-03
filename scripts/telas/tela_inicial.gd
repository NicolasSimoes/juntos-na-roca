extends Control
## Tela inicial. O jogo só começa quando os DOIS apertam AÇÃO.

var _pronto := {1: false, 2: false}
var _status := {}
var _cartoes := {}
var _indo := false
var _tempo := 0.0


func _ready() -> void:
	Jogo.novo_jogo()
	Sons.musica("musica_inicio")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fundo := TextureRect.new()
	fundo.texture = load("res://assets/sprites/extras/fundo_titulo.png")
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.stretch_mode = TextureRect.STRETCH_SCALE
	fundo.modulate = Color(0.55, 0.55, 0.6)
	add_child(fundo)
	var titulo := Fontes.rotulo("Juntos na Roça", Fontes.titulo(), 38, Color.WHITE, 10, Color(0.27, 0.12, 0.05))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.position = Vector2(0, 22)
	titulo.size = Vector2(640, 56)
	var ouro := ShaderMaterial.new()
	ouro.shader = load("res://assets/shaders/logo_ouro.gdshader")
	ouro.set_shader_parameter("altura", 46.0)
	titulo.material = ouro
	add_child(titulo)
	var sub := Hud.rotulo("Um jogo para fazer em dupla: na roça, ninguém faz nada sozinho!", 11, Color.WHITE, 4)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 80)
	sub.size = Vector2(640, 20)
	add_child(sub)
	_criar_cartao(1, Vector2(80, 112), "W A S D", "Espaço")
	_criar_cartao(2, Vector2(340, 112), "Setas", "Enter")
	var rodape := Hud.rotulo("Também dá para jogar com dois controles  ·  Esc: voltar ao menu", 8, Color(0.9, 0.9, 0.9), 3)
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rodape.position = Vector2(0, 340)
	rodape.size = Vector2(640, 14)
	add_child(rodape)


func _criar_cartao(n: int, pos: Vector2, andar: String, acao: String) -> void:
	var painel := PanelContainer.new()
	var cor: Color = Jogo.COR[n]
	painel.add_theme_stylebox_override("panel", Hud.estilo(Color(cor.darkened(0.55), 0.92), cor, 8))
	painel.position = pos
	painel.custom_minimum_size = Vector2(220, 196)
	add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", 3)
	painel.add_child(coluna)
	var nome := Hud.rotulo("Jogador %d" % n, 16, cor.lightened(0.4), 4)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(nome)
	var boneco := TextureRect.new()
	boneco.texture = load("res://assets/sprites/personagens/p%d_baixo_parado.png" % n)
	boneco.custom_minimum_size = Vector2(64, 64)
	boneco.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boneco.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coluna.add_child(boneco)
	var t1 := Hud.rotulo("Andar: " + andar, 11)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(t1)
	var t2 := Hud.rotulo("Ação: " + acao, 11)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(t2)
	var status := Hud.rotulo("Aperte %s!" % acao, 13, Color(1, 0.95, 0.6), 4)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(status)
	_status[n] = status
	_cartoes[n] = boneco


func _process(delta: float) -> void:
	_tempo += delta
	for n in [1, 2]:
		var status: Label = _status[n]
		if Jogo.apertou(n) and not _pronto[n]:
			_pronto[n] = true
			Sons.tocar("pegar")
			status.text = "Pronto!"
			status.add_theme_color_override("font_color", Color(0.6, 1, 0.5))
			var tw := create_tween()
			var boneco: TextureRect = _cartoes[n]
			boneco.texture = load("res://assets/sprites/personagens/p%d_comemora1.png" % n)
			tw.tween_property(boneco, "position:y", boneco.position.y - 10, 0.12)
			tw.tween_property(boneco, "position:y", boneco.position.y, 0.12)
		if not _pronto[n]:
			status.modulate.a = 0.55 + 0.45 * sin(_tempo * 6.0)
		else:
			status.modulate.a = 1.0
	if Input.is_action_just_pressed("pausa") and not _indo:
		_indo = true
		Sons.tocar("menu_voltar")
		get_tree().change_scene_to_file("res://cenas/menu_principal.tscn")
		return
	if _pronto[1] and _pronto[2] and not _indo:
		_indo = true
		Sons.tocar("acerto")
		await get_tree().create_timer(0.7).timeout
		get_tree().change_scene_to_file("res://cenas/fazenda.tscn")
