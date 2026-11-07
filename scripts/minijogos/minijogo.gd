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
## DOIS MODOS (temporário):
##   - modo cena: o minijogo é uma cena .tscn herdada de cenas/minijogos/minijogo_base.tscn.
##     Os nós (Painel, Titulo, RotuloA...) já existem na cena e o script só os preenche.
##   - modo legado: o minijogo ainda é criado com MinijogoX.new(), sem cena. Aí esta
##     classe cria os nós por código e o minijogo se desenha em desenhar().
## O modo legado existe só até a Tarefa 8 do plano (docs/superpowers/plans/), quando
## os cinco minijogos já forem cenas. Até lá, os que ainda não migraram não podem quebrar.

## Sinal: o jeito do Godot de um nó avisar "aconteceu algo" sem saber quem está ouvindo.
## A tarefa faz mj.concluido.connect(...) e é chamada quando emitimos concluido.emit().
signal concluido

const PAINEL := Rect2(40, 4, 560, 290)

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
var _modo_cena := false
var _erros_seguidos := 0
var _ultimo_erro := -10.0
var _titulo: Label
var _rotulo_a: Label
var _rotulo_b: Label
var _mensagem: Label
var _tween_msg: Tween


## _ready() é chamado pelo Godot uma vez, quando o nó entra na árvore de cenas
## (todos os filhos já existem nessa hora).
func _ready() -> void:
	layer = 4
	# "%Painel" procura o nó marcado como "nome único" (unique_name_in_owner) na cena.
	# Assim o script não depende do caminho exato (Painel/Conteudo/...): se alguém
	# mudar o nó de lugar no editor, o código continua achando.
	# get_node_or_null devolve null em vez de dar erro quando o nó não existe:
	# é assim que descobrimos se estamos numa cena ou no modo legado.
	if get_node_or_null("%Painel") != null:
		_modo_cena = true
		painel = %Painel
		_titulo = %Titulo
		_rotulo_a = %RotuloA
		_rotulo_b = %RotuloB
		_mensagem = %Mensagem
	else:
		_montar_sem_cena()
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


## Modo legado: cria por código os mesmos nós que a cena base tem.
func _montar_sem_cena() -> void:
	var fundo := ColorRect.new()
	fundo.color = Color(0.05, 0.04, 0.08, 0.6)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	painel = Control.new()
	painel.position = PAINEL.position
	painel.size = PAINEL.size
	painel.clip_contents = true
	add_child(painel)
	# No modo legado o minijogo se desenha "à mão" no sinal draw do painel.
	painel.draw.connect(_desenhar_painel)
	_titulo = Hud.rotulo("", 14, Color(1, 0.9, 0.5), 4)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.position = Vector2(0, 4)
	_titulo.size = Vector2(PAINEL.size.x, 20)
	painel.add_child(_titulo)
	var faixa := ColorRect.new()
	faixa.color = Color(0.1, 0.07, 0.05, 0.75)
	faixa.position = Vector2(0, PAINEL.size.y - 40)
	faixa.size = Vector2(PAINEL.size.x, 40)
	painel.add_child(faixa)
	_rotulo_a = Hud.rotulo("", 10, Color.WHITE, 3)
	_rotulo_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo_a.position = Vector2(0, PAINEL.size.y - 38)
	_rotulo_a.size = Vector2(PAINEL.size.x, 16)
	painel.add_child(_rotulo_a)
	_rotulo_b = Hud.rotulo("", 10, Color.WHITE, 3)
	_rotulo_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo_b.position = Vector2(0, PAINEL.size.y - 20)
	_rotulo_b.size = Vector2(PAINEL.size.x, 16)
	painel.add_child(_rotulo_b)
	_mensagem = Hud.rotulo("", 13, Color.WHITE, 4)
	_mensagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mensagem.position = Vector2(0, 26)
	_mensagem.size = Vector2(PAINEL.size.x, 20)
	painel.add_child(_mensagem)


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
	if not _modo_cena:
		# queue_redraw() pede ao Godot para chamar o desenho de novo neste quadro.
		painel.queue_redraw()


func _desenhar_painel() -> void:
	painel.draw_style_box(Hud.estilo(Color(0.55, 0.78, 0.95), Color(0.2, 0.15, 0.1), 8), Rect2(Vector2.ZERO, PAINEL.size))
	desenhar(painel)


# ---------------------------------------------------------- para cada minijogo
## Prepara o minijogo: define titulo, texto_a, texto_b e liga o que precisar.
func montar() -> void:
	pass


## Roda a cada quadro enquanto o minijogo não acabou: lê o controle e anda a regra.
func atualizar(_delta: float) -> void:
	pass


## Só no modo legado: desenha o minijogo à mão.
func desenhar(_c: Control) -> void:
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


# ---------------------------------------------------------- ajudantes de desenho (modo legado)
func texto_centro(c: Control, pos: Vector2, texto: String, tamanho := 9, cor := Color.WHITE, largura := 200.0) -> void:
	var f := ThemeDB.fallback_font
	var p := pos + Vector2(-largura / 2, 0)
	c.draw_string_outline(f, p, texto, HORIZONTAL_ALIGNMENT_CENTER, largura, tamanho, 4, Color(0.1, 0.07, 0.05))
	c.draw_string(f, p, texto, HORIZONTAL_ALIGNMENT_CENTER, largura, tamanho, cor)


func textura(c: Control, caminho: String, pos: Vector2, escala := 1.0, girar := false, cor := Color.WHITE) -> void:
	var t := Jogo.tex(caminho)
	var tam := t.get_size() * escala
	c.draw_texture_rect(t, Rect2(pos - tam / 2, tam), false, cor, girar)


func barra(c: Control, r: Rect2, valor: float, cor: Color) -> void:
	c.draw_rect(r.grow(2), Color(0.15, 0.1, 0.06))
	c.draw_rect(r, Color(0.3, 0.25, 0.2))
	c.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(valor, 0, 1), r.size.y)), cor)
