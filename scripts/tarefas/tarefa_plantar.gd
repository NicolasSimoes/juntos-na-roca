extends Tarefa
## Dia 3 — Plantar a horta. Um põe a semente na cova, o outro vem atrás regando.
## Semente sem água não brota.


func _init() -> void:
	dica = "Primeiro a semente. Depois a água!"


func posicao_estacao() -> Vector2:
	return Lugares.ESTACAO_HORTA


func papeis() -> Array:
	return ["semear", "regar", tex("res://assets/sprites/extras/semente.png"),
			tex("res://assets/sprites/extras/gota.png")]


func comecar(a: Jogador, b: Jogador) -> void:
	super.comecar(a, b)
	a.segurar("semente", tex("res://assets/sprites/extras/semente.png"))
	b.segurar("regador", tex("res://assets/sprites/objetos/regador.png"))
	fazenda.hud.falar("Jogador %d planta. Jogador %d rega!" % [a.numero, b.numero])


func atualizar(_delta: float) -> void:
	var horta: Horta = fazenda.horta
	var ia := horta.cova_perto(papel_a.global_position)
	var ib := horta.cova_perto(papel_b.global_position)
	horta.alvos = {papel_a.numero: ia, papel_b.numero: ib}
	if Jogo.apertou(papel_a.numero) and ia >= 0:
		var c := horta.cova(ia)
		if c["fase"] == 0:
			c["fase"] = 1
			Sons.tocar("plantar")
			progresso()
		else:
			fazenda.hud.aviso("Já tem semente aqui!")
	if Jogo.apertou(papel_b.numero) and ib >= 0:
		var c := horta.cova(ib)
		if c["fase"] == 1:
			c["fase"] = 2
			c["molhado"] = true
			Sons.tocar("regar")
			horta.atualizar_chao()
			progresso()
		elif c["fase"] == 0:
			Sons.tocar("toim")
			fazenda.hud.aviso("Primeiro a semente!")
		else:
			fazenda.hud.aviso("Essa já foi regada!")
	var pronto := true
	for c in Jogo.horta:
		if c["fase"] < 2:
			pronto = false
	if pronto:
		finalizar()


func ponto_guia() -> Variant:
	if not em_andamento:
		return super.ponto_guia()
	for i in Jogo.horta.size():
		if Jogo.horta[i]["fase"] < 2:
			return fazenda.horta.centro(i)
	return null


func encerrar() -> void:
	papel_a.largar()
	papel_b.largar()
	fazenda.horta.alvos = {}
