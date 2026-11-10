## =====================================================================
## REGRA DA SERRA — a "regra pura" do minijogo de serrar a tora.
## =====================================================================
## Este arquivo só sabe as REGRAS do jogo: de quem é a vez, quantos cortes
## já foram feitos, se a serra agarrou. Ele NÃO desenha nada, NÃO toca som
## e NÃO lê o teclado. Quem faz isso é a tela (minijogo_serra.gd + a cena
## minijogo_serra.tscn), que só pergunta "apertou?" e repassa para cá.
##
## Por que separar?
##  - Fica fácil de LER: a lógica cabe numa tela, sem coordenadas de desenho.
##  - Fica fácil de TESTAR: o teste chama passo() com "apertou / não apertou"
##    e confere o resultado, sem abrir o jogo (testes/test_regra_serra.gd).
##  - Dá para trocar o visual inteiro sem mexer na regra, e vice-versa.

# class_name dá um nome global a este script. Com isso, qualquer outro
# script pode escrever RegraSerra.new() sem precisar de load("...").
class_name RegraSerra

# extends RefCounted: a regra é um objeto simples, não um Node.
#  - Um Node vive na árvore de cena (aparece no editor, recebe _process...).
#  - Um RefCounted não fica na árvore: é só dados + funções.
#    O Godot conta quantas variáveis apontam para ele e o apaga sozinho
#    quando ninguém mais usa (contagem de referência) — não precisa de free().
extends RefCounted

# ---------------------------------------------------------------- sinais
# Um "signal" é um aviso que este objeto dispara com .emit().
# A regra não sabe QUEM está ouvindo: quem ouve é a tela, que liga
# (connect) cada sinal a uma reação — tocar som, mostrar mensagem, etc.
signal acertou                  ## alguém puxou na sua vez
signal errou(texto: String)     ## alguém puxou fora da vez (texto para a tela mostrar)
signal terminou(texto: String)  ## a tora foi serrada

# ---------------------------------------------------------------- constantes
# const = valor fixo, que não muda durante o jogo. Mudou o equilíbrio do
# minijogo? É só mexer aqui.
const CORTES := 12              ## quantas puxadas para serrar a tora
const TEMPO_TRAVADA := 0.7      ## segundos que a serra fica agarrada depois de um erro

# ---------------------------------------------------------------- estado
var vez := 0          ## de quem é a vez: 0 = papel A (cabo da esquerda), 1 = papel B (direita)
var cortes := 0       ## quantas puxadas certas já foram feitas
var travada := 0.0    ## segundos que ainda faltam para a serra destravar (0 = livre)
var lado := 0.0       ## para onde a serra foi puxada por último: -1 = esquerda (A), 1 = direita (B)


## Avança a regra em um quadro do jogo.
##  delta      = segundos desde o quadro anterior (o Godot passa isso no _process)
##  apertou_a  = o jogador do papel A apertou AÇÃO neste quadro?
##  apertou_b  = o jogador do papel B apertou AÇÃO neste quadro?
func passo(delta: float, apertou_a: bool, apertou_b: bool) -> void:
	# A trava vai diminuindo com o tempo. maxf(a, b) devolve o maior dos dois
	# números (versão para float): assim a trava para em 0 e nunca fica negativa.
	travada = maxf(0.0, travada - delta)

	# Olhamos os dois jogadores em ordem: primeiro A (k = 0), depois B (k = 1).
	# Detalhe: se os dois apertarem NO MESMO QUADRO, A é processado primeiro;
	# se era a vez de A, a vez passa para B e o aperto de B também conta.
	# Resultado: 2 cortes de uma vez. É o mesmo comportamento do código antigo.
	var apertos := [apertou_a, apertou_b]
	for k in 2:
		if not apertos[k]:
			continue          # este jogador não apertou: nada a fazer
		if travada > 0.0:
			continue          # serra agarrada: ignora apertos até destravar
		if cortes >= CORTES:
			continue          # já terminou: não conta mais nada
		if k == vez:
			# Puxou na sua vez: conta um corte e a vez passa para o outro.
			cortes += 1
			vez = 1 - vez                         # 0 vira 1, 1 vira 0
			lado = -1.0 if k == 0 else 1.0        # A puxa para a esquerda, B para a direita
			acertou.emit()
			if cortes >= CORTES:
				terminou.emit("A tora está serrada!")
		else:
			# Puxou fora da vez: a serra agarra por um instante.
			travada = TEMPO_TRAVADA
			errou.emit("Travou! Um de cada vez.")
