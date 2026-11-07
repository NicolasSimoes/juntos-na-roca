extends SceneTree
## Tira uma "foto" da fazenda em cada dia (1 a 5), para conferir o mapa.
## Precisa de janela (não use --headless):
##   godot --path . -s ferramentas/capturar_fazenda.gd
## Salva capturas/fazenda_dia<d>.png (sem o HUD, para ver o mapa inteiro)
## e capturas/fazenda_dia1_hud.png (com o HUD, como o jogador vê).

const CENA := "res://cenas/fazenda.tscn"


func _initialize() -> void:
	_capturar.call_deferred()


func _capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://capturas"))
	var jogo := root.get_node("Jogo")
	for d in range(1, 6):
		jogo.pular_para_dia(d)
		var fazenda: Node = (load(CENA) as PackedScene).instantiate()
		root.add_child(fazenda)
		await create_timer(2.5).timeout
		if d == 1:
			await _foto("fazenda_dia1_hud")
		fazenda.hud.visible = false
		await _foto("fazenda_dia%d" % d)
		fazenda.queue_free()
		await process_frame
		await process_frame
	quit()


func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://capturas/%s.png" % nome)
	print("capturado: ", nome)
