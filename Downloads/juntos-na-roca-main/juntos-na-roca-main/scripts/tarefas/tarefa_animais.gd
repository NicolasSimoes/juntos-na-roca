extends Tarefa
## Dia 4 — Cuidar dos animais. Primeiro: um traz milho (galpão) para o cocho
## e o outro traz água (poço) para o bebedouro. O bicho só fica feliz com os dois.
## Depois a ordenha: um dá capim para a Mimosa ficar quieta, o outro tira o leite.

var _fase := "abastecer"
var _saco: Coletavel
var _balde: Coletavel
var _cocho_cheio := false
var _bebedouro_cheio := false


func _init() -> void:
	dica = "Um traz o milho. O outro, a água!"


func posicao_estacao() -> Vector2:
	return Lugares.ESTACAO_ANIMAIS


func papeis() -> Array:
	return ["trazer milho", "trazer água", tex("res://assets/sprites/extras/saco_milho.png"),
			tex("res://assets/sprites/extras/balde_agua.png")]


func comecar(a: Jogador, b: Jogador) -> void:
	super.comecar(a, b)
	_saco = Coletavel.new().configurar("milho", "res://assets/sprites/extras/saco_milho.png", Lugares.SACO_MILHO)
	fazenda.mundo.add_child(_saco)
	_balde = Coletavel.new().configurar("agua", "res://assets/sprites/extras/balde_agua.png", Lugares.BALDE)
	fazenda.mundo.add_child(_balde)
	fazenda.hud.falar("Jogador %d: milho do galpão. Jogador %d: água do poço!" % [a.numero, b.numero])


func _centro_cocho() -> Vector2:
	return Lugares.COCHO + Vector2(16, 8)


func _centro_bebedouro() -> Vector2:
	return Lugares.BEBEDOURO + Vector2(16, 8)


func atualizar(_delta: float) -> void:
	if _fase != "abastecer":
		return
	for j in jogadores():
		if j.carregando == "milho" and j.global_position.distance_to(_centro_cocho()) < 30.0:
			j.largar()
			_cocho_cheio = true
			fazenda.encher_cocho()
			Sons.tocar("soltar")
			progresso()
		elif j.carregando == "agua" and j.global_position.distance_to(_centro_bebedouro()) < 30.0:
			j.largar()
			_bebedouro_cheio = true
			fazenda.encher_bebedouro()
			Sons.tocar("splash")
			progresso()
	if _cocho_cheio and _bebedouro_cheio:
		_fase = "ordenha"
		Sons.tocar("vaca")
		fazenda.hud.falar("A Mimosa está feliz! Agora, o leite.")
		await get_tree().create_timer(1.5).timeout
		var mj: MinijogoOrdenha = preload("res://cenas/minijogos/minijogo_ordenha.tscn").instantiate()
		abrir_minijogo(mj)
		mj.concluido.connect(_ordenhou)


func _ordenhou() -> void:
	Jogo.adicionar("leite", 1)
	finalizar()


func ponto_guia() -> Variant:
	if not em_andamento:
		return super.ponto_guia()
	if _fase != "abastecer":
		return null
	for j in jogadores():
		if j.carregando == "milho":
			return _centro_cocho()
		if j.carregando == "agua":
			return _centro_bebedouro()
	if is_instance_valid(_saco):
		return _saco.global_position
	if is_instance_valid(_balde):
		return _balde.global_position
	return null
