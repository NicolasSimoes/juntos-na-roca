@tool
class_name TeclasJogador
extends Control
## As teclas de UM jogador: a cruz de andar e a tecla de AÇÃO.
## Jogador 1: W A S D + Espaço.  Jogador 2: setas + Enter.
## Com "animar" ligado, as teclas se apertam sozinhas, como num tutorial.

@export_range(1, 2) var numero := 1:
	set(valor):
		numero = valor
		_atualizar()
@export var animar := false

var _tempo := 0.0
var _passo := -1


func _ready() -> void:
	_atualizar()


func _atualizar() -> void:
	if not is_inside_tree() or get_node_or_null("%Cima") == null:
		return
	var dois := numero == 2
	var nomes := {"Cima": "W", "Esquerda": "A", "Baixo": "S", "Direita": "D"}
	var setas := {"Cima": "cima", "Esquerda": "esquerda", "Baixo": "baixo", "Direita": "direita"}
	for nome in nomes:
		var t := get_node("%" + nome) as Tecla
		t.texto = "" if dois else nomes[nome]
		t.seta = setas[nome] if dois else "nenhuma"
	var acao := %Acao as Tecla
	acao.texto = "Enter" if dois else "Espaço"


func _process(delta: float) -> void:
	if not animar or Engine.is_editor_hint():
		return
	_tempo += delta
	# a cada 0,45 s aperta a próxima tecla: cima, esquerda, baixo, direita, AÇÃO
	var passo := int(_tempo / 0.45) % 6
	if passo != _passo:
		_passo = passo
		var ordem := ["Cima", "Esquerda", "Baixo", "Direita", "Acao"]
		if passo < ordem.size():
			(get_node("%" + ordem[passo]) as Tecla).apertar()
