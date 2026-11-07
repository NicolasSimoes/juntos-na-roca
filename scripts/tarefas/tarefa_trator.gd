extends Tarefa
## Dia 2 — Desatolar o trator. Um segura AÇÃO para acelerar,
## o outro aperta AÇÃO várias vezes para empurrar. Sozinho, não sai.


func _init() -> void:
	dica = "Quem acelera SEGURA o botão. Quem empurra APERTA várias vezes. Os dois juntos!"


func posicao_estacao() -> Vector2:
	return Lugares.ESTACAO_TRATOR


func papeis() -> Array:
	return ["acelerar", "empurrar", tex("res://assets/sprites/extras/trator.png"),
			tex("res://assets/sprites/tiles/lama.png")]


func comecar(a: Jogador, b: Jogador) -> void:
	super.comecar(a, b)
	var mj: MinijogoTrator = preload("res://cenas/minijogos/minijogo_trator.tscn").instantiate()
	abrir_minijogo(mj)
	mj.concluido.connect(finalizar)


func encerrar() -> void:
	fazenda.desatolar_trator()
