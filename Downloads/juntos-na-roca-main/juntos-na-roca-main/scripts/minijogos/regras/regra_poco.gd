## =====================================================================
## REGRA DO POÇO — a "regra pura" do minijogo de consertar a tampa do poço.
## =====================================================================
## A tampa tem 4 ESPAÇOS, cada um com um formato (quadrado, triângulo,
## círculo, losango). Embaixo há uma PILHA com as 4 tábuas, embaralhadas.
##
##   Papel A (encaixar): escolhe uma tábua na pilha (esquerda/direita + AÇÃO),
##                       leva até o espaço de MESMO formato e aperta AÇÃO.
##   Papel B (martelar): um marcador vai e volta numa barra; B aperta AÇÃO
##                       quando ele passa no prego. Cada tábua leva 2 pregos.
##
## Um depende do outro: o prego só aparece com a tábua encaixada, e a próxima
## tábua só entra depois que a anterior foi pregada.
##
## Este arquivo NÃO desenha, NÃO toca som e NÃO lê o teclado: a tela
## (minijogo_poco.gd) faz isso e reage aos sinais abaixo.

class_name RegraPoco
extends RefCounted

# ---------------------------------------------------------------- sinais
signal pegou_tabua              ## A tirou uma tábua da pilha
signal encaixou(texto: String)  ## A encaixou a tábua no espaço certo
signal martelou(no_prego: bool) ## B bateu o martelo (true = acertou o prego)
signal aviso(texto: String)     ## recado que não é erro ("espere a tábua")
signal errou(texto: String)     ## formato errado, martelo fora do prego...
signal terminou(texto: String)  ## os 4 espaços estão pregados

# ---------------------------------------------------------------- constantes
const FORMAS := ["quadrado", "triangulo", "circulo", "losango"]
const PREGOS_POR_TABUA := 2
const ZONA := 0.11             ## metade da largura da faixa do prego (a barra vai de 0 a 1)
const VEL_MARCADOR := 0.8      ## barras por segundo

# ---------------------------------------------------------------- estado
var vagas: Array = []          ## formato de cada espaço da tampa
var pilha: Array = []          ## formato de cada tábua da pilha ("" = já usada)
var pregos := {}               ## espaço -> pregos que ainda faltam (só espaços já encaixados)
var cursor_pilha := 0          ## qual tábua da pilha o papel A está olhando
var cursor_vaga := 0           ## qual espaço da tampa o papel A está olhando
var segurando := ""            ## formato da tábua na mão do papel A ("" = mão vazia)
var vaga_pregando := -1        ## espaço esperando o martelo (-1 = nenhum)
var marcador := 0.0            ## posição do marcador do martelo, de 0 a 1
var acabou := false

var _sentido := 1.0            ## 1 = marcador indo para a direita, -1 = para a esquerda
var _de_onde := 0              ## de que posição da pilha saiu a tábua da mão


## _init() é o "construtor": roda no RegraPoco.new(...).
## A tela passa as listas já embaralhadas; os testes passam numa ordem fixa.
func _init(ordem_vagas: Array = [], ordem_pilha: Array = []) -> void:
	vagas = ordem_vagas if not ordem_vagas.is_empty() else FORMAS.duplicate()
	pilha = ordem_pilha if not ordem_pilha.is_empty() else FORMAS.duplicate()


## Avança a regra em um quadro.
##  a_esq / a_dir / a_acao = o que o papel A apertou neste quadro
##  b_acao                 = o papel B apertou AÇÃO neste quadro?
func passo(delta: float, a_esq: bool, a_dir: bool, a_acao: bool, b_acao: bool) -> void:
	if acabou:
		return
	_papel_a(a_esq, a_dir, a_acao)
	_papel_b(delta, b_acao)


# ------------------------------------------------------------------ papel A
func _papel_a(esq: bool, dir: bool, acao: bool) -> void:
	if segurando == "":
		_escolher_na_pilha(esq, dir, acao)
	else:
		_escolher_espaco(esq, dir, acao)


## Mão vazia: o cursor anda pela pilha. "(x + 3) % 4" volta uma casa dando a
## volta (de 0 vai para 3); "(x + 1) % 4" avança (de 3 vai para 0).
func _escolher_na_pilha(esq: bool, dir: bool, acao: bool) -> void:
	if esq:
		cursor_pilha = (cursor_pilha + 3) % 4
	if dir:
		cursor_pilha = (cursor_pilha + 1) % 4
	if not acao:
		return
	if vaga_pregando >= 0:
		errou.emit("Espere o martelo!")
	elif pilha[cursor_pilha] == "":
		errou.emit("Essa já foi usada.")
	else:
		segurando = pilha[cursor_pilha]
		_de_onde = cursor_pilha
		pilha[cursor_pilha] = ""
		# o cursor dos espaços começa no primeiro espaço ainda vazio
		cursor_vaga = 0
		while pregos.has(cursor_vaga) and cursor_vaga < 3:
			cursor_vaga += 1
		pegou_tabua.emit()


## Tábua na mão: o cursor anda pelos espaços da tampa.
func _escolher_espaco(esq: bool, dir: bool, acao: bool) -> void:
	if esq:
		cursor_vaga = (cursor_vaga + 3) % 4
	if dir:
		cursor_vaga = (cursor_vaga + 1) % 4
	if not acao:
		return
	if pregos.has(cursor_vaga):
		errou.emit("Esse já está pronto.")
	elif vagas[cursor_vaga] == segurando:
		pregos[cursor_vaga] = PREGOS_POR_TABUA
		vaga_pregando = cursor_vaga
		segurando = ""
		# o cursor da pilha pula para a próxima tábua que ainda existe
		for k in 4:
			if pilha[(cursor_pilha + k) % 4] != "":
				cursor_pilha = (cursor_pilha + k) % 4
				break
		encaixou.emit("Encaixou! Agora o martelo.")
	else:
		# formato errado: a tábua volta para o lugar de onde saiu
		pilha[_de_onde] = segurando
		segurando = ""
		errou.emit("Formato errado!")


# ------------------------------------------------------------------ papel B
func _papel_b(delta: float, acao: bool) -> void:
	# O marcador vai e volta entre 0 e 1 (como um pêndulo).
	marcador += delta * VEL_MARCADOR * _sentido
	if marcador >= 1.0:
		marcador = 1.0
		_sentido = -1.0
	elif marcador <= 0.0:
		marcador = 0.0
		_sentido = 1.0
	if not acao:
		return
	if vaga_pregando < 0:
		aviso.emit("Espere a tábua!")
		return
	# absf = valor absoluto: distância do marcador até o meio (0,5), onde está o prego.
	if absf(marcador - 0.5) <= ZONA:
		pregos[vaga_pregando] -= 1
		martelou.emit(true)
		if pregos[vaga_pregando] <= 0:
			vaga_pregando = -1
			if pregos.size() == 4:
				acabou = true
				terminou.emit("Poço consertado!")
	else:
		martelou.emit(false)
		errou.emit("Errou o prego!")
