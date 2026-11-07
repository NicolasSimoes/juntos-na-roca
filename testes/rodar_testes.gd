extends SceneTree
## Executor de testes sem janela.
## Uso: godot --headless --path . -s testes/rodar_testes.gd
## Roda todo método "test_*" de todo res://testes/test_*.gd.

const PASTA := "res://testes/"
const AUTOLOADS := {
	"Jogo": "res://scripts/autoload/jogo.gd",
	"Sons": "res://scripts/autoload/sons.gd",
}


func _initialize() -> void:
	_rodar()


func _garantir_autoloads() -> void:
	for nome in AUTOLOADS:
		if root.get_node_or_null(nome) == null:
			var no: Node = load(AUTOLOADS[nome]).new()
			no.name = nome
			root.add_child(no)


func _rodar() -> void:
	await process_frame
	_garantir_autoloads()
	await process_frame
	var total := 0
	var falhas := 0
	var arquivos: Array[String] = []
	for nome in DirAccess.get_files_at(PASTA):
		if nome.begins_with("test_") and nome.ends_with(".gd"):
			arquivos.append(nome)
	arquivos.sort()
	for arquivo in arquivos:
		var script: GDScript = load(PASTA + arquivo)
		if script == null:
			printerr("FALHOU %s — não carregou" % arquivo)
			falhas += 1
			continue
		for metodo in script.get_script_method_list():
			var nome: String = metodo["name"]
			if not nome.begins_with("test_"):
				continue
			var caso: CasoDeTeste = script.new()
			caso.arvore = self
			total += 1
			await caso.call(nome)
			for f in caso.falhas:
				printerr("FALHOU %s::%s — %s" % [arquivo, nome, f])
			if not caso.falhas.is_empty():
				falhas += 1
	if falhas == 0:
		print("OK: %d testes" % total)
		quit(0)
	else:
		printerr("%d falha(s) em %d testes" % [falhas, total])
		quit(1)
