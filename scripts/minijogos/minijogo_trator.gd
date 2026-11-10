class_name MinijogoTrator
extends Minijogo
## =====================================================================
## MINIJOGO DO TRATOR (dia 2, tarefa "Desatolar o trator") — o script "COLA"
## =====================================================================
## Mesmo padrão da serra, em três peças:
##
##   1. A REGRA  -> scripts/minijogos/regras/regra_trator.gd
##      Força da dupla, quem está sozinho, quando sai da lama. Sem tela, sem som.
##
##   2. A CENA   -> cenas/minijogos/minijogo_trator.tscn
##      Árvores, cerca, barris, lama, trator e os netos. Tudo são nós montados
##      no editor com sprites (os do pacote Super Retro World e os do projeto).
##
##   3. A COLA   -> este arquivo
##      A cada quadro: lê o controle -> chama regra.passo() -> copia o estado
##      da regra para os nós (posição do trator, barra de força, fumaça...).
##
##   teclado ──> Jogo.segurando(na) / Jogo.apertou(nb) ──> regra.passo(...)
##                                                              │
##                       _mostrar() move o trator e a barra  <──┤
##                       som, tremida, mensagem              <──┘ (sinais)


## ---------------------------------------------------------------------
## Ajustes no Inspetor (@export aparece no editor ao selecionar a raiz)
## ---------------------------------------------------------------------
## Quantos pixels o trator anda para a direita quando a força chega a 1.
@export var distancia_saida := 120.0
## Quanto o empurrador "dá o passo" para a frente a cada empurrão.
@export var passo_empurrao := 6.0
## Intervalo entre os "vrum" do motor enquanto acelera (segundos).
@export var intervalo_motor := 0.55


## A regra: um objeto comum (RefCounted), criado aqui com .new().
var regra := RegraTrator.new()

var _empurrao := 0.0     ## segundos que ainda falta mostrar a tremida do empurrão
var _motor := 0.0        ## contagem para o próximo som de motor
var _inicio: Vector2     ## onde o trator começa (lido da cena, então dá para arrastar no editor)
var _empurrador_x := 0.0


## ---------------------------------------------------------------------
## Nós da cena. "%Nome" = nome único (o % ao lado do nó no painel Cena).
## @onready = só pega o nó quando a cena já está pronta (antes do _ready).
## ---------------------------------------------------------------------
@onready var _trator: Node2D = %Trator              # grupo que anda: trator + motorista + lama espirrando
@onready var _corpo: Sprite2D = %Corpo              # o desenho do trator
@onready var _motorista: Sprite2D = %Motorista      # cabeça do neto do papel A, na cabine
@onready var _empurrador: Sprite2D = %Empurrador    # neto do papel B, atrás do trator
@onready var _respingos: CPUParticles2D = %Respingos
@onready var _fumaca: CPUParticles2D = %Fumaca
@onready var _vrum: Label = %Vrum
@onready var _forca: ProgressBar = %Forca


## montar(): a classe Minijogo chama UMA vez, dentro do _ready().
func montar() -> void:
	titulo = "Tirar o trator da lama"
	texto_a = "SEGURE %s para acelerar" % Jogo.tecla_acao(na)
	texto_b = "APERTE %s para empurrar" % Jogo.tecla_acao(nb)

	# Sinais da regra -> reações da tela.
	regra.acertou.connect(_ao_empurrar)
	regra.errou.connect(erro)          # erro() (do Minijogo): "tóim" + mensagem + dica da Vovó
	regra.terminou.connect(terminar)   # terminar() (do Minijogo): mensagem verde e fim

	# Quem está em cada papel decide qual neto aparece (laranja ou azul).
	_empurrador.texture = Aparencia.neto(nb, "lado")
	Aparencia.ajustar_pes(_empurrador)
	_mostrar_so_a_cabeca(_motorista, Aparencia.neto(na, "lado"))

	_inicio = _trator.position
	_empurrador_x = _empurrador.position.x
	_mostrar(0.0)


## Na cabine só aparece a cabeça do motorista: usamos "region" do Sprite2D
## para recortar a parte de cima da imagem (qualquer tamanho de sprite).
func _mostrar_so_a_cabeca(s: Sprite2D, tex: Texture2D) -> void:
	s.texture = tex
	var tam := tex.get_size()
	var altura_cabeca := roundf(tam.y * 0.5)
	s.region_enabled = true
	s.region_rect = Rect2(0, 0, tam.x, altura_cabeca)
	s.centered = false
	s.offset = Vector2(-tam.x / 2.0, -altura_cabeca)   # origem embaixo da cabeça


## atualizar(delta): a classe Minijogo chama a cada quadro até o fim.
func atualizar(delta: float) -> void:
	# Jogo.segurando(n): a tecla está APERTADA agora (vale enquanto segura).
	# Jogo.apertou(n): a tecla DESCEU neste quadro (um aperto = uma vez).
	regra.passo(delta, Jogo.segurando(na), Jogo.apertou(nb))
	_som_do_motor(delta)
	_mostrar(delta)


## Sinal "acertou": empurrão que valeu (motor ligado).
func _ao_empurrar() -> void:
	_empurrao = 0.15
	# O tom sobe junto com a força: dá a sensação de "tá quase!".
	Sons.tocar("forca", -4.0, 0.8 + regra.forca)
	acerto()


func _som_do_motor(delta: float) -> void:
	if not regra.acelerando:
		_motor = 0.0
		return
	_motor -= delta
	if _motor <= 0.0:
		_motor = intervalo_motor
		Sons.tocar("motor", -4.0)


## Só visual: lê a regra e atualiza os nós.
func _mostrar(delta: float) -> void:
	_empurrao = maxf(0.0, _empurrao - delta)

	# O trator anda para a direita conforme a força; treme no empurrão.
	var tremor := sin(tempo * 60.0) * 2.0 if _empurrao > 0.0 else 0.0
	_trator.position = _inicio + Vector2(regra.forca * distancia_saida + tremor, 0)

	# Acelerando: o trator chacoalha (sobe e desce 1 pixel) e solta fumaça.
	var chacoalho := 1.0 if regra.acelerando and fmod(tempo, 0.1) < 0.05 else 0.0
	_corpo.offset.y = -17.0 - chacoalho
	_fumaca.emitting = regra.acelerando
	_vrum.visible = regra.acelerando

	# Patinando sozinho: a roda espirra lama para trás.
	_respingos.emitting = regra.patinando

	# O empurrador dá um passinho para a frente no empurrão.
	_empurrador.position.x = _empurrador_x + (passo_empurrao if _empurrao > 0.0 else 0.0)

	_forca.value = regra.forca
