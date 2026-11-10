extends Control
## A história em quadrinhos do começo do jogo: 2 páginas, 4 quadros cada.
##
##   Página 1 — "A carta"
##     1. Chega uma carta: "Netos, preciso de vocês!"
##     2. Os netos chegam na fazenda.
##     3. Uma tempestade deixou tudo quebrado e cinza.
##     4. Em 5 dias tem a Festa da Colheita! (o objetivo)
##   Página 2 — "O segredo da roça"
##     5. "Aqui na roça, ninguém faz nada sozinho." (a regra)
##     6. Sozinho não dá... Juntos, sim!
##     7. Cada tarefa feita traz a cor de volta! (como se ganha)
##     8. "Vocês topam ajudar?" — cada jogador aperta a SUA AÇÃO para topar.
##        Quando os dois toparem, eles batem as mãos (PÁ!) e o jogo começa.
##
## Os quadros são nós montados na cena (cenas/quadrinhos.tscn), com a arte do pacote
## Super Retro World. AÇÃO de qualquer um mostra o próximo quadro; Esc pula tudo.

const PROXIMA := "res://cenas/tela_inicial.tscn"
const TITULOS := ["1. A carta", "2. O segredo da roça"]

var _atual := -1                 # índice do quadro na tela (0 a 7)
var _tempo := 0.0
var _saindo := false
var _convite := false            # estamos no quadro 8, esperando os dois toparem?
var _topou := {1: false, 2: false}
var _comemorando := false
var _tween: Tween

@onready var _quadros: Array[Control] = [%Quadro1, %Quadro2, %Quadro3, %Quadro4,
		%Quadro5, %Quadro6, %Quadro7, %Quadro8]
@onready var _paginas: Array[Control] = [%Pagina1, %Pagina2]
@onready var _titulo_pagina: Label = %Pagina
@onready var _proximo: Label = %Proximo
@onready var _neto := {1: %NetoA as Sprite2D, 2: %NetoB as Sprite2D}
@onready var _tecla := {1: %Tecla1 as Tecla, 2: %Tecla2 as Tecla}
@onready var _status := {1: %Status1 as Label, 2: %Status2 as Label}
@onready var _pa: Label = %Pa
@onready var _confete: CPUParticles2D = %Confete


func _ready() -> void:
	Sons.musica("musica_inicio")
	Elenco.vestir(self)          # põe a arte certa nos netos e na Vovó
	_sem_ligaduras(self)
	for q in _quadros:
		q.modulate.a = 0.0
		q.pivot_offset = q.size / 2.0
	_paginas[1].position.x = size.x   # a página 2 começa escondida à direita
	_titulo_pagina.text = TITULOS[0]
	for n in [1, 2]:
		_tecla[n].cor = Jogo.COR[n].lightened(0.45)
	await get_tree().create_timer(0.4).timeout
	_mostrar_proximo()


func _process(delta: float) -> void:
	_tempo += delta
	_proximo.modulate.a = 0.6 + 0.4 * absf(sin(_tempo * 3.0))
	if _comemorando:
		_pa.scale = Vector2.ONE * (1.0 + 0.15 * sin(_tempo * 8.0))
	if _saindo:
		return
	if Input.is_action_just_pressed("pausa"):
		_sair()
	elif _convite:
		_esperar_os_dois()
	elif Jogo.apertou(1) or Jogo.apertou(2):
		if _tween and _tween.is_running():
			_tween.custom_step(10.0)   # termina a animação do quadro de uma vez
		else:
			_mostrar_proximo()


## Mostra o próximo quadro. Do 4 para o 5, vira a página antes.
func _mostrar_proximo() -> void:
	_atual += 1
	if _atual >= _quadros.size():
		return
	if _atual == 4:
		await _virar_pagina()
	var q := _quadros[_atual]
	q.scale = Vector2.ONE * 0.9
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(q, "modulate:a", 1.0, 0.25)
	_tween.tween_property(q, "scale", Vector2.ONE, 0.35)
	Sons.tocar("menu_ok")
	if _atual == 2:
		Sons.tocar("toim", -6.0, 0.7)     # a fazenda cinza: som triste
	if _atual == 7:
		_convite = true
		_proximo.text = "os dois: AÇÃO para topar!"


## A página 1 desliza para a esquerda e a página 2 entra pela direita.
func _virar_pagina() -> void:
	Sons.tocar("menu_abrir")
	_titulo_pagina.text = TITULOS[1]
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_paginas[0], "position:x", -size.x, 0.45)
	tw.tween_property(_paginas[1], "position:x", 0.0, 0.45)
	_tween = tw
	await tw.finished


## Quadro 8: cada um aperta a SUA AÇÃO e fica marcado "Topo!".
## Não precisa ser ao mesmo tempo (mais fácil para quem está aprendendo).
func _esperar_os_dois() -> void:
	for n in [1, 2]:
		if Jogo.apertou(n):
			topar(n)


## O jogador n topou: a tecla dele afunda, o neto pula e aparece "Topo!".
## Quando os dois toparem, começa a comemoração.
func topar(n: int) -> void:
	if not _convite or _topou[n]:
		return
	_topou[n] = true
	_tecla[n].apertar()
	_status[n].text = "Topo!"
	_status[n].add_theme_color_override("font_color", Color(0.6, 1, 0.5))
	Sons.tocar("pegar")
	var neto: Sprite2D = _neto[n]
	var tw := create_tween()
	tw.tween_property(neto, "position:y", neto.position.y - 10, 0.12)
	tw.tween_property(neto, "position:y", neto.position.y, 0.12)
	if _topou[1] and _topou[2]:
		_convite = false
		_comemorar()


## Os dois toparam: correm um para o outro, batem as mãos (PÁ!) e o jogo começa.
func _comemorar() -> void:
	_comemorando = true
	for n in [1, 2]:
		_neto[n].texture = Aparencia.neto(n, "lado")
		Aparencia.ajustar_pes(_neto[n])
	_neto[2].flip_h = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_neto[1], "position:x", 176.0, 0.3)
	tw.tween_property(_neto[2], "position:x", 204.0, 0.3)
	await tw.finished
	Sons.tocar("toca_aqui")
	# a pergunta da Vovó foi respondida: o balão sai e entra o PÁ!
	for nome in ["Convite", "ConviteRabo", "ConviteRaboContorno"]:
		_quadros[7].get_node(nome).visible = false
	_pa.visible = true
	_confete.emitting = true
	_proximo.text = "Vamos juntos!"
	await get_tree().create_timer(1.6).timeout
	_sair()


## A fonte Pixelify junta "fi" num desenho só (ligadura) que parece um "A"
## ("ficou" vira "Acou"). Aqui cada texto ganha uma cópia da fonte com as
## ligaduras desligadas (opentype_features "liga" = 0).
func _sem_ligaduras(no: Node) -> void:
	if no is Label:
		var l := no as Label
		var fonte := FontVariation.new()
		fonte.base_font = l.get_theme_font("font")
		fonte.opentype_features = {TextServerManager.get_primary_interface().name_to_tag("liga"): 0}
		l.add_theme_font_override("font", fonte)
	for filho in no.get_children():
		_sem_ligaduras(filho)


func _sair() -> void:
	if _saindo:
		return
	_saindo = true
	var preto := ColorRect.new()
	preto.color = Color(0, 0, 0, 0)
	preto.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(preto)
	var tw := create_tween()
	tw.tween_property(preto, "color:a", 1.0, 0.5)
	await tw.finished
	get_tree().change_scene_to_file(PROXIMA)
