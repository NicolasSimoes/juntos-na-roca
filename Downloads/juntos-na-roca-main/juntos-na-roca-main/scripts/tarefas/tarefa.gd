class_name Tarefa
extends Node2D
## Base de todas as tarefas da fazenda.
## Cada tarefa tem uma estação (os dois círculos). Quando os dois param nela,
## a fazenda chama comecar(papel_a, papel_b). Quando a parte jogável acaba,
## a tarefa chama finalizar() e a fazenda cuida do "toca aqui" e da foto.

signal terminou

var id := ""
var fazenda: Node                 # a cena da fazenda (scripts/fazenda.gd)
var estacao: Estacao
var papel_a: Jogador
var papel_b: Jogador
var em_andamento := false
var overlay: Minijogo             # minijogo aberto por cima do mapa (se tiver)
var dica := ""                    # o que a Vovó fala se a dupla empacar
var _sem_progresso := 0.0


# ---------------------------------------------------------- para cada tarefa preencher
func posicao_estacao() -> Vector2:
	return Vector2.ZERO


func papeis() -> Array:
	## [texto do papel A, texto do papel B, ícone A, ícone B]
	return ["", "", null, null]


func preparar() -> void:
	## Chamado no começo do dia (coloca itens no mapa etc.).
	pass


func pode_comecar() -> bool:
	return true


func comecar(a: Jogador, b: Jogador) -> void:
	papel_a = a
	papel_b = b
	em_andamento = true
	_sem_progresso = 0.0


func ponto_guia() -> Variant:
	## Para onde a setinha aponta. null = não aponta.
	if estacao != null and estacao.ativa:
		return estacao.global_position
	return null


func encerrar() -> void:
	## Arruma o mapa depois que a tarefa acaba (antes do "toca aqui").
	pass


# ---------------------------------------------------------- ajudantes
func progresso() -> void:
	_sem_progresso = 0.0


func finalizar() -> void:
	if not em_andamento:
		return
	em_andamento = false
	terminou.emit()


func abrir_minijogo(mj: Minijogo) -> void:
	overlay = mj
	mj.na = papel_a.numero
	mj.nb = papel_b.numero
	mj.dica = dica
	mj.fazenda = fazenda
	mj.tarefa = self
	fazenda.travar(true)
	fazenda.add_child(mj)


func tex(caminho: String) -> Texture2D:
	return Jogo.tex(caminho)


func _ready() -> void:
	z_index = 6


func _process(delta: float) -> void:
	queue_redraw()
	if not em_andamento:
		aguardando(delta)
		return
	_sem_progresso += delta
	if _sem_progresso > 22.0 and dica != "" and overlay == null:
		_sem_progresso = 0.0
		fazenda.hud.falar(dica)
	atualizar(delta)


func aguardando(_delta: float) -> void:
	## Roda todo frame enquanto a tarefa ainda não começou.
	pass


func atualizar(_delta: float) -> void:
	## Roda todo frame enquanto a tarefa está acontecendo.
	pass


func jogadores() -> Array[Jogador]:
	return fazenda.jogadores
