## =====================================================================
## REGRA DO TRATOR — a "regra pura" do minijogo de desatolar o trator.
## =====================================================================
## Um jogador SEGURA a ação (acelera). O outro APERTA várias vezes (empurra).
## A força da dupla só sobe quando alguém empurra COM o motor ligado.
## Sozinho não adianta: sem acelerador, empurrar não faz nada; sem empurrão,
## a roda só patina na lama.
##
## Este arquivo NÃO desenha, NÃO toca som e NÃO lê o teclado. A tela
## (minijogo_trator.gd) pergunta "está segurando? apertou?" e repassa para cá.
## Por isso dá para testar tudo em testes/test_regra_trator.gd.

# class_name: nome global. Qualquer script pode fazer RegraTrator.new().
class_name RegraTrator
# RefCounted: objeto simples (só dados + funções), fora da árvore de cena.
# O Godot apaga sozinho quando ninguém mais usa.
extends RefCounted

# ---------------------------------------------------------------- sinais
# A regra só AVISA; quem decide o que fazer (som, mensagem) é a tela.
signal acertou                  ## um empurrão com o motor ligado (a força subiu)
signal errou(texto: String)     ## empurrou sem motor, ou ficou acelerando sozinho
signal terminou(texto: String)  ## o trator saiu da lama

# ---------------------------------------------------------------- constantes
const EMPURRAO := 0.075            ## quanto cada empurrão (com motor) soma na força
const PERDA_POR_SEGUNDO := 0.04    ## a lama puxa de volta: a força cai devagar
const SOZINHO_DEPOIS_DE := 1.2     ## segundos sem empurrão até contar como "sozinho"
const AVISO_SOZINHO_A_CADA := 2.2  ## segundos patinando sozinho entre um aviso e outro

const TEXTO_DESLIGADO := "Primeiro acelere o trator!"
const TEXTO_SOZINHO := "Empurre junto! Sozinho não sai."
const TEXTO_FIM := "Saiu da lama!"

# ---------------------------------------------------------------- estado
var forca := 0.0          ## força da dupla, de 0 a 1 (1 = saiu da lama)
var acelerando := false   ## o motor está ligado neste quadro? (a tela usa para a fumaça e o "VRUM!")
var patinando := false    ## acelerando sem ninguém empurrar (a roda espirra lama)
var tempo := 0.0          ## relógio da regra, em segundos
var _ultimo_empurrao := -10.0   ## quando foi o último empurrão que valeu
var _sozinho := 0.0             ## há quanto tempo está patinando sozinho
var _terminou := false


## Avança a regra em um quadro.
##  delta      = segundos desde o quadro anterior
##  acelerando = o papel A está SEGURANDO a ação?
##  empurrou   = o papel B APERTOU a ação neste quadro?
func passo(delta: float, segurando_acelerador: bool, empurrou: bool) -> void:
	if _terminou:
		return
	tempo += delta
	acelerando = segurando_acelerador

	# 1) Empurrão: só vale com o motor ligado.
	if empurrou:
		if acelerando:
			forca += EMPURRAO
			_ultimo_empurrao = tempo
			acertou.emit()
		else:
			errou.emit(TEXTO_DESLIGADO)

	# 2) Acelerando sem empurrão recente = patinando sozinho.
	patinando = acelerando and tempo - _ultimo_empurrao > SOZINHO_DEPOIS_DE
	if patinando:
		_sozinho += delta
		if _sozinho > AVISO_SOZINHO_A_CADA:
			_sozinho = 0.0
			errou.emit(TEXTO_SOZINHO)
	else:
		_sozinho = 0.0

	# 3) A lama puxa de volta. maxf impede a força de ficar negativa.
	forca = maxf(0.0, forca - delta * PERDA_POR_SEGUNDO)

	# 4) Chegou a 1? Saiu da lama.
	if forca >= 1.0:
		forca = 1.0
		_terminou = true
		terminou.emit(TEXTO_FIM)
