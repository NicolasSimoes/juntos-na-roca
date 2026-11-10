extends SceneTree
## Fotografa o cartão de missão de cada tarefa (com janela):
##   godot --path . -s ferramentas/capturar_cartoes.gd
## Salva em capturas/cartao_<tarefa>.png.

const CARTAO := "res://cenas/objetos/cartao_missao.tscn"
const TAREFAS := "res://scripts/tarefas/tarefa_%s.gd"


func _initialize() -> void:
	_capturar.call_deferred()


func _capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://capturas"))
	var fundo := ColorRect.new()
	fundo.color = Color(0.42, 0.75, 0.19)
	fundo.size = Vector2(640, 360)
	root.add_child(fundo)
	var textos = load("res://scripts/textos.gd")
	for id in textos.MISSOES:
		var tarefa = load(TAREFAS % id).new()
		var papeis: Array = tarefa.papeis()
		tarefa.free()
		var c = (load(CARTAO) as PackedScene).instantiate()
		root.add_child(c)
		# alterna quem fica com o papel A, para ver as duas cores nos dois lados
		var na := 1 if id.length() % 2 == 0 else 2
		c.abrir(id, na, 3 - na, papeis[2], papeis[3])
		for i in 15:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://capturas/cartao_%s.png" % id)
		print("capturado: ", id)
		c.queue_free()
		await process_frame
	quit()
