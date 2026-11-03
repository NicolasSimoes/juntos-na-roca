extends Tarefa
## Dia 4 — Cuidar da horta. Um rega os brotos com sede (gotinha em cima),
## o outro arranca o mato. A planta só cresce com água e sem mato.


func _init() -> void:
	dica = "Onde tem gotinha, precisa de água. Onde tem mato, precisa arrancar. Cada um faz a sua parte!"


func posicao_estacao() -> Vector2:
	return Lugares.ESTACAO_HORTA


func papeis() -> Array:
	return ["regar", "tirar o mato", tex("res://assets/sprites/extras/gota.png"),
			tex("res://assets/sprites/extras/mato.png")]


func comecar(a: Jogador, b: Jogador) -> void:
	super.comecar(a, b)
	a.segurar("regador", tex("res://assets/sprites/objetos/regador.png"))
	fazenda.horta.mostrar_sede = true
	fazenda.hud.falar("Jogador %d rega onde tem gotinha. Jogador %d arranca o mato!" % [a.numero, b.numero])


func atualizar(_delta: float) -> void:
	var horta: Horta = fazenda.horta
	var ia := horta.cova_perto(papel_a.global_position)
	var ib := horta.cova_perto(papel_b.global_position)
	horta.alvos = {papel_a.numero: ia, papel_b.numero: ib}
	if Jogo.apertou(papel_a.numero) and ia >= 0:
		var c := horta.cova(ia)
		if c["fase"] == 2 and not c["molhado"]:
			c["molhado"] = true
			Sons.tocar("regar")
			horta.atualizar_chao()
			_crescer(ia)
			progresso()
		else:
			fazenda.hud.aviso("Essa não está com sede.")
	if Jogo.apertou(papel_b.numero) and ib >= 0:
		var c := horta.cova(ib)
		if c["mato"]:
			c["mato"] = false
			Sons.tocar("arrancar")
			_crescer(ib)
			progresso()
		else:
			fazenda.hud.aviso("Aqui não tem mato.")
	var pronto := true
	for c in Jogo.horta:
		if c["fase"] < 3:
			pronto = false
	if pronto:
		finalizar()


func _crescer(i: int) -> void:
	var c: Dictionary = Jogo.horta[i]
	if c["fase"] == 2 and c["molhado"] and not c["mato"]:
		c["fase"] = 3
		Sons.tocar("acerto", -8.0, 1.3)


func ponto_guia() -> Variant:
	if not em_andamento:
		return super.ponto_guia()
	for i in Jogo.horta.size():
		if Jogo.horta[i]["fase"] < 3:
			return fazenda.horta.centro(i)
	return null


func encerrar() -> void:
	papel_a.largar()
	fazenda.horta.alvos = {}
	fazenda.horta.mostrar_sede = false
