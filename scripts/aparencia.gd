class_name Aparencia
## Ponto ÚNICO que diz qual imagem usar para cada personagem.
## Todo lugar que mostra um neto ou a Vovó (mapa, minijogos, telas) pede aqui,
## em vez de escrever o caminho do arquivo. Assim, trocar a arte é mexer só aqui.
##
## A arte vem do pacote Super Retro World (Characters/Characters/chara_N.png).
## Cada folha tem 3 colunas x 4 linhas de quadros de 16 x 20 pixels:
##   linha 0 = de frente, 1 = olhando para a esquerda,
##   linha 2 = olhando para a direita, 3 = de costas.
##   coluna 1 = parado; colunas 0 e 2 = os passos da caminhada.
##
## Poses aceitas em neto() e vovo():
##   "frente", "costas", "lado" (olhando para a direita), "esquerda",
##   "passo1", "passo2" (andando de lado), "pulo", "mao", "toca",
##   "comemora1", "comemora2".
## O pacote não tem pose de pular ou de bater a mão: elas reaproveitam
## quadros parecidos, e quem usa faz o resto com movimento (pulo, giro).

const PASTA := "res://assets/SuperRetroWorld_Farming/Characters/Characters/"
const LARGURA := 16
const ALTURA := 20

## Qual personagem do pacote é cada um.
const FOLHA_NETO := {1: "chara_9.png", 2: "chara_6.png"}   # 1 = laranja, 2 = azul
const FOLHA_VOVO := "chara_1.png"

## pose -> [linha, coluna] na folha
const POSES := {
	"frente": [0, 1], "costas": [3, 1], "lado": [2, 1], "esquerda": [1, 1],
	"passo1": [2, 0], "passo2": [2, 2],
	"pulo": [2, 0], "mao": [2, 2], "toca": [2, 2],
	"comemora1": [0, 0], "comemora2": [0, 2],
}

static var _cache := {}


## Imagem parada do neto do jogador n (1 = laranja, 2 = azul).
static func neto(n: int, pose := "lado") -> Texture2D:
	return _quadro(FOLHA_NETO[n], POSES[pose][0], POSES[pose][1])


## Imagem parada da Vovó.
static func vovo(pose := "frente") -> Texture2D:
	return _quadro(FOLHA_VOVO, POSES[pose][0], POSES[pose][1])


## Animações prontas do neto (as mesmas que o Jogador usa no mapa).
static func quadros_neto(n: int) -> SpriteFrames:
	return load("res://assets/animacoes/neto_%d.tres" % n)


## Animações prontas da Vovó.
static func quadros_vovo() -> SpriteFrames:
	return load("res://assets/animacoes/vovo.tres")


## Um quadro de 16 x 20 recortado da folha (AtlasTexture: aponta para um
## pedaço da imagem grande, sem copiar pixels). Guardado em cache.
static func _quadro(folha: String, linha: int, coluna: int) -> Texture2D:
	var chave := "%s:%d:%d" % [folha, linha, coluna]
	if not _cache.has(chave):
		var t := AtlasTexture.new()
		t.atlas = load(PASTA + folha)
		t.region = Rect2(coluna * LARGURA, linha * ALTURA, LARGURA, ALTURA)
		_cache[chave] = t
	return _cache[chave]


## Põe a origem do Sprite2D nos PÉS do personagem (centro embaixo),
## qualquer que seja o tamanho da imagem. Use depois de trocar a textura.
static func ajustar_pes(s: Sprite2D) -> void:
	s.centered = false
	var tam := s.texture.get_size()
	s.offset = Vector2(-tam.x / 2.0, -tam.y)
