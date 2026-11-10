"""Gera as poucas imagens do mapa que o pacote Super Retro World não tem prontas.

Uso: python3 ferramentas/gerar_recortes_mapa.py .

- assets/recortes/mapa/anel_pes.png : anel branco sob os pés de cada neto
  (o jogo pinta com a cor do jogador).
- assets/recortes/mapa/campo_atlas.png : 8 blocos de 16x16 na MESMA ordem do
  atlas antigo do chão (o código das tarefas usa esses números):
  0 grama, 1 caminho, 2 terra arada, 3 água, 4 lama, 5 terra arada molhada,
  6 grama 2, 7 campo sem arar. Todos são recortes do pacote (a terra arada
  ganha os sulcos do arado por cima).
"""
import os
import sys

from PIL import Image, ImageDraw

PROJ = sys.argv[1]
PACOTE = os.path.join(PROJ, "assets", "SuperRetroWorld_Farming", "Tilesets")
SAIDA = os.path.join(PROJ, "assets", "recortes", "mapa")
os.makedirs(SAIDA, exist_ok=True)

tileset = Image.open(os.path.join(PACOTE, "SuperRetroWorld_Farming_Tileset.png")).convert("RGBA")
autotile = Image.open(os.path.join(PACOTE, "SuperRetroWorld_Farming_Autotile.png")).convert("RGBA")
anim = Image.open(os.path.join(PACOTE, "SuperRetroWorld_Farming_Autotile_Anim.png")).convert("RGBA")


def bloco(img, x, y):
    return img.crop((x * 16, y * 16, x * 16 + 16, y * 16 + 16))


def escurecer(img, f):
    px = img.load()
    out = img.copy()
    po = out.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            po[x, y] = (int(r * f), int(g * f), int(b * f), a)
    return out


def sulcos(img):
    """Desenha as linhas do arado: faixa escura com brilho embaixo."""
    out = img.copy()
    d = ImageDraw.Draw(out)
    for y in (2, 7, 12):
        d.line([(0, y), (15, y)], fill=(92, 52, 38, 255))
        d.line([(0, y + 1), (15, y + 1)], fill=(110, 64, 46, 255))
        d.line([(0, y + 2), (15, y + 2)], fill=(176, 112, 82, 255))
    return out


grama = bloco(tileset, 18, 30)
grama2 = bloco(tileset, 27, 30)
caminho = bloco(autotile, 10, 1)
terra = bloco(autotile, 9, 22)
arada = sulcos(terra)
agua = bloco(anim, 10, 5)
campo = bloco(autotile, 10, 5)
lama = escurecer(terra, 0.75)
molhada = escurecer(arada, 0.72)

atlas = Image.new("RGBA", (128, 16))
for i, b in enumerate([grama, caminho, arada, agua, lama, molhada, grama2, campo]):
    atlas.paste(b, (i * 16, 0))
atlas.save(os.path.join(SAIDA, "campo_atlas.png"))

anel = Image.new("RGBA", (16, 8))
d = ImageDraw.Draw(anel)
d.ellipse([0, 0, 15, 7], fill=(255, 255, 255, 70), outline=(255, 255, 255, 255), width=1)
anel.save(os.path.join(SAIDA, "anel_pes.png"))
print("ok")
