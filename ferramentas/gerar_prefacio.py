"""Arte do prefácio na roça: a linha do horizonte (serra, morros, casinha da Vovó,
galpão, cata-vento e árvores) e o girassol que passa ao lado da cerca.

Uso: python3 gerar_prefacio.py <pasta do projeto godot>
"""
import math
import os
import random
import sys

from PIL import Image, ImageDraw

PROJ = sys.argv[1]
OUT = os.path.join(PROJ, "assets", "sprites", "menu")
os.makedirs(OUT, exist_ok=True)
rng = random.Random(7)
T = (0, 0, 0, 0)
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def cor(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


W, H = 640, 64          # o fundo da imagem fica exatamente na linha do horizonte
CASA_X = 404            # centro da casinha (o prefácio dá zoom aqui no final)


def horizonte():
    img = Image.new("RGBA", (W, H), T)
    px = img.load()
    d = ImageDraw.Draw(img)
    # serra bem longe
    serra, serra_luz = cor("9a8fc8"), cor("b9b0e0")
    for x in range(W):
        a = 16 + 8 * math.sin(x / 41.0) + 5 * math.sin(x / 13.0 + 1.1) + 3 * math.sin(x / 6.0)
        topo = H - 14 - int(a)
        for y in range(max(0, topo), H):
            px[x, y] = serra_luz if y - topo < 2 else serra
    # morros verdes
    verde, verde_c = cor("5fa344"), cor("7cc25a")
    topos = []
    for x in range(W):
        a = 12 + 5 * math.sin(x / 57.0 + 0.6) + 3 * math.sin(x / 19.0)
        topos.append(H - int(a))
    for x in range(W):
        for y in range(topos[x], H):
            limiar = (BAYER[y % 4][x % 4] + 0.5) / 16.0
            px[x, y] = verde_c if (y - topos[x]) < 2 + 2 * limiar else verde
    # árvores redondinhas
    for x in list(range(12, W, 23)):
        x += rng.randint(-6, 6)
        if abs(x - CASA_X) < 40 or abs(x - 470) < 26 or abs(x - 236) < 14:
            continue
        if rng.random() < 0.35:
            continue
        y = topos[min(W - 1, max(0, x))] + 1
        r = rng.randint(4, 6)
        d.rectangle([x, y - 4, x + 1, y], fill=cor("5a3c28"))
        d.ellipse([x - r, y - 4 - 2 * r, x + r + 1, y - 4], fill=cor("3d7f33"))
        d.ellipse([x - r + 2, y - 3 - 2 * r, x + r - 1, y - 7], fill=cor("4f9a3c"))
    # casinha da Vovó
    cx, base = CASA_X, topos[CASA_X] + 2
    parede, parede_s = cor("f3e3c3"), cor("d9c19b")
    telhado, telhado_e = cor("c4533c"), cor("8e3528")
    d.rectangle([cx - 13, base - 14, cx + 13, base], fill=parede)
    d.rectangle([cx + 8, base - 14, cx + 13, base], fill=parede_s)
    d.polygon([(cx - 17, base - 13), (cx, base - 25), (cx + 17, base - 13)], fill=telhado)
    d.line([(cx - 17, base - 13), (cx + 17, base - 13)], fill=telhado_e)
    d.rectangle([cx + 6, base - 27, cx + 9, base - 19], fill=cor("7a3b2a"))
    d.rectangle([cx - 9, base - 10, cx - 5, base - 6], fill=cor("8fc8ef"))
    d.rectangle([cx + 3, base - 10, cx + 7, base - 6], fill=cor("8fc8ef"))
    d.rectangle([cx - 2, base - 9, cx + 1, base], fill=cor("7a4a2e"))
    # galpão vermelho
    gx, gb = 470, topos[470] + 2
    d.rectangle([gx - 11, gb - 12, gx + 11, gb], fill=cor("b0412f"))
    d.polygon([(gx - 13, gb - 11), (gx, gb - 19), (gx + 13, gb - 11)], fill=cor("7d2e22"))
    d.rectangle([gx - 4, gb - 8, gx + 4, gb], fill=cor("f3e3c3"))
    d.line([(gx - 4, gb - 8), (gx + 4, gb)], fill=cor("b0412f"))
    d.line([(gx + 4, gb - 8), (gx - 4, gb)], fill=cor("b0412f"))
    # cata-vento
    vx, vb = 236, topos[236] + 1
    d.line([(vx - 4, vb), (vx, vb - 26)], fill=cor("6b6b78"))
    d.line([(vx + 4, vb), (vx, vb - 26)], fill=cor("6b6b78"))
    d.line([(vx - 3, vb - 8), (vx + 3, vb - 8)], fill=cor("6b6b78"))
    d.line([(vx - 2, vb - 16), (vx + 2, vb - 16)], fill=cor("6b6b78"))
    # as pás do cata-vento são desenhadas girando pelo prefacio.gd
    img.save(os.path.join(OUT, "horizonte.png"))
    with open(os.path.join(OUT, "horizonte_casa.txt"), "w") as f:
        f.write("%d %d %d %d" % (CASA_X, base - 12, vx, vb - 27))


def girassol():
    img = Image.new("RGBA", (16, 32), T)
    d = ImageDraw.Draw(img)
    d.line([(8, 31), (8, 11)], fill=cor("3a7a30"), width=2)
    d.ellipse([2, 18, 8, 22], fill=cor("4f9a3c"))
    d.ellipse([9, 23, 14, 27], fill=cor("4f9a3c"))
    d.ellipse([1, 1, 15, 15], fill=cor("c98a1c"))
    d.ellipse([2, 2, 14, 14], fill=cor("f6c83c"))
    d.ellipse([5, 5, 11, 11], fill=cor("7a482e"))
    d.point([(6, 6), (9, 8)], fill=cor("5a3420"))
    img.save(os.path.join(OUT, "girassol.png"))


horizonte()
girassol()
prev = Image.new("RGBA", (W, 140), cor("f2b08c"))
prev.alpha_composite(Image.open(os.path.join(OUT, "horizonte.png")), (0, 40))
prev = prev.resize((W * 2, 280), Image.NEAREST)
prev.save(sys.argv[2] if len(sys.argv) > 2 else os.path.join(OUT, "previa_horizonte.png"))
print("ok")
