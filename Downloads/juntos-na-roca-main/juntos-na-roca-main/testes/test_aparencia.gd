extends CasoDeTeste
## Personagens do pacote: cada neto e a Vovó têm imagem e animações próprias.


func test_cada_neto_tem_a_sua_imagem() -> void:
	var a := Aparencia.neto(1, "frente")
	var b := Aparencia.neto(2, "frente")
	afirmar(a != b, "netos diferentes")
	afirmar_igual(a.get_size(), Vector2(16, 20))
	afirmar(Aparencia.neto(1, "lado") == Aparencia.neto(1, "lado"), "o cache devolve a mesma imagem")
	afirmar(Aparencia.vovo() != a, "Vovó tem a sua imagem")


func test_todas_as_poses_existem() -> void:
	for pose in Aparencia.POSES:
		afirmar(Aparencia.neto(1, pose) != null, pose)


func test_animacoes_que_o_jogador_usa() -> void:
	for n in [1, 2]:
		var q := Aparencia.quadros_neto(n)
		for nome in ["parado_baixo", "parado_cima", "parado_lado", "anda_baixo", "anda_cima", "anda_lado", "comemora"]:
			afirmar(q.has_animation(nome), "neto %d: %s" % [n, nome])
	afirmar(Aparencia.quadros_vovo().has_animation("parado_baixo"), "Vovó")


func test_ajustar_pes_poe_origem_nos_pes() -> void:
	var s := Sprite2D.new()
	s.texture = Aparencia.neto(1)
	Aparencia.ajustar_pes(s)
	afirmar_igual(s.offset, Vector2(-8, -20))
	s.free()
