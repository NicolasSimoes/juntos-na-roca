extends Tarefa
## Dia 3 — Recolher as galinhas. Sozinho ninguém pega: a galinha corre mais.
## Com os dois bem pertinho, ela se acalma e segue a dupla até o cercado.


func _init() -> void:
	dica = "Sozinho, ela foge! Cheguem os dois bem pertinho dela, ao mesmo tempo."


func posicao_estacao() -> Vector2:
	return Lugares.ESTACAO_GALINHAS


func papeis() -> Array:
	var g := tex("res://assets/sprites/personagens/galinha_1.png")
	return ["cercar", "cercar", g, g]


func comecar(a: Jogador, b: Jogador) -> void:
	super.comecar(a, b)
	for g in fazenda.galinhas:
		g.pode_cercar = true
	fazenda.hud.falar("Cheguem os dois pertinho de uma galinha. Ela se acalma e vai com vocês até o cercado!")


func atualizar(_delta: float) -> void:
	for g in fazenda.galinhas:
		if g.estado != Galinha.Estado.GUARDADA:
			return
	finalizar()


func ponto_guia() -> Variant:
	if not em_andamento:
		return super.ponto_guia()
	var meio: Vector2 = (jogadores()[0].global_position + jogadores()[1].global_position) / 2.0
	var melhor: Galinha = null
	var menor := 99999.0
	for item in fazenda.galinhas:
		var g: Galinha = item
		if g.estado == Galinha.Estado.CERCADA:
			return Lugares.PORTAO_GALINHAS + Vector2(0, -16)
		if g.estado == Galinha.Estado.SOLTA:
			var d := g.global_position.distance_to(meio)
			if d < menor:
				menor = d
				melhor = g
	return melhor.global_position if melhor != null else null
