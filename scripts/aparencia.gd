class_name Aparencia
## Ponto ÚNICO que diz qual imagem usar para cada personagem.
## Todo lugar que mostra um neto ou a Vovó (mapa, minijogos, telas) pede aqui,
## em vez de escrever o caminho do arquivo. Assim, trocar a arte é mexer só aqui.
##
## Poses: "frente" (olhando para baixo), "costas", "lado" (olhando para a direita).

const POSES := {"frente": "baixo_parado", "costas": "cima_parado", "lado": "lado_parado"}


## Imagem parada do neto do jogador n (1 = laranja, 2 = azul).
static func neto(n: int, pose := "lado") -> Texture2D:
	return Jogo.tex("res://assets/sprites/personagens/p%d_%s.png" % [n, POSES[pose]])


## Imagem parada da Vovó.
static func vovo(_pose := "frente") -> Texture2D:
	return Jogo.tex("res://assets/sprites/personagens/vovo_zefa.png")


## Põe a origem do Sprite2D nos PÉS do personagem (centro embaixo),
## qualquer que seja o tamanho da imagem. Use depois de trocar a textura.
static func ajustar_pes(s: Sprite2D) -> void:
	s.centered = false
	var tam := s.texture.get_size()
	s.offset = Vector2(-tam.x / 2.0, -tam.y)
