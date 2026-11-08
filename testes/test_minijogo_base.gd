extends CasoDeTeste
## Testes da cena base dos minijogos (cenas/minijogos/minijogo_base.tscn).

const CENA := "res://cenas/minijogos/minijogo_base.tscn"


func test_rotulos_usam_a_cor_de_cada_papel() -> void:
	var mj: Minijogo = load(CENA).instantiate()
	mj.na = 2
	mj.nb = 1
	mj.texto_a = "x"
	mj.texto_b = "y"
	arvore.root.add_child(mj)
	await arvore.process_frame
	var a: Label = mj.get_node("%RotuloA")
	var b: Label = mj.get_node("%RotuloB")
	afirmar_igual(a.text, "Jogador 2: x")
	afirmar_igual(a.get_theme_color("font_color"), Jogo.COR[2].lightened(0.35), "cor do papel A")
	afirmar_igual(b.text, "Jogador 1: y")
	afirmar_igual(b.get_theme_color("font_color"), Jogo.COR[1].lightened(0.35), "cor do papel B")
	mj.free()


func test_pausa_para_o_minijogo() -> void:
	var mj: Minijogo = load(CENA).instantiate()
	afirmar_igual(mj.process_mode, Node.PROCESS_MODE_INHERIT)
	mj.free()
