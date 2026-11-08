extends CasoDeTeste
## Testa a CENA da pesca ligada à regra (a regra sozinha está em test_regra_pesca.gd).

const CENA := preload("res://cenas/minijogos/minijogo_pesca.tscn")


func _abrir(na: int, nb: int) -> MinijogoPesca:
	var mj: MinijogoPesca = CENA.instantiate()
	mj.na = na
	mj.nb = nb
	arvore.root.add_child(mj)
	return mj


func test_papeis_trocados_usam_o_neto_e_a_cor_certos() -> void:
	var mj := _abrir(2, 1)
	await arvore.process_frame
	afirmar(mj.get_node("%Pescador").texture == Aparencia.neto(2, "lado"), "o pescador (papel A) deveria ser o jogador 2")
	afirmar(mj.get_node("%Puqueiro").texture == Aparencia.neto(1, "lado"), "quem tem o puçá (papel B) deveria ser o jogador 1")
	afirmar_igual(mj.get_node("%RotuloA").get_theme_color("font_color"), Jogo.COR[2].lightened(0.35))
	mj.free()


func test_cada_estado_mostra_o_seu_objeto() -> void:
	var mj := _abrir(1, 2)
	await arvore.process_frame
	afirmar(mj.get_node("%Boia").visible, "esperando: boia")
	afirmar(not mj.get_node("%Distancia").visible)
	mj.regra.estado = "fisgado"
	mj._mostrar()
	afirmar(mj.get_node("%Sombra").visible, "fisgado: sombra")
	afirmar(mj.get_node("%Distancia").visible, "fisgado: barra de distância")
	afirmar(not mj.get_node("%Boia").visible)
	mj.regra.estado = "pulando"
	mj._mostrar()
	afirmar(mj.get_node("%Peixe").visible, "pulando: peixe")
	afirmar(not mj.get_node("%Sombra").visible)
	mj.free()


func test_puca_e_neto_andam_juntos() -> void:
	var mj := _abrir(1, 2)
	await arvore.process_frame
	var puca: Sprite2D = mj.get_node("%Puca")
	var antes := puca.position.x
	mj.regra.puca_x += 50.0
	mj._mostrar()
	afirmar_perto(puca.position.x, antes + 50.0)
	afirmar_perto(mj.get_node("%Puqueiro").position.x, puca.position.x - mj.neto_atras_do_puca)
	mj.free()


func test_placar_acende_os_peixes_pegos() -> void:
	var mj := _abrir(1, 2)
	await arvore.process_frame
	mj.regra.pegos = 2
	mj._mostrar()
	var placar: Node2D = mj.get_node("%Placar")
	afirmar_igual(placar.get_child(1).modulate, Color.WHITE)
	afirmar(placar.get_child(2).modulate != Color.WHITE, "o 3º peixe ainda não foi pego")
	mj.free()
