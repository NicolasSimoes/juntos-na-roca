class_name TocaAqui
extends CanvasLayer
## "Toca aqui!": no fim de cada tarefa, os dois apertam AÇÃO ao mesmo tempo.
## Cada neto levanta a mão quando o seu jogador aperta. Quando os dois apertam juntos,
## eles correm um até o outro, pulam, batem as mãos no alto ("PÁ!") e comemoram.

signal pronto

const JANELA := 0.45        # os dois apertos precisam estar a menos disso (segundos)
const ESCALA := 5.0         # tamanho dos netos na tela
const CHAO := 262.0         # altura dos pés
const LONGE := 150.0        # distância do centro onde cada um começa
const MAO := 36.0           # da metade do corpo até a ponta da mão (já na escala)

# linha do tempo da animação (segundos)
const T_CORRER := 0.40
const T_SUBIR := 0.62
const T_SEGURA := 0.80
const T_DESCER := 1.00
const T_FIM := 2.30

var _apertos := {1: -10.0, 2: -10.0}
var _feito := false
var _tempo := 0.0
var _t := -1.0              # tempo desde o "1, 2, 3, já!" (-1 = ainda esperando)
var _som_pulo := false
var _som_toque := false
var _desenho: Control
var _titulo: Label
var _sub: Label
var _confete: CPUParticles2D
var _poeira: Array = []


func _ready() -> void:
	layer = 20
	var fundo := ColorRect.new()
	fundo.color = Color(0.05, 0.04, 0.08, 0.55)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	_desenho = Control.new()
	_desenho.set_anchors_preset(Control.PRESET_FULL_RECT)
	_desenho.draw.connect(_desenhar)
	add_child(_desenho)
	_titulo = Hud.rotulo("Toca aqui!", 28, Color(1, 0.9, 0.45), 6)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.position = Vector2(0, 30)
	_titulo.size = Vector2(640, 40)
	_titulo.pivot_offset = Vector2(320, 20)
	add_child(_titulo)
	_sub = Hud.rotulo("Os dois: AÇÃO juntos!", 12, Color.WHITE, 4)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.position = Vector2(0, 306)
	_sub.size = Vector2(640, 20)
	add_child(_sub)
	_confete = CPUParticles2D.new()
	_confete.emitting = false
	_confete.one_shot = true
	_confete.amount = 110
	_confete.lifetime = 1.8
	_confete.explosiveness = 0.95
	_confete.texture = Jogo.tex("res://assets/sprites/extras/pixel.png")
	_confete.direction = Vector2(0, -1)
	_confete.spread = 180.0
	_confete.initial_velocity_min = 120.0
	_confete.initial_velocity_max = 260.0
	_confete.gravity = Vector2(0, 300)
	_confete.angular_velocity_min = -300.0
	_confete.angular_velocity_max = 300.0
	_confete.scale_amount_min = 1.5
	_confete.scale_amount_max = 3.0
	var cores := Gradient.new()
	cores.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	cores.colors = PackedColorArray([Color("eb8931"), Color("5b8dee"), Color("f0c846"), Color("6abe30"), Color("d93c3c"), Color("ffffff")])
	_confete.color_initial_ramp = cores
	add_child(_confete)


func _process(delta: float) -> void:
	_tempo += delta
	if not _feito:
		for n in [1, 2]:
			if Jogo.apertou(n):
				_apertos[n] = _tempo
				Sons.tocar("pegar", -6.0, 0.9 if n == 1 else 1.1)
		var a: float = _apertos[1]
		var b: float = _apertos[2]
		if absf(a - b) < JANELA and _tempo - minf(a, b) < JANELA + 0.1:
			_feito = true
			_t = 0.0
			_sub.text = ""
		elif (a > 0 or b > 0) and _tempo - maxf(a, b) < 0.9:
			_sub.text = "Juntos! 1, 2, 3, já!"
	else:
		_animar(delta)
	_desenho.queue_redraw()


func _animar(delta: float) -> void:
	_t += delta
	if _t < T_CORRER and randf() < 0.5:
		for item in [-1, 1]:
			var lado: int = item
			var x: float = _x_do_neto(lado) - lado * 30.0
			_poeira.append({"p": Vector2(x, CHAO - 2), "v": Vector2(-lado * randf_range(10, 40), randf_range(-20, -5)), "vida": 0.4})
	if _t >= T_CORRER and not _som_pulo:
		_som_pulo = true
		Sons.tocar("forca", -2.0, 1.3)
	if _t >= T_SUBIR and not _som_toque:
		_som_toque = true
		Sons.tocar("toca_aqui")
		Sons.tocar("toc", 0.0, 1.4)
		_confete.position = _ponto_do_toque()
		_confete.emitting = true
		_titulo.text = "Muito bem!"
	# a tela treme um pouquinho no "PÁ!"
	if _t >= T_SUBIR and _t < T_SUBIR + 0.18:
		offset = Vector2(randf_range(-3, 3), randf_range(-3, 3))
	else:
		offset = Vector2.ZERO
	if _t >= T_DESCER:
		var pulso := 1.0 + 0.08 * absf(sin((_t - T_DESCER) * 8.0))
		_titulo.scale = Vector2(pulso, pulso)
	for p in _poeira:
		p["p"] += p["v"] * delta
		p["vida"] -= delta
	_poeira = _poeira.filter(func(p): return p["vida"] > 0)
	if _t >= T_FIM:
		set_process(false)
		pronto.emit()
		queue_free()


# ------------------------------------------------------------------ posições ao longo do tempo
func _x_do_neto(lado: int) -> float:
	var perto := 320.0 + lado * MAO
	var longe := 320.0 + lado * LONGE
	if _t < 0.0:
		return longe
	var u := clampf(_t / T_CORRER, 0.0, 1.0)
	u = u * u * (3.0 - 2.0 * u)
	return lerpf(longe, perto, u)


func _altura_do_pulo() -> float:
	if _t < T_CORRER:
		return 0.0
	if _t < T_SUBIR:
		var u := (_t - T_CORRER) / (T_SUBIR - T_CORRER)
		return 56.0 * (1.0 - (1.0 - u) * (1.0 - u))
	if _t < T_SEGURA:
		return 56.0 + 3.0 * sin((_t - T_SUBIR) * 12.0)
	if _t < T_DESCER:
		var u := (_t - T_SEGURA) / (T_DESCER - T_SEGURA)
		return 56.0 * (1.0 - u * u)
	return absf(sin((_t - T_DESCER) * 9.0)) * 14.0


func _ponto_do_toque() -> Vector2:
	# a mão fica mais ou menos na linha 10 do quadro (de 20)
	return Vector2(320, CHAO - 56.0 - 10.0 * ESCALA)


## Qual imagem do neto mostrar agora (as poses vêm de scripts/aparencia.gd).
func _quadro(n: int, _lado: int) -> Texture2D:
	if _t < 0.0:
		if _tempo - _apertos[n] < 0.7:
			return Aparencia.neto(n, "mao")
		return Aparencia.neto(n, "lado")
	if _t < T_CORRER:
		return Aparencia.neto(n, ["passo1", "lado", "passo2", "lado"][int(_t * 14.0) % 4])
	if _t < T_SUBIR:
		return Aparencia.neto(n, "pulo")
	if _t < T_SEGURA:
		return Aparencia.neto(n, "toca")
	if _t < T_DESCER:
		return Aparencia.neto(n, "pulo")
	return Aparencia.neto(n, "comemora1" if int((_t - T_DESCER) * 7.0) % 2 == 0 else "comemora2")


# ------------------------------------------------------------------ desenho
func _desenhar() -> void:
	var f := ThemeDB.fallback_font
	for p in _poeira:
		_desenho.draw_circle(p["p"], 3.0 + 4.0 * (0.4 - p["vida"]), Color(0.9, 0.85, 0.7, p["vida"] * 1.5))
	for n in [1, 2]:
		var lado := -1 if n == 1 else 1
		var x := _x_do_neto(lado)
		var y := CHAO - _altura_do_pulo()
		if _t < 0.0:
			y -= 2.0 * absf(sin(_tempo * 3.0 + n))
		# sombra no chão
		var tam_sombra := 1.0 - _altura_do_pulo() / 120.0
		_desenho.draw_set_transform(Vector2(x, CHAO), 0.0, Vector2(1.0, 0.3))
		_desenho.draw_circle(Vector2.ZERO, 30.0 * tam_sombra, Color(0, 0, 0, 0.3))
		# o neto (o da esquerda olha para a direita, o da direita é espelhado)
		var t := _quadro(n, lado)
		var espelho := 1.0 if n == 1 else -1.0
		if _t >= T_DESCER:
			espelho = 1.0
		_desenho.draw_set_transform(Vector2(x, y), 0.0, Vector2(ESCALA * espelho, ESCALA))
		_desenho.draw_texture(t, Vector2(-t.get_width() / 2.0, -t.get_height()))
		_desenho.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# tecla de cada um, enquanto espera
		if _t < 0.0:
			var tecla := Jogo.tecla_acao(n)
			var pos := Vector2(x - 50, CHAO + 26)
			_desenho.draw_string_outline(f, pos, tecla, HORIZONTAL_ALIGNMENT_CENTER, 100, 12, 4, Color.BLACK)
			_desenho.draw_string(f, pos, tecla, HORIZONTAL_ALIGNMENT_CENTER, 100, 12, Jogo.COR[n].lightened(0.3))
			if _tempo - _apertos[n] < 0.7:
				var brilho := Vector2(x - lado * MAO, CHAO - 10.0 * ESCALA)
				_estrela(brilho, 8.0, Color(1, 1, 0.7, 0.9), _tempo * 4.0)
	# o "PÁ!" do toque
	if _t >= T_SUBIR and _t < T_SUBIR + 0.7:
		var u := (_t - T_SUBIR) / 0.7
		var c := _ponto_do_toque()
		_desenho.draw_arc(c, 10.0 + 70.0 * u, 0, TAU, 40, Color(1, 1, 0.8, 1.0 - u), 4.0 * (1.0 - u) + 1.0)
		for k in 10:
			var a := TAU * k / 10.0 + 0.3
			var r0 := 14.0 + 40.0 * u
			var r1 := r0 + 18.0 * (1.0 - u)
			_desenho.draw_line(c + Vector2(r0, 0).rotated(a), c + Vector2(r1, 0).rotated(a), Color(1, 0.95, 0.4, 1.0 - u), 3.0)
		_estrela(c, 22.0 * (1.0 - u * 0.5), Color(1, 1, 1, 1.0 - u), u * 2.0)
		var tam := int(30 + 14 * sin(minf(u * 6.0, PI)))
		var pos := c + Vector2(-60, -44)
		_desenho.draw_string_outline(f, pos, "PÁ!", HORIZONTAL_ALIGNMENT_CENTER, 120, tam, 8, Color(0.25, 0.1, 0.05, 1.0 - u))
		_desenho.draw_string(f, pos, "PÁ!", HORIZONTAL_ALIGNMENT_CENTER, 120, tam, Color(1, 0.95, 0.5, 1.0 - u))
	# estrelinhas na comemoração
	if _t >= T_DESCER:
		for k in 6:
			var a := TAU * k / 6.0 + _t * 1.5
			var p := Vector2(320, 150) + Vector2(150, 0).rotated(a) * Vector2(1.0, 0.45)
			_estrela(p, 6.0 + 3.0 * sin(_t * 8.0 + k), Color(1, 0.95, 0.5, 0.9), _t * 3.0)


func _estrela(c: Vector2, r: float, cor: Color, giro: float) -> void:
	var pts := PackedVector2Array()
	for k in 8:
		var raio := r if k % 2 == 0 else r * 0.35
		pts.append(c + Vector2(raio, 0).rotated(giro + TAU * k / 8.0))
	_desenho.draw_colored_polygon(pts, cor)
