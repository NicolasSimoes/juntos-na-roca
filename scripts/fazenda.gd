extends Node2D
## A fazenda: cuida da ordem das coisas no dia:
## estação -> tarefa -> foto -> "toca aqui" -> área colorida -> próxima tarefa -> dormir.
##
## O MAPA (chão, casa, árvores, cercas, poço, pedras...) é a cena cenas/fazenda.tscn,
## montada no editor com a arte do pacote Super Retro World. Este script não desenha
## nada: ele só ajusta o mapa ao dia (_aplicar_estado_do_dia) e cria o que é do dia
## (horta, netos, galinhas, tarefas e o HUD).

const CENA_JOGADOR := preload("res://cenas/jogador.tscn")
const POCO_CONSERTADO := preload("res://assets/recortes/mapa/poco_consertado.tres")

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

## Camada do campo (terra arada). As tarefas de arar e plantar mexem nela:
## bloco 2 = terra arada, 5 = arada e molhada (vazio = campo sem arar).
@onready var chao: TileMapLayer = %Campo
## Onde ficam as coisas que andam ou mudam (netos, tarefas, pedras, horta...).
@onready var mundo: Node2D = %Mundo
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
var _tempo := 0.0

# Peças do cenário que mudam conforme o dia (nomes únicos na cena).
@onready var _seta: Sprite2D = %Seta
@onready var _poco: Sprite2D = %Poco
@onready var _trator_parado: Sprite2D = %TratorParado
@onready var _trator_parede: StaticBody2D = %ParedeTratorParado
@onready var _trator_atolado: Sprite2D = %TratorAtolado
@onready var _fumaca: CPUParticles2D = %Fumaca
@onready var _pilha_lenha: Sprite2D = %PilhaLenha
@onready var _cocho: Sprite2D = %Cocho
@onready var _bebedouro: Sprite2D = %Bebedouro
@onready var _vovo: AnimatedSprite2D = %Vovo


func _ready() -> void:
	Sons.musica("musica_fazenda")
	_aplicar_estado_do_dia()
	horta = Horta.new()
	horta.chao = chao
	mundo.add_child(horta)
	horta.atualizar_chao()
	_soltar_galinhas()
	_montar_jogadores()
	hud = Hud.new()
	add_child(hud)
	_criar_tarefas()
	_criar_estacao_dormir()
	travar(true)
	await hud.mostrar_dia(Jogo.dia, _subtitulo_do_dia())
	await hud.conversa(Textos.FALAS_DO_DIA.get(Jogo.dia, []))
	travar(false)
	ocupado = false


func _subtitulo_do_dia() -> String:
	var nomes: Array[String] = []
	for id in Jogo.tarefas_do_dia():
		nomes.append(Jogo.NOMES[id])
	return " · ".join(nomes)


# ================================================================== o mapa no dia de hoje
## Ajusta o cenário da cena ao que já foi feito (Jogo guarda as tarefas feitas).
func _aplicar_estado_do_dia() -> void:
	var arado := Jogo.feita("arar")
	if arado:
		for x in range(Lugares.CAMPO.position.x, Lugares.CAMPO.end.x):
			for y in range(Lugares.CAMPO.position.y, Lugares.CAMPO.end.y):
				chao.set_cell(Vector2i(x, y), 0, Vector2i(2, 0))
	if Jogo.feita("poco"):
		consertar_poco()
	_pilha_lenha.visible = Jogo.feita("lenha")
	_fumaca.emitting = Jogo.feita("lenha")
	if Jogo.feita("animais"):
		encher_cocho()
		encher_bebedouro()
	if Jogo.feita("trator"):
		_trator_atolado.queue_free()
		_trator_atolado = null
	mostrar_trator_parado(Jogo.feita("trator"))
	for p in %Pedras.get_children():
		if arado:
			p.queue_free()
		else:
			pedras.append(p)
	var coloridas := Jogo.zonas_coloridas()
	for cinza in %Zonas.get_children():
		if String(cinza.name) in coloridas:
			cinza.queue_free()
		else:
			_zonas[String(cinza.name)] = cinza
	_vovo.play("parado_baixo")


func _soltar_galinhas() -> void:
	for p in Lugares.GALINHAS_SOLTAS:
		var g := Galinha.new()
		g.cercado = Lugares.CERCADO
		g.position = p
		mundo.add_child(g)
		galinhas.append(g)
		if Jogo.feita("galinhas"):
			g.colocar_no_cercado()


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
		await hud.falar(Textos.ELOGIOS.get(t.id, "Muito bem!"))
		hud.falar("Tudo pronto por hoje! Agora os dois na porta de casa, para dormir.")
		estacao_dormir.ativa = true
	else:
		hud.falar(Textos.ELOGIOS.get(t.id, "Muito bem!"))


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
	_poco.texture = POCO_CONSERTADO


func acender_fogao() -> void:
	_pilha_lenha.visible = true
	_fumaca.emitting = true


func desatolar_trator() -> void:
	if _trator_atolado != null:
		_trator_atolado.queue_free()
		_trator_atolado = null
	mostrar_trator_parado(true)


func mostrar_trator_parado(sim: bool) -> void:
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
