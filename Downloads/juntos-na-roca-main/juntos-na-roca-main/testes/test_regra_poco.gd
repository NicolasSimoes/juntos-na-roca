extends CasoDeTeste
## Testes da regra do poço (scripts/minijogos/regras/regra_poco.gd).
## Ordem fixa nos testes: espaços da tampa e pilha na MESMA ordem,
## então a tábua da posição i da pilha encaixa no espaço i.

const DT := 1.0 / 60.0
const ORDEM := ["quadrado", "triangulo", "circulo", "losango"]


func _nova() -> RegraPoco:
	return RegraPoco.new(ORDEM.duplicate(), ORDEM.duplicate())


func _gravar(r: RegraPoco) -> Dictionary:
	var ev := {"pegou": [], "encaixou": [], "martelou": [], "aviso": [], "errou": [], "terminou": []}
	r.pegou_tabua.connect(func(): ev["pegou"].append(true))
	r.encaixou.connect(func(t: String): ev["encaixou"].append(t))
	r.martelou.connect(func(no_prego: bool): ev["martelou"].append(no_prego))
	r.aviso.connect(func(t: String): ev["aviso"].append(t))
	r.errou.connect(func(t: String): ev["errou"].append(t))
	r.terminou.connect(func(t: String): ev["terminou"].append(t))
	return ev


## Papel A: pega a tábua do cursor da pilha (já está no lugar certo) e
## anda o cursor dos espaços até "alvo", depois aperta.
func _encaixar_em(r: RegraPoco, alvo: int) -> void:
	r.passo(0.0, false, false, true, false)          # pega
	while r.cursor_vaga != alvo:
		r.passo(0.0, false, true, false, false)      # anda para a direita
	r.passo(0.0, false, false, true, false)          # encaixa


## Papel B: espera o marcador entrar na zona do prego e bate.
func _pregar(r: RegraPoco) -> void:
	var guarda := 0
	while absf(r.marcador - 0.5) > RegraPoco.ZONA and guarda < 1000:
		r.passo(DT, false, false, false, false)
		guarda += 1
	r.passo(0.0, false, false, false, true)


func test_encaixe_certo_libera_martelo() -> void:
	var r := _nova()
	var ev := _gravar(r)
	_encaixar_em(r, 0)
	afirmar_igual(r.vaga_pregando, 0)
	afirmar_igual(r.pregos.get(0), RegraPoco.PREGOS_POR_TABUA)
	afirmar_igual(r.segurando, "")
	afirmar_igual(r.pilha[0], "")
	afirmar_igual(ev["pegou"].size(), 1)
	afirmar_igual(ev["encaixou"].size(), 1)
	afirmar_igual(r.cursor_pilha, 1, "o cursor pula para a próxima tábua da pilha")


func test_formato_errado_devolve_para_pilha() -> void:
	var r := _nova()
	var ev := _gravar(r)
	r.passo(0.0, false, false, true, false)          # pega o quadrado
	r.passo(0.0, false, true, false, false)          # cursor no espaço 1 (triângulo)
	r.passo(0.0, false, false, true, false)          # tenta encaixar
	afirmar_igual(r.segurando, "")
	afirmar_igual(r.pilha[0], "quadrado", "a tábua volta para o mesmo lugar")
	afirmar(not r.pregos.has(1))
	afirmar_igual(ev["errou"].size(), 1)


func test_cursor_da_pilha_da_a_volta() -> void:
	var r := _nova()
	r.passo(0.0, true, false, false, false)
	afirmar_igual(r.cursor_pilha, 3)
	r.passo(0.0, false, true, false, false)
	afirmar_igual(r.cursor_pilha, 0)


func test_nao_pega_tabua_enquanto_prega() -> void:
	var r := _nova()
	var ev := _gravar(r)
	_encaixar_em(r, 0)
	r.passo(0.0, false, false, true, false)
	afirmar_igual(r.segurando, "")
	afirmar_igual(ev["errou"].size(), 1)


func test_tabua_usada_nao_pode_ser_pega() -> void:
	var r := _nova()
	var ev := _gravar(r)
	_encaixar_em(r, 0)
	_pregar(r)
	_pregar(r)
	r.passo(0.0, true, false, false, false)          # volta o cursor para a posição 0 (vazia)
	r.passo(0.0, false, false, true, false)
	afirmar_igual(r.segurando, "")
	afirmar_igual(ev["errou"].size(), 1)


func test_martelo_sem_tabua_so_avisa() -> void:
	var r := _nova()
	var ev := _gravar(r)
	r.passo(0.0, false, false, false, true)
	afirmar_igual(ev["aviso"].size(), 1)
	afirmar_igual(ev["errou"].size(), 0)
	afirmar_igual(ev["martelou"].size(), 0)


func test_martelo_fora_da_zona_erra() -> void:
	var r := _nova()
	var ev := _gravar(r)
	_encaixar_em(r, 0)
	afirmar(absf(r.marcador - 0.5) > RegraPoco.ZONA, "o marcador começa fora da zona")
	r.passo(0.0, false, false, false, true)
	afirmar_igual(r.pregos[0], 2)
	afirmar_igual(ev["martelou"], [false])
	afirmar_igual(ev["errou"].size(), 1)


func test_marcador_vai_e_volta() -> void:
	var r := _nova()
	r.passo(1.0, false, false, false, false)
	afirmar_perto(r.marcador, 0.8)
	r.passo(0.5, false, false, false, false)
	afirmar_igual(r.marcador, 1.0)
	r.passo(0.5, false, false, false, false)
	afirmar_perto(r.marcador, 0.6)


func test_dois_pregos_liberam_proxima_tabua() -> void:
	var r := _nova()
	var ev := _gravar(r)
	_encaixar_em(r, 0)
	_pregar(r)
	afirmar_igual(r.pregos[0], 1)
	afirmar_igual(r.vaga_pregando, 0)
	_pregar(r)
	afirmar_igual(r.pregos[0], 0)
	afirmar_igual(r.vaga_pregando, -1)
	afirmar_igual(ev["martelou"], [true, true])
	r.passo(0.0, false, false, true, false)
	afirmar_igual(r.segurando, "triangulo")


func test_quatro_vagas_terminam() -> void:
	var r := _nova()
	var ev := _gravar(r)
	for i in 4:
		_encaixar_em(r, i)
		_pregar(r)
		_pregar(r)
	afirmar_igual(ev["terminou"].size(), 1)
	afirmar_igual(ev["errou"].size(), 0)
	r.passo(0.0, false, false, true, true)
	afirmar_igual(ev["terminou"].size(), 1)
