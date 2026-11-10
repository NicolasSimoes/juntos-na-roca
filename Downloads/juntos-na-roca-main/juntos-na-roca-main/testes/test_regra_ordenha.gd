extends CasoDeTeste
## Testes da regra da ordenha (scripts/minijogos/regras/regra_ordenha.gd).

const DT := 1.0 / 60.0


func _gravar(regra: RegraOrdenha) -> Dictionary:
	var ev := {"acertou": [], "errou": [], "terminou": []}
	regra.acertou.connect(func(): ev["acertou"].append(true))
	regra.errou.connect(func(t: String): ev["errou"].append(t))
	regra.terminou.connect(func(t: String): ev["terminou"].append(t))
	return ev


func test_sem_capim_da_coice() -> void:
	var r := RegraOrdenha.new()
	var ev := _gravar(r)
	r.passo(DT, false, true)
	afirmar_igual(r.leite, 0.0)
	afirmar_perto(r.coice, RegraOrdenha.TEMPO_COICE)
	afirmar_igual(ev["errou"], [RegraOrdenha.TEXTO_SEM_CAPIM])


func test_com_capim_tira_leite() -> void:
	var r := RegraOrdenha.new()
	var ev := _gravar(r)
	r.passo(0.25, true, false)        # 0,25 s x 3/s = 0,75 de calma (> 0,6)
	afirmar_perto(r.calma, 0.75)
	r.passo(DT, true, true)
	afirmar_perto(r.leite, RegraOrdenha.LEITE_POR_APERTO)
	afirmar_igual(ev["acertou"].size(), 1)
	afirmar_igual(ev["errou"].size(), 0)


func test_calma_no_limite_ainda_da_coice() -> void:
	var r := RegraOrdenha.new()
	r.calma = 0.6
	var ev := _gravar(r)
	r.passo(0.0, false, true)
	afirmar_igual(ev["errou"].size(), 1, "precisa de calma MAIOR que 0,6")


func test_calma_cai_ao_soltar() -> void:
	var r := RegraOrdenha.new()
	r.passo(1.0, true, false)
	afirmar_igual(r.calma, 1.0)
	r.passo(0.2, false, false)
	afirmar_perto(r.calma, 1.0 - 0.2 * 1.5)


func test_coice_passa_com_o_tempo() -> void:
	var r := RegraOrdenha.new()
	r.passo(DT, false, true)
	r.passo(1.0, false, false)
	afirmar_igual(r.coice, 0.0)


func test_balde_cheio_termina() -> void:
	var r := RegraOrdenha.new()
	var ev := _gravar(r)
	r.passo(1.0, true, false)
	for i in 20:
		r.passo(DT, true, true)
	afirmar_igual(r.leite, 1.0)
	afirmar_igual(ev["terminou"], [RegraOrdenha.TEXTO_FIM])
	r.passo(DT, true, true)
	afirmar_igual(ev["terminou"].size(), 1, "termina uma vez só")
