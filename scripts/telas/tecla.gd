@tool
class_name Tecla
extends Control
## Uma tecla de teclado desenhada (keycap), para mostrar os comandos sem texto longo.
## Pode ter um rótulo ("W", "Espaço", "Enter") ou uma seta (cima, baixo, esquerda, direita).
## @tool = o script também roda dentro do editor, então a tecla aparece certa na cena.
## apertar() faz a tecla "afundar" por um instante (bom para tutoriais animados).

@export var texto := "":
	set(valor):
		texto = valor
		_atualizar()
@export_enum("nenhuma", "cima", "baixo", "esquerda", "direita") var seta := "nenhuma":
	set(valor):
		seta = valor
		_atualizar()
@export var tamanho_fonte := 9:
	set(valor):
		tamanho_fonte = valor
		_atualizar()
## Cor da borda de cima (para pintar com a cor do jogador).
@export var cor := Color(0.96, 0.94, 0.88):
	set(valor):
		cor = valor
		_atualizar()

## Quanto a parte de cima da tecla afunda quando é apertada (em pixels).
const AFUNDAR := 2.0
const GIRO := {"cima": PI, "baixo": 0.0, "esquerda": PI / 2.0, "direita": -PI / 2.0}

var _tween: Tween


func _ready() -> void:
	_atualizar()


func _atualizar() -> void:
	if not is_inside_tree():
		return
	var rotulo := get_node_or_null("Topo/Rotulo") as Label
	var desenho := get_node_or_null("Topo/Seta") as TextureRect
	var topo := get_node_or_null("Topo") as Panel
	if rotulo == null or desenho == null or topo == null:
		return
	rotulo.text = texto
	rotulo.add_theme_font_size_override("font_size", tamanho_fonte)
	desenho.visible = seta != "nenhuma"
	# A seta.png aponta para baixo; girar o desenho faz as outras direções.
	desenho.rotation = GIRO.get(seta, 0.0)
	desenho.pivot_offset = desenho.size / 2.0
	var estilo := topo.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if estilo:
		estilo.bg_color = cor
		topo.add_theme_stylebox_override("panel", estilo)


## A tecla afunda e volta (como se alguém tivesse apertado).
func apertar() -> void:
	var topo := get_node_or_null("Topo") as Control
	if topo == null:
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(topo, "position:y", AFUNDAR, 0.06)
	_tween.tween_property(topo, "position:y", 0.0, 0.12)
