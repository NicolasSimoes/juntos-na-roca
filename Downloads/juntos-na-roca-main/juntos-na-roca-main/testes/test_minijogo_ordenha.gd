extends CasoDeTeste
## Testa a CENA da ordenha ligada à regra (a regra sozinha está em test_regra_ordenha.gd).

const CENA := preload("res://cenas/minijogos/minijogo_ordenha.tscn")


func _abrir(na: int, nb: int) -> MinijogoOrdenha:
	var mj: MinijogoOrdenha = CENA.instantiate()
	mj.na = na
	mj.nb = nb
	arvore.root.add_child(mj)
	return mj


func test_papeis_trocados_usam_o_neto_e_a_cor_certos() -> void:
	var mj := _abrir(2, 1)
	await arvore.process_frame
	afirmar(mj.get_node("%NetoA").texture == Aparencia.neto(2, "lado"), "neto do capim (papel A) deveria ser o jogador 2")
	afirmar(mj.get_node("%NetoB").texture == Aparencia.neto(1, "lado"), "neto do balde (papel B) deveria ser o jogador 1")
	afirmar(mj.get_node("%NetoA").flip_h, "neto do capim olha para a vaca")
	afirmar_igual(mj.get_node("%RotuloB").get_theme_color("font_color"), Jogo.COR[1].lightened(0.35))
	mj.free()


func test_capim_aparece_so_segurando() -> void:
	var mj := _abrir(1, 2)
	await arvore.process_frame
	afirmar(not mj.get_node("%Capim").visible, "sem segurar, sem capim")
	mj.regra.passo(0.016, true, false)
	mj._mostrar()
	afirmar(mj.get_node("%Capim").visible, "segurando, o capim aparece")
	mj.free()


func test_leite_sobe_no_balde_e_na_barra() -> void:
	var mj := _abrir(1, 2)
	await arvore.process_frame
	var leite: ColorRect = mj.get_node("%LeiteNoBalde")
	var fundo := leite.position.y + leite.size.y
	afirmar_igual(leite.size.y, 0.0, "balde começa vazio")
	mj.regra.leite = 0.5
	mj._mostrar()
	afirmar_perto(leite.size.y, mj.altura_leite * 0.5)
	afirmar_perto(leite.position.y + leite.size.y, fundo, 0.001, "o leite cresce a partir do fundo")
	afirmar_perto(mj.get_node("%Leite").value, 0.5)
	mj.free()
