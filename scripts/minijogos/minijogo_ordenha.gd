class_name MinijogoOrdenha
extends Minijogo
## =====================================================================
## MINIJOGO DA ORDENHA (dia 4, tarefa "Cuidar dos animais") — o script "COLA"
## =====================================================================
## Mesmo padrão da serra e do trator, em três peças:
##
##   1. A REGRA  -> scripts/minijogos/regras/regra_ordenha.gd
##      Calma da Mimosa, leite no balde, coice. Sem tela, sem som.
##
##   2. A CENA   -> cenas/minijogos/minijogo_ordenha.tscn
##      O estábulo: parede e chão de tábuas, barris e cocho (pacote Super Retro
##      World), a Mimosa e os netos. Tudo montado no editor.
##
##   3. A COLA   -> este arquivo
##      A cada quadro: lê o controle -> regra.passo() -> atualiza os nós.
##
##   teclado ──> Jogo.segurando(na) (capim) / Jogo.apertou(nb) (ordenhar)
##                    │
##                    ▼
##              regra.passo(...) ──> sinais: acertou / errou / terminou
##                    │
##                    ▼
##              _mostrar(): barras, balde enchendo, capim, vaca tremendo


## ---------------------------------------------------------------------
## Ajustes no Inspetor
## ---------------------------------------------------------------------
## Quanto a Mimosa treme para os lados no coice (pixels).
@export var forca_do_coice := 4.0
## Altura do leite quando o balde está cheio (pixels).
@export var altura_leite := 30.0


var regra := RegraOrdenha.new()
var _vaca_inicio: Vector2
var _capim_inicio: Vector2
var _fundo_do_balde := 0.0


## Nós da cena (nome único com %).
@onready var _vaca: Sprite2D = %Vaca
@onready var _neto_a: Sprite2D = %NetoA
@onready var _neto_b: Sprite2D = %NetoB
@onready var _capim: Sprite2D = %Capim
@onready var _leite_no_balde: ColorRect = %LeiteNoBalde
@onready var _gotas: CPUParticles2D = %Gotas
@onready var _coracao: Sprite2D = %Coracao
@onready var _barra_calma: ProgressBar = %Calma
@onready var _barra_leite: ProgressBar = %Leite


func montar() -> void:
	titulo = "Tirar o leite da Mimosa"
	texto_a = "SEGURE %s para dar capim" % Jogo.tecla_acao(na)
	texto_b = "APERTE %s para tirar leite" % Jogo.tecla_acao(nb)

	regra.acertou.connect(_ao_tirar_leite)
	regra.errou.connect(_ao_levar_coice)
	regra.terminou.connect(terminar)

	# Neto do papel A (capim) fica do lado da cabeça, olhando para a vaca:
	# flip_h espelha a imagem (a pose "lado" olha para a direita).
	_neto_a.texture = Aparencia.neto(na, "lado")
	_neto_a.flip_h = true
	Aparencia.ajustar_pes(_neto_a)
	_neto_b.texture = Aparencia.neto(nb, "lado")
	Aparencia.ajustar_pes(_neto_b)

	_vaca_inicio = _vaca.position
	_capim_inicio = _capim.position
	# O leite cresce de baixo para cima: guardamos onde fica o fundo do balde.
	_fundo_do_balde = _leite_no_balde.position.y + _leite_no_balde.size.y
	_mostrar()


func atualizar(delta: float) -> void:
	regra.passo(delta, Jogo.segurando(na), Jogo.apertou(nb))
	_mostrar()


## Sinal "acertou": saiu um jato de leite.
func _ao_tirar_leite() -> void:
	Sons.tocar("leite", 0.0, randf_range(0.9, 1.2))
	_gotas.restart()          # rajada de gotinhas caindo no balde
	_gotas.emitting = true
	acerto()


## Sinal "errou": a Mimosa não estava calma e deu coice.
func _ao_levar_coice(texto: String) -> void:
	Sons.tocar("vaca", -4.0, 1.2)
	erro(texto)


## Só visual.
func _mostrar() -> void:
	# Coice: a vaca treme rápido para os lados (seno com frequência alta).
	var tremor := sin(tempo * 50.0) * forca_do_coice if regra.coice > 0.0 else 0.0
	_vaca.position = _vaca_inicio + Vector2(tremor, 0)

	# O capim só aparece enquanto o papel A segura, balançando de leve.
	_capim.visible = regra.dando_capim
	_capim.position = _capim_inicio + Vector2(0, sin(tempo * 10.0) * 2.0)

	# Coração: quanto mais calma, mais forte a cor (modulate.a = transparência).
	_coracao.modulate.a = 0.35 + 0.65 * regra.calma

	# Balde enchendo: a altura do retângulo branco segue o leite (0 a 1),
	# crescendo para cima a partir do fundo do balde.
	_leite_no_balde.size.y = altura_leite * regra.leite
	_leite_no_balde.position.y = _fundo_do_balde - _leite_no_balde.size.y

	_barra_calma.value = regra.calma
	_barra_leite.value = regra.leite
