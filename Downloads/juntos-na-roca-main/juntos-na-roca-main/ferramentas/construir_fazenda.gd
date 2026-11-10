extends SceneTree
## Monta do zero a cena da fazenda (cenas/fazenda.tscn) com a arte do pacote
## Super Retro World e salva. Depois disso a cena é editada NO EDITOR do Godot
## (pintar o chão, arrastar árvores...). Só rode de novo se quiser recomeçar,
## porque este script APAGA o que foi mexido à mão:
##   godot --headless --path . -s ferramentas/construir_fazenda.gd
##
## Também salva os recortes (AtlasTexture) em assets/recortes/mapa/: cada
## recorte aponta para um pedaço da folha do pacote, sem copiar pixels.

const TILESET_PACOTE := "res://assets/SuperRetroWorld_Farming/Tilesets/Super_Retro_Tilesets.tres"
const FOLHA := "res://assets/SuperRetroWorld_Farming/Tilesets/SuperRetroWorld_Farming_Tileset.png"
const PROPS := "res://assets/SuperRetroWorld_Farming/Props/"
const RECORTES := "res://assets/recortes/mapa/"
const SHADER_CINZA := "res://assets/shaders/cinza.gdshader"

## O chão, como texto (40 x 23 blocos de 16 px). Só usado para montar a cena.
## "." e "," = grama   "#" = caminho de terra   "~" = água   "l" = lama   "c" = campo
const MAPA := [
	",,.,,....,..,,,....,.....,...,.,........",
	"....,..,,......,.,.......,,,..,.,.,.....",
	",........,.,...,,,...,..,,,,.,,.,.,.....",
	",.,.,...,.,,,.,,.........,,.............",
	".,...,.,..,,....,,.##,.....,......,,....",
	",...,..,....,..,,..##..,.,....,.,,.....,",
	".....,,............##..,...,,,.,.....,..",
	",...,,.....,......,##..........,........",
	".,,....llll.....,.,##.,,..,......,,,.,,.",
	".......llll..,..,,.##.....,.,.,,..,...,.",
	"......#########################...,....,",
	",,...,#########################....,,...",
	"........,...,.,.,,,##..,...,,.,.....,.,.",
	",.,,,......,,....,.##.,,,.......,,,,.,..",
	"...,..,,,....,...,.##.,,...,......,....,",
	"..cccccccccc.......##,.,...,..,..,.....,",
	"..cccccccccc..,.,..##..,...,,...~~~~~~~~",
	".,cccccccccc#########,.,.....,.~~~~~~~~~",
	",.cccccccccc#########..,...,.,~~~~~~~~~~",
	",.cccccccccc,.,....##...,.....~~~~~~~~~~",
	"..,,......,.,.....,##.........~~~~~~~~~~",
	".,,...,..,....,,...##,.,,,.,,.~~~~~~~~~~",
	".....,,..,..........,,,......,.~~~~~~~~~",
]

## Pedaços da folha grande do pacote (em pixels).
const PEDACOS := {
	"poco_quebrado": Rect2(256, 896, 32, 32),
	"poco_consertado": Rect2(352, 896, 32, 32),
	"cerca_h": Rect2(272, 944, 16, 16),
	"cerca_v": Rect2(288, 944, 16, 16),
	"cerca_canto_ce": Rect2(256, 928, 16, 16),   # canto de cima, esquerda
	"cerca_canto_cd": Rect2(288, 928, 16, 16),
	"cerca_canto_be": Rect2(256, 960, 16, 16),   # canto de baixo, esquerda
	"cerca_canto_bd": Rect2(288, 960, 16, 16),
	"cerca_poste": Rect2(272, 960, 16, 16),
	"prancha": Rect2(1200, 128, 16, 16),
	"poca": Rect2(112, 928, 48, 16),
	"pilha_lenha": Rect2(432, 64, 16, 32),
	"arvore_pequena": Rect2(288, 32, 16, 32),
	"arbusto_1": Rect2(320, 64, 16, 16),
	"arbusto_2": Rect2(336, 64, 16, 16),
	"flor_branca": Rect2(272, 144, 16, 16),
	"flor_vermelha": Rect2(288, 144, 16, 16),
	"flor_amarela": Rect2(304, 144, 16, 16),
	"flor_azul": Rect2(320, 144, 16, 16),
	"cogumelo": Rect2(336, 160, 16, 16),
	"vitoria_regia_1": Rect2(336, 176, 16, 16),
	"vitoria_regia_2": Rect2(352, 192, 16, 16),
	# horta: fase 1 = semente; 2, 3, 4 = crescendo até maduro
	"semente": Rect2(96, 912, 16, 16),
	"milho_fase2": Rect2(160, 896, 16, 16),
	"milho_fase3": Rect2(192, 880, 16, 32),
	"milho_fase4": Rect2(224, 880, 16, 32),
	"feijao_fase2": Rect2(32, 784, 16, 32),
	"feijao_fase3": Rect2(80, 784, 16, 32),
	"feijao_fase4": Rect2(128, 784, 16, 32),
	"jerimum_fase2": Rect2(16, 944, 16, 16),
	"jerimum_fase3": Rect2(32, 944, 16, 16),
	"jerimum_fase4": Rect2(64, 944, 16, 16),
}

## Árvores da mata (uma imagem do pacote para cada posição de Lugares.ARVORES).
const ARVORES := ["tree_04", "tree_01", "tree_13", "tree_03", "tree_30", "tree_31", "tree_01"]

## Enfeites: [recorte, posição dos pés]
const ENFEITES := [
	["flor_branca", Vector2(24, 92)], ["flor_amarela", Vector2(106, 70)], ["cogumelo", Vector2(170, 96)],
	["flor_vermelha", Vector2(198, 36)], ["arbusto_1", Vector2(206, 84)], ["arbusto_2", Vector2(122, 22)],
	["flor_azul", Vector2(244, 30)], ["flor_branca", Vector2(436, 30)], ["arbusto_1", Vector2(440, 96)],
	["flor_amarela", Vector2(170, 214)], ["flor_vermelha", Vector2(414, 150)], ["flor_branca", Vector2(388, 226)],
	["arbusto_2", Vector2(436, 214)], ["flor_azul", Vector2(232, 340)], ["flor_amarela", Vector2(398, 344)],
	["flor_vermelha", Vector2(452, 300)], ["arbusto_1", Vector2(196, 254)], ["flor_branca", Vector2(12, 228)],
	["arvore_pequena", Vector2(458, 50)], ["arvore_pequena", Vector2(460, 252)],
	["vitoria_regia_1", Vector2(586, 314)], ["vitoria_regia_2", Vector2(618, 290)], ["vitoria_regia_1", Vector2(512, 344)],
]

const PEDRAS := ["rock_21", "rock_22", "rock_23", "rock_24", "rock_21", "rock_23"]

var _recortes := {}
var _raiz: Node2D
var _mundo: Node2D
var _paredes: Node2D


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RECORTES))
	_salvar_recortes()
	var campo := _salvar_tileset_campo()
	_raiz = Node2D.new()
	_raiz.name = "Fazenda"
	_montar_chao(campo)
	_mundo = _no(Node2D.new(), "Mundo", _raiz, true)
	_paredes = _no(Node2D.new(), "Paredes", _mundo, true)
	_montar_cenario()
	_montar_zonas()
	var seta := _no(Sprite2D.new(), "Seta", _raiz, true) as Sprite2D
	seta.texture = load("res://assets/sprites/extras/seta.png")
	seta.z_index = 20
	seta.visible = false
	seta.editor_description = "Setinha amarela que mostra para onde ir (o script move)."
	_raiz.set_script(load("res://scripts/fazenda.gd"))
	_dono(_raiz, _raiz)
	var cena := PackedScene.new()
	var erro := cena.pack(_raiz)
	print("pack: ", erro)
	print("salvo: ", ResourceSaver.save(cena, "res://cenas/fazenda.tscn"))
	_raiz.free()
	quit()


# ================================================================== recursos
func _salvar_recortes() -> void:
	var folha: Texture2D = load(FOLHA)
	for nome in PEDACOS:
		var t := AtlasTexture.new()
		t.atlas = folha
		t.region = PEDACOS[nome]
		var caminho: String = RECORTES + nome + ".tres"
		ResourceSaver.save(t, caminho, ResourceSaver.FLAG_CHANGE_PATH)
		_recortes[nome] = load(caminho)


## TileSet pequeno do chão (grama de fundo e o campo arado). A ordem dos blocos
## é a mesma do atlas antigo, porque as tarefas usam esses números:
## 0 grama, 1 caminho, 2 terra arada, 3 água, 4 lama, 5 terra molhada, 6 grama 2, 7 campo.
func _salvar_tileset_campo() -> TileSet:
	var conjunto := TileSet.new()
	conjunto.tile_size = Vector2i(16, 16)
	var fonte := TileSetAtlasSource.new()
	fonte.texture = load(RECORTES + "campo_atlas.png")
	fonte.texture_region_size = Vector2i(16, 16)
	for i in 8:
		fonte.create_tile(Vector2i(i, 0))
	conjunto.add_source(fonte, 0)
	ResourceSaver.save(conjunto, RECORTES + "campo.tres", ResourceSaver.FLAG_CHANGE_PATH)
	return load(RECORTES + "campo.tres")


func _recorte(nome: String) -> Texture2D:
	return _recortes[nome]


# ================================================================== chão
func _montar_chao(campo: TileSet) -> void:
	var base := _no(TileMapLayer.new(), "Base", _raiz, true) as TileMapLayer
	base.tile_set = campo
	base.editor_description = "Grama de fundo do mapa inteiro."
	for y in MAPA.size():
		for x in 40:
			base.set_cell(Vector2i(x, y), 0, Vector2i(6 if (x * 7 + y * 13) % 5 == 0 else 0, 0))
	var terreno := _no(TileMapLayer.new(), "Terreno", _raiz, true) as TileMapLayer
	terreno.tile_set = load(TILESET_PACOTE)
	terreno.editor_description = "Caminhos, campo e lago, pintados com os terrenos do pacote (as bordas com grama se ajustam sozinhas)."
	var caminho: Array[Vector2i] = []
	var agua: Array[Vector2i] = []
	var plantio: Array[Vector2i] = []
	for y in MAPA.size():
		var linha: String = MAPA[y]
		for x in linha.length():
			var c := Vector2i(x, y)
			match linha[x]:
				"#":
					caminho.append(c)
				"~":
					agua.append(c)
					# o lago continua para fora da tela (assim a borda não aparece)
					if x == 39:
						agua.append(Vector2i(40, y))
						agua.append(Vector2i(41, y))
					if y == MAPA.size() - 1:
						agua.append(Vector2i(x, y + 1))
						agua.append(Vector2i(x, y + 2))
				"c":
					plantio.append(c)
	agua.append(Vector2i(40, 23))
	agua.append(Vector2i(41, 23))
	terreno.set_cells_terrain_connect(plantio, 0, 1)
	terreno.set_cells_terrain_connect(caminho, 0, 0)
	terreno.set_cells_terrain_connect(agua, 4, 1)
	var campo_camada := _no(TileMapLayer.new(), "Campo", _raiz, true) as TileMapLayer
	campo_camada.tile_set = campo
	campo_camada.editor_description = "Terra arada do campo. Começa vazia: o trator e o script pintam (bloco 2 = arada, 5 = molhada)."


# ================================================================== cenário
func _montar_cenario() -> void:
	var cenario := _no(Node2D.new(), "Cenario", _mundo, true)
	# casa da Vovó
	_sprite(PROPS + "Houses/Sprites/house_02.png", Lugares.CASA, cenario, "Casa")
	_parede(Rect2(Lugares.CASA + Vector2(2, 14), Vector2(71, 34)), "Casa")
	var lenha := _sprite_recorte("pilha_lenha", Lugares.PILHA_LENHA - Vector2(8, 28), cenario, "PilhaLenha")
	lenha.editor_description = "Pilha de lenha ao lado da casa. Só aparece depois da tarefa da lenha."
	var fumaca := _no(CPUParticles2D.new(), "Fumaca", cenario, true) as CPUParticles2D
	fumaca.position = Lugares.CHAMINE
	fumaca.z_index = 7
	fumaca.amount = 10
	fumaca.lifetime = 2.2
	fumaca.texture = load("res://assets/sprites/extras/bolinha.png")
	fumaca.direction = Vector2(0.3, -1)
	fumaca.spread = 12.0
	fumaca.gravity = Vector2(4, -6)
	fumaca.initial_velocity_min = 6.0
	fumaca.initial_velocity_max = 12.0
	fumaca.scale_amount_min = 0.4
	fumaca.scale_amount_max = 1.0
	fumaca.color = Color(1, 1, 1, 0.55)
	fumaca.emitting = false
	fumaca.editor_description = "Fumaça do fogão. Liga quando tem lenha."
	# mata
	var arvores := _no(Node2D.new(), "Arvores", cenario, false)
	for i in Lugares.ARVORES.size():
		var pe: Vector2 = Lugares.ARVORES[i] + Vector2(16, 32)   # pé da árvore antiga
		var tex: Texture2D = load(PROPS + "Trees/Sprites/%s.png" % ARVORES[i])
		var s := _sprite_textura(tex, pe - Vector2(tex.get_width() / 2.0, tex.get_height()), arvores, "Arvore%d" % (i + 1))
		s.z_index = 1
		_parede(Rect2(pe + Vector2(-5, -9), Vector2(10, 8)), "Tronco%d" % (i + 1))
	# galpão e galinheiro
	_sprite(PROPS + "Houses/Sprites/house_05.png", Lugares.GALPAO, cenario, "Galpao")
	_parede(Rect2(Lugares.GALPAO + Vector2(2, 16), Vector2(60, 30)), "Galpao")
	_sprite("res://assets/sprites/estruturas/galinheiro.png", Lugares.GALINHEIRO, cenario, "Galinheiro")
	_parede(Rect2(Lugares.GALINHEIRO + Vector2(3, 14), Vector2(34, 20)), "Galinheiro")
	_sprite(PROPS + "Barrels/Sprites/barrel_01.png", Vector2(10, 146), cenario, "Barril1")
	_sprite(PROPS + "Barrels/Sprites/barrel_02.png", Vector2(100, 136), cenario, "Barril2")
	# poço
	var poco := _sprite_recorte("poco_quebrado", Lugares.POCO, cenario, "Poco")
	poco.editor_description = "Poço de pedra. O script troca para o consertado depois da tarefa."
	_parede(Rect2(Lugares.POCO + Vector2(3, 12), Vector2(26, 18)), "Poco")
	# cercas
	var cercas := _no(Node2D.new(), "Cercas", cenario, false)
	_cerca_retangulo(cercas, "Cercado", 29, 37, 1, 6, [31, 32, 33], [32, 33, 34], [], [])
	_cerca_retangulo(cercas, "Curral", 31, 38, 9, 13, [], [], [11], [])
	_cerca_linha(cercas, "CercaBaixo1", 14, 18, 21)
	_cerca_linha(cercas, "CercaBaixo2", 21, 26, 21)
	# curral: vaca, cocho e bebedouro
	_sprite("res://assets/sprites/personagens/vaca_mimosa.png", Lugares.VACA, cenario, "Vaca")
	_sprite("res://assets/sprites/extras/cocho_vazio.png", Lugares.COCHO, cenario, "Cocho")
	_sprite("res://assets/sprites/extras/bebedouro_vazio.png", Lugares.BEBEDOURO, cenario, "Bebedouro")
	# porteira e píer
	_sprite("res://assets/sprites/estruturas/porteira.png", Lugares.PORTEIRA, cenario, "Porteira")
	var pier := _no(Node2D.new(), "Pier", cenario, false)
	for y in range(14, 21):
		var p := _sprite_recorte("prancha", Vector2(Lugares.PIER_X, y * 16), pier, "Prancha%d" % y)
		p.z_index = 1
	# poça de lama onde o trator atola (manchas de terra do pacote, escurecidas)
	for k in 2:
		var poca := _sprite_recorte("poca", Vector2(110 + k * 18, 134 + k * 10), cenario, "Lama%d" % (k + 1))
		poca.modulate = Color(0.62, 0.42, 0.3)
	# trator: atolado na lama (dias 1 e 2) ou parado perto do campo (depois)
	var atolado := _sprite("res://assets/sprites/extras/trator.png", Lugares.TRATOR_ATOLADO, cenario, "TratorAtolado")
	atolado.editor_description = "Trator atolado. Some quando a tarefa do trator acaba."
	var parado := _sprite("res://assets/sprites/extras/trator.png", Lugares.TRATOR_PARADO - Vector2(16, 24), cenario, "TratorParado")
	parado.editor_description = "Trator estacionado perto do campo (depois de desatolar)."
	_parede(Rect2(Lugares.TRATOR_PARADO + Vector2(-13, -8), Vector2(26, 8)), "TratorParado")
	# pedras do campo (o trator bate nelas; somem depois de arar)
	var pedras := _no(Node2D.new(), "Pedras", _mundo, true)
	pedras.editor_description = "Pedras do campo. Ficam no grupo 'pedras'; o script apaga depois que a terra foi arada."
	for i in Lugares.PEDRAS.size():
		var b: Vector2i = Lugares.PEDRAS[i]
		_pedra(pedras, Vector2(b.x * 16 + 8, b.y * 16 + 10), PEDRAS[i], i + 1)
	# enfeites
	var enfeites := _no(Node2D.new(), "Enfeites", cenario, false)
	for i in ENFEITES.size():
		var e: Array = ENFEITES[i]
		var tex := _recorte(e[0])
		_sprite_textura(tex, (e[1] as Vector2) - Vector2(tex.get_width() / 2.0, tex.get_height()), enfeites, "Enfeite%d" % (i + 1))
	# Vovó
	var vovo := _no(AnimatedSprite2D.new(), "Vovo", _mundo, true) as AnimatedSprite2D
	vovo.sprite_frames = load("res://assets/animacoes/vovo.tres")
	vovo.animation = &"parado_baixo"
	vovo.position = Lugares.VOVO + Vector2(0, -10)
	vovo.z_index = 7
	vovo.editor_description = "A Vovó Zefa, parada ao lado da casa."
	# água do lago (não dá para entrar; o píer fica livre) e bordas da tela
	_parede(Rect2(512, 256, 32, 16), "Lago1")
	_parede(Rect2(560, 256, 80, 16), "Lago2")
	_parede(Rect2(496, 272, 48, 16), "Lago3")
	_parede(Rect2(560, 272, 80, 16), "Lago4")
	_parede(Rect2(480, 288, 64, 48), "Lago5")
	_parede(Rect2(560, 288, 80, 48), "Lago6")
	_parede(Rect2(480, 336, 160, 32), "Lago7")
	_parede(Rect2(-16, 0, 16, 360), "BordaEsquerda")
	_parede(Rect2(640, 0, 16, 360), "BordaDireita")
	_parede(Rect2(0, -16, 640, 16), "BordaCima")
	_parede(Rect2(0, 352, 640, 16), "BordaBaixo")


func _montar_zonas() -> void:
	var zonas := _no(Node2D.new(), "Zonas", _raiz, true)
	zonas.editor_description = "Áreas que começam cinza. Cada tarefa feita apaga a sua (ver Jogo.ZONAS_DA_TAREFA)."
	var shader: Shader = load(SHADER_CINZA)
	for nome in Lugares.ZONAS:
		var r: Rect2 = Lugares.ZONAS[nome]
		var cinza := _no(ColorRect.new(), nome, zonas, false) as ColorRect
		cinza.position = r.position
		cinza.size = r.size
		cinza.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cinza.z_index = 5
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.resource_local_to_scene = true
		cinza.material = mat


# ================================================================== ajudantes
func _no(no: Node, nome: String, pai: Node, unico: bool) -> Node:
	no.name = nome
	pai.add_child(no)
	no.set_meta("_unico", unico)
	return no


func _dono(no: Node, raiz: Node) -> void:
	for filho in no.get_children():
		filho.owner = raiz
		if filho.has_meta("_unico"):
			filho.unique_name_in_owner = filho.get_meta("_unico")
			filho.remove_meta("_unico")
		_dono(filho, raiz)


func _sprite(caminho: String, pos: Vector2, pai: Node, nome: String) -> Sprite2D:
	return _sprite_textura(load(caminho), pos, pai, nome)


func _sprite_recorte(recorte: String, pos: Vector2, pai: Node, nome: String) -> Sprite2D:
	return _sprite_textura(_recorte(recorte), pos, pai, nome)


func _sprite_textura(tex: Texture2D, pos: Vector2, pai: Node, nome: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = pos.round()
	_no(s, nome, pai, pai == _mundo.get_node("Cenario") if _mundo.has_node("Cenario") else false)
	return s


func _parede(r: Rect2, nome: String) -> StaticBody2D:
	var corpo := StaticBody2D.new()
	corpo.collision_layer = 1
	corpo.collision_mask = 0
	_no(corpo, "Parede" + nome, _paredes, nome == "TratorParado")
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = r.size
	forma.shape = ret
	forma.position = r.get_center()
	_no(forma, "Forma", corpo, false)
	return corpo


func _pedra(pai: Node, pos: Vector2, arquivo: String, i: int) -> void:
	var corpo := StaticBody2D.new()
	corpo.collision_layer = 8
	corpo.collision_mask = 0
	corpo.position = pos
	corpo.z_index = 3
	corpo.add_to_group("pedras", true)
	_no(corpo, "Pedra%d" % i, pai, false)
	# a forma TEM que ser o primeiro filho (fazenda.tirar_pedra usa get_child(0))
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(12, 8)
	forma.shape = ret
	forma.position = Vector2(0, -2)
	_no(forma, "Forma", corpo, false)
	var s := Sprite2D.new()
	s.texture = load(PROPS + "Rocks/Sprites/%s.png" % arquivo)
	s.position = Vector2(0, -6)
	_no(s, "Desenho", corpo, false)


## Cerca em volta de um retângulo de blocos (x0..x1, y0..y1).
## Os "buracos" são as aberturas: em cima, embaixo, na esquerda e na direita.
func _cerca_retangulo(pai: Node, nome: String, x0: int, x1: int, y0: int, y1: int,
		buraco_cima: Array, buraco_baixo: Array, buraco_esq: Array, buraco_dir: Array) -> void:
	var grupo := _no(Node2D.new(), nome, pai, false)
	for x in range(x0, x1 + 1):
		for y in [y0, y1]:
			if x in (buraco_cima if y == y0 else buraco_baixo):
				continue
			var peca := "cerca_h"
			if x == x0:
				peca = "cerca_canto_ce" if y == y0 else "cerca_canto_be"
			elif x == x1:
				peca = "cerca_canto_cd" if y == y0 else "cerca_canto_bd"
			_peca_cerca(grupo, peca, x, y)
			_parede(Rect2(x * 16, y * 16 + 3, 16, 9), "%s_%d_%d" % [nome, x, y])
	for y in range(y0 + 1, y1):
		for x in [x0, x1]:
			if y in (buraco_esq if x == x0 else buraco_dir):
				continue
			_peca_cerca(grupo, "cerca_v", x, y)
			_parede(Rect2(x * 16 + 3, y * 16, 9, 16), "%s_%d_%d" % [nome, x, y])


func _cerca_linha(pai: Node, nome: String, x0: int, x1: int, y: int) -> void:
	var grupo := _no(Node2D.new(), nome, pai, false)
	for x in range(x0, x1 + 1):
		_peca_cerca(grupo, "cerca_h", x, y)
		_parede(Rect2(x * 16, y * 16 + 3, 16, 9), "%s_%d" % [nome, x])


func _peca_cerca(pai: Node, peca: String, x: int, y: int) -> void:
	var s := Sprite2D.new()
	s.texture = _recorte(peca)
	s.centered = false
	s.position = Vector2(x * 16, y * 16)
	_no(s, "%s_%d_%d" % [peca, x, y], pai, false)
