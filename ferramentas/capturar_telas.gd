extends SceneTree
## Tira uma "foto" de cada minijogo aberto sozinho, para comparar o antes e o depois.
## Precisa de janela (não use --headless):
##   godot --path . -s ferramentas/capturar_telas.gd
## Salva em capturas/<nome>.png (a pasta está no .gitignore).
## Cada tarefa da refatoração acrescenta o seu minijogo em TELAS.

const TELAS := {
	"serra": "res://cenas/minijogos/minijogo_serra.tscn",
	"pesca": "res://cenas/minijogos/minijogo_pesca.tscn",
	"poco": "res://cenas/minijogos/minijogo_poco.tscn",
}


func _initialize() -> void:
	_capturar.call_deferred()


func _capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://capturas"))
	for nome in TELAS:
		var mj: Node = (load(TELAS[nome]) as PackedScene).instantiate()
		root.add_child(mj)
		for i in 20:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.save_png("res://capturas/%s.png" % nome)
		print("capturado: ", nome)
		mj.queue_free()
		await process_frame
	quit()
