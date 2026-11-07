extends CasoDeTeste
## Teste de fumaça: toda cena do jogo abre sem erro.


func test_todas_as_cenas_carregam() -> void:
	for caminho in _cenas("res://cenas/"):
		var cena := load(caminho) as PackedScene
		afirmar(cena != null, "não carregou: " + caminho)
		if cena == null:
			continue
		var no := cena.instantiate()
		afirmar(no != null, "não instanciou: " + caminho)
		if no != null:
			no.free()


func _cenas(pasta: String) -> Array[String]:
	var lista: Array[String] = []
	for arquivo in DirAccess.get_files_at(pasta):
		if arquivo.ends_with(".tscn"):
			lista.append(pasta + arquivo)
	for sub in DirAccess.get_directories_at(pasta):
		lista.append_array(_cenas(pasta + sub + "/"))
	return lista
