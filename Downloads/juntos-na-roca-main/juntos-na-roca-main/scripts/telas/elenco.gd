class_name Elenco
## Veste os personagens de uma cena. Na cena, cada Sprite2D ou TextureRect que é
## um personagem leva dois metadados (painel Inspetor > Metadata):
##   personagem = "neto1", "neto2" ou "vovo"
##   pose       = "frente", "costas" ou "lado"   (opcional; padrão "frente")
## Assim a cena não guarda o caminho da imagem: quem decide é Aparencia.
## Se a arte dos personagens mudar, as telas mudam junto.


static func vestir(raiz: Node) -> void:
	for no in _todos(raiz):
		if not no.has_meta("personagem"):
			continue
		var quem: String = no.get_meta("personagem")
		var pose: String = no.get_meta("pose", "frente")
		var textura := Aparencia.vovo(pose) if quem == "vovo" else Aparencia.neto(2 if quem == "neto2" else 1, pose)
		if no is Sprite2D:
			(no as Sprite2D).texture = textura
			Aparencia.ajustar_pes(no as Sprite2D)
		elif no is TextureRect:
			(no as TextureRect).texture = textura


static func _todos(no: Node) -> Array[Node]:
	var lista: Array[Node] = [no]
	for filho in no.get_children():
		lista.append_array(_todos(filho))
	return lista
