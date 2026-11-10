extends CasoDeTeste
## Testa a CENA do trator ligada à regra (a regra sozinha está em test_regra_trator.gd).

const CENA := preload("res://cenas/minijogos/minijogo_trator.tscn")


func _abrir(na: int, nb: int) -> MinijogoTrator:
	var mj: MinijogoTrator = CENA.instantiate()
	mj.na = na
	mj.nb = nb
	arvore.root.add_child(mj)
	return mj


func test_papeis_trocados_usam_o_neto_e_a_cor_certos() -> void:
	var mj := _abrir(2, 1)
	await arvore.process_frame
	afirmar(mj.get_node("%Motorista").texture == Aparencia.neto(2, "lado"), "motorista (papel A) deveria ser o jogador 2")
	afirmar(mj.get_node("%Empurrador").texture == Aparencia.neto(1, "lado"), "empurrador (papel B) deveria ser o jogador 1")
	afirmar_igual(mj.get_node("%RotuloA").get_theme_color("font_color"), Jogo.COR[2].lightened(0.35))
	mj.free()


func test_forca_move_o_trator_e_enche_a_barra() -> void:
	var mj := _abrir(1, 2)
	await arvore.process_frame
	var x0: float = mj.get_node("%Trator").position.x
	mj.regra.forca = 0.5
	mj._mostrar(0.0)
	afirmar_perto(mj.get_node("%Forca").value, 0.5)
	afirmar_perto(mj.get_node("%Trator").position.x - x0, 0.5 * mj.distancia_saida)
	mj.free()


func test_acelerando_mostra_fumaca_e_vrum() -> void:
	var mj := _abrir(1, 2)
	await arvore.process_frame
	mj.regra.passo(0.016, true, false)
	mj._mostrar(0.016)
	afirmar(mj.get_node("%Fumaca").emitting, "fumaça deveria sair")
	afirmar(mj.get_node("%Vrum").visible, "VRUM! deveria aparecer")
	mj.regra.passo(0.016, false, false)
	mj._mostrar(0.016)
	afirmar(not mj.get_node("%Vrum").visible, "VRUM! some ao soltar")
	mj.free()
