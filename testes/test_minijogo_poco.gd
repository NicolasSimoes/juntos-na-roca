extends CasoDeTeste
## Testa a CENA do poço ligada à regra (a regra sozinha está em test_regra_poco.gd).

const CENA := preload("res://cenas/minijogos/minijogo_poco.tscn")


func _abrir(na: int, nb: int) -> MinijogoPoco:
	var mj: MinijogoPoco = CENA.instantiate()
	mj.na = na
	mj.nb = nb
	arvore.root.add_child(mj)
	return mj


func test_papeis_trocados_pintam_cursor_e_marcador() -> void:
	var mj := _abrir(2, 1)
	await arvore.process_frame
	afirmar_igual(mj.get_node("%CursorVaga").border_color, Jogo.COR[2], "cursor do papel A na cor do jogador 2")
	afirmar_igual(mj.get_node("%CursorPilha").border_color, Jogo.COR[2])
	afirmar_igual(mj.get_node("%Marcador").color, Jogo.COR[1], "marcador do papel B na cor do jogador 1")
	afirmar_igual(mj.get_node("%RotuloB").get_theme_color("font_color"), Jogo.COR[1].lightened(0.35))
	mj.free()


func test_espacos_mostram_as_formas_da_regra() -> void:
	var mj := _abrir(1, 2)
	await arvore.process_frame
	var vagas: Node2D = mj.get_node("%Vagas")
	for i in 4:
		var tabua := vagas.get_child(i).get_node("Tabua") as Sprite2D
		afirmar(tabua.texture == MinijogoPoco.TEXTURAS[mj.regra.vagas[i]], "espaço %d com a forma da regra" % i)
		afirmar_igual(tabua.modulate, MinijogoPoco.VAZIO, "começa vazio (escuro)")
	mj.free()


func test_encaixar_mostra_pregos_e_libera_martelo() -> void:
	var mj := _abrir(1, 2)
	await arvore.process_frame
	var r: RegraPoco = mj.regra
	r.cursor_pilha = r.pilha.find(r.vagas[0])
	r.passo(0.0, false, false, true, false)       # pega a tábua certa
	mj._mostrar()
	afirmar(mj.get_node("%TabuaNaMao").visible, "tábua na mão aparece")
	afirmar(mj.get_node("%CursorVaga").visible)
	r.passo(0.0, false, false, true, false)       # encaixa no espaço 0
	mj._mostrar()
	var vaga := mj.get_node("%Vagas").get_child(0)
	afirmar_igual((vaga.get_node("Tabua") as Sprite2D).modulate, Color.WHITE, "encaixada fica com a cor da madeira")
	afirmar((vaga.get_node("Prego1") as Sprite2D).visible, "pregos aparecem")
	afirmar(mj.get_node("%Espere").visible, "papel A espera o martelo")
	afirmar_igual(mj.get_node("%Zona").color, Color(0.4, 0.8, 0.35), "faixa do prego fica verde")
	mj.free()


func test_poco_enche_com_as_tabuas_prontas() -> void:
	var mj := _abrir(1, 2)
	await arvore.process_frame
	mj.regra.pregos = {0: 0, 1: 0}
	mj._mostrar()
	afirmar(mj.get_node("%Poco").texture == MinijogoPoco.POCOS[2], "2 tábuas prontas = poço no estágio 2")
	mj.free()
