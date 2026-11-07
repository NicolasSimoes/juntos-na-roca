extends CasoDeTeste
## Testes da regra do trator (scripts/minijogos/regras/regra_trator.gd).

const DT := 1.0 / 60.0


func _gravar(regra: RegraTrator) -> Dictionary:
	var ev := {"acertou": [], "errou": [], "terminou": []}
	regra.acertou.connect(func(): ev["acertou"].append(true))
	regra.errou.connect(func(t: String): ev["errou"].append(t))
	regra.terminou.connect(func(t: String): ev["terminou"].append(t))
	return ev


func test_empurrar_com_acelerador_sobe_forca() -> void:
	var r := RegraTrator.new()
	var ev := _gravar(r)
	r.passo(DT, true, true)
	afirmar_perto(r.forca, RegraTrator.EMPURRAO - DT * RegraTrator.PERDA_POR_SEGUNDO)
	afirmar_igual(ev["acertou"].size(), 1)
	afirmar_igual(ev["errou"].size(), 0)


func test_empurrar_sem_acelerador_da_erro() -> void:
	var r := RegraTrator.new()
	var ev := _gravar(r)
	r.passo(DT, false, true)
	afirmar_igual(r.forca, 0.0)
	afirmar_igual(ev["errou"], [RegraTrator.TEXTO_DESLIGADO])


func test_sozinho_por_muito_tempo_da_erro() -> void:
	# Acelerando sem ninguém empurrar: depois de 1,2 s começa a "patinar" e,
	# a cada 2,2 s patinando, avisa. Em 3,5 s: 1,2 + 2,2 = 3,4 -> um aviso.
	var r := RegraTrator.new()
	var ev := _gravar(r)
	var t := 0.0
	while t < 3.5:
		r.passo(DT, true, false)
		t += DT
	afirmar_igual(ev["errou"], [RegraTrator.TEXTO_SOZINHO])
	afirmar(r.patinando, "deveria estar patinando")


func test_empurrao_recente_nao_patina() -> void:
	var r := RegraTrator.new()
	r.passo(DT, true, true)
	r.passo(0.5, true, false)
	afirmar(not r.patinando, "empurrou há 0,5 s: não está sozinho")


func test_forca_cai_sem_ninguem() -> void:
	var r := RegraTrator.new()
	r.forca = 0.5
	r.passo(1.0, false, false)
	afirmar_perto(r.forca, 0.5 - RegraTrator.PERDA_POR_SEGUNDO)
	r.passo(100.0, false, false)
	afirmar_igual(r.forca, 0.0)


func test_chega_a_um_e_termina() -> void:
	var r := RegraTrator.new()
	var ev := _gravar(r)
	for i in 30:
		r.passo(DT, true, true)
	afirmar_igual(r.forca, 1.0)
	afirmar_igual(ev["terminou"], [RegraTrator.TEXTO_FIM])
	r.passo(DT, true, true)
	afirmar_igual(ev["terminou"].size(), 1, "termina uma vez só")
