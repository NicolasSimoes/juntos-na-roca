extends SceneTree
## Fotografa as telas de fora da fazenda: menu, como jogar, créditos, prefácio,
## quadrinhos e tela inicial. Precisa de janela (não use --headless):
##   godot --path . -s ferramentas/capturar_menus.gd
## Salva em capturas/menus_<nome>.png (a pasta está no .gitignore).


func _initialize() -> void:
	_rodar.call_deferred()


func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png("res://capturas/menus_%s.png" % nome)
	print("capturado: ", nome)


func _esperar(quadros: int) -> void:
	for i in quadros:
		await process_frame


func _abrir(caminho: String) -> Node:
	var cena: Node = (load(caminho) as PackedScene).instantiate()
	root.add_child(cena)
	return cena


func _fechar(cena: Node) -> void:
	cena.queue_free()
	await process_frame


func _rodar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://capturas"))
	# menu: título e depois a caixa aberta
	var menu := _abrir("res://cenas/menu_principal.tscn")
	await _esperar(90)
	await _foto("titulo")
	menu._abrir_menu()
	await _esperar(40)
	await _foto("menu")
	menu._abrir_painel(menu.PAINEIS["Como jogar"])
	await _esperar(40)
	await _foto("como_jogar")
	menu._fechar_painel()
	menu._abrir_painel(menu.PAINEIS["Créditos"])
	await _esperar(40)
	menu._painel.get_node("%Rolo").position.y = 40
	await _esperar(3)
	await _foto("creditos_1")
	menu._painel.get_node("%Rolo").position.y = -260
	await _esperar(3)
	await _foto("creditos_2")
	await _fechar(menu)

	# prefácio em alguns momentos
	var pref := _abrir("res://cenas/prefacio.tscn")
	await _esperar(5)
	for t in [3.0, 9.0, 20.0, 35.0, 50.0, 67.5]:
		pref._tempo = t
		await _esperar(4)
		await _foto("prefacio_%02d" % int(t))
	pref._saindo = true
	await _fechar(pref)

	# quadrinhos: os 8 quadros, um de cada vez, e o convite antes/depois de topar
	var hq := _abrir("res://cenas/quadrinhos.tscn")
	await _esperar(40)
	await _foto("quadrinhos_1")
	for i in range(2, 9):
		hq._mostrar_proximo()
		await _esperar(70 if i == 5 else 40)
		await _foto("quadrinhos_%d" % i)
	hq.topar(1)
	await _esperar(30)
	await _foto("quadrinhos_8_um_topou")
	hq.topar(2)
	await _esperar(50)
	await _foto("quadrinhos_8_os_dois")
	hq._saindo = true
	await _fechar(hq)

	var inicio := _abrir("res://cenas/tela_inicial.tscn")
	await _esperar(30)
	await _foto("tela_inicial")
	await _fechar(inicio)

	# festa, com a cesta cheia como no fim do jogo
	var jogo: Node = root.get_node("Jogo")   # autoload: aqui só existe como nó
	for item in jogo.ITENS:
		jogo.adicionar(item, 3)
	var festa := _abrir("res://cenas/festa.tscn")
	await _esperar(200)
	await _foto("festa")
	await _fechar(festa)
	quit()
