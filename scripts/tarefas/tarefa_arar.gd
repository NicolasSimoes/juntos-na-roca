extends Tarefa
## Dia 2 — Arar a terra. Um dirige o trator, que ara por onde passa.
## O outro vai na frente tirando as pedras: o trator para quando bate numa pedra.

var _trator: TratorDirigivel
var _arados := 0
var _total := 0


func _init() -> void:
	dica = "Quem está a pé tira as pedras com AÇÃO. O trator ara tudo por onde passa!"


func posicao_estacao() -> Vector2:
	return Lugares.ESTACAO_ARAR


func papeis() -> Array:
	return ["dirigir", "tirar pedras", tex("res://assets/sprites/extras/trator.png"),
			tex("res://assets/sprites/objetos/pedra.png")]


func pode_comecar() -> bool:
	return Jogo.feita("trator")


func comecar(a: Jogador, b: Jogador) -> void:
	super.comecar(a, b)
	fazenda.mostrar_trator_parado(false)
	a.esconder(true)
	_trator = TratorDirigivel.new()
	_trator.motorista = a.numero
	_trator.chao = fazenda.chao
	_trator.area_arar = Lugares.CAMPO
	_trator.position = Lugares.TRATOR_PARADO
	fazenda.mundo.add_child(_trator)
	_trator.arou.connect(_arou)
	_total = Lugares.CAMPO.size.x * Lugares.CAMPO.size.y
	fazenda.hud.falar("Jogador %d dirige o trator. Jogador %d tira as pedras do caminho com AÇÃO!" % [a.numero, b.numero])


func _arou(_bloco: Vector2i) -> void:
	_arados += 1
	progresso()


func atualizar(_delta: float) -> void:
	if Jogo.apertou(papel_b.numero):
		var pedra: Node2D = fazenda.pedra_perto(papel_b.global_position, 20.0)
		if pedra != null:
			fazenda.tirar_pedra(pedra)
			progresso()
	if fazenda.pedras.is_empty() and _arados >= int(_total * 0.85):
		for x in range(Lugares.CAMPO.position.x, Lugares.CAMPO.end.x):
			for y in range(Lugares.CAMPO.position.y, Lugares.CAMPO.end.y):
				fazenda.chao.set_cell(Vector2i(x, y), 0, Vector2i(2, 0))
		_trator.set_physics_process(false)
		finalizar()


func ponto_guia() -> Variant:
	if not em_andamento:
		return super.ponto_guia()
	if not fazenda.pedras.is_empty():
		var pedra: Node2D = fazenda.pedra_perto(papel_b.global_position, 9999.0)
		return pedra.global_position
	var melhor := Vector2.ZERO
	var menor := 99999.0
	for x in range(Lugares.CAMPO.position.x, Lugares.CAMPO.end.x):
		for y in range(Lugares.CAMPO.position.y, Lugares.CAMPO.end.y):
			if fazenda.chao.get_cell_atlas_coords(Vector2i(x, y)) != Vector2i(2, 0):
				var p := Vector2(x * 16 + 8, y * 16 + 8)
				var d := p.distance_to(_trator.global_position)
				if d < menor:
					menor = d
					melhor = p
	return melhor if menor < 99999.0 else null


func encerrar() -> void:
	papel_a.global_position = _trator.global_position + Vector2(0, 14)
	papel_a.esconder(false)
