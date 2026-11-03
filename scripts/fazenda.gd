extends Node2D
## A fazenda: monta o mapa, os jogadores e as tarefas do dia e cuida da ordem das coisas:
## estação -> tarefa -> foto -> "toca aqui" -> área colorida -> próxima tarefa -> dormir.

const CENA_JOGADOR := preload("res://cenas/jogador.tscn")
const SHADER_CINZA := preload("res://assets/shaders/cinza.gdshader")

const TAREFAS := {
	"poco": preload("res://scripts/tarefas/tarefa_poco.gd"),
	"lenha": preload("res://scripts/tarefas/tarefa_lenha.gd"),
	"trator": preload("res://scripts/tarefas/tarefa_trator.gd"),
	"arar": preload("res://scripts/tarefas/tarefa_arar.gd"),
	"plantar": preload("res://scripts/tarefas/tarefa_plantar.gd"),
	"galinhas": preload("res://scripts/tarefas/tarefa_galinhas.gd"),
	"animais": preload("res://scripts/tarefas/tarefa_animais.gd"),
	"pesca": preload("res://scripts/tarefas/tarefa_pesca.gd"),
	"cuidar_horta": preload("res://scripts/tarefas/tarefa_cuidar_horta.gd"),
	"colher": preload("res://scripts/tarefas/tarefa_colher.gd"),
}

## O chão, como texto (40 x 23 blocos de 16 px).
## "." e "," = grama   "#" = caminho   "~" = água   "l" = lama   "c" = campo (vira terra arada)
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

const FALAS_DO_DIA := {
	1: ["Que bom que vocês vieram! Aqui na roça, ninguém faz nada sozinho.",
		"O poço quebrou e o fogão está sem lenha. A setinha amarela mostra para onde ir.",
		"Para começar uma tarefa, cada um para em um círculo. A cor da borda é a minha sugestão de quem faz o quê."],
	2: ["Bom dia! O trator atolou na lama e o campo está cheio de pedras.",
		"Vamos desatolar o trator e depois arar a terra?"],
	3: ["Hoje é dia de plantar milho, feijão e jerimum!",
		"E as galinhas fujonas? Sozinho ninguém pega. Cerquem juntos!"],
	4: ["As galinhas já botaram ovos! Coloquei na cesta.",
		"Hoje tem bicho com fome, peixe para pescar e horta pedindo cuidado."],
	5: ["Chegou o dia da Festa da Colheita!",
		"Vamos colher tudo e levar o jerimum gigante até a porteira."],
}

const ELOGIOS := {
	"poco": "Poço consertado! Agora tem água para tudo.",
	"lenha": "Que cheirinho! O fogão acendeu e vou fazer bolo de milho.",
	"trator": "O trator saiu da lama! Juntos vocês têm muita força.",
	"arar": "A terra está arada. Amanhã a gente planta!",
	"plantar": "Tudo plantado e regado. Logo, logo cresce!",
	"galinhas": "As galinhas estão em casa. Obrigada, meus amores!",
	"animais": "A Mimosa está feliz. Leite fresquinho!",
	"pesca": "Que peixes bonitos! Já tem almoço para a festa.",
	"cuidar_horta": "A horta está linda. Amanhã é dia de colher!",
}

var chao: TileMapLayer
var mundo: Node2D
var hud: Hud
var horta: Horta
var jogadores: Array[Jogador] = []
var tarefas := {}
var tarefa_atual: Tarefa
var galinhas: Array[Galinha] = []
var pedras: Array[Node2D] = []
var estacao_dormir: Estacao
var ocupado := true

var _zonas := {}
var _seta: Sprite2D
var _poco: Sprite2D
var _trator_parado: Sprite2D
var _trator_parede: StaticBody2D
var _trator_atolado: Sprite2D
var _fumaca: CPUParticles2D
var _pilha_lenha: Sprite2D
var _cocho: Sprite2D
var _bebedouro: Sprite2D
var _vovo: Sprite2D
var _tempo := 0.0


func _ready() -> void:
	Sons.musica("musica_fazenda")
	_montar_chao()
	mundo = Node2D.new()
	add_child(mundo)
	_montar_construcoes()
	horta = Horta.new()
	horta.chao = chao
	mundo.add_child(horta)
	horta.atualizar_chao()
	_montar_estado_do_dia()
	_montar_zonas()
	_montar_jogadores()
	_seta = Sprite2D.new()
	_seta.texture = Jogo.tex("res://assets/sprites/extras/seta.png")
	_seta.z_index = 20
	_seta.visible = false
	add_child(_seta)
	hud = Hud.new()
	add_child(hud)
	_criar_tarefas()
	_criar_estacao_dormir()
	travar(true)
	await hud.mostrar_dia(Jogo.dia, _subtitulo_do_dia())
	await hud.conversa(FALAS_DO_DIA.get(Jogo.dia, []))
	travar(false)
	ocupado = false


func _subtitulo_do_dia() -> String:
	var nomes: Array[String] = []
	for id in Jogo.tarefas_do_dia():
		nomes.append(Jogo.NOMES[id])
	return " · ".join(nomes)


# ================================================================== montagem do mapa
func _montar_chao() -> void:
	chao = TileMapLayer.new()
	var conjunto := TileSet.new()
	conjunto.tile_size = Vector2i(16, 16)
	var fonte := TileSetAtlasSource.new()
	fonte.texture = load("res://assets/sprites/tiles/atlas.png")
	fonte.texture_region_size = Vector2i(16, 16)
	for i in 8:
		fonte.create_tile(Vector2i(i, 0))
	conjunto.add_source(fonte, 0)
	chao.tile_set = conjunto
	add_child(chao)
	var arado := Jogo.feita("arar")
	for y in MAPA.size():
		var linha: String = MAPA[y]
		for x in linha.length():
			var bloco := 0
			match linha[x]:
				",":
					bloco = 6
				"#":
					bloco = 1
				"~":
					bloco = 3
				"l":
					bloco = 4
				"c":
					bloco = 2 if arado else 7
			chao.set_cell(Vector2i(x, y), 0, Vector2i(bloco, 0))


func _sprite(caminho: String, pos: Vector2, z := 0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Jogo.tex(caminho)
	s.centered = false
	s.position = pos
	s.z_index = z
	mundo.add_child(s)
	return s


func _parede(r: Rect2, camada := 1) -> StaticBody2D:
	var corpo := StaticBody2D.new()
	corpo.collision_layer = camada
	corpo.collision_mask = 0
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = r.size
	forma.shape = ret
	forma.position = r.get_center()
	corpo.add_child(forma)
	mundo.add_child(corpo)
	return corpo


func _cerca_h(x0: int, x1: int, y: int, pular: Array = []) -> void:
	for x in range(x0, x1 + 1):
		if x in pular:
			continue
		_sprite("res://assets/sprites/estruturas/cerca_h.png", Vector2(x * 16, y * 16))
		_parede(Rect2(x * 16, y * 16 + 4, 16, 10))


func _cerca_v(x: int, y0: int, y1: int, pular: Array = []) -> void:
	for y in range(y0, y1 + 1):
		if y in pular:
			continue
		_sprite("res://assets/sprites/estruturas/cerca_v.png", Vector2(x * 16, y * 16))
		_parede(Rect2(x * 16 + 4, y * 16, 10, 16))


func _montar_construcoes() -> void:
	# casa da Vovó
	_sprite("res://assets/sprites/estruturas/casa.png", Lugares.CASA)
	_sprite("res://assets/sprites/extras/chamine.png", Lugares.CHAMINE - Vector2(5, -2))
	_parede(Rect2(Lugares.CASA + Vector2(2, 22), Vector2(60, 34)))
	_pilha_lenha = _sprite("res://assets/sprites/extras/lenha.png", Lugares.PILHA_LENHA - Vector2(8, 16))
	_pilha_lenha.visible = Jogo.feita("lenha")
	_fumaca = CPUParticles2D.new()
	_fumaca.position = Lugares.CHAMINE
	_fumaca.z_index = 7
	_fumaca.amount = 10
	_fumaca.lifetime = 2.2
	_fumaca.texture = Jogo.tex("res://assets/sprites/extras/bolinha.png")
	_fumaca.direction = Vector2(0.3, -1)
	_fumaca.spread = 12.0
	_fumaca.gravity = Vector2(4, -6)
	_fumaca.initial_velocity_min = 6.0
	_fumaca.initial_velocity_max = 12.0
	_fumaca.scale_amount_min = 0.4
	_fumaca.scale_amount_max = 1.0
	_fumaca.color = Color(1, 1, 1, 0.55)
	_fumaca.emitting = Jogo.feita("lenha")
	mundo.add_child(_fumaca)
	# mata
	for p in Lugares.ARVORES:
		_sprite("res://assets/sprites/estruturas/arvore.png", p)
		_parede(Rect2(p + Vector2(11, 20), Vector2(10, 10)))
	# galpão e galinheiro
	_sprite("res://assets/sprites/estruturas/galpao.png", Lugares.GALPAO)
	_parede(Rect2(Lugares.GALPAO + Vector2(3, 18), Vector2(50, 28)))
	_sprite("res://assets/sprites/estruturas/galinheiro.png", Lugares.GALINHEIRO)
	_parede(Rect2(Lugares.GALINHEIRO + Vector2(3, 14), Vector2(34, 20)))
	# poço
	var poco := "res://assets/sprites/objetos/poco.png" if Jogo.feita("poco") else "res://assets/sprites/extras/poco_quebrado.png"
	_poco = _sprite(poco, Lugares.POCO)
	_parede(Rect2(Lugares.POCO + Vector2(1, 6), Vector2(14, 10)))
	# cercado das galinhas (abertura embaixo)
	_cerca_h(29, 37, 1, [31, 32, 33])
	_cerca_v(29, 2, 5)
	_cerca_v(37, 2, 5)
	_cerca_h(29, 37, 6, [32, 33, 34])
	# curral (entrada do lado esquerdo)
	_cerca_h(31, 38, 9)
	_cerca_h(31, 38, 13)
	_cerca_v(31, 10, 12, [11])
	_cerca_v(38, 10, 12)
	_sprite("res://assets/sprites/personagens/vaca_mimosa.png", Lugares.VACA)
	var cheio := Jogo.feita("animais")
	_cocho = _sprite("res://assets/sprites/extras/cocho_%s.png" % ("cheio" if cheio else "vazio"), Lugares.COCHO)
	_bebedouro = _sprite("res://assets/sprites/extras/bebedouro_%s.png" % ("cheio" if cheio else "vazio"), Lugares.BEBEDOURO)
	# cerca de baixo, porteira e píer
	_cerca_h(14, 18, 21)
	_cerca_h(21, 26, 21)
	_sprite("res://assets/sprites/estruturas/porteira.png", Lugares.PORTEIRA)
	for y in range(14, 21):
		_sprite("res://assets/sprites/estruturas/pier.png", Vector2(Lugares.PIER_X, y * 16), 1)
	# água do lago e bordas da tela (não dá para passar)
	_parede(Rect2(480, 272, 160, 96))
	_parede(Rect2(512, 256, 128, 16))
	_parede(Rect2(-16, 0, 16, 360))
	_parede(Rect2(640, 0, 16, 360))
	_parede(Rect2(0, -16, 640, 16))
	_parede(Rect2(0, 352, 640, 16))
	# Vovó
	_vovo = _sprite("res://assets/sprites/personagens/vovo_zefa.png", Lugares.VOVO - Vector2(8, 24), 7)


func _montar_estado_do_dia() -> void:
	if Jogo.feita("trator"):
		_criar_trator_parado()
	else:
		_trator_atolado = _sprite("res://assets/sprites/extras/trator.png", Lugares.TRATOR_ATOLADO)
	if not Jogo.feita("arar"):
		for b in Lugares.PEDRAS:
			_criar_pedra(Vector2(b.x * 16 + 8, b.y * 16 + 10))
	for p in Lugares.GALINHAS_SOLTAS:
		var g := Galinha.new()
		g.cercado = Lugares.CERCADO
		g.position = p
		mundo.add_child(g)
		galinhas.append(g)
		if Jogo.feita("galinhas"):
			g.colocar_no_cercado()


func _criar_trator_parado() -> void:
	_trator_parado = _sprite("res://assets/sprites/extras/trator.png", Lugares.TRATOR_PARADO - Vector2(16, 24))
	_trator_parede = _parede(Rect2(Lugares.TRATOR_PARADO + Vector2(-13, -8), Vector2(26, 8)))


func _criar_pedra(pos: Vector2) -> void:
	var corpo := StaticBody2D.new()
	corpo.collision_layer = 8
	corpo.collision_mask = 0
	corpo.position = pos
	corpo.z_index = 3
	corpo.add_to_group("pedras")
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(12, 8)
	forma.shape = ret
	forma.position = Vector2(0, -2)
	corpo.add_child(forma)
	var s := Sprite2D.new()
	s.texture = Jogo.tex("res://assets/sprites/objetos/pedra.png")
	s.position = Vector2(0, -6)
	corpo.add_child(s)
	mundo.add_child(corpo)
	pedras.append(corpo)


func _montar_zonas() -> void:
	var coloridas := Jogo.zonas_coloridas()
	for nome in Lugares.ZONAS:
		if nome in coloridas:
			continue
		var r: Rect2 = Lugares.ZONAS[nome]
		var cinza := ColorRect.new()
		cinza.position = r.position
		cinza.size = r.size
		cinza.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cinza.z_index = 5
		var mat := ShaderMaterial.new()
		mat.shader = SHADER_CINZA
		cinza.material = mat
		add_child(cinza)
		_zonas[nome] = cinza


func _montar_jogadores() -> void:
	for n in [1, 2]:
		var j: Jogador = CENA_JOGADOR.instantiate()
		j.numero = n
		j.position = Lugares.INICIO_J1 if n == 1 else Lugares.INICIO_J2
		mundo.add_child(j)
		jogadores.append(j)


# ================================================================== tarefas
func _criar_tarefas() -> void:
	for id in Jogo.tarefas_do_dia():
		if Jogo.feita(id):
			continue
		var t: Tarefa = TAREFAS[id].new()
		t.id = id
		t.fazenda = self
		mundo.add_child(t)
		var e := Estacao.new()
		var p := t.papeis()
		e.papel_a = p[0]
		e.papel_b = p[1]
		e.icone_a = p[2]
		e.icone_b = p[3]
		e.sugerir = p[0] != p[1]
		e.position = t.posicao_estacao()
		mundo.add_child(e)
		t.estacao = e
		e.prontos.connect(_comecar_tarefa.bind(t))
		t.terminou.connect(_tarefa_terminou.bind(t))
		t.preparar()
		tarefas[id] = t


func _criar_estacao_dormir() -> void:
	estacao_dormir = Estacao.new()
	estacao_dormir.papel_a = "dormir"
	estacao_dormir.papel_b = "dormir"
	estacao_dormir.sugerir = false
	estacao_dormir.position = Lugares.PORTA
	mundo.add_child(estacao_dormir)
	estacao_dormir.prontos.connect(_dormir)


func _comecar_tarefa(a: Jogador, b: Jogador, t: Tarefa) -> void:
	if ocupado or tarefa_atual != null:
		return
	tarefa_atual = t
	Jogo.ultimo_papel_a = a.numero
	t.comecar(a, b)


func _tarefa_terminou(t: Tarefa) -> void:
	ocupado = true
	travar(true)
	var foto: Image = null
	if t.overlay != null:
		foto = await tirar_foto()
		t.overlay.queue_free()
		t.overlay = null
	t.encerrar()
	travar(true)
	await mostrar_toca_aqui()
	Jogo.concluir(t.id)
	tarefa_atual = null
	colorir(t.id)
	hud.atualizar()
	for j in jogadores:
		j.comemorar()
	if foto == null:
		await get_tree().create_timer(1.7).timeout
		foto = await tirar_foto()
	Jogo.guardar_foto(foto, Jogo.NOMES[t.id])
	if t.id == "colher":
		await _ir_para_festa()
		return
	travar(false)
	ocupado = false
	if Jogo.dia_completo():
		await hud.falar(ELOGIOS.get(t.id, "Muito bem!"))
		hud.falar("Tudo pronto por hoje! Agora os dois na porta de casa, para dormir.")
		estacao_dormir.ativa = true
	else:
		hud.falar(ELOGIOS.get(t.id, "Muito bem!"))


func _dormir(_a: Jogador, _b: Jogador) -> void:
	ocupado = true
	travar(true)
	await hud.escurecer("Boa noite!")
	Jogo.proximo_dia()
	get_tree().reload_current_scene()


func _ir_para_festa() -> void:
	await hud.escurecer("Festa da Colheita!")
	await get_tree().create_timer(0.6).timeout
	get_tree().change_scene_to_file("res://cenas/festa.tscn")


func mostrar_toca_aqui() -> void:
	var toca := TocaAqui.new()
	add_child(toca)
	await toca.pronto


func tirar_foto() -> Image:
	var img: Image = null
	if DisplayServer.get_name() != "headless":
		hud.visible = false
		await RenderingServer.frame_post_draw
		img = get_viewport().get_texture().get_image()
		hud.visible = true
	if img == null or img.is_empty():
		img = Image.create(320, 180, false, Image.FORMAT_RGB8)
		img.fill(Color(0.42, 0.75, 0.19))
	else:
		img.resize(320, 180, Image.INTERPOLATE_BILINEAR)
	return img


func travar(sim: bool) -> void:
	for j in jogadores:
		if j.visible:
			j.pode_mover = not sim


func colorir(id: String) -> void:
	for nome in Jogo.ZONAS_DA_TAREFA.get(id, []):
		if not _zonas.has(nome):
			continue
		var cinza: ColorRect = _zonas[nome]
		_zonas.erase(nome)
		var mat := cinza.material as ShaderMaterial
		var tw := create_tween()
		tw.tween_method(func(v: float): mat.set_shader_parameter("cinza", v), 1.0, 0.0, 1.6)
		tw.tween_callback(cinza.queue_free)


# ================================================================== mudanças no mapa
func consertar_poco() -> void:
	_poco.texture = Jogo.tex("res://assets/sprites/objetos/poco.png")


func acender_fogao() -> void:
	_pilha_lenha.visible = true
	_fumaca.emitting = true


func desatolar_trator() -> void:
	if _trator_atolado != null:
		_trator_atolado.queue_free()
		_trator_atolado = null
	_criar_trator_parado()


func mostrar_trator_parado(sim: bool) -> void:
	if _trator_parado == null:
		return
	_trator_parado.visible = sim
	(_trator_parede.get_child(0) as CollisionShape2D).set_deferred("disabled", not sim)


func encher_cocho() -> void:
	_cocho.texture = Jogo.tex("res://assets/sprites/extras/cocho_cheio.png")


func encher_bebedouro() -> void:
	_bebedouro.texture = Jogo.tex("res://assets/sprites/extras/bebedouro_cheio.png")


func pedra_perto(pos: Vector2, raio: float) -> Node2D:
	var melhor: Node2D = null
	var menor := raio
	for p in pedras:
		var d := p.global_position.distance_to(pos)
		if d <= menor:
			menor = d
			melhor = p
	return melhor


func tirar_pedra(p: Node2D) -> void:
	pedras.erase(p)
	Sons.tocar("arrancar")
	(p.get_child(0) as CollisionShape2D).set_deferred("disabled", true)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(p, "position", p.position + Vector2(randf_range(-20, 20), -26), 0.35)
	tw.tween_property(p, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(p.queue_free)


# ================================================================== a cada frame
func _process(delta: float) -> void:
	_tempo += delta
	for id in tarefas:
		var t: Tarefa = tarefas[id]
		var deve := not ocupado and tarefa_atual == null and not Jogo.feita(id) and t.pode_comecar()
		if t.estacao.ativa != deve:
			t.estacao.ativa = deve
	_vovo.offset.y = -1.0 if fmod(_tempo, 1.2) < 0.6 else 0.0
	_atualizar_seta()


func _atualizar_seta() -> void:
	var alvo: Variant = null
	if not ocupado:
		if tarefa_atual != null:
			alvo = tarefa_atual.ponto_guia()
		elif estacao_dormir.ativa:
			alvo = estacao_dormir.global_position
		else:
			for id in Jogo.tarefas_do_dia():
				if Jogo.feita(id) or not tarefas.has(id):
					continue
				alvo = tarefas[id].ponto_guia()
				if alvo != null:
					break
	_seta.visible = alvo != null
	if alvo != null:
		_seta.position = (alvo as Vector2) + Vector2(0, -30 + 3.0 * sin(_tempo * 6.0))


## Atalhos para testar: F1 a F5 começam direto no dia escolhido.
func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo:
		var teclas := [KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5]
		var i := teclas.find((evento as InputEventKey).keycode)
		if i >= 0:
			Jogo.pular_para_dia(i + 1)
			get_tree().reload_current_scene()
