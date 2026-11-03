class_name Horta
extends Node2D
## Desenha as 12 covas da horta (o estado fica em Jogo.horta).
## Fileira de cima: milho. Do meio: feijão. De baixo: jerimum.

const COLUNAS := [4, 6, 8, 10]      # em blocos
const LINHAS := [15, 17, 19]

var chao: TileMapLayer
var alvos := {}        # numero do jogador -> índice da cova que ele está mirando
var mostrar_sede := false
var _tempo := 0.0


func _ready() -> void:
	z_index = 2


func centro(i: int) -> Vector2:
	var coluna: int = COLUNAS[i % 4]
	var linha: int = LINHAS[floori(i / 4.0)]
	return Vector2(coluna * 16 + 8, linha * 16 + 8)


func tipo(i: int) -> String:
	return Jogo.TIPOS_HORTA[floori(i / 4.0)]


func cova(i: int) -> Dictionary:
	return Jogo.horta[i]


## Cova mais perto dos pés do jogador (ou -1 se nenhuma estiver perto).
func cova_perto(pos: Vector2) -> int:
	var melhor := -1
	var menor := 13.0
	for i in Jogo.horta.size():
		var d := pos.distance_to(centro(i) + Vector2(0, 4))
		if d < menor:
			menor = d
			melhor = i
	return melhor


## Pinta o chão das covas regadas de terra molhada.
func atualizar_chao() -> void:
	if chao == null or not Jogo.feita("arar"):
		return
	for i in Jogo.horta.size():
		var c := centro(i)
		var bloco := Vector2i(floori(c.x / 16.0), floori(c.y / 16.0))
		var molhado: bool = cova(i)["molhado"]
		chao.set_cell(bloco, 0, Vector2i(5 if molhado else 2, 0))


func _process(delta: float) -> void:
	_tempo += delta
	queue_redraw()


func _draw() -> void:
	for i in Jogo.horta.size():
		var c := centro(i)
		var dados := cova(i)
		var fase: int = dados["fase"]
		var t := tipo(i)
		var caminho := ""
		match fase:
			1:
				caminho = "res://assets/sprites/extras/semente.png"
			2, 3, 4:
				var n := fase - 1
				if t == "milho":
					caminho = "res://assets/sprites/objetos/milho_fase%d.png" % n
				else:
					caminho = "res://assets/sprites/extras/%s_fase%d.png" % [t, n]
		if caminho != "":
			draw_texture(Jogo.tex(caminho), c - Vector2(8, 10))
		if dados["mato"]:
			draw_texture(Jogo.tex("res://assets/sprites/extras/mato.png"), c - Vector2(8, 8))
		if mostrar_sede and fase in [2, 3] and not dados["molhado"]:
			var y := -20.0 - 2.0 * sin(_tempo * 4.0 + i)
			draw_texture(Jogo.tex("res://assets/sprites/extras/gota.png"), c + Vector2(-8, y))
		if fase == 4:
			var brilho := 0.5 + 0.5 * sin(_tempo * 5.0 + i)
			draw_circle(c + Vector2(6, -10), 1.5, Color(1, 1, 0.6, brilho))
	for n in alvos:
		var i: int = alvos[n]
		if i >= 0:
			draw_rect(Rect2(centro(i) - Vector2(9, 9), Vector2(18, 18)), Jogo.COR[n], false, 1.5)
