class_name MinijogoPesca
extends Minijogo
## =====================================================================
## MINIJOGO DA PESCA (dia 4, tarefa "Pescar") — o script "COLA"
## =====================================================================
## Mesmo formato da serra, em três peças:
##   1. REGRA -> scripts/minijogos/regras/regra_pesca.gd  (lógica pura, testável)
##   2. CENA  -> cenas/minijogos/minijogo_pesca.tscn      (lago, píer, netos, peixe)
##   3. COLA  -> este arquivo: lê o controle, chama a regra e atualiza os nós.
##
##   teclado ──> regra.passo(...) ──> sinais (fisgou, puxou, pulou, pegou, errou, terminou)
##                     │                         │
##                     ▼                         ▼
##              _mostrar() move os nós      som, mensagem, fim


## ---------------------------------------------------------------------
## Valores ajustáveis no Inspetor (@export)
## ---------------------------------------------------------------------
## Altura máxima do pulo do peixe (pixels).
@export var altura_do_pulo := 70.0
## Quantos quadros da animação da água por segundo.
@export var quadros_da_agua_por_segundo := 5.0
## Distância do neto até o puçá (o neto fica à esquerda da rede).
@export var neto_atras_do_puca := 26.0

## Linha da água no painel (em pixels): sombra e boia ficam em relação a ela.
const AGUA_Y := 150.0
const QUADROS_DA_AGUA := 6      ## water_03_48x48.png tem 6 quadros de 48 px lado a lado

var regra := RegraPesca.new()

@onready var _agua: NinePatchRect = %Agua
@onready var _pescador: Sprite2D = %Pescador
@onready var _puqueiro: Sprite2D = %Puqueiro
@onready var _vara: Line2D = %Vara
@onready var _linha: Line2D = %Linha
@onready var _boia: Sprite2D = %Boia
@onready var _sombra: Sprite2D = %Sombra
@onready var _bolhas: CPUParticles2D = %Bolhas
@onready var _peixe: Sprite2D = %Peixe
@onready var _puca: Sprite2D = %Puca
@onready var _placar: Node2D = %Placar
@onready var _distancia: ProgressBar = %Distancia

var _puca_dx := 0.0     ## distância (x) entre o puçá na cena e o puca_x da regra
var _boia_y := 0.0


func montar() -> void:
	titulo = "Pescar no píer"
	texto_a = "Aperte %s: puxe a linha" % Jogo.tecla_acao(na)
	texto_b = "%s: ande · %s: pegue" % [Jogo.teclas_lado(nb), Jogo.tecla_acao(nb)]

	# Cada sinal da regra vira uma reação na tela.
	regra.fisgou.connect(_ao_mexer_na_agua)
	regra.pulou.connect(_ao_mexer_na_agua)
	regra.puxou.connect(_ao_puxar)
	regra.pegou.connect(_ao_pegar)
	regra.errou.connect(erro)          # erro() vem do Minijogo: "tóim", mensagem e dica
	regra.terminou.connect(terminar)   # terminar() vem do Minijogo

	# Quem pegou cada papel define qual neto aparece (Aparencia = lugar único da arte).
	_pescador.texture = Aparencia.neto(na, "lado")
	_puqueiro.texture = Aparencia.neto(nb, "lado")
	Aparencia.ajustar_pes(_pescador)
	Aparencia.ajustar_pes(_puqueiro)

	# Guardamos onde o puçá e a boia estão na cena: o layout continua sendo o do editor.
	_puca_dx = _puca.position.x - regra.puca_x
	_boia_y = _boia.position.y
	_mostrar()


func atualizar(_delta: float) -> void:
	# Jogo.direcao(n) devolve um Vector2 com as setas/WASD; usamos só o x (esquerda/direita).
	regra.passo(_delta, Jogo.apertou(na), Jogo.direcao(nb).x, Jogo.apertou(nb))
	_mostrar()


# ---------------------------------------------------------------- reações aos sinais
## O peixe mordeu ou pulou: barulho de água e recado amarelo.
func _ao_mexer_na_agua(texto: String) -> void:
	Sons.tocar("splash")
	mensagem(texto, Color(1, 1, 0.7))


## Puxada do papel A: som de força (mais baixo e agudo) e progresso.
func _ao_puxar() -> void:
	Sons.tocar("forca", -8.0, 1.4)
	acerto()


## O papel B pegou o peixe.
func _ao_pegar(texto: String) -> void:
	Sons.tocar("acerto")
	acerto()
	if texto != "":
		mensagem(texto, Color(0.8, 1, 0.7))


# ---------------------------------------------------------------- só visual
func _mostrar() -> void:
	# Água: andar o region_rect de 48 em 48 px troca o quadro da animação.
	var quadro := int(tempo * quadros_da_agua_por_segundo) % QUADROS_DA_AGUA
	_agua.region_rect.position.x = 48.0 * quadro

	# O puçá e o neto andam juntos pelo píer.
	_puca.position.x = regra.puca_x + _puca_dx
	_puqueiro.position.x = _puca.position.x - neto_atras_do_puca

	# A ponta da vara é o último ponto da Line2D da vara.
	var ponta := _vara.points[_vara.points.size() - 1]
	_boia.visible = regra.estado == "esperando"
	_sombra.visible = regra.estado == "fisgado"
	_peixe.visible = regra.estado == "pulando"
	# emitting liga/desliga as partículas: bolhas só com peixe fisgado.
	_bolhas.emitting = regra.estado == "fisgado"
	_bolhas.position.x = regra.peixe_x
	var fim_da_linha := Vector2.ZERO
	match regra.estado:
		"esperando":
			_boia.position.y = _boia_y + sin(tempo * 4.0) * 2.0   # boia balançando
			fim_da_linha = _boia.position
		"fisgado":
			_sombra.position.x = regra.peixe_x
			fim_da_linha = Vector2(regra.peixe_x, AGUA_Y + 30.0)
		"pulando":
			# sin de 0 a PI faz um arco: sobe e desce em JANELA_DO_PULO segundos.
			var t := clampf(regra.pulo / RegraPesca.JANELA_DO_PULO, 0.0, 1.0)
			_peixe.position = Vector2(regra.peixe_x, AGUA_Y - sin(t * PI) * altura_do_pulo)
			fim_da_linha = _peixe.position
	# Line2D.points é a lista de pontos da linha: da ponta da vara até o fim.
	_linha.points = PackedVector2Array([ponta, fim_da_linha])

	# Placar: os peixes pegos ficam coloridos (modulate branco = cor original).
	for i in _placar.get_child_count():
		var icone := _placar.get_child(i) as Sprite2D
		icone.modulate = Color.WHITE if i < regra.pegos else Color(0, 0, 0, 0.35)

	_distancia.visible = regra.estado == "fisgado"
	_distancia.value = regra.dist
