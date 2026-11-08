extends CasoDeTeste
## Testes das telas de fora da fazenda: menu, como jogar, créditos, quadrinhos,
## tela inicial e os textos para crianças.


func _abrir(caminho: String) -> Node:
	var cena: Node = (load(caminho) as PackedScene).instantiate()
	arvore.root.add_child(cena)
	return cena


func test_menu_nao_tem_mais_prefacio() -> void:
	var menu := _abrir("res://cenas/menu_principal.tscn")
	await arvore.process_frame
	afirmar_igual(menu.OPCOES, ["Jogar", "Como jogar", "Créditos"])
	menu.free()


func test_como_jogar_e_creditos_avisam_quando_fecham() -> void:
	for caminho in ["res://cenas/como_jogar.tscn", "res://cenas/creditos.tscn"]:
		var cena := _abrir(caminho)
		await arvore.process_frame
		afirmar(cena.has_signal("fechou"), caminho + " deveria ter o sinal fechou")
		cena.free()


func test_creditos_listam_a_equipe() -> void:
	var cena := _abrir("res://cenas/creditos.tscn")
	await arvore.process_frame
	var nomes: Array = cena.get_node("%Equipe").get_children().map(func(l): return l.text)
	afirmar_igual(nomes.size(), Textos.CREDITOS_EQUIPE.size())
	afirmar(nomes[0].begins_with(Textos.CREDITOS_EQUIPE[0][0]))
	cena.free()


func test_quadrinhos_tem_oito_quadros_e_vestem_os_personagens() -> void:
	var cena := _abrir("res://cenas/quadrinhos.tscn")
	await arvore.process_frame
	for i in 8:
		afirmar(cena.get_node_or_null("%%Quadro%d" % (i + 1)) != null, "falta o Quadro%d" % (i + 1))
	afirmar(cena.get_node("%NetoA").texture == Aparencia.neto(1, "frente"), "o neto 1 deveria vir da Aparencia")
	afirmar(cena.get_node("%NetoB").texture == Aparencia.neto(2, "frente"), "o neto 2 deveria vir da Aparencia")
	cena._saindo = true
	cena.free()


func test_quadrinhos_convite_so_segue_quando_os_dois_topam() -> void:
	var cena := _abrir("res://cenas/quadrinhos.tscn")
	await arvore.process_frame
	cena._atual = 6
	cena._mostrar_proximo()   # abre o quadro 8 (o convite)
	afirmar(cena._convite, "o quadro 8 deveria esperar os dois")
	cena.topar(1)
	cena.topar(1)              # apertar de novo não conta duas vezes
	afirmar(not cena._comemorando, "só um topou: ainda não pode seguir")
	afirmar_igual(cena.get_node("%Status1").text, "Topo!")
	afirmar_igual(cena.get_node("%Status2").text, "Topa?")
	cena.topar(2)
	afirmar(cena._comemorando, "os dois toparam: deveria comemorar")
	cena._saindo = true
	cena.free()


func test_quadrinhos_esc_pula_tudo() -> void:
	var cena := _abrir("res://cenas/quadrinhos.tscn")
	await arvore.process_frame
	Input.action_press("pausa")
	await arvore.process_frame
	Input.action_release("pausa")
	afirmar(cena._saindo, "Esc deveria pular os quadrinhos")
	cena.free()


func test_teclas_do_jogador_2_sao_setas_e_enter() -> void:
	var cena: TeclasJogador = (load("res://cenas/objetos/teclas_jogador.tscn") as PackedScene).instantiate()
	cena.numero = 2
	arvore.root.add_child(cena)
	await arvore.process_frame
	afirmar_igual((cena.get_node("%Acao") as Tecla).texto, "Enter")
	afirmar_igual((cena.get_node("%Cima") as Tecla).seta, "cima")
	afirmar_igual((cena.get_node("%Cima") as Tecla).texto, "")
	cena.free()


func test_tela_inicial_comeca_esperando_os_dois() -> void:
	var cena := _abrir("res://cenas/tela_inicial.tscn")
	await arvore.process_frame
	afirmar_igual(cena.get_node("%Status1").text, "Aperte Espaço!")
	afirmar_igual(cena.get_node("%Status2").text, "Aperte Enter!")
	cena.free()


func test_falas_da_vovo_sao_curtas() -> void:
	# regra do jogo: frases de até umas 8 palavras (aceitamos 9 de folga)
	var falas: Array = []
	for dia in Textos.FALAS_DO_DIA:
		falas.append_array(Textos.FALAS_DO_DIA[dia])
	falas.append_array(Textos.ELOGIOS.values())
	for fala in falas:
		for frase in (fala as String).replace("!", ".").replace("?", ".").split(".", false):
			var palavras := frase.strip_edges().split(" ", false).size()
			afirmar(palavras <= 9, "frase longa demais: \"%s\"" % frase.strip_edges())
