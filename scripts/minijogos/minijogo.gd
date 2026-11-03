class_name Minijogo
extends CanvasLayer
## Base dos minijogos que abrem por cima do mapa (poço, serra, trator, ordenha, pesca).
## Cada minijogo desenha no "painel" e usa na / nb (número do jogador de cada papel).

signal concluido

const PAINEL := Rect2(40, 4, 560, 290)

var na := 1          # jogador do papel A
var nb := 2          # jogador do papel B
var dica := ""
var fazenda: Node
var tarefa: Tarefa
var titulo := ""
var texto_a := ""    # o que o papel A faz (aparece embaixo, na cor do jogador)
var texto_b := ""
var acabou := false
var tempo := 0.0

var painel: Control
var _erros_seguidos := 0
var _ultimo_erro := -10.0
var _rotulo_a: Label
var _rotulo_b: Label
var _mensagem: Label
var _tween_msg: Tween


func _ready() -> void:
	layer = 4
	var fundo := ColorRect.new()
	fundo.color = Color(0.05, 0.04, 0.08, 0.6)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	painel = Control.new()
	painel.position = PAINEL.position
	painel.size = PAINEL.size
	painel.clip_contents = true
	add_child(painel)
	painel.draw.connect(_desenhar_painel)
	montar()
	var t := Hud.rotulo(titulo, 14, Color(1, 0.9, 0.5), 4)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector2(0, 4)
	t.size = Vector2(PAINEL.size.x, 20)
	painel.add_child(t)
	var faixa := ColorRect.new()
	faixa.color = Color(0.1, 0.07, 0.05, 0.75)
	faixa.position = Vector2(0, PAINEL.size.y - 40)
	faixa.size = Vector2(PAINEL.size.x, 40)
	painel.add_child(faixa)
	_rotulo_a = Hud.rotulo(_texto_papel(na, texto_a), 10, Jogo.COR[na].lightened(0.35), 3)
	_rotulo_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo_a.position = Vector2(0, PAINEL.size.y - 38)
	_rotulo_a.size = Vector2(PAINEL.size.x, 16)
	painel.add_child(_rotulo_a)
	_rotulo_b = Hud.rotulo(_texto_papel(nb, texto_b), 10, Jogo.COR[nb].lightened(0.35), 3)
	_rotulo_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo_b.position = Vector2(0, PAINEL.size.y - 20)
	_rotulo_b.size = Vector2(PAINEL.size.x, 16)
	painel.add_child(_rotulo_b)
	if fazenda != null:
		fazenda.hud.mostrar_topo(false)
	_mensagem = Hud.rotulo("", 13, Color.WHITE, 4)
	_mensagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mensagem.position = Vector2(0, 26)
	_mensagem.size = Vector2(PAINEL.size.x, 20)
	painel.add_child(_mensagem)


func _exit_tree() -> void:
	if fazenda != null and is_instance_valid(fazenda) and is_instance_valid(fazenda.hud):
		fazenda.hud.mostrar_topo(true)


func _texto_papel(n: int, texto: String) -> String:
	return "Jogador %d: %s" % [n, texto]


func _process(delta: float) -> void:
	tempo += delta
	if not acabou:
		atualizar(delta)
	painel.queue_redraw()


func _desenhar_painel() -> void:
	painel.draw_style_box(Hud.estilo(Color(0.55, 0.78, 0.95), Color(0.2, 0.15, 0.1), 8), Rect2(Vector2.ZERO, PAINEL.size))
	desenhar(painel)


# ---------------------------------------------------------- para cada minijogo
func montar() -> void:
	pass


func atualizar(_delta: float) -> void:
	pass


func desenhar(_c: Control) -> void:
	pass


# ---------------------------------------------------------- ajudantes
func mensagem(texto: String, cor := Color.WHITE) -> void:
	_mensagem.text = texto
	_mensagem.add_theme_color_override("font_color", cor)
	_mensagem.modulate.a = 1.0
	if _tween_msg:
		_tween_msg.kill()
	_tween_msg = create_tween()
	_tween_msg.tween_interval(1.2)
	_tween_msg.tween_property(_mensagem, "modulate:a", 0.0, 0.4)


func erro(texto := "") -> void:
	var agora := tempo
	if agora - _ultimo_erro > 0.5:
		Sons.tocar("toim")
	_ultimo_erro = agora
	if texto != "":
		mensagem(texto, Color(1, 0.75, 0.6))
	_erros_seguidos += 1
	if _erros_seguidos >= 3 and dica != "" and fazenda != null:
		_erros_seguidos = 0
		fazenda.hud.falar(dica)


func acerto() -> void:
	_erros_seguidos = 0
	if tarefa != null:
		tarefa.progresso()


func terminar(texto := "Conseguiram!") -> void:
	if acabou:
		return
	acabou = true
	mensagem(texto, Color(0.7, 1, 0.6))
	Sons.tocar("acerto")
	await get_tree().create_timer(1.0).timeout
	concluido.emit()


func texto_centro(c: Control, pos: Vector2, texto: String, tamanho := 9, cor := Color.WHITE, largura := 200.0) -> void:
	var f := ThemeDB.fallback_font
	var p := pos + Vector2(-largura / 2, 0)
	c.draw_string_outline(f, p, texto, HORIZONTAL_ALIGNMENT_CENTER, largura, tamanho, 4, Color(0.1, 0.07, 0.05))
	c.draw_string(f, p, texto, HORIZONTAL_ALIGNMENT_CENTER, largura, tamanho, cor)


func textura(c: Control, caminho: String, pos: Vector2, escala := 1.0, girar := false, cor := Color.WHITE) -> void:
	var t := Jogo.tex(caminho)
	var tam := t.get_size() * escala
	c.draw_texture_rect(t, Rect2(pos - tam / 2, tam), false, cor, girar)


func barra(c: Control, r: Rect2, valor: float, cor: Color) -> void:
	c.draw_rect(r.grow(2), Color(0.15, 0.1, 0.06))
	c.draw_rect(r, Color(0.3, 0.25, 0.2))
	c.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(valor, 0, 1), r.size.y)), cor)
