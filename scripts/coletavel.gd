class_name Coletavel
extends Node2D
## Um item no chão. Chegue perto com as mãos livres e aperte AÇÃO para pegar.

signal coletado(jogador: Jogador)

var item := ""
var textura: Texture2D
var _tempo := 0.0
var _perto := false


func configurar(nome_item: String, caminho_textura: String, posicao: Vector2) -> Coletavel:
	item = nome_item
	textura = Jogo.tex(caminho_textura)
	position = posicao
	return self


func _ready() -> void:
	z_index = 6


func _process(delta: float) -> void:
	_tempo += delta
	_perto = false
	for no in get_tree().get_nodes_in_group("jogadores"):
		var j := no as Jogador
		if not j.visible or not j.pode_mover or j.carregando != "":
			continue
		if j.global_position.distance_to(global_position) < 16.0:
			_perto = true
			if Jogo.apertou(j.numero):
				j.segurar(item, textura)
				Sons.tocar("pegar")
				coletado.emit(j)
				queue_free()
				return
	queue_redraw()


func _draw() -> void:
	var y := -4.0 * absf(sin(_tempo * 3.0))
	draw_circle(Vector2(0, 2), 6, Color(0, 0, 0, 0.25))
	if textura:
		draw_texture(textura, Vector2(-textura.get_width() / 2.0, -textura.get_height() + y))
	if _perto:
		var fonte := ThemeDB.fallback_font
		draw_string_outline(fonte, Vector2(-30, -22), "AÇÃO", HORIZONTAL_ALIGNMENT_CENTER, 60, 7, 3, Color.BLACK)
		draw_string(fonte, Vector2(-30, -22), "AÇÃO", HORIZONTAL_ALIGNMENT_CENTER, 60, 7, Color(1, 0.95, 0.5))
