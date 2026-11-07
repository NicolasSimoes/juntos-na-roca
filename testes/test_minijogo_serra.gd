extends CasoDeTeste
## Testa a CENA da serra ligada à regra (não a regra sozinha: isso está em test_regra_serra.gd).

const CENA := preload("res://cenas/minijogos/minijogo_serra.tscn")


func _abrir(na: int, nb: int) -> MinijogoSerra:
	var mj: MinijogoSerra = CENA.instantiate()
	mj.na = na
	mj.nb = nb
	arvore.root.add_child(mj)
	return mj


func test_papeis_trocados_usam_o_neto_e_a_cor_certos() -> void:
	var mj := _abrir(2, 1)
	await arvore.process_frame
	afirmar(mj.get_node("%NetoA").texture == Aparencia.neto(2, "lado"), "neto A deveria ser o jogador 2")
	afirmar(mj.get_node("%NetoB").texture == Aparencia.neto(1, "lado"), "neto B deveria ser o jogador 1")
	afirmar_igual(mj.get_node("%SetaVez").modulate, Jogo.COR[2].lightened(0.2), "a seta começa na cor de quem tem a vez (papel A = jogador 2)")
	mj.free()


func test_puxada_atualiza_barra_e_contador() -> void:
	var mj := _abrir(1, 2)
	await arvore.process_frame
	mj.regra.passo(0.016, true, false)
	mj._mostrar(0.016)
	afirmar_igual(mj.get_node("%Progresso").value, 1.0)
	afirmar_igual(mj.get_node("%Contador").text, "1 de 12 puxadas")
	afirmar(mj.get_node("%Corte").size.y > 0.0, "o corte deveria ter começado")
	mj.free()
