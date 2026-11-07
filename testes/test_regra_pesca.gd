extends CasoDeTeste
## Testes da regra da pesca (scripts/minijogos/regras/regra_pesca.gd).

const DT := 1.0 / 60.0


func _gravar(r: RegraPesca) -> Dictionary:
	var ev := {"fisgou": [], "pulou": [], "puxou": [], "pegou": [], "errou": [], "terminou": []}
	r.fisgou.connect(func(t: String): ev["fisgou"].append(t))
	r.pulou.connect(func(t: String): ev["pulou"].append(t))
	r.puxou.connect(func(): ev["puxou"].append(true))
	r.pegou.connect(func(t: String): ev["pegou"].append(t))
	r.errou.connect(func(t: String): ev["errou"].append(t))
	r.terminou.connect(func(t: String): ev["terminou"].append(t))
	return ev


## Leva a regra até o peixe pular (estado "pulando").
func _ate_pular(r: RegraPesca) -> void:
	var guarda := 0
	while r.estado != "pulando" and guarda < 2000:
		r.passo(DT, r.estado == "fisgado", 0.0, false)
		guarda += 1


func test_fisga_depois_da_espera() -> void:
	var r := RegraPesca.new()
	var ev := _gravar(r)
	r.passo(1.4, false, 0.0, false)
	afirmar_igual(r.estado, "esperando")
	r.passo(0.2, false, 0.0, false)
	afirmar_igual(r.estado, "fisgado")
	afirmar_igual(ev["fisgou"].size(), 1)


func test_puxar_aproxima_e_linha_volta_sozinha() -> void:
	var r := RegraPesca.new()
	r.passo(1.6, false, 0.0, false)
	r.passo(DT, true, 0.0, false)
	afirmar_perto(r.dist, 1.0 - 0.07 + DT * 0.06, 0.0001)
	var antes := r.dist
	r.passo(1.0, false, 0.0, false)
	afirmar_perto(r.dist, antes + 0.06, 0.0001, "a linha volta 0,06 por segundo")


func test_puxar_ate_pular() -> void:
	var r := RegraPesca.new()
	var ev := _gravar(r)
	_ate_pular(r)
	afirmar_igual(r.estado, "pulando")
	afirmar(r.dist <= 0.22, "pula com a distância em 0,22 ou menos")
	afirmar_igual(ev["pulou"].size(), 1)
	afirmar(ev["puxou"].size() > 0, "cada puxada avisa")


func test_puca_anda_e_fica_no_pier() -> void:
	var r := RegraPesca.new()
	r.passo(0.1, false, 1.0, false)
	afirmar_perto(r.puca_x, 300.0 + 17.0, 0.001)
	r.passo(10.0, false, 1.0, false)
	afirmar_igual(r.puca_x, 540.0)
	r.passo(10.0, false, -1.0, false)
	afirmar_igual(r.puca_x, 160.0)


func test_pegar_com_puca_alinhado() -> void:
	var r := RegraPesca.new()
	var ev := _gravar(r)
	_ate_pular(r)
	r.puca_x = r.peixe_x
	r.passo(0.0, false, 0.0, true)
	afirmar_igual(r.pegos, 1)
	afirmar_igual(r.estado, "esperando")
	afirmar_perto(r.espera, 1.2)
	afirmar_igual(r.dist, 1.0)
	afirmar_igual(ev["pegou"].size(), 1)
	afirmar(ev["pegou"][0] != "", "avisa quantos faltam")


func test_puca_longe_erra_e_volta_para_045() -> void:
	var r := RegraPesca.new()
	var ev := _gravar(r)
	_ate_pular(r)
	r.puca_x = r.peixe_x + 40.0
	r.passo(0.0, false, 0.0, true)
	afirmar_igual(r.pegos, 0)
	afirmar_igual(r.estado, "fisgado")
	afirmar_igual(r.dist, 0.45)
	afirmar_igual(ev["errou"].size(), 1)


func test_janela_do_pulo_expira() -> void:
	var r := RegraPesca.new()
	var ev := _gravar(r)
	_ate_pular(r)
	r.passo(1.1, false, 0.0, false)
	afirmar_igual(r.estado, "pulando")
	r.passo(0.2, false, 0.0, false)
	afirmar_igual(r.estado, "fisgado")
	afirmar_igual(r.dist, 0.45)
	afirmar_igual(ev["errou"].size(), 1)


func test_tres_peixes_termina() -> void:
	var r := RegraPesca.new()
	var ev := _gravar(r)
	for i in RegraPesca.META:
		_ate_pular(r)
		r.puca_x = r.peixe_x
		r.passo(0.0, false, 0.0, true)
	afirmar_igual(r.pegos, 3)
	afirmar_igual(ev["terminou"].size(), 1)
	afirmar_igual(ev["pegou"][2], "", "no último peixe quem fala é o terminou")
	r.passo(5.0, true, 0.0, true)
	afirmar_igual(r.pegos, 3)
	afirmar_igual(ev["terminou"].size(), 1)
