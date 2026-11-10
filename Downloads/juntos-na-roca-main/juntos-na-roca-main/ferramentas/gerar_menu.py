"""Arte do menu e do prefácio: paisagem em camadas (pixel art 640 x 360) e o vaga-lume.

Uso: python3 gerar_menu.py <pasta do projeto godot>
"""
import math
import os
import random
import sys

from PIL import Image, ImageDraw

PROJ = sys.argv[1]
OUT = os.path.join(PROJ, "assets", "sprites", "menu")
os.makedirs(OUT, exist_ok=True)
SPR = os.path.join(PROJ, "assets", "sprites")
rng = random.Random(21)
T = (0, 0, 0, 0)

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def cor(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mistura(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


# ------------------------------------------------------------------ céu (degradê com pontilhado)
def ceu():
    paradas = [(0, cor("2c3a86")), (110, cor("4f6fd0")), (190, cor("8fa8ef")),
               (240, cor("f2c48c")), (275, cor("f59a6a")), (360, cor("f59a6a"))]
    img = Image.new("RGBA", (640, 360))
    px = img.load()
    for y in range(360):
        for i in range(len(paradas) - 1):
            y0, c0 = paradas[i]
            y1, c1 = paradas[i + 1]
            if y0 <= y <= y1:
                t = (y - y0) / max(1, (y1 - y0))
                break
        # quantiza em faixas de 8 tons e pontilha a passagem
        passos = 8
        for x in range(640):
            limiar = (BAYER[y % 4][x % 4] + 0.5) / 16.0
            tq = math.floor(t * passos + limiar) / passos
            px[x, y] = mistura(c0, c1, min(1.0, tq))
    img.save(os.path.join(OUT, "ceu.png"))


# ------------------------------------------------------------------ sol
def sol():
    img = Image.new("RGBA", (96, 96), T)
    d = ImageDraw.Draw(img)
    for r, c in ((46, cor("fff1b8", 40)), (40, cor("fff1b8", 70)), (33, cor("ffe9a0", 120))):
        d.ellipse([48 - r, 48 - r, 48 + r, 48 + r], fill=c)
    d.ellipse([48 - 24, 48 - 24, 48 + 24, 48 + 24], fill=cor("ffe27a"))
    d.ellipse([48 - 20, 48 - 22, 48 + 18, 48 + 16], fill=cor("fff3c4"))
    img.save(os.path.join(OUT, "sol.png"))


# ------------------------------------------------------------------ nuvens
def nuvem(d, cx, cy, larg):
    branco, sombra, borda = cor("fff8f0"), cor("e8d4e8"), cor("c9b2d6")
    bolhas = []
    x = cx - larg // 2
    while x < cx + larg // 2:
        r = rng.randint(7, 15)
        bolhas.append((x, cy - rng.randint(0, 8), r))
        x += rng.randint(8, 14)
    bolhas.append((cx, cy - 12, 16))
    for (bx, by, r) in bolhas:
        d.ellipse([bx - r - 1, by - r - 1, bx + r + 1, by + r + 1], fill=borda)
    for (bx, by, r) in bolhas:
        d.ellipse([bx - r, by - r, bx + r, by + r], fill=sombra)
    for (bx, by, r) in bolhas:
        d.ellipse([bx - r + 1, by - r, bx + r - 2, by + r - 4], fill=branco)
    d.rectangle([cx - larg // 2 - 6, cy + 4, cx + larg // 2 + 6, cy + 9], fill=sombra)


def nuvens():
    img = Image.new("RGBA", (1280, 150), T)
    d = ImageDraw.Draw(img)
    for (cx, cy, l) in ((120, 60, 90), (420, 95, 60), (640, 40, 110), (900, 85, 80), (1150, 55, 70)):
        nuvem(d, cx, cy, l)
        nuvem(d, cx + 1280, cy, l)   # repete para emendar
        nuvem(d, cx - 1280, cy, l)
    img.save(os.path.join(OUT, "nuvens.png"))


# ------------------------------------------------------------------ serra ao longe
def serra():
    w, h = 1280, 130
    img = Image.new("RGBA", (w, h), T)
    px = img.load()
    base, luz = cor("8c7fc0"), cor("b4a8de")
    alturas = []
    for x in range(w):
        a = (40 + 22 * math.sin(x / 70.0) + 14 * math.sin(x / 23.0 + 1.3)
             + 9 * math.sin(x / 11.0 + 0.4) + 18 * math.sin(2 * math.pi * x / w))
        alturas.append(int(a))
    for x in range(w):
        topo = h - alturas[x] - 30
        for y in range(max(0, topo), h):
            c = base
            if y - topo < 3 and alturas[x] >= alturas[x - 1]:
                c = luz
            px[x, y] = c
    img.save(os.path.join(OUT, "serra.png"))


# ------------------------------------------------------------------ morros com arvorezinhas
def morros():
    w, h = 1280, 120
    img = Image.new("RGBA", (w, h), T)
    d = ImageDraw.Draw(img)
    px = img.load()
    verde, verde_c, escuro = cor("4f9a3c"), cor("6dbb4a"), cor("3a7a30")
    topos = []
    for x in range(w):
        a = 50 + 18 * math.sin(2 * math.pi * x / w * 2) + 10 * math.sin(x / 37.0 + 2.0)
        topos.append(h - int(a))
    for x in range(w):
        for y in range(topos[x], h):
            limiar = (BAYER[y % 4][x % 4] + 0.5) / 16.0
            c = verde_c if (y - topos[x]) < 4 + 3 * limiar else verde
            px[x, y] = c
    for i in range(46):
        x = rng.randrange(w)
        y = topos[x] + rng.randint(2, 18)
        r = rng.randint(5, 9)
        d.rectangle([x - 1, y, x + 1, y + r], fill=cor("5a3c28"))
        d.ellipse([x - r, y - r - 4, x + r, y + r - 6], fill=escuro)
        d.ellipse([x - r + 2, y - r - 3, x + r - 4, y + r - 9], fill=cor("4f9a3c"))
    img.save(os.path.join(OUT, "morros.png"))


# ------------------------------------------------------------------ frente: morrinho com a casa, cerca e girassóis
def frente():
    w, h = 640, 200
    img = Image.new("RGBA", (w, h), T)
    d = ImageDraw.Draw(img)
    px = img.load()
    grama, grama_c, grama_e = cor("6abe30"), cor("8fd650"), cor("4f9a3c")
    topos = []
    for x in range(w):
        a = 70 + 16 * math.cos((x - 320) / 210.0) + 3 * math.sin(x / 9.0)
        topos.append(h - int(a))
    for x in range(w):
        for y in range(topos[x], h):
            c = grama
            if y - topos[x] < 3:
                c = grama_c
            elif (x * 7 + y * 3) % 23 == 0:
                c = grama_e
            px[x, y] = c
    # casa da Vovó (2x)
    casa = Image.open(os.path.join(SPR, "estruturas", "casa.png")).convert("RGBA")
    casa = casa.resize((casa.width * 2, casa.height * 2), Image.NEAREST)
    cx = 430
    img.alpha_composite(casa, (cx - casa.width // 2, topos[cx] - casa.height + 14))
    # chaminé
    cham = Image.open(os.path.join(SPR, "extras", "chamine.png")).convert("RGBA").resize((20, 28), Image.NEAREST)
    img.alpha_composite(cham, (cx + 30, topos[cx] - casa.height + 6))
    # cerca
    cerca = Image.open(os.path.join(SPR, "estruturas", "cerca_h.png")).convert("RGBA").resize((32, 32), Image.NEAREST)
    for x in range(0, 300, 32):
        img.alpha_composite(cerca, (x, topos[x + 16] - 18))
    for x in range(530, 640, 32):
        img.alpha_composite(cerca, (x, topos[min(639, x + 16)] - 18))
    # girassóis
    for x in (40, 70, 560, 600, 620):
        y = topos[x] - 4
        d.line([(x, y), (x, y - 22)], fill=cor("3a7a30"), width=2)
        d.ellipse([x - 4, y - 14, x + 2, y - 10], fill=cor("4f9a3c"))
        d.ellipse([x - 7, y - 31, x + 7, y - 17], fill=cor("f6c83c"))
        d.ellipse([x - 3, y - 27, x + 3, y - 21], fill=cor("7a482e"))
    # jerimuns no chão
    jer = Image.open(os.path.join(SPR, "objetos", "jerimum.png")).convert("RGBA").resize((32, 32), Image.NEAREST)
    for x in (130, 168, 520):
        img.alpha_composite(jer, (x, topos[x + 16] - 22))
    img.save(os.path.join(OUT, "frente.png"))
    # guarda a altura do chão no meio (onde ficam os netos)
    with open(os.path.join(OUT, "chao_frente.txt"), "w") as f:
        f.write(str(topos[320]))


# ------------------------------------------------------------------ vaga-lume (cursor do menu), 2 quadros
def vagalume():
    for k in range(2):
        img = Image.new("RGBA", (16, 16), T)
        d = ImageDraw.Draw(img)
        d.ellipse([1, 1, 14, 14], fill=cor("fff4a0", 50))
        d.ellipse([3, 3, 12, 12], fill=cor("fff4a0", 90))
        asa = cor("dff6ff", 210)
        if k == 0:
            d.ellipse([3, 2, 7, 7], fill=asa)
            d.ellipse([9, 2, 13, 7], fill=asa)
        else:
            d.ellipse([2, 4, 7, 8], fill=asa)
            d.ellipse([9, 4, 14, 8], fill=asa)
        d.ellipse([6, 6, 10, 11], fill=cor("fff27a"))
        d.point([(7, 7)], fill=cor("ffffff"))
        d.rectangle([7, 4, 8, 5], fill=cor("5a4632"))
        img.save(os.path.join(OUT, "vagalume%d.png" % (k + 1)))


ceu()
sol()
nuvens()
serra()
morros()
frente()
vagalume()

# prévia montada
prev = Image.open(os.path.join(OUT, "ceu.png")).convert("RGBA")
prev.alpha_composite(Image.open(os.path.join(OUT, "sol.png")), (470, 150))
prev.alpha_composite(Image.open(os.path.join(OUT, "nuvens.png")).crop((0, 0, 640, 150)), (0, 10))
prev.alpha_composite(Image.open(os.path.join(OUT, "serra.png")).crop((0, 0, 640, 130)), (0, 150))
prev.alpha_composite(Image.open(os.path.join(OUT, "morros.png")).crop((0, 0, 640, 120)), (0, 196))
prev.alpha_composite(Image.open(os.path.join(OUT, "frente.png")), (0, 160))
prev.save(os.path.join(sys.argv[2] if len(sys.argv) > 2 else OUT, "previa_menu.png"))
print("ok")
