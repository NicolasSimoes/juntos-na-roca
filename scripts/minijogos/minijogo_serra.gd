class_name MinijogoSerra
extends Minijogo
## =====================================================================
## MINIJOGO DA SERRA (dia 1, tarefa "Lenha") — o script "COLA"
## =====================================================================
## O minijogo agora é dividido em três peças, cada uma com um só trabalho:
##
##   1. A REGRA  -> scripts/minijogos/regras/regra_serra.gd
##      Só a lógica: de quem é a vez, quantos cortes, se a serra agarrou.
##      Não sabe nada de tela, de teclado nem de som. Por isso dá para testar.
##
##   2. A CENA   -> cenas/minijogos/minijogo_serra.tscn
##      Só o visual: a tora, a serra, os netos, a barra. Tudo são NÓS montados
##      no editor do Godot com os sprites do projeto (nada é desenhado em código).
##      Para mudar algo de lugar, é só arrastar no editor.
##
##   3. A COLA   -> este arquivo
##      Liga as duas: lê o controle de cada jogador, passa para a regra
##      e copia o estado da regra para os nós da cena, a cada quadro.
##
## Fluxo de um quadro (o Godot chama _process ~60 vezes por segundo):
##
##   teclado ──> Jogo.apertou(n) ──> regra.passo(...) ──> sinais (acertou/errou/terminou)
##                                         │                     │
##                                         ▼                     ▼
##                                  _mostrar() atualiza     som, mensagem,
##                                  posição/texto dos nós   partículas, fim
##
## Quem herda daqui? Ninguém. Quem este arquivo herda? "Minijogo"
## (scripts/minijogos/minijogo.gd), que já cuida do painel, do título, dos textos
## de cada papel embaixo, das mensagens e da dica da Vovó depois de 3 erros.


## ---------------------------------------------------------------------
## Valores ajustáveis no Inspetor
## ---------------------------------------------------------------------
## "@export" faz a variável aparecer no painel Inspetor do editor quando o nó
## raiz da cena está selecionado. Dá para ajustar sem abrir o código.

## Quanto a serra anda para cada lado a cada puxada (em pixels).
@export var vai_e_vem := 26.0
## Velocidade com que a serra desliza até o lado puxado (unidades por segundo).
@export var velocidade_serra := 7.0
## Profundidade do corte quando a tora estiver serrada (altura da tora, em pixels).
@export var profundidade_maxima := 64.0
## Distância do centro da serra até cada cabo (onde a seta "SUA VEZ!" aparece).
@export var distancia_cabo := 92.0


## ---------------------------------------------------------------------
## A regra e o estado só de animação
## ---------------------------------------------------------------------
## A regra é um objeto comum (RefCounted), criado aqui mesmo com .new().
var regra := RegraSerra.new()

## Posição animada da serra, de -1 (esquerda) a 1 (direita). A regra diz
## para que LADO a serra foi puxada; aqui a gente só a faz deslizar até lá.
var _x := 0.0


## ---------------------------------------------------------------------
## Referências aos nós da cena
## ---------------------------------------------------------------------
## "@onready" = esta linha só roda quando o nó entra na árvore de cena
## (logo antes do _ready), porque antes disso os filhos ainda não existem.
## "%Serra" = busca pelo NOME ÚNICO. Na cena, esses nós têm a opção
## "Acesso como nome único" ligada (o % ao lado do nome, no painel Cena).
## Assim o código não depende do caminho: dá para mover o nó de pasta
## no editor sem quebrar nada.
@onready var _tora: Sprite2D = %Tora
@onready var _corte: ColorRect = %Corte
@onready var _serra: Sprite2D = %Serra
@onready var _neto_a: Sprite2D = %NetoA
@onready var _neto_b: Sprite2D = %NetoB
@onready var _seta: Sprite2D = %SetaVez
@onready var _sua_vez: Label = %SuaVez
@onready var _serragem: CPUParticles2D = %Serragem
@onready var _progresso: ProgressBar = %Progresso
@onready var _contador: Label = %Contador

## Onde cada nó está na cena (guardado no começo). A animação soma
## deslocamentos a partir daqui, então o layout continua sendo o do editor.
var _serra_inicio: Vector2
var _neto_a_inicio: Vector2
var _neto_b_inicio: Vector2
var _seta_y: float


## ---------------------------------------------------------------------
## montar(): chamado UMA vez pela classe Minijogo, dentro do _ready().
## ---------------------------------------------------------------------
func montar() -> void:
	# Textos que a classe Minijogo mostra no topo e na faixa de baixo.
	# Jogo.tecla_acao(n) devolve "Espaço" para o jogador 1 e "Enter" para o 2.
	titulo = "Serrar a tora"
	texto_a = "APERTE %s na sua vez" % Jogo.tecla_acao(na)
	texto_b = "APERTE %s na sua vez" % Jogo.tecla_acao(nb)

	# SINAIS: a regra "avisa" quando algo acontece; aqui decidimos o que fazer.
	# .connect(funcao) = "quando este sinal for emitido, chame esta função".
	regra.acertou.connect(_ao_acertar)
	regra.errou.connect(erro)          # erro() vem do Minijogo: som "tóim" + mensagem + dica
	regra.terminou.connect(terminar)   # terminar() vem do Minijogo: mensagem verde e fim

	# Qual neto aparece em cada cabo depende de quem escolheu cada círculo
	# (na = jogador do papel A, nb = do papel B). Por isso a textura é
	# trocada aqui, e não fixada na cena.
	# Aparencia é o lugar único que sabe qual imagem é de cada neto.
	_neto_a.texture = Aparencia.neto(na, "lado")
	_neto_b.texture = Aparencia.neto(nb, "lado")
	Aparencia.ajustar_pes(_neto_a)   # origem nos pés, qualquer tamanho de sprite
	Aparencia.ajustar_pes(_neto_b)

	_progresso.max_value = RegraSerra.CORTES
	_serra_inicio = _serra.position
	_neto_a_inicio = _neto_a.position
	_neto_b_inicio = _neto_b.position
	_seta_y = _seta.position.y
	_mostrar(0.0)


## ---------------------------------------------------------------------
## atualizar(delta): chamado pela classe Minijogo a cada quadro, enquanto
## o minijogo não acabou. "delta" = segundos desde o quadro anterior (~0,016).
## ---------------------------------------------------------------------
func atualizar(delta: float) -> void:
	# 1) ENTRADA: Jogo.apertou(n) usa Input.is_action_just_pressed("pN_acao"),
	#    que é verdadeiro só no quadro em que a tecla desceu (não enquanto segura).
	# 2) REGRA: a regra decide o que esses apertos significam.
	regra.passo(delta, Jogo.apertou(na), Jogo.apertou(nb))
	# 3) TELA: copiar o estado da regra para os nós.
	_mostrar(delta)


## Chamado pelo sinal "acertou" da regra: puxada certa, na vez certa.
func _ao_acertar() -> void:
	# Sons é um autoload (scripts/autoload/sons.gd). O terceiro valor muda um
	# pouco o tom a cada puxada, para não soar repetido.
	Sons.tocar("serra", 0.0, randf_range(0.9, 1.1))
	# restart() dispara de novo a rajada de serragem (partículas "one shot").
	_serragem.restart()
	_serragem.emitting = true
	# acerto() vem do Minijogo: zera a contagem de erros seguidos e avisa a
	# tarefa que houve progresso (a Vovó não precisa dar dica).
	acerto()


## ---------------------------------------------------------------------
## _mostrar(): só visual. Lê a regra e posiciona/atualiza os nós.
## Nenhuma decisão de jogo é tomada aqui.
## ---------------------------------------------------------------------
func _mostrar(delta: float) -> void:
	# move_toward(de, para, passo_maximo): anda até o alvo sem passar dele.
	# Faz a serra DESLIZAR até o lado puxado em vez de pular.
	_x = move_toward(_x, regra.lado, delta * velocidade_serra)

	# Serra agarrada: tremidinha rápida para o lado (seno com frequência alta).
	var tremor := sin(tempo * 70.0) * 3.0 if regra.travada > 0.0 else 0.0
	var dx := _x * vai_e_vem + tremor

	# Profundidade do corte: proporcional aos cortes feitos.
	# float(...) evita divisão inteira (6 / 12 daria 0 com dois inteiros).
	var profundidade := profundidade_maxima * float(regra.cortes) / RegraSerra.CORTES
	_corte.size.y = profundidade

	# A serra vai e vem e desce conforme o corte fica mais fundo.
	# Os netos acompanham a serra pela metade do movimento (puxar e soltar).
	_serra.position = _serra_inicio + Vector2(dx, profundidade * 0.5)
	_neto_a.position = _neto_a_inicio + Vector2(dx * 0.5, 0)
	_neto_b.position = _neto_b_inicio + Vector2(dx * 0.5, 0)

	# Seta de "SUA VEZ!": fica em cima do cabo de quem tem a vez e pinta com a
	# cor desse jogador (Jogo.COR: 1 = laranja, 2 = azul). "modulate" multiplica
	# a cor do sprite, então uma seta branca vira laranja ou azul.
	var jogador_da_vez := na if regra.vez == 0 else nb
	var cor: Color = Jogo.COR[jogador_da_vez]
	var x_cabo := _serra.position.x + (-distancia_cabo if regra.vez == 0 else distancia_cabo)
	_seta.position = Vector2(x_cabo, _seta_y + 4.0 * sin(tempo * 8.0))   # sobe e desce
	_seta.modulate = cor.lightened(0.2)
	_sua_vez.text = "SUA VEZ!" if regra.travada <= 0.0 else "agarrou..."
	_sua_vez.position.x = x_cabo - _sua_vez.size.x / 2.0
	# add_theme_color_override troca só a cor deste rótulo, sem mexer no tema.
	_sua_vez.add_theme_color_override("font_color", cor.lightened(0.3))

	# Barra e contador de puxadas.
	_progresso.value = regra.cortes
	_contador.text = "PUXADAS  %d / %d" % [regra.cortes, RegraSerra.CORTES]
