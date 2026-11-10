"""Gera a arte extra e os sons do projeto Juntos na Roça.

Uso: python3 gerar_assets.py <pasta do projeto godot> <pasta dos sprites já feitos>
"""
import os
import random
import shutil
import subprocess
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw

PROJ = sys.argv[1]
SPR_ANTIGOS = sys.argv[2]
SPR = os.path.join(PROJ, "assets", "sprites")
SONS = os.path.join(PROJ, "assets", "sons")
for p in ["personagens", "tiles", "objetos", "estruturas", "extras"]:
    os.makedirs(os.path.join(SPR, p), exist_ok=True)
os.makedirs(SONS, exist_ok=True)

# ---------------------------------------------------------------- sprites antigos
for pasta in ["personagens", "tiles", "objetos", "estruturas"]:
    for nome in os.listdir(os.path.join(SPR_ANTIGOS, pasta)):
        shutil.copy(os.path.join(SPR_ANTIGOS, pasta, nome), os.path.join(SPR, pasta, nome))

# ---------------------------------------------------------------- paleta
T = (0, 0, 0, 0)
PRETO = (34, 32, 52, 255)
VERDE = (106, 190, 48, 255)
VERDE_S = (75, 150, 35, 255)
VERDE_E = (55, 115, 35, 255)
TERRA = (151, 106, 60, 255)
TERRA_S = (116, 78, 44, 255)
TERRA_C = (176, 130, 80, 255)
MOLHADA = (104, 70, 40, 255)
MOLHADA_S = (80, 52, 30, 255)
MAD = (166, 110, 62, 255)
MAD_S = (120, 74, 40, 255)
MAD_C = (205, 155, 100, 255)
METAL = (130, 136, 148, 255)
METAL_S = (84, 90, 102, 255)
METAL_C = (180, 186, 196, 255)
AGUA = (73, 140, 230, 255)
AGUA_C = (150, 200, 250, 255)
BRANCO = (248, 248, 248, 255)
CREME = (242, 234, 211, 255)
AMARELO = (240, 200, 70, 255)
AMARELO_S = (200, 150, 40, 255)
ABOB = (232, 126, 40, 255)
ABOB_S = (186, 88, 22, 255)
VERMELHO = (217, 60, 60, 255)
CORDA = (214, 180, 120, 255)
CORDA_S = (160, 124, 74, 255)
SACO = (222, 200, 150, 255)
SACO_S = (178, 150, 100, 255)


def grade(linhas, pal):
    h, w = len(linhas), len(linhas[0])
    img = Image.new("RGBA", (w, h), T)
    px = img.load()
    for y, l in enumerate(linhas):
        assert len(l) == w, (l, len(l), w)
        for x, ch in enumerate(l):
            if ch != ".":
                px[x, y] = pal[ch]
    return img


def salvar(img, nome, pasta="extras"):
    img.save(os.path.join(SPR, pasta, nome + ".png"))


rng = random.Random(3)

# ---------------------------------------------------------------- atlas de tiles
def pontilhado(base, escuro, claro, n_esc=14, n_cla=4, seed=0):
    r = random.Random(seed)
    img = Image.new("RGBA", (16, 16), base)
    px = img.load()
    for _ in range(n_esc):
        px[r.randrange(16), r.randrange(16)] = escuro
    for _ in range(n_cla):
        px[r.randrange(16), r.randrange(16)] = claro
    return img


def arado(base, escuro, claro):
    img = Image.new("RGBA", (16, 16), base)
    d = ImageDraw.Draw(img)
    for y in (2, 7, 12):
        d.line([(0, y), (15, y)], fill=escuro)
        d.line([(0, y + 1), (15, y + 1)], fill=claro)
    return img


tiles = [
    Image.open(os.path.join(SPR, "tiles", "grama.png")).convert("RGBA"),        # 0 grama
    Image.open(os.path.join(SPR, "tiles", "terra.png")).convert("RGBA"),        # 1 caminho
    Image.open(os.path.join(SPR, "tiles", "terra_arada.png")).convert("RGBA"),  # 2 arada
    Image.open(os.path.join(SPR, "tiles", "agua.png")).convert("RGBA"),         # 3 água
    Image.open(os.path.join(SPR, "tiles", "lama.png")).convert("RGBA"),         # 4 lama
    arado(MOLHADA, MOLHADA_S, (124, 88, 54, 255)),                             # 5 molhada
    pontilhado(VERDE, VERDE_S, (140, 215, 80, 255), 10, 7, seed=9),             # 6 grama 2
    pontilhado((92, 170, 44, 255), VERDE_S, VERDE, 18, 3, seed=5),              # 7 grama do campo
]
atlas = Image.new("RGBA", (16 * len(tiles), 16), T)
for i, t in enumerate(tiles):
    atlas.alpha_composite(t, (16 * i, 0))
atlas.save(os.path.join(SPR, "tiles", "atlas.png"))

# ---------------------------------------------------------------- plantas
def planta(fase, tipo):
    img = Image.new("RGBA", (16, 16), T)
    d = ImageDraw.Draw(img)
    if tipo == "feijao":
        if fase >= 1:
            d.rectangle([7, 12, 8, 14], fill=VERDE_E)
            d.point([(6, 12), (9, 12), (5, 11), (10, 11)], fill=VERDE)
        if fase >= 2:
            d.rectangle([7, 7, 8, 11], fill=VERDE_E)
            d.ellipse([3, 8, 6, 10], fill=VERDE)
            d.ellipse([9, 6, 12, 8], fill=VERDE)
        if fase >= 3:
            d.rectangle([7, 3, 8, 6], fill=VERDE_E)
            d.ellipse([4, 3, 7, 5], fill=VERDE)
            d.ellipse([10, 9, 13, 11], fill=VERDE)
            for (x, y) in [(5, 6), (11, 4), (10, 12)]:
                d.rectangle([x, y, x + 1, y + 3], fill=(150, 200, 70, 255))
    if tipo == "jerimum":
        if fase >= 1:
            d.point([(7, 13), (8, 13), (7, 12), (6, 11), (9, 11)], fill=VERDE)
        if fase >= 2:
            d.line([(2, 13), (13, 13)], fill=VERDE_E)
            d.ellipse([2, 9, 6, 12], fill=VERDE)
            d.ellipse([9, 9, 13, 12], fill=VERDE)
            d.point([(5, 8), (11, 8)], fill=AMARELO)
        if fase >= 3:
            d.line([(1, 14), (14, 14)], fill=VERDE_E)
            d.ellipse([1, 10, 5, 13], fill=VERDE)
            d.ellipse([4, 6, 12, 14], fill=ABOB)
            d.line([(8, 7), (8, 13)], fill=ABOB_S)
            d.line([(6, 8), (6, 12)], fill=ABOB_S)
            d.line([(10, 8), (10, 12)], fill=ABOB_S)
            d.rectangle([7, 4, 8, 6], fill=VERDE_E)
    return img


for f in (1, 2, 3):
    salvar(planta(f, "feijao"), f"feijao_fase{f}")
    salvar(planta(f, "jerimum"), f"jerimum_fase{f}")

# cova com semente
cova = Image.new("RGBA", (16, 16), T)
d = ImageDraw.Draw(cova)
d.ellipse([4, 9, 11, 13], fill=TERRA_S)
d.ellipse([6, 10, 9, 12], fill=(70, 46, 26, 255))
d.point([(7, 10), (8, 11)], fill=AMARELO)
salvar(cova, "semente")

# mato
mato = grade([
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "....g.....g.....",
    ".....g...g...g..",
    "..g..gg.gg..g...",
    "...g..ggg..g....",
    "...gg.gGg.gg....",
    "....gggGggg.....",
    ".....gGGGg......",
    "......GGG.......",
    "................",
    "................",
], {"g": (150, 160, 60, 255), "G": (110, 120, 40, 255)})
salvar(mato, "mato")

# gota d'água
gota = grade([
    "................",
    "................",
    ".......A........",
    "......AAA.......",
    "......AAA.......",
    ".....AAcAA......",
    ".....AcAAA......",
    "....AAcAAAA.....",
    "....AAAAAAA.....",
    "....AAAAAAA.....",
    ".....AAAAA......",
    "......AAA.......",
    "................",
    "................",
    "................",
    "................",
], {"A": AGUA, "c": AGUA_C})
salvar(gota, "gota")

# corda
corda = Image.new("RGBA", (16, 16), T)
d = ImageDraw.Draw(corda)
d.ellipse([2, 4, 13, 13], outline=CORDA_S, width=2)
d.ellipse([4, 6, 11, 11], outline=CORDA, width=2)
d.ellipse([6, 8, 9, 9], fill=CORDA_S)
d.line([(12, 11), (15, 14)], fill=CORDA, width=1)
salvar(corda, "corda")

# pilha de tábuas
pilha = Image.new("RGBA", (16, 16), T)
d = ImageDraw.Draw(pilha)
for i, y in enumerate((11, 8, 5)):
    d.rectangle([1 + i, y, 14 - i, y + 2], fill=MAD, outline=MAD_S)
    d.point([(4 + i, y + 1), (10 - i, y + 1)], fill=MAD_C)
salvar(pilha, "pilha_tabuas")

# saco de milho
saco = grade([
    "................",
    "................",
    "......CCCC......",
    ".......CC.......",
    ".....SSSSSS.....",
    "....SSSSSSSS....",
    "...SSSSSSSSSS...",
    "...SSSAAASSSS...",
    "...SSAAAAASSS...",
    "...SSSAAASSSS...",
    "...SSSSSSSSSS...",
    "...SSSSSSSSSS...",
    "....ssssssss....",
    "................",
    "................",
    "................",
], {"C": CORDA_S, "S": SACO, "s": SACO_S, "A": AMARELO})
salvar(saco, "saco_milho")

# baldes
def balde(conteudo):
    img = Image.new("RGBA", (16, 16), T)
    d = ImageDraw.Draw(img)
    d.arc([3, 1, 12, 9], 180, 360, fill=METAL_S)
    d.polygon([(3, 5), (12, 5), (11, 14), (4, 14)], fill=METAL)
    d.line([(3, 5), (12, 5)], fill=METAL_C)
    d.line([(4, 14), (11, 14)], fill=METAL_S)
    if conteudo:
        d.rectangle([4, 6, 11, 7], fill=conteudo)
    return img


salvar(balde(AGUA), "balde_agua")
salvar(balde(BRANCO), "balde_leite")
salvar(balde(None), "balde_vazio")

# cochos (32x16)
def cocho(conteudo, cor_borda):
    img = Image.new("RGBA", (32, 16), T)
    d = ImageDraw.Draw(img)
    d.polygon([(1, 6), (30, 6), (27, 13), (4, 13)], fill=cor_borda)
    d.line([(1, 6), (30, 6)], fill=MAD_C)
    d.rectangle([5, 13, 6, 15], fill=MAD_S)
    d.rectangle([25, 13, 26, 15], fill=MAD_S)
    if conteudo == "milho":
        for x in range(4, 28, 2):
            d.point((x, 7 + (x // 2) % 2), fill=AMARELO)
            d.point((x + 1, 7), fill=AMARELO_S)
    elif conteudo == "agua":
        d.rectangle([4, 7, 27, 8], fill=AGUA)
        d.line([(8, 7), (11, 7)], fill=AGUA_C)
    return img


salvar(cocho(None, MAD), "cocho_vazio")
salvar(cocho("milho", MAD), "cocho_cheio")
salvar(cocho(None, METAL), "bebedouro_vazio")
salvar(cocho("agua", METAL), "bebedouro_cheio")

# ícones da cesta
ovos = Image.new("RGBA", (16, 16), T)
d = ImageDraw.Draw(ovos)
for (x, y) in [(2, 7), (8, 7), (5, 3)]:
    d.ellipse([x, y, x + 5, y + 7], fill=CREME, outline=(200, 190, 160, 255))
salvar(ovos, "ovos")

lenha = Image.new("RGBA", (16, 16), T)
d = ImageDraw.Draw(lenha)
for (x, y) in [(1, 10), (6, 10), (11, 10), (3, 6), (8, 6), (5, 2)]:
    d.ellipse([x, y, x + 4, y + 4], fill=MAD, outline=MAD_S)
    d.point((x + 2, y + 2), fill=MAD_C)
salvar(lenha, "lenha")

milho_ic = grade([
    "................",
    "..........GG....",
    ".........GG.....",
    "........YYG.....",
    ".......YYYY.....",
    "......YyYyY.....",
    ".....YYYYYG.....",
    "....YyYyYG......",
    "...YYYYYG.......",
    "...YyYyG........",
    "..GYYYG.........",
    "..GGGG..........",
    ".GG.............",
    "................",
    "................",
    "................",
], {"Y": AMARELO, "y": AMARELO_S, "G": VERDE})
salvar(milho_ic, "milho")

feijao_ic = grade([
    "................",
    "................",
    "................",
    "...........GG...",
    "..........GG....",
    ".........GGG....",
    "........GGLG....",
    ".......GGLGG....",
    "......GGLGG.....",
    ".....GGLGG......",
    "....GGLGG.......",
    "...GGGGG........",
    "...GGG..........",
    "................",
    "................",
    "................",
], {"G": (120, 175, 60, 255), "L": (170, 215, 100, 255)})
salvar(feijao_ic, "feijao")

peixe = Image.open(os.path.join(SPR, "objetos", "peixe.png")).convert("RGBA")

# puçá e vara
puca = Image.new("RGBA", (16, 16), T)
d = ImageDraw.Draw(puca)
d.line([(1, 15), (8, 8)], fill=MAD, width=1)
d.ellipse([7, 1, 15, 9], outline=METAL_S)
for x in range(9, 15, 2):
    d.line([(x, 2), (x, 8)], fill=(200, 200, 200, 255))
for y in range(3, 9, 2):
    d.line([(8, y), (14, y)], fill=(200, 200, 200, 255))
salvar(puca, "puca")

vara = Image.new("RGBA", (16, 16), T)
d = ImageDraw.Draw(vara)
d.line([(1, 15), (14, 1)], fill=MAD_S)
d.line([(14, 1), (15, 10)], fill=(220, 220, 220, 255))
d.ellipse([3, 10, 6, 13], fill=METAL)
salvar(vara, "vara")

capim = grade([
    "................",
    "................",
    "................",
    "................",
    ".......g........",
    "...g...g...g....",
    "....g..g..g.....",
    "....g.gGg.g.....",
    ".....gGGGg......",
    "..g..gGGGg..g...",
    "...ggGGGGGgg....",
    "....GGGGGGG.....",
    ".....YYYYY......",
    "......YYY.......",
    "................",
    "................",
], {"g": (150, 210, 80, 255), "G": VERDE, "Y": AMARELO_S})
salvar(capim, "capim")

coracao = grade([
    "................",
    "................",
    "................",
    "................",
    "....RR...RR.....",
    "...RRRR.RRRR....",
    "...RWRRRRRRR....",
    "...RRRRRRRRR....",
    "....RRRRRRR.....",
    ".....RRRRR......",
    "......RRR.......",
    ".......R........",
    "................",
    "................",
    "................",
    "................",
], {"R": VERMELHO, "W": (255, 190, 190, 255)})
salvar(coracao, "coracao")

seta = grade([
    "................",
    "....YYYYYYY.....",
    "....YyyyyyY.....",
    "....YyyyyyY.....",
    "....YyyyyyY.....",
    "....YyyyyyY.....",
    ".YYYYyyyyyYYYY..",
    "..YyyyyyyyyyY...",
    "...YyyyyyyyY....",
    "....YyyyyyY.....",
    ".....YyyyY......",
    "......YyY.......",
    ".......Y........",
    "................",
    "................",
    "................",
], {"Y": (120, 70, 20, 255), "y": AMARELO})
salvar(seta, "seta")

# fumaça e partícula (bolinha branca)
bola = Image.new("RGBA", (8, 8), T)
ImageDraw.Draw(bola).ellipse([0, 0, 7, 7], fill=BRANCO)
salvar(bola, "bolinha")
pix = Image.new("RGBA", (2, 2), BRANCO)
salvar(pix, "pixel")

# sombra de peixe
sombra = Image.new("RGBA", (16, 8), T)
d = ImageDraw.Draw(sombra)
d.ellipse([3, 2, 13, 6], fill=(20, 50, 110, 150))
d.polygon([(0, 1), (4, 4), (0, 7)], fill=(20, 50, 110, 150))
salvar(sombra, "sombra_peixe")

# boia
boia = grade([
    "........",
    "...WW...",
    "..WWWW..",
    "..RRRR..",
    "..RRRR..",
    "...RR...",
    "........",
    "........",
], {"W": BRANCO, "R": VERMELHO})
salvar(boia, "boia")

# mesa da festa (48x24)
mesa = Image.new("RGBA", (48, 24), T)
d = ImageDraw.Draw(mesa)
d.rectangle([0, 6, 47, 12], fill=(250, 250, 250, 255))
for x in range(0, 48, 6):
    d.rectangle([x, 6, x + 2, 12], fill=VERMELHO)
d.rectangle([0, 13, 47, 15], fill=MAD)
d.rectangle([3, 16, 5, 23], fill=MAD_S)
d.rectangle([42, 16, 44, 23], fill=MAD_S)
salvar(mesa, "mesa")

# trator sem o atolamento (mesmo sprite, só copiamos para "extras" por clareza)
shutil.copy(os.path.join(SPR, "objetos", "trator.png"), os.path.join(SPR, "extras", "trator.png"))

# ícone do projeto (64x64): jerimum + dois amigos
icone = Image.new("RGBA", (64, 64), (106, 190, 48, 255))
jer = Image.open(os.path.join(SPR, "objetos", "jerimum.png")).convert("RGBA").resize((32, 32), Image.NEAREST)
p1 = Image.open(os.path.join(SPR, "personagens", "p1_baixo_parado.png")).convert("RGBA").resize((32, 32), Image.NEAREST)
p2 = Image.open(os.path.join(SPR, "personagens", "p2_baixo_parado.png")).convert("RGBA").resize((32, 32), Image.NEAREST)
icone.alpha_composite(jer, (16, 30))
icone.alpha_composite(p1, (0, 6))
icone.alpha_composite(p2, (32, 6))
icone.save(os.path.join(PROJ, "icon.png"))

# ================================================================= SONS
SR = 22050


def salvar_wav(nome, sinal):
    sinal = np.clip(sinal, -1, 1)
    dados = (sinal * 32767 * 0.8).astype(np.int16)
    with wave.open(os.path.join(SONS, nome + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(dados.tobytes())


def t(dur):
    return np.linspace(0, dur, int(SR * dur), endpoint=False)


def env(n, ataque=0.005, queda=None):
    e = np.ones(n)
    a = max(1, int(SR * ataque))
    e[:a] = np.linspace(0, 1, a)
    if queda is None:
        e[a:] = np.linspace(1, 0, n - a) ** 2
    return e


def tom(freq, dur, forma="seno", vol=1.0):
    tt = t(dur)
    if callable(freq):
        fase = 2 * np.pi * np.cumsum(freq(tt)) / SR
    else:
        fase = 2 * np.pi * freq * tt
    if forma == "seno":
        s = np.sin(fase)
    elif forma == "quadrada":
        s = np.sign(np.sin(fase)) * 0.5
    elif forma == "triangulo":
        s = 2 / np.pi * np.arcsin(np.sin(fase))
    elif forma == "serra":
        s = 2 * ((fase / (2 * np.pi)) % 1) - 1
    return s * vol


def ruido(dur, vol=1.0, seed=1):
    return np.random.default_rng(seed).uniform(-1, 1, int(SR * dur)) * vol


def passa_baixa(s, k=8):
    return np.convolve(s, np.ones(k) / k, mode="same")


# erro engraçado: "tóim"
s = tom(lambda x: 520 * np.exp(-x * 3.2) + 120 + 25 * np.sin(2 * np.pi * 14 * x), 0.55, "seno")
salvar_wav("toim", s * env(len(s)))

# acerto
s = np.concatenate([tom(660, 0.07, "quadrada"), tom(880, 0.07, "quadrada"), tom(1320, 0.12, "quadrada")])
salvar_wav("acerto", s * env(len(s), queda=False) * np.linspace(1, 0.2, len(s)))

# martelada
s = ruido(0.12, 1, 2) * np.exp(-t(0.12) * 45) + tom(110, 0.12, "seno") * np.exp(-t(0.12) * 25)
salvar_wav("toc", s)

# encaixe
s = ruido(0.05, 0.8, 3) * np.exp(-t(0.05) * 80) + tom(900, 0.05, "quadrada", 0.4) * np.exp(-t(0.05) * 60)
salvar_wav("encaixe", s)

# serra (vai e volta)
tt = t(0.22)
s = passa_baixa(ruido(0.22, 1, 4), 3) * (0.4 + 0.6 * np.abs(np.sin(2 * np.pi * 9 * tt))) * np.sin(np.pi * tt / 0.22)
salvar_wav("serra", s)

# motor
tt = t(0.6)
s = tom(lambda x: 55 + 8 * np.sin(2 * np.pi * 7 * x), 0.6, "quadrada") * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 14 * tt)))
salvar_wav("motor", passa_baixa(s, 6) * np.sin(np.pi * tt / 0.6) ** 0.3)

# splash
s = passa_baixa(ruido(0.4, 1, 5), 4) * np.exp(-t(0.4) * 9)
salvar_wav("splash", s)

# pegar / soltar
s = tom(lambda x: 400 + 1600 * x, 0.1, "quadrada")
salvar_wav("pegar", s * env(len(s)))
s = tom(lambda x: 300 - 900 * x, 0.12, "triangulo") + ruido(0.12, 0.3, 6) * np.exp(-t(0.12) * 30)
salvar_wav("soltar", s * env(len(s)))

# plantar (pop), regar (chuá), arrancar
s = tom(lambda x: 200 + 2500 * np.exp(-x * 40), 0.08, "seno")
salvar_wav("plantar", s * env(len(s)))
tt = t(0.35)
s = passa_baixa(ruido(0.35, 0.8, 7), 2) * np.sin(np.pi * tt / 0.35)
salvar_wav("regar", s)
s = ruido(0.1, 0.8, 8) * np.exp(-t(0.1) * 40) + tom(lambda x: 300 + 800 * x, 0.1, "quadrada", 0.3)
salvar_wav("arrancar", s * env(len(s)))

# galinha (cocó)
partes = []
for f in (900, 1100, 950):
    p = tom(lambda x, f=f: f + 300 * np.sin(2 * np.pi * 30 * x), 0.06, "quadrada")
    partes += [p * env(len(p)), np.zeros(int(SR * 0.04))]
salvar_wav("galinha", passa_baixa(np.concatenate(partes), 3))

# vaca (muuu)
tt = t(0.9)
s = tom(lambda x: 130 + 30 * np.sin(np.pi * x / 0.9) + 3 * np.sin(2 * np.pi * 5 * x), 0.9, "serra")
salvar_wav("vaca", passa_baixa(s, 14) * np.sin(np.pi * tt / 0.9) ** 0.5)

# galo (cocoricó)
notas = [(700, 0.1), (900, 0.1), (1000, 0.12), (1200, 0.35)]
partes = []
for f, d_ in notas:
    p = tom(lambda x, f=f: f + 60 * np.sin(2 * np.pi * 25 * x), d_, "quadrada")
    partes += [p * env(len(p)), np.zeros(int(SR * 0.02))]
salvar_wav("galo", passa_baixa(np.concatenate(partes), 4))

# ordenha (esguicho)
s = passa_baixa(ruido(0.12, 0.7, 9), 2) * np.exp(-t(0.12) * 20)
salvar_wav("leite", s)

# fala da Vovó (blip)
s = tom(lambda x: 520 + 120 * np.sin(2 * np.pi * 18 * x), 0.05, "quadrada")
salvar_wav("fala", s * env(len(s)) * 0.6)

# toca aqui: palma + brilho
palma = passa_baixa(ruido(0.08, 1, 10), 2) * np.exp(-t(0.08) * 60)
brilho = np.concatenate([tom(f, 0.08, "quadrada", 0.5) * np.exp(-t(0.08) * 10) for f in (1047, 1319, 1568, 2093)])
salvar_wav("toca_aqui", np.concatenate([palma, brilho]))

# passo do dia
s = np.concatenate([tom(f, 0.15, "triangulo") * env(int(SR * 0.15)) for f in (523, 659, 784, 1047)])
salvar_wav("novo_dia", s)

# força (barrinha subindo) e escorregar
s = tom(lambda x: 300 + 200 * x / 0.08, 0.08, "quadrada", 0.5)
salvar_wav("forca", s * env(len(s)))
s = tom(lambda x: 600 * np.exp(-x * 6), 0.3, "triangulo")
salvar_wav("escapou", s * env(len(s)))


# ---------------------------------------------------------------- música (estilo baião)
def nota_freq(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def musica(nome, bpm, melodia, baixo, compassos, vol_mel=0.22, vol_bx=0.3, zabumba=True):
    batida = 60 / bpm
    total = compassos * 4 * batida
    n = int(SR * total)
    mix = np.zeros(n)

    def tocar(lista, forma, vol, legato=0.9):
        pos = 0.0
        for m, dur in lista:
            dur_s = dur * batida
            if m is not None:
                k = int(SR * pos)
                tt_ = t(dur_s * legato)
                s_ = tom(nota_freq(m), dur_s * legato, forma, vol)
                e_ = np.minimum(1, np.linspace(0, 40, len(tt_))) * np.linspace(1, 0.35, len(tt_))
                s_ *= e_
                fim = min(n, k + len(s_))
                mix[k:fim] += s_[: fim - k]
            pos += dur_s
            if pos >= total:
                break

    tocar(melodia, "quadrada", vol_mel)
    tocar(baixo, "triangulo", vol_bx, 0.8)
    if zabumba:
        # baião: batida no 1, no "e" do 2 e no 3 (aproximado), e triângulo nas colcheias
        for c in range(compassos * 2):
            base = c * 2 * batida
            for off, v in ((0, 0.5), (0.75 * batida, 0.35), (batida, 0.45)):
                k = int(SR * (base + off))
                b = tom(lambda x: 60 + 90 * np.exp(-x * 30), 0.15, "seno", v) * np.exp(-t(0.15) * 18)
                fim = min(n, k + len(b))
                mix[k:fim] += b[: fim - k]
            for i in range(4):
                k = int(SR * (base + i * batida / 2))
                h = ruido(0.03, 0.08 if i % 2 else 0.12, 20 + i) * np.exp(-t(0.03) * 120)
                fim = min(n, k + len(h))
                mix[k:fim] += h[: fim - k]
    mix = mix / max(1e-6, np.max(np.abs(mix))) * 0.9
    wav_tmp = os.path.join(SONS, nome + "_tmp.wav")
    salvar_wav(nome + "_tmp", mix)
    ogg = os.path.join(SONS, nome + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_tmp, "-c:a", "libvorbis", "-q:a", "4", ogg], check=True)
    os.remove(wav_tmp)


# Sol mixolídio (G A B C D E F), bem nordestino
G4, A4, B4, C5, D5, E5, F5, G5 = 67, 69, 71, 72, 74, 76, 77, 79
D4, E4, F4 = 62, 64, 65
G2, C3, D3, F2 = 43, 48, 50, 41
mel = [
    (D5, 0.5), (D5, 0.5), (B4, 0.5), (G4, 0.5), (A4, 1), (B4, 1),
    (C5, 0.5), (B4, 0.5), (A4, 0.5), (G4, 0.5), (F4, 1), (G4, 1),
    (D5, 0.5), (E5, 0.5), (F5, 0.5), (E5, 0.5), (D5, 1), (B4, 1),
    (C5, 0.5), (A4, 0.5), (F4, 0.5), (A4, 0.5), (G4, 2),
    (B4, 0.5), (B4, 0.5), (C5, 0.5), (D5, 0.5), (E5, 1), (D5, 1),
    (C5, 0.5), (B4, 0.5), (A4, 0.5), (B4, 0.5), (C5, 1), (A4, 1),
    (G4, 0.5), (A4, 0.5), (B4, 0.5), (D5, 0.5), (C5, 1), (A4, 1),
    (F4, 0.5), (G4, 0.5), (A4, 0.5), (F4, 0.5), (G4, 2),
]
bx = []
for raiz in [G2, G2, F2, G2, G2, C3, D3, G2]:
    bx += [(raiz, 1), (raiz + 7, 0.5), (raiz + 12, 0.5), (raiz, 1), (raiz + 7, 1)]
musica("musica_fazenda", 104, mel, bx, 8)

mel_festa = [(G4, 0.5), (B4, 0.5), (D5, 0.5), (G5, 0.5), (F5, 0.5), (D5, 0.5), (E5, 1)] * 2 + \
            [(C5, 0.5), (E5, 0.5), (G5, 0.5), (E5, 0.5), (F5, 0.5), (D5, 0.5), (B4, 1)] * 2
bx_festa = []
for raiz in [G2, G2, C3, D3]:
    bx_festa += [(raiz, 1), (raiz + 7, 0.5), (raiz + 12, 0.5), (raiz, 1), (raiz + 7, 1)]
musica("musica_festa", 128, mel_festa, bx_festa, 4)

mel_inicio = [(D5, 1), (B4, 0.5), (G4, 0.5), (A4, 1), (G4, 1), (F4, 1), (A4, 1), (G4, 2)] * 2
bx_inicio = []
for raiz in [G2, F2, G2, G2]:
    bx_inicio += [(raiz, 2), (raiz + 7, 2)]
musica("musica_inicio", 84, mel_inicio, bx_inicio, 4, vol_mel=0.18, zabumba=False)

print("assets ok")
