extends SceneTree
## Gera as animações dos personagens (SpriteFrames) a partir das folhas do pacote
## e salva em assets/animacoes/. Rode quando trocar o personagem em aparencia.gd:
##   godot --headless --path . -s ferramentas/gerar_animacoes.gd
##
## Nomes das animações (os mesmos que o Jogador usa):
##   parado_baixo, parado_cima, parado_lado, anda_baixo, anda_cima, anda_lado, comemora
## "lado" olha para a direita; para a esquerda o Jogador usa flip_h.

const LINHA := {"baixo": 0, "lado": 2, "cima": 3}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/animacoes"))
	for n in Aparencia.FOLHA_NETO:
		_salvar(Aparencia.FOLHA_NETO[n], "res://assets/animacoes/neto_%d.tres" % n)
	_salvar(Aparencia.FOLHA_VOVO, "res://assets/animacoes/vovo.tres")
	quit()


func _salvar(folha: String, destino: String) -> void:
	var textura: Texture2D = load(Aparencia.PASTA + folha)
	var quadros := SpriteFrames.new()
	quadros.remove_animation("default")
	for d in LINHA:
		var l: int = LINHA[d]
		quadros.add_animation("parado_" + d)
		quadros.add_frame("parado_" + d, _recorte(textura, l, 1))
		quadros.add_animation("anda_" + d)
		quadros.set_animation_speed("anda_" + d, 8.0)
		for c in [0, 1, 2, 1]:   # passo, parado, outro passo, parado
			quadros.add_frame("anda_" + d, _recorte(textura, l, c))
	quadros.add_animation("comemora")
	quadros.set_animation_speed("comemora", 7.0)
	quadros.add_frame("comemora", _recorte(textura, 0, 0))
	quadros.add_frame("comemora", _recorte(textura, 0, 2))
	var erro := ResourceSaver.save(quadros, destino)
	print("salvo: ", destino, " (", erro, ")")


func _recorte(textura: Texture2D, linha: int, coluna: int) -> AtlasTexture:
	var t := AtlasTexture.new()
	t.atlas = textura
	t.region = Rect2(coluna * Aparencia.LARGURA, linha * Aparencia.ALTURA, Aparencia.LARGURA, Aparencia.ALTURA)
	return t
