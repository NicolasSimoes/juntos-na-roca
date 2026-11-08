extends Node
## Autoload "Jogo": guarda tudo o que passa de uma cena para outra
## (o dia, as tarefas feitas, a cesta do time, a horta e as fotos do álbum).

signal cesta_mudou

const COR := {1: Color("eb8931"), 2: Color("5b8dee")}   # 1 = laranja, 2 = azul
const ULTIMO_DIA := 5

const DIAS := {
	1: ["poco", "lenha"],
	2: ["trator", "arar"],
	3: ["plantar", "galinhas"],
	4: ["animais", "pesca", "cuidar_horta"],
	5: ["colher"],
}

const NOMES := {
	"poco": "Consertar o poço",
	"lenha": "Serrar a lenha",
	"trator": "Tirar o trator da lama",
	"arar": "Afofar a terra",
	"plantar": "Plantar a horta",
	"galinhas": "Recolher as galinhas",
	"animais": "Cuidar dos animais",
	"pesca": "Pescar no lago",
	"cuidar_horta": "Cuidar da horta",
	"colher": "Colher e levar o jerimum",
}

const ICONES := {
	"poco": "res://assets/sprites/objetos/poco.png",
	"lenha": "res://assets/sprites/extras/lenha.png",
	"trator": "res://assets/sprites/extras/trator.png",
	"arar": "res://assets/sprites/objetos/pedra.png",
	"plantar": "res://assets/sprites/extras/semente.png",
	"galinhas": "res://assets/sprites/personagens/galinha_1.png",
	"animais": "res://assets/sprites/personagens/vaca_mimosa.png",
	"pesca": "res://assets/sprites/objetos/peixe.png",
	"cuidar_horta": "res://assets/sprites/extras/gota.png",
	"colher": "res://assets/sprites/objetos/jerimum.png",
}

# Áreas do mapa que ficam coloridas quando a tarefa termina.
const ZONAS_DA_TAREFA := {
	"poco": ["quintal"],
	"lenha": ["mata", "casa"],
	"trator": ["galpao"],
	"arar": ["campo"],
	"galinhas": ["galinheiro"],
	"animais": ["curral"],
	"pesca": ["lago"],
	"colher": ["porteira"],
}

const ITENS := ["lenha", "ovos", "leite", "peixe", "milho", "feijao", "jerimum"]
const ICONE_ITEM := {
	"lenha": "res://assets/sprites/extras/lenha.png",
	"ovos": "res://assets/sprites/extras/ovos.png",
	"leite": "res://assets/sprites/extras/balde_leite.png",
	"peixe": "res://assets/sprites/objetos/peixe.png",
	"milho": "res://assets/sprites/extras/milho.png",
	"feijao": "res://assets/sprites/extras/feijao.png",
	"jerimum": "res://assets/sprites/objetos/jerimum.png",
}

# Horta: 12 covas (3 fileiras de 4). fase: 0 vazia, 1 semente, 2 broto,
# 3 crescendo, 4 madura, 5 colhida.
const TIPOS_HORTA := ["milho", "feijao", "jerimum"]

var dia := 1
var feitas: Array[String] = []
var cesta := {}
var horta: Array[Dictionary] = []
var fotos: Array[Dictionary] = []
var ultimo_papel_a := 2   # quem fez o papel da esquerda por último (para sugerir a troca)
var _texturas := {}


func _ready() -> void:
	novo_jogo()


func novo_jogo() -> void:
	dia = 1
	feitas.clear()
	fotos.clear()
	ultimo_papel_a = 2
	cesta = {}
	for item in ITENS:
		cesta[item] = 0
	horta.clear()
	for i in 12:
		horta.append({"fase": 0, "molhado": false, "mato": false})


# ------------------------------------------------------------------ tarefas e dias
func tarefas_do_dia() -> Array:
	return DIAS.get(dia, [])


func feita(id: String) -> bool:
	return id in feitas


func dia_completo() -> bool:
	for id in tarefas_do_dia():
		if not feita(id):
			return false
	return true


func concluir(id: String) -> void:
	if not feita(id):
		feitas.append(id)


func zonas_coloridas() -> Array[String]:
	var lista: Array[String] = []
	for id in feitas:
		for z in ZONAS_DA_TAREFA.get(id, []):
			lista.append(z)
	return lista


## Passa para o dia seguinte e faz a horta crescer durante a noite.
func proximo_dia() -> void:
	dia += 1
	if dia == 4:
		# Os brotos amanhecem com sede e nasce mato em algumas covas.
		var com_mato := [0, 3, 5, 6, 10]
		for i in horta.size():
			horta[i]["molhado"] = false
			horta[i]["mato"] = i in com_mato and horta[i]["fase"] >= 2
		if feita("galinhas"):
			adicionar("ovos", 6)
	if dia == 5:
		for c in horta:
			if c["fase"] == 3:
				c["fase"] = 4
			c["molhado"] = false
			c["mato"] = false


## Atalho para testar: começa direto no dia escolhido (F1 a F5 no jogo).
func pular_para_dia(alvo: int) -> void:
	novo_jogo()
	while dia < alvo:
		for id in tarefas_do_dia():
			concluir(id)
			match id:
				"lenha":
					adicionar("lenha", 5)
				"plantar":
					for c in horta:
						c["fase"] = 2
						c["molhado"] = true
				"cuidar_horta":
					for c in horta:
						c["fase"] = 3
						c["mato"] = false
						c["molhado"] = true
				"animais":
					adicionar("leite", 1)
				"pesca":
					adicionar("peixe", 3)
		proximo_dia()


# ------------------------------------------------------------------ cesta e fotos
func adicionar(item: String, quantidade := 1) -> void:
	cesta[item] = cesta.get(item, 0) + quantidade
	cesta_mudou.emit()


func guardar_foto(imagem: Image, legenda: String) -> void:
	fotos.append({"textura": ImageTexture.create_from_image(imagem), "legenda": legenda})


# ------------------------------------------------------------------ controles
func acao(n: int) -> String:
	return "p%d_acao" % n


func apertou(n: int) -> bool:
	return Input.is_action_just_pressed(acao(n))


func segurando(n: int) -> bool:
	return Input.is_action_pressed(acao(n))


func direcao(n: int) -> Vector2:
	return Input.get_vector("p%d_esquerda" % n, "p%d_direita" % n, "p%d_cima" % n, "p%d_baixo" % n)


func apertou_esquerda(n: int) -> bool:
	return Input.is_action_just_pressed("p%d_esquerda" % n)


func apertou_direita(n: int) -> bool:
	return Input.is_action_just_pressed("p%d_direita" % n)


## Texto curto com as teclas de cada jogador.
func tecla_acao(n: int) -> String:
	return "Espaço" if n == 1 else "Enter"


func teclas_lado(n: int) -> String:
	return "A / D" if n == 1 else "Setas"


## Quem a Vovó sugere para o círculo da esquerda (para os papéis se revezarem).
func sugerido_a() -> int:
	return 1 if ultimo_papel_a == 2 else 2


# ------------------------------------------------------------------ texturas
func tex(caminho: String) -> Texture2D:
	if not _texturas.has(caminho):
		_texturas[caminho] = load(caminho)
	return _texturas[caminho]
