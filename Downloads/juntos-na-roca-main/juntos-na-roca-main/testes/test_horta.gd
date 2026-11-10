extends CasoDeTeste
## A horta: covas, tipos por fileira e as imagens das plantas do pacote.


func test_tipo_por_fileira() -> void:
	var h := Horta.new()
	afirmar_igual(h.tipo(0), "milho")
	afirmar_igual(h.tipo(3), "milho")
	afirmar_igual(h.tipo(4), "feijao")
	afirmar_igual(h.tipo(11), "jerimum")
	h.free()


func test_cova_perto_acha_a_mais_proxima_dentro_de_13px() -> void:
	var h := Horta.new()
	afirmar_igual(h.cova_perto(h.centro(5) + Vector2(0, 4)), 5)
	afirmar_igual(h.cova_perto(h.centro(5) + Vector2(0, 20)), -1)
	h.free()


func test_imagens_de_todas_as_fases() -> void:
	afirmar(load("res://assets/recortes/mapa/semente.tres") != null, "semente")
	for t in Jogo.TIPOS_HORTA:
		for fase in [2, 3, 4]:
			afirmar(load("res://assets/recortes/mapa/%s_fase%d.tres" % [t, fase]) != null, "%s fase %d" % [t, fase])
