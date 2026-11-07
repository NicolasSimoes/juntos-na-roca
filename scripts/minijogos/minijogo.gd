class_name Minijogo
extends CanvasLayer
## Base dos minijogos que abrem por cima do mapa (poço, serra, trator, ordenha, pesca).
##
## Por que CanvasLayer? Uma CanvasLayer é uma "camada" de desenho separada do mundo:
## o que está nela aparece por cima do mapa (layer = 4) e não acompanha a câmera.
## É o jeito do Godot fazer uma tela que abre "por cima" do jogo.
##
## Esta classe cuida do que é comum a todos os minijogos:
##   - o painel, o título e o texto do que cada papel faz (na cor de cada jogador);
##   - mensagem(), erro(), acerto() e terminar();
##   - avisar a tarefa quando acabou, pelo sinal "concluido".
## Cada minijogo herda daqui (extends Minijogo) e preenche montar() e atualizar().
##
## Cada minijogo é uma cena .tscn herdada de cenas/minijogos/minijogo_base.tscn:
## os nós comuns (Painel, Titulo, RotuloA, RotuloB, Mensagem) vêm da cena base e
## cada minijogo põe os seus nós dentro de Painel/Conteudo. Nada é desenhado em código.

## Sinal: o jeito do Godot de um nó avisar "aconteceu algo" sem saber quem está ouvindo.
## A tarefa faz mj.concluido.connect(...) e é chamada quando emitimos concluido.emit().
signal concluido

var na := 1          # número do jogador (1 ou 2) que pegou o papel A
var nb := 2          # número do jogador que pegou o papel B
var dica := ""       # o que a Vovó fala depois de 3 erros seguidos
var fazenda: Node    # a cena da fazenda (pode ser null ao testar o minijogo sozinho)
var tarefa: Tarefa   # a tarefa que abriu este minijogo (pode ser null)
var titulo := ""
var texto_a := ""    # o que o papel A faz (aparece embaixo, na cor do jogador)
var texto_b := ""
var acabou := false
var tempo := 0.0     # segundos desde que o minijogo abriu

var painel: Control
var _erros_seguidos := 0
var _ultimo_erro := -10.0

## "@onready" busca os nós logo antes do _ready(), quando eles já existem.
## "%Titulo" = nó com "nome único" na cena: o script não depende do caminho exato,
## então dá para mover o nó de lugar no editor sem quebrar o código.
@onready var _titulo: Label = %Titulo
@onready var _rotulo_a: Label = %RotuloA
@onready var _rotulo_b: Label = %RotuloB
@onready var _mensagem: Label = %Mensagem
var _tween_msg: Tween


## _ready() é chamado pelo Godot uma vez, quando o nó entra na árvore de cenas
## (todos os filhos já existem nessa hora).
func _ready() -> void:
	layer = 4
	painel = %Painel
	# Primeiro o minijogo se prepara (define titulo, texto_a, texto_b...)...
	montar()
	# ...e só depois preenchemos os textos com o que ele definiu.
	_titulo.text = titulo
	_pintar_rotulo(_rotulo_a, na, texto_a)
	_pintar_rotulo(_rotulo_b, nb, texto_b)
	if fazenda != null:
		# Esconde o quadro de tarefas e a cesta enquanto o minijogo está aberto.
		fazenda.hud.mostrar_topo(false)


## O nome e a cor do rótulo dependem de QUEM pegou o papel: se o jogador 2 pegou
## o papel A, o rótulo A fica azul. add_theme_color_override troca só uma cor do
## tema neste nó, sem mexer no tema dos outros.
func _pintar_rotulo(rotulo: Label, n: int, texto: String) -> void:
	rotulo.text = _texto_papel(n, texto)
	rotulo.add_theme_color_override("font_color", Jogo.COR[n].lightened(0.35))


## _exit_tree() é chamado quando o nó sai da árvore (o minijogo fechou).
func _exit_tree() -> void:
	if fazenda != null and is_instance_valid(fazenda) and is_instance_valid(fazenda.hud):
		fazenda.hud.mostrar_topo(true)


func _texto_papel(n: int, texto: String) -> String:
	return "Jogador %d: %s" % [n, texto]


## _process(delta) roda a cada quadro (umas 60 vezes por segundo).
## delta = quantos segundos passaram desde o quadro anterior (~0,016).
func _process(delta: float) -> void:
	tempo += delta
	if not acabou:
		atualizar(delta)


# ---------------------------------------------------------- para cada minijogo
## Prepara o minijogo: define titulo, texto_a, texto_b e liga o que precisar.
func montar() -> void:
	pass


## Roda a cada quadro enquanto o minijogo não acabou: lê o controle e anda a regra.
func atualizar(_delta: float) -> void:
	pass


# ---------------------------------------------------------- ajudantes
## Mostra um recado no alto do painel e apaga devagar.
## Tween = animação feita por código: "leve esta propriedade até este valor em X segundos".
func mensagem(texto: String, cor := Color.WHITE) -> void:
	_mensagem.text = texto
	_mensagem.add_theme_color_override("font_color", cor)
	_mensagem.modulate.a = 1.0
	if _tween_msg:
		_tween_msg.kill()   # cancela o apagar do recado anterior
	_tween_msg = create_tween()
	_tween_msg.tween_interval(1.2)                                # espera 1,2 s
	_tween_msg.tween_property(_mensagem, "modulate:a", 0.0, 0.4)  # some em 0,4 s


## Errou: toca o "tóim" (no máximo um a cada 0,5 s) e, depois de 3 erros
## seguidos, a Vovó fala a dica. Errar nunca tira ponto: só repete o passo.
func erro(texto := "") -> void:
	var agora := tempo
	if agora - _ultimo_erro > 0.5:
		Sons.tocar("toim")
	_ultimo_erro = agora
	if texto != "":
		mensagem(texto, Color(1, 0.75, 0.6))
	_erros_seguidos += 1
	if _erros_seguidos >= 3 and dica != "" and fazenda != null:
		_erros_seguidos = 0
		fazenda.hud.falar(dica)


## Acertou: zera a contagem de erros e avisa a tarefa que houve progresso
## (assim a Vovó não aparece com dica à toa).
func acerto() -> void:
	_erros_seguidos = 0
	if tarefa != null:
		tarefa.progresso()


## Fim do minijogo. "await" pausa SÓ esta função até o sinal chegar:
## create_timer(1.0) cria um relógio de 1 segundo e .timeout é o sinal de quando ele acaba.
## O jogo continua rodando nesse segundo (dá tempo de ver "Conseguiram!").
func terminar(texto := "Conseguiram!") -> void:
	if acabou:
		return
	acabou = true
	mensagem(texto, Color(0.7, 1, 0.6))
	Sons.tocar("acerto")
	await get_tree().create_timer(1.0).timeout
	concluido.emit()
