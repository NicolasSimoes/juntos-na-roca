class_name Lugares
## Onde fica cada coisa no mapa, em pixels (cada bloco do chão tem 16 x 16).
## A tela tem 640 x 360. Mudou algo de lugar? Mude aqui.

# Casa da Vovó
const CASA := Vector2(288, 4)              # canto de cima/esquerda do desenho
const PORTA := Vector2(320, 78)            # estação de dormir
const VOVO := Vector2(366, 64)
const INICIO_J1 := Vector2(304, 100)
const INICIO_J2 := Vector2(336, 100)
const PILHA_LENHA := Vector2(380, 62)
const DESTINO_LENHA := Rect2(352, 34, 64, 52)
const CHAMINE := Vector2(340, 10)

# Poço (quintal)
const POCO := Vector2(256, 124)            # canto do desenho (16 x 16)
const POCO_CENTRO := Vector2(264, 136)
const ESTACAO_POCO := Vector2(264, 158)
const BALDE := Vector2(290, 140)

# Mata
const ARVORES := [Vector2(0, 0), Vector2(40, 14), Vector2(88, 0), Vector2(136, 10),
		Vector2(186, 2), Vector2(8, 52), Vector2(52, 44)]
const TORA := Vector2(144, 80)
const ESTACAO_LENHA := Vector2(144, 102)
const TABUAS := Vector2(108, 94)

# Galpão e lama
const GALPAO := Vector2(32, 104)
const CORDA := Vector2(60, 164)
const SACO_MILHO := Vector2(78, 164)
const TRATOR_ATOLADO := Vector2(128, 132)
const ESTACAO_TRATOR := Vector2(144, 178)
const TRATOR_PARADO := Vector2(224, 232)   # base (pé) do trator estacionado
const ESTACAO_ARAR := Vector2(224, 252)

# Campo / horta (em blocos)
const CAMPO := Rect2i(2, 15, 10, 5)
const PEDRAS := [Vector2i(3, 15), Vector2i(6, 16), Vector2i(9, 15), Vector2i(4, 18),
		Vector2i(8, 19), Vector2i(10, 17)]
const ESTACAO_HORTA := Vector2(232, 286)
const JERIMUM_GIGANTE := Vector2(112, 286)

# Galinhas
const GALINHEIRO := Vector2(496, 0)
const CERCADO := Rect2(480, 32, 112, 64)   # parte de dentro do cercado
const PORTAO_GALINHAS := Vector2(536, 104)
const ESTACAO_GALINHAS := Vector2(536, 126)
const GALINHAS_SOLTAS := [Vector2(420, 140), Vector2(300, 230), Vector2(400, 300), Vector2(240, 60)]

# Curral
const CURRAL := Rect2(512, 160, 96, 48)    # parte de dentro do curral
const VACA := Vector2(548, 172)
const COCHO := Vector2(520, 192)
const BEBEDOURO := Vector2(568, 192)
const ESTACAO_ANIMAIS := Vector2(464, 212)

# Lago
const PIER_X := 544
const ESTACAO_PESCA := Vector2(552, 236)

# Porteira (festa)
const PORTEIRA := Vector2(304, 336)
const DESTINO_FESTA := Rect2(288, 300, 64, 56)

# Áreas que começam cinza e ficam coloridas
const ZONAS := {
	"mata": Rect2(0, 0, 208, 104),
	"galpao": Rect2(0, 104, 208, 136),
	"campo": Rect2(0, 240, 208, 120),
	"casa": Rect2(208, 0, 240, 112),
	"quintal": Rect2(208, 112, 240, 128),
	"porteira": Rect2(208, 240, 240, 120),
	"galinheiro": Rect2(448, 0, 192, 112),
	"curral": Rect2(448, 112, 192, 112),
	"lago": Rect2(448, 224, 192, 136),
}
