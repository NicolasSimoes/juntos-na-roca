extends CasoDeTeste
## Controle de ESP32: as linhas "J,X1,Y1,B1,X2,Y2,B2" viram as ações p1_ e p2_.

const Controle := preload("res://scripts/autoload/controle_esp32.gd")


func _novo() -> Node:
	var c: Node = Controle.new()
	arvore.root.add_child(c)
	return c


func _soltar(c: Node) -> void:
	c._soltar_tudo()
	Input.flush_buffered_events()
	c.queue_free()


func test_linha_invalida_e_ignorada() -> void:
	var c := _novo()
	afirmar(not c._aplicar(""), "vazia")
	afirmar(not c._aplicar("J,1,2,3"), "curta")
	afirmar(not c._aplicar("X,512,512,0,512,512,0"), "sem J")
	afirmar(not c._aplicar("J,512,abc,0,512,512,0"), "número quebrado")
	afirmar(c._aplicar("J,512,512,0,512,512,0"), "centro")
	_soltar(c)


func test_centro_nao_aperta_nada() -> void:
	var c := _novo()
	c._aplicar("J,512,512,0,512,512,0")
	for n in [1, 2]:
		for d in ["cima", "baixo", "esquerda", "direita", "acao"]:
			afirmar(not Input.is_action_pressed("p%d_%s" % [n, d]), "p%d_%s" % [n, d])
	_soltar(c)


func test_direcoes_e_botao() -> void:
	var c := _novo()
	# jogador 1 para a direita e para cima (Y alto = cima no Funduino), botão do 2 apertado
	c._aplicar("J,1023,1023,0,0,512,1")
	Input.flush_buffered_events()   # o Godot entrega os eventos no quadro seguinte
	afirmar(Input.is_action_pressed("p1_direita"), "p1 direita")
	afirmar(Input.is_action_pressed("p1_cima"), "p1 cima")
	afirmar(not Input.is_action_pressed("p1_baixo"), "p1 não baixo")
	afirmar(Input.is_action_pressed("p2_esquerda"), "p2 esquerda")
	afirmar(Input.is_action_pressed("p2_acao"), "p2 ação")
	afirmar(not Input.is_action_pressed("p1_acao"), "p1 sem ação")
	var v := Input.get_vector("p1_esquerda", "p1_direita", "p1_cima", "p1_baixo")
	afirmar(v.x > 0.5 and v.y < -0.5, "vetor do p1: %s" % v)
	# volta ao centro: tudo solto
	c._aplicar("J,512,512,0,512,512,0")
	Input.flush_buffered_events()
	afirmar(not Input.is_action_pressed("p1_direita"), "soltou direita")
	afirmar(not Input.is_action_pressed("p2_acao"), "soltou ação")
	_soltar(c)


func test_pouco_movimento_nao_conta() -> void:
	var c := _novo()
	c._aplicar("J,600,420,0,512,512,0")   # menos da metade do curso
	Input.flush_buffered_events()
	afirmar(not Input.is_action_pressed("p1_direita"), "direita fraca")
	afirmar(not Input.is_action_pressed("p1_baixo"), "baixo fraco")
	_soltar(c)
