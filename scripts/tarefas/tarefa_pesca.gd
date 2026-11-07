extends Tarefa
## Dia 4 — Pescar. Um puxa a linha, o outro pega o peixe com o puçá
## quando ele pula perto do píer.


func _init() -> void:
	dica = "Sigam a sombra! Peguem quando o peixe pular!"


func posicao_estacao() -> Vector2:
	return Lugares.ESTACAO_PESCA


func papeis() -> Array:
	return ["puxar a linha", "puçá", tex("res://assets/sprites/extras/vara.png"),
			tex("res://assets/sprites/extras/puca.png")]


func comecar(a: Jogador, b: Jogador) -> void:
	super.comecar(a, b)
	var mj := MinijogoPesca.new()
	abrir_minijogo(mj)
	mj.concluido.connect(_pescou)


func _pescou() -> void:
	Jogo.adicionar("peixe", 3)
	finalizar()
