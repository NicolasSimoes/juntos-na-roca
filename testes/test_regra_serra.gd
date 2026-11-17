extends CasoDeTeste
## Testes da regra da serra (scripts/minijogos/regras/regra_serra.gd).

const DT := 1.0 / 60.0


func _gravar(regra: RegraSerra) -> Dictionary:
	var ev := {"acertou": [], "errou": [], "terminou": []}
	regra.acertou.connect(func(): ev["acertou"].append(true))
	regra.errou.connect(func(t: String): ev["errou"].append(t))
	regra.terminou.connect(func(t: String): ev["terminou"].append(t))
	return ev


func test_alternar_conta_corte() -> void:
	var r := RegraSerra.new()
	var ev := _gravar(r)
	r.passo(DT, true, false)
	afirmar_igual(r.cortes, 1)
	afirmar_igual(r.vez, 1)
	afirmar_igual(r.lado, -1.0)
	r.passo(DT, false, true)
	afirmar_igual(r.cortes, 2)
	afirmar_igual(r.vez, 0)
	afirmar_igual(r.lado, 1.0)
	afirmar_igual(ev["acertou"].size(), 2)
	afirmar_igual(ev["errou"].size(), 0)


func test_fora_da_vez_trava() -> void:
	var r := RegraSerra.new()
	var ev := _gravar(r)
	r.passo(DT, false, true)
	afirmar_igual(r.cortes, 0)
	afirmar_perto(r.travada, RegraSerra.TEMPO_TRAVADA)
	afirmar_igual(ev["errou"], ["Travou! Um de cada vez."])


func test_aperto_durante_travada_e_ignorado() -> void:
	var r := RegraSerra.new()
	var ev := _gravar(r)
	r.passo(DT, false, true)
	r.passo(DT, true, false)
	afirmar_igual(r.cortes, 0)
	afirmar_igual(r.vez, 0)
	afirmar_igual(ev["errou"].size(), 1)


func test_travada_acaba_depois_de_07s() -> void:
	var r := RegraSerra.new()
	r.passo(DT, false, true)
	r.passo(0.69, false, false)
	afirmar(r.travada > 0.0, "ainda deveria estar travada")
	r.passo(0.02, true, false)
	afirmar_igual(r.travada, 0.0)
	afirmar_igual(r.cortes, 1)


func test_os_dois_no_mesmo_quadro_contam_dois() -> void:
	var r := RegraSerra.new()
	var ev := _gravar(r)
	r.passo(DT, true, true)
	afirmar_igual(r.cortes, 2)
	afirmar_igual(r.vez, 0)
	afirmar_igual(ev["errou"].size(), 0)


func test_doze_cortes_termina() -> void:
	var r := RegraSerra.new()
	var ev := _gravar(r)
	for i in RegraSerra.CORTES:
		r.passo(DT, i % 2 == 0, i % 2 == 1)
	afirmar_igual(r.cortes, 12)
	afirmar_igual(ev["terminou"], ["O tronco está serrado!"])
	r.passo(DT, true, false)
	r.passo(DT, false, true)
	afirmar_igual(r.cortes, 12)
	afirmar_igual(ev["terminou"].size(), 1)
	afirmar_igual(ev["errou"].size(), 0)
