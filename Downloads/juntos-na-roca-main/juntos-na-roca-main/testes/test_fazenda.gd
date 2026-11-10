extends CasoDeTeste
## A cena da fazenda (cenas/fazenda.tscn): o cenário bate com Lugares e o
## estado de cada dia vem de Jogo.

const CENA := preload("res://cenas/fazenda.tscn")


func test_cenario_bate_com_lugares() -> void:
	var f := CENA.instantiate()
	afirmar_igual(f.get_node("%Casa").position, Lugares.CASA, "casa")
	afirmar_igual(f.get_node("%Poco").position, Lugares.POCO, "poço")
	afirmar_igual(f.get_node("%Galpao").position, Lugares.GALPAO, "galpão")
	afirmar_igual(f.get_node("%Galinheiro").position, Lugares.GALINHEIRO, "galinheiro")
	afirmar_igual(f.get_node("%Porteira").position, Lugares.PORTEIRA, "porteira")
	afirmar_igual(f.get_node("%Vaca").position, Lugares.VACA, "vaca")
	afirmar_igual(f.get_node("%Cocho").position, Lugares.COCHO, "cocho")
	afirmar_igual(f.get_node("%Bebedouro").position, Lugares.BEBEDOURO, "bebedouro")
	afirmar_igual(f.get_node("%TratorAtolado").position, Lugares.TRATOR_ATOLADO, "trator atolado")
	f.free()


func test_pedras_ficam_dentro_do_campo() -> void:
	var f := CENA.instantiate()
	var campo := Rect2(Vector2(Lugares.CAMPO.position) * 16, Vector2(Lugares.CAMPO.size) * 16)
	var pedras: Array = f.get_node("%Pedras").get_children()
	afirmar_igual(pedras.size(), Lugares.PEDRAS.size(), "uma pedra por posição de Lugares.PEDRAS")
	for p in pedras:
		afirmar(campo.has_point(p.position), "%s fora do campo" % p.name)
		afirmar(p.is_in_group("pedras"), "%s precisa estar no grupo pedras" % p.name)
		afirmar(p.get_child(0) is CollisionShape2D, "a forma da %s tem que ser o primeiro filho" % p.name)
	f.free()


func test_chao_tem_lago_caminho_e_campo() -> void:
	var f := CENA.instantiate()
	var terreno: TileMapLayer = f.get_node("%Terreno")
	# um bloco de água, um de caminho e um de campo (do MAPA antigo)
	afirmar(terreno.get_cell_source_id(Vector2i(35, 19)) != -1, "lago")
	afirmar(terreno.get_cell_source_id(Vector2i(19, 10)) != -1, "caminho")
	afirmar(terreno.get_cell_source_id(Vector2i(5, 17)) != -1, "campo")
	afirmar_igual(terreno.get_cell_source_id(Vector2i(25, 3)), -1, "grama pura fica só na camada de baixo")
	afirmar_igual(f.get_node("%Campo").get_used_cells().size(), 0, "o campo começa sem arar")
	f.free()


func test_estado_de_cada_dia() -> void:
	for d in range(1, 6):
		Jogo.pular_para_dia(d)
		var f := CENA.instantiate()
		arvore.root.add_child(f)
		await arvore.process_frame
		var arado := Jogo.feita("arar")
		afirmar_igual(f.pedras.size(), 0 if arado else Lugares.PEDRAS.size(), "dia %d: pedras" % d)
		afirmar_igual(f._trator_atolado != null, not Jogo.feita("trator"), "dia %d: trator atolado" % d)
		afirmar_igual(f.get_node("%TratorParado").visible, Jogo.feita("trator"), "dia %d: trator parado" % d)
		afirmar_igual(f.get_node("%PilhaLenha").visible, Jogo.feita("lenha"), "dia %d: lenha" % d)
		var arada: bool = f.chao.get_cell_atlas_coords(Vector2i(3, 16)) == Vector2i(2, 0) \
				or f.chao.get_cell_atlas_coords(Vector2i(3, 16)) == Vector2i(5, 0)
		afirmar_igual(arada, arado, "dia %d: campo arado" % d)
		var esperadas := []
		for nome in Lugares.ZONAS:
			if not nome in Jogo.zonas_coloridas():
				esperadas.append(nome)
		var cinzas: Array = f._zonas.keys()
		cinzas.sort()
		esperadas.sort()
		afirmar_igual(cinzas, esperadas, "dia %d: zonas cinza" % d)
		f.queue_free()
		await arvore.process_frame
	Jogo.novo_jogo()


## Busca em largura numa grade de 4 px a partir de onde o jogador 1 começa,
## com o tamanho dos pés do neto (10 x 6). Todo lugar que uma tarefa usa
## tem que ser alcançável sem atravessar parede.
func test_lugares_das_tarefas_sao_alcancaveis() -> void:
	var f := CENA.instantiate()
	var paredes: Array[Rect2] = []
	for corpo in f.get_node("%Paredes").get_children():
		var forma: CollisionShape2D = corpo.get_child(0)
		var tam: Vector2 = (forma.shape as RectangleShape2D).size
		paredes.append(Rect2(corpo.position + forma.position - tam / 2.0, tam))
	f.free()
	var passo := 4
	var inicio := Vector2i(Lugares.INICIO_J1 / passo)
	var visto := {inicio: true}
	var fila: Array[Vector2i] = [inicio]
	while not fila.is_empty():
		var c: Vector2i = fila.pop_front()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var v: Vector2i = c + d
			if visto.has(v) or v.x < 0 or v.y < 0 or v.x > 640 / passo or v.y > 360 / passo:
				continue
			if _livre(Vector2(v * passo), paredes):
				visto[v] = true
				fila.append(v)
	var alvos := {
		"porta": Lugares.PORTA, "corda": Lugares.CORDA, "tabuas": Lugares.TABUAS,
		"saco de milho": Lugares.SACO_MILHO, "balde": Lugares.BALDE, "poço": Lugares.POCO_CENTRO + Vector2(0, 20),
		"tora": Lugares.TORA + Vector2(0, 8), "lenha": Lugares.DESTINO_LENHA.get_center(),
		"festa": Lugares.DESTINO_FESTA.get_center(), "jerimum": Lugares.JERIMUM_GIGANTE,
		"cercado": Lugares.CERCADO.get_center(), "cocho": Lugares.COCHO + Vector2(16, 20),
		"bebedouro": Lugares.BEBEDOURO + Vector2(16, 20), "pesca": Lugares.ESTACAO_PESCA,
	}
	for e in [Lugares.ESTACAO_POCO, Lugares.ESTACAO_LENHA, Lugares.ESTACAO_TRATOR, Lugares.ESTACAO_ARAR,
			Lugares.ESTACAO_HORTA, Lugares.ESTACAO_GALINHAS, Lugares.ESTACAO_ANIMAIS, Lugares.ESTACAO_PESCA]:
		alvos["estação %s (esq)" % e] = e + Vector2(-18, 0)
		alvos["estação %s (dir)" % e] = e + Vector2(18, 0)
	for nome in alvos:
		var p: Vector2 = alvos[nome]
		var achou := false
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				if visto.has(Vector2i(p / passo) + Vector2i(dx, dy)):
					achou = true
		afirmar(achou, "não dá para chegar em: %s %s" % [nome, p])


func _livre(p: Vector2, paredes: Array[Rect2]) -> bool:
	var pes := Rect2(p + Vector2(-5, -6), Vector2(10, 6))
	for r in paredes:
		if r.intersects(pes):
			return false
	return true
