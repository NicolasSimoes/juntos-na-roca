extends Tarefa
## Dia 1 — Lenha. Os dois serram a tora com a serra de dois cabos,
## apertando alternado, e depois carregam a tora juntos até a casa.

var _fase := "serrar"
var _tora: CarregarJuntos


func _init() -> void:
	dica = "Um de cada vez! Olhem a seta: aperta só quem tem a vez."


func posicao_estacao() -> Vector2:
	return Lugares.ESTACAO_LENHA


func papeis() -> Array:
	var serra := tex("res://assets/sprites/objetos/serra.png")
	return ["cabo da esquerda", "cabo da direita", serra, serra]


func comecar(a: Jogador, b: Jogador) -> void:
	super.comecar(a, b)
	var mj := MinijogoSerra.new()
	abrir_minijogo(mj)
	mj.concluido.connect(_serrou)


func _serrou() -> void:
	overlay.queue_free()
	overlay = null
	fazenda.travar(false)
	_fase = "carregar"
	dica = "Fiquem pertinho um do outro. Se se afastarem demais, a tora cai!"
	_tora = CarregarJuntos.new().configurar("res://assets/sprites/objetos/tora.png", Lugares.TORA + Vector2(0, 8), Lugares.DESTINO_LENHA)
	fazenda.mundo.add_child(_tora)
	_tora.entregue.connect(_entregou)
	_tora.caiu.connect(func(): fazenda.hud.aviso("Opa, caiu! Fiquem pertinho."))
	fazenda.hud.falar("Agora levem a tora juntos até o lado da casa. Os dois pertinho dela apertam AÇÃO!")


func _entregou() -> void:
	_tora.queue_free()
	Jogo.adicionar("lenha", 5)
	finalizar()


func encerrar() -> void:
	fazenda.acender_fogao()


func ponto_guia() -> Variant:
	if em_andamento and _fase == "carregar" and is_instance_valid(_tora):
		if _tora.segurando:
			return Lugares.DESTINO_LENHA.get_center()
		return _tora.global_position
	return super.ponto_guia()


func _draw() -> void:
	if _fase == "serrar" and not Jogo.feita("lenha"):
		var t := tex("res://assets/sprites/objetos/tora.png")
		draw_texture(t, Lugares.TORA - Vector2(t.get_width() / 2.0, t.get_height()))
