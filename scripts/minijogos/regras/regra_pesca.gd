## =====================================================================
## REGRA DA PESCA — a "regra pura" do minijogo de pescar no píer.
## =====================================================================
## Dois papéis:
##   A (vara)  aperta AÇÃO várias vezes para puxar a linha: o peixe chega perto.
##   B (puçá)  anda pelo píer seguindo a sombra do peixe e aperta AÇÃO
##             quando o peixe pula. São 3 peixes.
##
## O peixe passa por três ESTADOS (uma "máquina de estados"):
##
##   "esperando" --(espera acaba)--> "fisgado" --(dist <= 0,22)--> "pulando"
##        ^                              ^                            |
##        |                              +---(errou / demorou)--------+
##        +----------------------(pegou com o puçá)-------------------+
##
## Como a serra, este arquivo NÃO desenha, NÃO toca som e NÃO lê o teclado.
## A tela (minijogo_pesca.gd) lê o controle, chama passo() e reage aos sinais.

class_name RegraPesca
extends RefCounted   # objeto simples (sem nó na árvore), apagado sozinho quando ninguém usa

# ---------------------------------------------------------------- sinais
signal fisgou(texto: String)    ## um peixe mordeu a isca
signal puxou                    ## o papel A puxou a linha (para tocar o som e contar progresso)
signal pulou(texto: String)     ## o peixe pulou perto do píer: hora do puçá!
signal pegou(texto: String)     ## o papel B pegou o peixe (texto vazio no último: quem fala é "terminou")
signal errou(texto: String)     ## puçá longe do peixe, ou o peixe voltou para a água
signal terminou(texto: String)  ## pegaram os 3 peixes

# ---------------------------------------------------------------- constantes
const META := 3                ## peixes para terminar
const ESPERA_INICIAL := 1.5    ## segundos até o primeiro peixe morder
const ESPERA_ENTRE := 1.2      ## segundos até o próximo peixe morder
const PUXADA := 0.07           ## quanto cada aperto do papel A aproxima o peixe
const VOLTA_DA_LINHA := 0.06   ## quanto o peixe se afasta sozinho, por segundo
const PERTO_DO_PIER := 0.22    ## com a distância nisso (ou menos), o peixe pula
const JANELA_DO_PULO := 1.2    ## segundos que o peixe fica no ar
const ALCANCE_PUCA := 30.0     ## distância máxima (em pixels) entre puçá e peixe para pegar
const DIST_DEPOIS_DO_ERRO := 0.45
const VEL_PUCA := 170.0        ## pixels por segundo
const PUCA_MIN := 160.0        ## o puçá só anda em cima do píer
const PUCA_MAX := 540.0

# ---------------------------------------------------------------- estado
var estado := "esperando"
var espera := ESPERA_INICIAL   ## segundos que ainda faltam para morder
var dist := 1.0                ## 1 = peixe longe, 0 = colado no píer
var puca_x := 300.0            ## onde está o puçá (pixels, no painel)
var peixe_x := 400.0           ## onde está o peixe (pixels, no painel)
var pulo := 0.0                ## há quanto tempo o peixe está no ar
var pegos := 0                 ## peixes já pegos
var tempo := 0.0               ## relógio da regra (faz a sombra do peixe balançar)


## Avança a regra em um quadro.
##  puxou      = o papel A apertou AÇÃO neste quadro?
##  mover_puca = direção do papel B: -1 (esquerda) a 1 (direita)
##  pegou_agora = o papel B apertou AÇÃO neste quadro?
func passo(delta: float, puxou_agora: bool, mover_puca: float, pegou_agora: bool) -> void:
	if pegos >= META:
		return   # já terminou: nada mais conta
	tempo += delta
	# clampf(valor, mínimo, máximo) segura o puçá dentro do píer.
	puca_x = clampf(puca_x + mover_puca * VEL_PUCA * delta, PUCA_MIN, PUCA_MAX)
	# O peixe fica mais perto do píer (x menor) quanto menor a distância,
	# e balança para os lados com um seno (sin) para a sombra parecer nadando.
	peixe_x = 190.0 + dist * 320.0 + sin(tempo * 2.3) * 26.0

	# "match" é o "escolha um caso" do GDScript: roda só o bloco do estado atual.
	match estado:
		"esperando":
			espera -= delta
			if espera <= 0.0:
				estado = "fisgado"
				dist = 1.0
				fisgou.emit("Fisgou! Puxe a linha!")
		"fisgado":
			if puxou_agora:
				dist -= PUXADA
				puxou.emit()
			# minf(a, b) = o menor dos dois: a distância nunca passa de 1.
			dist = minf(1.0, dist + delta * VOLTA_DA_LINHA)
			if dist <= PERTO_DO_PIER:
				estado = "pulando"
				pulo = 0.0
				pulou.emit("Pulou! Pegue com o puçá!")
		"pulando":
			pulo += delta
			if pegou_agora:
				if absf(puca_x - peixe_x) < ALCANCE_PUCA:
					_pegar()
				else:
					_voltar_para_agua("Errou! Siga a sombra.")
			elif pulo >= JANELA_DO_PULO:
				_voltar_para_agua("Voltou para a água!")


func _pegar() -> void:
	pegos += 1
	estado = "esperando"
	espera = ESPERA_ENTRE
	dist = 1.0
	if pegos >= META:
		pegou.emit("")
		terminou.emit("3 peixes! Que almoço!")
	else:
		var faltam := META - pegos
		pegou.emit("Pegou! Falta %d." % faltam if faltam == 1 else "Pegou! Faltam %d." % faltam)


## Errou o puçá ou demorou: o peixe cai de volta, mas não foge longe.
func _voltar_para_agua(texto: String) -> void:
	estado = "fisgado"
	dist = DIST_DEPOIS_DO_ERRO
	errou.emit(texto)
