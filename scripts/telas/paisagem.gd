class_name Paisagem
extends Control
## A paisagem do menu e do fim do prefácio: céu, sol, nuvens andando,
## serra, morros, a casa da Vovó, passarinhos e os netos.
## "noite" vai de 0 (dia) a 1 (noite escura) e "descida" empurra tudo para baixo.

const PASTA := "res://assets/sprites/menu/"
const CHAO := 286.0

var noite := 0.0
var descida := 0.0
var mostrar_gente := true
var ceu_alfa := 1.0   # 0 deixa ver o que está atrás (as estrelas do prefácio)
var _tempo := 0.0
var _passaros: Array = []
var _brilhos: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 4:
		_passaros.append({"x": randf_range(0, 640), "y": randf_range(60, 130), "v": randf_range(14, 22), "fase": randf() * TAU})
	for i in 18:
		_brilhos.append({"p": Vector2(randf_range(0, 640), randf_range(150, 300)), "fase": randf() * TAU})


func _process(delta: float) -> void:
	_tempo += delta
	for p in _passaros:
		p["x"] += p["v"] * delta
		if p["x"] > 660:
			p["x"] = -20.0
			p["y"] = randf_range(60, 130)
	queue_redraw()


func _draw() -> void:
	var tinta := Color(1, 1, 1).lerp(Color(0.22, 0.26, 0.5), noite)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if ceu_alfa > 0.0:
		draw_texture(Jogo.tex(PASTA + "ceu.png"), Vector2(0, descida * 0.3), Color(tinta, ceu_alfa))
	var brilho_sol := 0.9 + 0.1 * sin(_tempo * 1.5)
	draw_texture(Jogo.tex(PASTA + "sol.png"), Vector2(470, 150 + descida * 0.5), Color(brilho_sol, brilho_sol, brilho_sol, clampf(1.0 - noite * 1.4, 0.0, 1.0)))
	_faixa_tinta(Jogo.tex(PASTA + "nuvens.png"), 10, 6.0, tinta)
	_faixa_tinta(Jogo.tex(PASTA + "serra.png"), 150, 2.0, tinta)
	_faixa_tinta(Jogo.tex(PASTA + "morros.png"), 196, 5.0, tinta)
	# passarinhos
	for p in _passaros:
		var asa := 3.0 * sin(_tempo * 9.0 + p["fase"])
		var c := Vector2(p["x"], p["y"] + descida)
		draw_line(c, c + Vector2(-5, -asa), Color(0.2, 0.15, 0.25, 1.0 - noite), 1.0)
		draw_line(c, c + Vector2(5, -asa), Color(0.2, 0.15, 0.25, 1.0 - noite), 1.0)
	draw_texture(Jogo.tex(PASTA + "frente.png"), Vector2(0, 160 + descida), tinta)
	if mostrar_gente:
		_gente(tinta)
	# vagalumes / brilhinhos no campo
	for b in _brilhos:
		var a := 0.5 + 0.5 * sin(_tempo * 2.0 + b["fase"])
		var pos: Vector2 = b["p"] + Vector2(3 * sin(_tempo + b["fase"]), descida)
		draw_circle(pos, 1.2, Color(1, 1, 0.7, a * (0.35 + 0.65 * noite)))


func _faixa_tinta(t: Texture2D, y: float, velocidade: float, tinta: Color) -> void:
	var w := t.get_width()
	var x := -fmod(_tempo * velocidade, float(w))
	draw_texture(t, Vector2(x, y + descida), tinta)
	draw_texture(t, Vector2(x + w, y + descida), tinta)


func _gente(tinta: Color) -> void:
	var base := "res://assets/sprites/personagens/"
	var vovo := Jogo.tex(base + "vovo_zefa.png")
	var y := CHAO + descida
	draw_set_transform(Vector2(434, y), 0.0, Vector2(2, 2))
	draw_texture(vovo, Vector2(-8, -24 + (0.5 if fmod(_tempo, 1.4) < 0.7 else 0.0)), tinta)
	# os netos comemoram de vez em quando
	var ciclo := fmod(_tempo, 6.0)
	for item in [1, 2]:
		var n: int = item
		var x := 512.0 + (n - 1) * 34.0
		var quadro := "p%d_baixo_parado.png" % n
		var pulo := 0.0
		if ciclo > 4.6:
			quadro = "p%d_comemora%d.png" % [n, 1 + int(_tempo * 7.0) % 2]
			pulo = absf(sin((ciclo - 4.6) * 9.0)) * 6.0
		draw_set_transform(Vector2(x, y - pulo), 0.0, Vector2(2, 2))
		draw_texture(Jogo.tex(base + quadro), Vector2(-8, -24), tinta)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
