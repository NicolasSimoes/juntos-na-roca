extends CasoDeTeste
## A narrativa dá contexto suficiente e continua curta para crianças de 10 anos.

const CARTAO := preload("res://cenas/objetos/cartao_missao.tscn")
const LIMITE := 9   # palavras por frase


func _palavras(texto: String) -> int:
	return texto.split(" ", false).size()


func test_toda_tarefa_tem_missao_com_porque_e_os_dois_papeis() -> void:
	for id in Jogo.NOMES:
		afirmar(Textos.MISSOES.has(id), "falta missão para '%s'" % id)
		var m: Dictionary = Textos.MISSOES.get(id, {})
		for campo in ["porque", "a", "b"]:
			afirmar(String(m.get(campo, "")) != "", "missão '%s' sem '%s'" % [id, campo])


func test_textos_da_vovo_sao_curtos() -> void:
	var frases: Array[String] = []
	for dia in Textos.FALAS_DO_DIA:
		for f in Textos.FALAS_DO_DIA[dia]:
			frases.append(f)
	for f in Textos.ELOGIOS.values():
		frases.append(f)
	for f in Textos.NOITE.values():
		frases.append(f)
	for m in Textos.MISSOES.values():
		for campo in ["porque", "a", "b", "depois"]:
			if m.has(campo):
				frases.append(m[campo])
	for f in frases:
		afirmar(_palavras(f) <= LIMITE, "frase longa demais (%d palavras): %s" % [_palavras(f), f])


func test_todo_dia_antes_da_festa_tem_fala_de_noite() -> void:
	for dia in range(1, Jogo.ULTIMO_DIA):
		afirmar(Textos.NOITE.has(dia), "falta a fala de noite do dia %d" % dia)


func test_cartao_mostra_o_papel_de_cada_jogador() -> void:
	var c: CartaoMissao = CARTAO.instantiate()
	arvore.root.add_child(c)
	c.abrir("trator", 2, 1, null, null)
	afirmar_igual(c.get_node("%NomeA").text, "Jogador 2", "papel A é do jogador 2")
	afirmar_igual(c.get_node("%VerboA").text, Textos.MISSOES["trator"]["a"])
	afirmar_igual(c.get_node("%Porque").text, Textos.MISSOES["trator"]["porque"])
	afirmar_igual(c.get_node("%StatusA").text, "Aperte Enter!", "o jogador 2 aperta Enter")
	afirmar(not c.get_node("%FaixaDepois").visible, "trator não tem segunda parte")
	c.free()


func test_cartao_so_fecha_quando_os_dois_confirmam() -> void:
	var c: CartaoMissao = CARTAO.instantiate()
	arvore.root.add_child(c)
	c.abrir("lenha", 1, 2, null, null)
	var fechou := [false]
	c.pronto.connect(func(): fechou[0] = true)
	c.confirmar(1)
	c.confirmar(1)   # apertar de novo não conta como o outro
	for i in 40:
		await arvore.process_frame
	afirmar(not fechou[0], "não pode fechar com um jogador só")
	c.confirmar(2)
	await arvore.create_timer(0.7).timeout
	afirmar(fechou[0], "fecha quando os dois confirmam")
	afirmar(c.get_node("%FaixaDepois").visible, "lenha tem segunda parte")
	c.free()
