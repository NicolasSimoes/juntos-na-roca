## =====================================================================
## REGRA DA ORDENHA — a "regra pura" do minijogo de tirar o leite.
## =====================================================================
## Um jogador SEGURA a ação: dá capim e a Mimosa fica calma.
## O outro APERTA várias vezes: tira o leite. Sem capim (pouca calma),
## a Mimosa dá um coice e não deixa. Só funciona com os dois juntos.
##
## Este arquivo NÃO desenha, NÃO toca som e NÃO lê o teclado.
## Testes em testes/test_regra_ordenha.gd.

class_name RegraOrdenha
extends RefCounted

# ---------------------------------------------------------------- sinais
signal acertou                  ## saiu um jato de leite
signal errou(texto: String)     ## tentou ordenhar com a vaca nervosa
signal terminou(texto: String)  ## o balde encheu

# ---------------------------------------------------------------- constantes
const CALMA_SOBE := 3.0          ## por segundo, enquanto dá capim
const CALMA_DESCE := 1.5         ## por segundo, sem capim
const CALMA_MINIMA := 0.6        ## precisa de calma MAIOR que isso para ordenhar
const LEITE_POR_APERTO := 0.07   ## quanto cada aperto enche o balde (de 0 a 1)
const TEMPO_COICE := 0.5         ## segundos que a vaca fica tremendo depois do coice

const TEXTO_SEM_CAPIM := "Dê capim para a Mimosa!"
const TEXTO_FIM := "Leite fresquinho!"

# ---------------------------------------------------------------- estado
var calma := 0.0          ## de 0 (nervosa) a 1 (calminha)
var leite := 0.0          ## de 0 (balde vazio) a 1 (cheio)
var coice := 0.0          ## segundos de coice que ainda faltam (a tela faz a vaca tremer)
var dando_capim := false  ## o papel A está segurando o capim neste quadro?
var _terminou := false


## Avança a regra em um quadro.
##  delta      = segundos desde o quadro anterior
##  capim      = o papel A está SEGURANDO a ação?
##  ordenhou   = o papel B APERTOU a ação neste quadro?
func passo(delta: float, capim: bool, ordenhou: bool) -> void:
	if _terminou:
		return
	dando_capim = capim
	coice = maxf(0.0, coice - delta)

	# move_toward(de, para, passo): chega perto do alvo sem passar dele.
	# Com capim a calma sobe rápido; sem capim, cai devagar.
	if capim:
		calma = move_toward(calma, 1.0, delta * CALMA_SOBE)
	else:
		calma = move_toward(calma, 0.0, delta * CALMA_DESCE)

	if ordenhou:
		if calma > CALMA_MINIMA:
			leite += LEITE_POR_APERTO
			acertou.emit()
		else:
			coice = TEMPO_COICE
			errou.emit(TEXTO_SEM_CAPIM)

	if leite >= 1.0:
		leite = 1.0
		_terminou = true
		terminou.emit(TEXTO_FIM)
