class_name MinijogoPoco
extends Minijogo
## =====================================================================
## MINIJOGO DO POÇO (dia 1, tarefa "Consertar o poço") — o script "COLA"
## =====================================================================
## Mesmo formato da serra, em três peças:
##   1. REGRA -> scripts/minijogos/regras/regra_poco.gd  (lógica pura, testável)
##   2. CENA  -> cenas/minijogos/minijogo_poco.tscn      (tampa, pilha, martelo, poço)
##   3. COLA  -> este arquivo: lê o controle, chama a regra e atualiza os nós.
##
##   teclado ──> regra.passo(...) ──> sinais (pegou_tabua, encaixou, martelou, aviso, errou, terminou)
##                     │                          │
##                     ▼                          ▼
##              _mostrar() atualiza os nós   som, mensagem, fim

## A imagem de cada formato de tábua. preload carrega o arquivo uma vez, junto com o script.
const TEXTURAS := {
	"quadrado": preload("res://assets/sprites/objetos/tabua_quadrado.png"),
	"triangulo": preload("res://assets/sprites/objetos/tabua_triangulo.png"),
	"circulo": preload("res://assets/sprites/objetos/tabua_circulo.png"),
	"losango": preload("res://assets/sprites/objetos/tabua_losango.png"),
}
## O poço enche de água conforme as tábuas são pregadas (recortes do tileset do pacote).
const POCOS := [
	preload("res://assets/recortes/minijogos/poco_poco_0.tres"),
	preload("res://assets/recortes/minijogos/poco_poco_1.tres"),
	preload("res://assets/recortes/minijogos/poco_poco_2.tres"),
	preload("res://assets/recortes/minijogos/poco_poco_3.tres"),
]
const VAZIO := Color(0.12, 0.1, 0.1)      ## cor do espaço ainda sem tábua (forma escura)
const PREGO_BATIDO := Color(0.75, 0.75, 0.8)

## ---------------------------------------------------------------------
## Valores ajustáveis no Inspetor (@export)
## ---------------------------------------------------------------------
@export var martelo_levantado := -0.9    ## rotação do martelo parado (radianos)
@export var martelo_batendo := 0.4       ## rotação do martelo no instante da batida
@export var tempo_da_batida := 0.18      ## quanto tempo o martelo fica embaixo
@export var tempo_do_tremor := 0.3       ## quanto tempo a barra treme depois de errar

var regra: RegraPoco
var _batida := 0.0      ## segundos que o martelo ainda fica embaixo
var _tremor := 0.0      ## segundos que a barra ainda treme

@onready var _vagas: Node2D = %Vagas
@onready var _pilha: Node2D = %Pilha
@onready var _cursor_vaga: ReferenceRect = %CursorVaga
@onready var _cursor_pilha: ReferenceRect = %CursorPilha
@onready var _tabua_na_mao: Sprite2D = %TabuaNaMao
@onready var _espere: Label = %Espere
@onready var _poco: Sprite2D = %Poco
@onready var _martelo: Sprite2D = %Martelo
@onready var _barra: Control = %Batida
@onready var _zona: ColorRect = %Zona
@onready var _marcador: ColorRect = %Marcador
@onready var _agora: Label = %Agora

var _barra_x := 0.0


func montar() -> void:
	titulo = "Consertar o poço"
	texto_a = "%s: escolha · %s: encaixe" % [Jogo.teclas_lado(na), Jogo.tecla_acao(na)]
	texto_b = "Aperte %s no prego" % Jogo.tecla_acao(nb)

	# Embaralha os espaços e a pilha (shuffle) e entrega para a regra.
	var vagas: Array = RegraPoco.FORMAS.duplicate()
	vagas.shuffle()
	var pilha: Array = RegraPoco.FORMAS.duplicate()
	pilha.shuffle()
	regra = RegraPoco.new(vagas, pilha)

	# Cada sinal da regra vira uma reação na tela.
	regra.pegou_tabua.connect(func(): Sons.tocar("pegar"))   # função anônima (lambda) de uma linha
	regra.encaixou.connect(_ao_encaixar)
	regra.martelou.connect(_ao_martelar)
	regra.aviso.connect(func(texto: String): mensagem(texto, Color(1, 0.9, 0.6)))
	regra.errou.connect(erro)          # erro() vem do Minijogo: "tóim", mensagem e dica
	regra.terminou.connect(terminar)   # terminar() vem do Minijogo

	# O formato de cada espaço da tampa vem da regra (embaralhado).
	for i in 4:
		_tabua_da_vaga(i).texture = TEXTURAS[regra.vagas[i]]
	# Cores de quem joga cada papel.
	_cursor_vaga.border_color = Jogo.COR[na]
	_marcador.color = Jogo.COR[nb]
	_barra_x = _barra.position.x
	_mostrar()


func atualizar(delta: float) -> void:
	_batida = maxf(0.0, _batida - delta)
	_tremor = maxf(0.0, _tremor - delta)
	# apertou_esquerda/direita: verdadeiro só no quadro em que a seta desceu.
	regra.passo(delta, Jogo.apertou_esquerda(na), Jogo.apertou_direita(na), Jogo.apertou(na), Jogo.apertou(nb))
	_mostrar()


# ---------------------------------------------------------------- reações aos sinais
func _ao_encaixar(texto: String) -> void:
	Sons.tocar("encaixe")
	mensagem(texto, Color(0.8, 1, 0.7))
	acerto()


## Toda batida desce o martelo; se errou o prego, a barra treme.
func _ao_martelar(no_prego: bool) -> void:
	_batida = tempo_da_batida
	if no_prego:
		Sons.tocar("toc")
		acerto()
	else:
		_tremor = tempo_do_tremor


# ---------------------------------------------------------------- só visual
func _tabua_da_vaga(i: int) -> Sprite2D:
	return _vagas.get_child(i).get_node("Tabua")


func _mostrar() -> void:
	var prontas := 0
	for i in 4:
		var vaga := _vagas.get_child(i)
		var encaixada := regra.pregos.has(i)
		# Espaço vazio = forma quase preta (um buraco); encaixado = cor da madeira.
		(vaga.get_node("Tabua") as Sprite2D).modulate = Color.WHITE if encaixada else VAZIO
		var faltam: int = regra.pregos.get(i, RegraPoco.PREGOS_POR_TABUA)
		if encaixada and faltam == 0:
			prontas += 1
		for k in RegraPoco.PREGOS_POR_TABUA:
			var prego := vaga.get_node("Prego%d" % (k + 1)) as Sprite2D
			prego.visible = encaixada
			var batido := k < RegraPoco.PREGOS_POR_TABUA - faltam
			prego.modulate = PREGO_BATIDO if batido else Color.WHITE
			prego.scale = Vector2(0.8, 0.5) if batido else Vector2.ONE   # prego batido "afunda" (fica achatado)

	# Papel A: com a mão vazia, olha a pilha; com tábua, olha os espaços.
	var cor_a: Color = Jogo.COR[na]
	var segurando := regra.segurando != ""
	_cursor_pilha.visible = not segurando
	_cursor_vaga.visible = segurando
	_tabua_na_mao.visible = segurando
	var vaga_pos := (_vagas.get_child(regra.cursor_vaga) as Node2D).position
	_cursor_vaga.position = vaga_pos - _cursor_vaga.size / 2.0
	if segurando:
		_tabua_na_mao.texture = TEXTURAS[regra.segurando]
		_tabua_na_mao.position = vaga_pos + Vector2(0, -2.0 + 3.0 * sin(tempo * 8.0))   # flutuando
	var lugar_pos := (_pilha.get_child(regra.cursor_pilha) as Node2D).position
	_cursor_pilha.position = lugar_pos - _cursor_pilha.size / 2.0
	# darkened(0.5) escurece a cor: o cursor apaga enquanto o martelo trabalha.
	_cursor_pilha.border_color = cor_a.darkened(0.5) if regra.vaga_pregando >= 0 else cor_a
	for i in 4:
		var tabua := _pilha.get_child(i).get_node("Tabua") as Sprite2D
		tabua.visible = regra.pilha[i] != ""
		if tabua.visible:
			tabua.texture = TEXTURAS[regra.pilha[i]]
	_espere.visible = regra.vaga_pregando >= 0 and not segurando

	# O poço enche: 0 a 3 tábuas prontas (com 4, continua cheio).
	_poco.texture = POCOS[mini(prontas, POCOS.size() - 1)]

	# Papel B: martelo, barra e marcador.
	_martelo.rotation = martelo_batendo if _batida > 0.0 else martelo_levantado
	var tremor := sin(tempo * 80.0) * 3.0 * _tremor / tempo_do_tremor if _tremor > 0.0 else 0.0
	_barra.position.x = _barra_x + tremor
	_marcador.position.x = _barra.size.x * regra.marcador - _marcador.size.x / 2.0
	var pregando := regra.vaga_pregando >= 0
	_zona.color = Color(0.4, 0.8, 0.35) if pregando else Color(0.6, 0.6, 0.6)
	if not pregando:
		_agora.text = "espere a tábua..."
	else:
		_agora.text = "AGORA!" if absf(regra.marcador - 0.5) <= RegraPoco.ZONA else ""
