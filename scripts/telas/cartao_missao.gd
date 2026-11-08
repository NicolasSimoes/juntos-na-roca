class_name CartaoMissao
extends CanvasLayer
## Cartão de missão: aparece ANTES de toda tarefa, quando os dois param nos círculos.
## Responde às três perguntas que uma criança precisa antes de jogar:
##   1. POR QUÊ?  a Vovó conta o problema da fazenda (balão em cima);
##   2. O QUÊ?    cada jogador vê o SEU papel: o neto, o ícone, o verbo e as teclas;
##   3. PRONTO?   a tarefa só começa quando os DOIS apertam AÇÃO (assim os dois leram).
## Os textos ficam em Textos.MISSOES. A fazenda abre o cartão e espera o sinal "pronto".

signal pronto

var _quem := {}                       # papel ("a" ou "b") -> número do jogador
var _confirmou := {1: false, 2: false}
var _tempo := 0.0
var _fechando := false

@onready var _titulo: Label = %Titulo
@onready var _porque: Label = %Porque
@onready var _depois: Label = %Depois
@onready var _cartoes := {"a": %CartaoA as PanelContainer, "b": %CartaoB as PanelContainer}
@onready var _nomes := {"a": %NomeA as Label, "b": %NomeB as Label}
@onready var _netos := {"a": %NetoA as TextureRect, "b": %NetoB as TextureRect}
@onready var _icones := {"a": %IconeA as TextureRect, "b": %IconeB as TextureRect}
@onready var _verbos := {"a": %VerboA as Label, "b": %VerboB as Label}
@onready var _teclas := {"a": %TeclasA as TeclasJogador, "b": %TeclasB as TeclasJogador}
@onready var _status := {"a": %StatusA as Label, "b": %StatusB as Label}


## Preenche o cartão para a tarefa "id". na/nb = número do jogador em cada papel.
func abrir(id: String, na: int, nb: int, icone_a: Texture2D, icone_b: Texture2D) -> void:
	var m: Dictionary = Textos.MISSOES.get(id, {})
	_titulo.text = Jogo.NOMES.get(id, "")
	_porque.text = m.get("porque", "")
	_depois.text = m.get("depois", "")
	%FaixaDepois.visible = _depois.text != ""
	%ImagemDepois.texture = _textura(m.get("imagem_depois", ""))
	# figura do que a Vovó está falando (a vaca, a galinha, o peixe...)
	%Imagem.texture = _textura(m.get("imagem", ""))
	%Vovo.texture = Aparencia.vovo("frente")
	_quem = {"a": na, "b": nb}
	var icones := {"a": icone_a, "b": icone_b}
	for papel in ["a", "b"]:
		var n: int = _quem[papel]
		_nomes[papel].text = "Jogador %d" % n
		_nomes[papel].add_theme_color_override("font_color", Jogo.COR[n].lightened(0.35))
		_netos[papel].texture = Aparencia.neto(n, "frente")
		_icones[papel].texture = icones[papel]
		_verbos[papel].text = m.get(papel, "")
		_teclas[papel].numero = n
		_so_as_teclas_usadas(_teclas[papel], m.get("teclas_" + papel, "andar"), m.get("gesto_" + papel, ""))
		_status[papel].text = "Aperte %s!" % Jogo.tecla_acao(n)
		# a borda do cartão fica na cor de quem faz aquele papel
		var estilo := (_cartoes[papel].get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
		estilo.border_color = Jogo.COR[n]
		estilo.bg_color = Jogo.COR[n].darkened(0.7)
		estilo.bg_color.a = 0.95
		_cartoes[papel].add_theme_stylebox_override("panel", estilo)
	Sons.tocar("fala")


## Mostra só as teclas que aquele papel usa:
##   "andar" = cruz de andar + AÇÃO;  "lados" = esquerda/direita + AÇÃO;  "acao" = só AÇÃO.
## O gesto ("segure", "várias vezes") aparece embaixo da tecla de AÇÃO.
func _so_as_teclas_usadas(teclas: TeclasJogador, modo: String, gesto: String) -> void:
	for nome in ["Cima", "Baixo"]:
		teclas.get_node(nome).visible = modo == "andar"
	for nome in ["Esquerda", "Direita", "RotuloAndar"]:
		teclas.get_node(nome).visible = modo != "acao"
	(teclas.get_node("RotuloAndar") as Label).text = "lados" if modo == "lados" else "andar"
	(teclas.get_node("RotuloAcao") as Label).text = gesto if gesto != "" else "ação"


func _textura(caminho: String) -> Texture2D:
	return null if caminho == "" else Jogo.tex(caminho)


func _process(delta: float) -> void:
	_tempo += delta
	for papel in ["a", "b"]:
		var n: int = _quem.get(papel, 1)
		var status: Label = _status[papel]
		status.modulate.a = 1.0 if _confirmou[n] else 0.55 + 0.45 * absf(sin(_tempo * 4.0))
	# espera um instante antes de aceitar AÇÃO: quem acabou de entrar no círculo
	# não pula o cartão sem querer
	if _tempo < 0.6:
		return
	for n in [1, 2]:
		if Jogo.apertou(n):
			confirmar(n)


## Um jogador apertou AÇÃO: fica marcado "Pronto!". Com os dois, o cartão fecha.
func confirmar(n: int) -> void:
	if _confirmou[n] or _fechando:
		return
	_confirmou[n] = true
	Sons.tocar("pegar")
	for papel in ["a", "b"]:
		if _quem.get(papel) == n:
			_status[papel].text = "Pronto!"
			_status[papel].add_theme_color_override("font_color", Color(0.6, 1, 0.5))
			(_teclas[papel] as TeclasJogador).get_node("%Acao").apertar()
	if _confirmou[1] and _confirmou[2]:
		_fechando = true
		Sons.tocar("acerto")
		await get_tree().create_timer(0.4).timeout
		pronto.emit()
