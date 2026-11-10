extends Control
## A história em quadrinhos que vem depois do prefácio: uma página com 4 quadros
## que aparecem um de cada vez.
##   1. Os netos chegam na casa da Vovó.
##   2. A Vovó mostra a fazenda sem cor.
##   3. Sozinho não dá... juntos, sim!
##   4. Toca aqui!
## Cada quadro é montado na cena (cenas/quadrinhos.tscn) com a arte do pacote
## Super Retro World. AÇÃO mostra o próximo quadro; Esc pula tudo.

const PROXIMA := "res://cenas/tela_inicial.tscn"

var _atual := -1
var _tempo := 0.0
var _saindo := false
var _tween: Tween

@onready var _quadros: Array[Control] = [%Quadro1, %Quadro2, %Quadro3, %Quadro4]
@onready var _proximo: Label = %Proximo
@onready var _confete: CPUParticles2D = %Confete
@onready var _pulo_a: Sprite2D = %PuloA
@onready var _pulo_b: Sprite2D = %PuloB
@onready var _pa: Label = %Pa


func _ready() -> void:
	Sons.musica("musica_inicio")
	Elenco.vestir(self)
	for q in _quadros:
		q.modulate.a = 0.0
		q.pivot_offset = q.size / 2.0
	await get_tree().create_timer(0.4).timeout
	_mostrar_proximo()


func _process(delta: float) -> void:
	_tempo += delta
	# no último quadro os dois pulam e batem as mãos sem parar
	if _atual >= 3:
		var ciclo := fmod(_tempo, 1.2)
		var pulo := absf(sin(ciclo * PI / 0.5)) * 10.0 if ciclo < 0.5 else 0.0
		_pulo_a.position.x = 118.0 + (8.0 if ciclo < 0.5 else 0.0)
		_pulo_b.position.x = 188.0 - (8.0 if ciclo < 0.5 else 0.0)
		_pulo_a.offset.y = -_pulo_a.texture.get_height() - pulo / _pulo_a.scale.y
		_pulo_b.offset.y = _pulo_a.offset.y
		_pa.scale = Vector2.ONE * (1.0 + 0.15 * sin(_tempo * 8.0))
	_proximo.modulate.a = 0.55 + 0.45 * absf(sin(_tempo * 3.0))
	if _saindo:
		return
	if Input.is_action_just_pressed("pausa"):
		_sair()
	elif Jogo.apertou(1) or Jogo.apertou(2):
		if _tween and _tween.is_running():
			_tween.custom_step(10.0)   # termina a animação do quadro de uma vez
		else:
			_mostrar_proximo()


func _mostrar_proximo() -> void:
	_atual += 1
	if _atual >= _quadros.size():
		_sair()
		return
	var q := _quadros[_atual]
	q.scale = Vector2.ONE * 0.9
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(q, "modulate:a", 1.0, 0.25)
	_tween.tween_property(q, "scale", Vector2.ONE, 0.35)
	Sons.tocar("menu_ok")
	if _atual == 3:
		Sons.tocar("toca_aqui")
		_confete.emitting = true
		_proximo.text = "Jogar!"


func _sair() -> void:
	_saindo = true
	var preto := ColorRect.new()
	preto.color = Color(0, 0, 0, 0)
	preto.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(preto)
	var tw := create_tween()
	tw.tween_property(preto, "color:a", 1.0, 0.5)
	await tw.finished
	get_tree().change_scene_to_file(PROXIMA)
