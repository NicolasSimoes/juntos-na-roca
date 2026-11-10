"""Desenha os dois netos e a Vovó em pixel art 16 x 24, com contorno automático.

Uso: python3 gerar_netos.py <pasta de saída> [<pasta da prévia>]
Cada pose é montada por partes (cabeça, tronco, braços, pernas), então todas
as poses ficam com o mesmo jeitinho.
"""
import os
import sys

from PIL import Image, ImageDraw

W, H = 16, 24
Y0 = 2           # topo da cabeça
CONTORNO = (42, 32, 51, 255)


class Tela:
    def __init__(self):
        self.px = [[None] * W for _ in range(H)]

    def p(self, x, y, c):
        if 0 <= x < W and 0 <= y < H:
            self.px[y][x] = c

    def r(self, x0, y0, x1, y1, c):
        for y in range(min(y0, y1), max(y0, y1) + 1):
            for x in range(min(x0, x1), max(x0, x1) + 1):
                self.p(x, y, c)

    def imagem(self):
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = img.load()
        for y in range(H):
            for x in range(W):
                if self.px[y][x] is not None:
                    d[x, y] = self.px[y][x]
        # contorno de 1 pixel em volta de tudo
        for y in range(H):
            for x in range(W):
                if self.px[y][x] is not None:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < W and 0 <= yy < H and self.px[yy][xx] is not None:
                        d[x, y] = CONTORNO
                        break
        return img


def cor(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


PELE = {"pele": cor("f6cda6"), "pele_s": cor("dea47e"), "olho": cor("2a2033"),
        "boca": cor("b04a4a"), "bochecha": cor("f2a08e"), "branco": cor("ffffff")}

NETOS = {
    1: dict(PELE, cabelo=cor("7a482e"), cabelo_c=cor("a56940"), cabelo_s=cor("5a3422"),
            camisa=cor("f08c32"), camisa_c=cor("ffb45a"), camisa_s=cor("c8641e"),
            short=cor("42589a"), short_s=cor("323f73"),
            tenis=cor("d23c3c"), tenis_s=cor("9a2a2a"), sola=cor("f0f0f0"), estilo="liso"),
    2: dict(PELE, pele=cor("c98d62"), pele_s=cor("a56e48"), bochecha=cor("d98a72"),
            cabelo=cor("2e2428"), cabelo_c=cor("54464c"), cabelo_s=cor("1c1418"),
            camisa=cor("5a8cee"), camisa_c=cor("8cb4ff"), camisa_s=cor("3760be"),
            short=cor("6e7a44"), short_s=cor("525b30"),
            tenis=cor("f0f0f0"), tenis_s=cor("b4b4c0"), sola=cor("5a5a6a"), estilo="cacheado"),
}


# ------------------------------------------------------------------ cabeças
def cabelo_frente(t, c, y):
    H_, h, s = c["cabelo"], c["cabelo_c"], c["cabelo_s"]
    if c["estilo"] == "liso":
        t.r(7, y, 8, y, H_)                     # topete
        t.r(5, y + 1, 10, y + 1, H_)
        t.r(4, y + 2, 11, y + 2, H_)
        t.r(3, y + 3, 12, y + 3, H_)
        t.r(3, y + 4, 12, y + 4, H_)
        t.r(3, y + 5, 6, y + 5, H_)              # franja para o lado
        t.p(12, y + 5, H_)
        t.r(3, y + 6, 3, y + 7, H_)
        t.r(12, y + 6, 12, y + 7, s)
        for (x, yy) in ((6, 1), (5, 2), (6, 2), (4, 3)):
            t.p(x, y + yy, h)
        for (x, yy) in ((11, 3), (12, 4), (11, 4)):
            t.p(x, y + yy, s)
    else:
        for x in (5, 6, 9, 10):                  # cachinhos em cima
            t.p(x, y, H_)
        t.r(4, y + 1, 11, y + 1, H_)
        t.r(3, y + 2, 12, y + 2, H_)
        t.p(2, y + 3, H_)
        t.p(13, y + 3, H_)
        t.r(3, y + 3, 12, y + 3, H_)
        t.r(3, y + 4, 12, y + 4, H_)
        for x in (4, 6, 8, 10):                  # franja de cachinhos
            t.p(x, y + 5, H_)
        t.p(3, y + 5, H_)
        t.p(12, y + 5, H_)
        t.r(3, y + 6, 3, y + 6, H_)
        t.r(12, y + 6, 12, y + 6, s)
        for (x, yy) in ((5, 1), (9, 1), (4, 2), (7, 2), (10, 3), (5, 4)):
            t.p(x, y + yy, h)
        for (x, yy) in ((12, 3), (11, 4), (13, 3)):
            t.p(x, y + yy, s)


def cabeca_frente(t, c, y, feliz=False, boca_aberta=False):
    t.r(4, y + 4, 11, y + 8, c["pele"])
    t.r(5, y + 9, 10, y + 9, c["pele"])
    t.p(11, y + 8, c["pele_s"])
    t.r(6, y + 9, 9, y + 9, c["pele"])
    cabelo_frente(t, c, y)
    if feliz:
        for ex in (5, 10):
            t.p(ex - 1, y + 7, c["olho"])
            t.p(ex, y + 6, c["olho"])
            t.p(ex + 1, y + 7, c["olho"])
    else:
        for ex in (5, 10):
            t.r(ex, y + 6, ex, y + 7, c["olho"])
            t.p(ex, y + 6, c["olho"])
        t.p(5, y + 6, c["olho"])
    t.p(4, y + 8, c["bochecha"])
    t.p(11, y + 8, c["bochecha"])
    if boca_aberta:
        t.r(7, y + 8, 8, y + 9, c["boca"])
    else:
        t.r(7, y + 8, 8, y + 8, c["boca"])


def cabeca_costas(t, c, y):
    H_, h, s = c["cabelo"], c["cabelo_c"], c["cabelo_s"]
    t.r(4, y + 1, 11, y + 1, H_)
    t.r(3, y + 2, 12, y + 7, H_)
    t.r(4, y + 8, 11, y + 8, H_)
    t.r(6, y + 9, 9, y + 9, c["pele_s"])       # nuca
    if c["estilo"] == "liso":
        t.r(7, y, 8, y, H_)
        t.r(4, y + 3, 5, y + 3, h)
        t.p(5, y + 4, h)
        t.r(11, y + 4, 12, y + 7, s)
    else:
        for x in (5, 6, 9, 10):
            t.p(x, y, H_)
        t.p(2, y + 3, H_)
        t.p(13, y + 3, H_)
        t.p(2, y + 6, H_)
        t.p(13, y + 6, H_)
        for (x, yy) in ((5, 2), (8, 3), (4, 5), (10, 2), (7, 6)):
            t.p(x, y + yy, h)
        t.r(12, y + 5, 12, y + 7, s)


def cabeca_lado(t, c, y, feliz=False, boca_aberta=False):
    """Olhando para a direita."""
    H_, h, s = c["cabelo"], c["cabelo_c"], c["cabelo_s"]
    t.r(5, y + 4, 12, y + 8, c["pele"])
    t.r(6, y + 9, 11, y + 9, c["pele"])
    t.p(13, y + 7, c["pele"])                  # narizinho
    t.r(5, y + 8, 6, y + 9, c["pele_s"])
    # cabelo: em cima e atrás
    t.r(5, y + 1, 11, y + 1, H_)
    t.r(4, y + 2, 12, y + 2, H_)
    t.r(3, y + 3, 12, y + 3, H_)
    t.r(3, y + 4, 12, y + 4, H_)
    t.r(3, y + 5, 8, y + 5, H_)
    t.r(3, y + 6, 6, y + 7, H_)
    t.r(4, y + 8, 5, y + 8, H_)
    t.p(7, y + 6, c["pele_s"])                 # orelha
    if c["estilo"] == "liso":
        t.r(7, y, 8, y, H_)
        t.p(12, y + 5, H_)                     # franja
        t.r(5, y + 2, 6, y + 2, h)
        t.p(4, y + 3, h)
        t.r(3, y + 6, 3, y + 7, s)
    else:
        for x in (5, 6, 9, 10):
            t.p(x, y, H_)
        t.p(2, y + 3, H_)
        t.p(2, y + 6, H_)
        t.p(10, y + 5, H_)
        t.p(12, y + 5, H_)
        for (x, yy) in ((5, 1), (8, 2), (4, 4), (6, 3)):
            t.p(x, y + yy, h)
        t.r(3, y + 7, 4, y + 7, s)
    if feliz:
        t.p(10, y + 7, c["olho"])
        t.p(11, y + 6, c["olho"])
        t.p(12, y + 7, c["olho"])
    else:
        t.r(11, y + 6, 11, y + 7, c["olho"])
    t.p(10, y + 8, c["bochecha"])
    if boca_aberta:
        t.r(12, y + 8, 12, y + 9, c["boca"])
    else:
        t.p(12, y + 9, c["boca"])


# ------------------------------------------------------------------ corpos
def tronco_frente(t, c, y):
    t.r(5, y + 10, 10, y + 15, c["camisa"])
    t.r(10, y + 10, 10, y + 15, c["camisa_s"])
    t.r(5, y + 15, 10, y + 15, c["camisa_s"])
    t.r(5, y + 10, 5, y + 13, c["camisa_c"])
    t.r(7, y + 10, 8, y + 10, c["pele_s"])     # pescoço


def braco_frente(t, c, y, lado, pose):
    """lado -1 = esquerda da tela, 1 = direita. pose: baixo, balanca, cima."""
    x = 4 if lado < 0 else 11
    manga = c["camisa_c"] if lado < 0 else c["camisa_s"]
    if pose == "baixo":
        t.r(x, y + 10, x, y + 11, manga)
        t.r(x, y + 12, x, y + 14, c["pele"])
    elif pose == "balanca":
        t.r(x, y + 10, x, y + 11, manga)
        t.r(x, y + 12, x, y + 13, c["pele"])
    elif pose == "cima":
        dx = lado
        t.p(x, y + 10, manga)
        t.p(x + dx, y + 9, manga)
        t.p(x + 2 * dx, y + 8, c["pele"])
        t.r(x + 3 * dx, y + 5, x + 3 * dx, y + 7, c["pele"])


def pernas_frente(t, c, y, passo=0):
    """passo: 0 parado, -1 pé esquerdo levantado, 1 pé direito levantado, 2 pulo (pernas abertas)."""
    t.r(5, y + 16, 10, y + 17, c["short"])
    t.r(5, y + 17, 10, y + 17, c["short_s"])
    t.r(7, y + 17, 8, y + 17, None)
    for lado in (-1, 1):
        xs = (5, 6) if lado < 0 else (9, 10)
        sobe = 1 if passo == lado else 0
        abre = -1 if (passo == 2 and lado < 0) else (1 if passo == 2 else 0)
        x0, x1 = xs[0] + abre, xs[1] + abre
        t.r(x0, y + 18 - sobe, x1, y + 18 - sobe, c["pele"])
        sx0, sx1 = (x0 - 1, x1) if lado < 0 else (x0, x1 + 1)
        t.r(sx0, y + 19 - sobe, sx1, y + 19 - sobe, c["tenis"])
        t.r(sx0, y + 20 - sobe, sx1, y + 20 - sobe, c["sola"])


def tronco_lado(t, c, y):
    t.r(6, y + 10, 10, y + 15, c["camisa"])
    t.r(6, y + 10, 6, y + 15, c["camisa_s"])
    t.r(6, y + 15, 10, y + 15, c["camisa_s"])
    t.r(10, y + 10, 10, y + 13, c["camisa_c"])


def braco_lado(t, c, y, pose):
    """pose: baixo, frente, tras, toca (esticado para frente e para cima)."""
    m, p = c["camisa_s"], c["pele"]
    if pose == "baixo":
        t.r(8, y + 10, 8, y + 12, m)
        t.r(8, y + 13, 8, y + 14, p)
    elif pose == "frente":
        t.r(9, y + 10, 9, y + 11, m)
        t.p(10, y + 12, p)
        t.r(11, y + 12, 11, y + 13, p)
    elif pose == "tras":
        t.r(7, y + 10, 7, y + 11, m)
        t.p(6, y + 12, p)
        t.r(5, y + 12, 5, y + 13, p)
    elif pose == "toca":
        t.r(9, y + 11, 10, y + 11, m)
        t.r(11, y + 11, 12, y + 11, p)
        t.p(13, y + 10, p)
        t.r(14, y + 9, 14, y + 11, p)           # mão aberta
        t.r(15, y + 9, 15, y + 10, p)


def pernas_lado(t, c, y, passo=0):
    """passo: 0 parado, 1 perna da frente na frente, -1 perna da frente atrás, 2 pulo."""
    t.r(6, y + 16, 10, y + 17, c["short"])
    t.r(6, y + 17, 7, y + 17, c["short_s"])
    longe = {"pele": c["pele_s"], "tenis": c["tenis_s"]}
    perto = {"pele": c["pele"], "tenis": c["tenis"]}
    if passo == 0:
        pernas = [(7, 0, longe), (8, 0, perto)]
    elif passo == 2:
        pernas = [(5, -2, longe), (9, -2, perto)]
    else:
        pernas = [(7 - 2 * passo, 0, longe), (8 + 2 * passo, 0, perto)]
    for x, dy, cores in pernas:
        t.p(x, y + 18 + dy, cores["pele"])
        t.r(x, y + 19 + dy, x + 2, y + 19 + dy, cores["tenis"])
        t.r(x, y + 20 + dy, x + 2, y + 20 + dy, c["sola"])


# ------------------------------------------------------------------ poses
def frente(c, passo=0, bracos=("baixo", "baixo"), feliz=False, boca=False, sobe=0):
    t = Tela()
    y = Y0 - sobe
    pernas_frente(t, c, y + sobe if passo != 2 else y, passo)
    tronco_frente(t, c, y)
    braco_frente(t, c, y, -1, bracos[0])
    braco_frente(t, c, y, 1, bracos[1])
    cabeca_frente(t, c, y, feliz, boca)
    if sobe and passo != 2:
        t.r(5, y + 18, 6, y + 18, c["pele"])
        t.r(9, y + 18, 10, y + 18, c["pele"])
    return t.imagem()


def costas(c, passo=0, bracos=("baixo", "baixo"), sobe=0):
    t = Tela()
    y = Y0 - sobe
    pernas_frente(t, c, y + sobe, passo)
    tronco_frente(t, c, y)
    t.r(7, y + 10, 8, y + 10, c["camisa"])
    braco_frente(t, c, y, -1, bracos[0])
    braco_frente(t, c, y, 1, bracos[1])
    cabeca_costas(t, c, y)
    if sobe:
        t.r(5, y + 18, 6, y + 18, c["pele"])
        t.r(9, y + 18, 10, y + 18, c["pele"])
    return t.imagem()


def lado(c, passo=0, braco="baixo", feliz=False, boca=False, sobe=0):
    t = Tela()
    y = Y0 - sobe
    pernas_lado(t, c, y + sobe if passo != 2 else y, passo)
    if braco == "frente":
        braco_lado(t, c, y, "tras")            # o braço de longe vai para trás
    tronco_lado(t, c, y)
    cabeca_lado(t, c, y, feliz, boca)
    braco_lado(t, c, y, braco)
    if sobe and passo != 2:
        t.p(7, y + 18, c["pele_s"])
        t.p(8, y + 18, c["pele"])
    return t.imagem()


def poses(n):
    c = NETOS[n]
    return {
        "baixo_parado": frente(c),
        "baixo_anda1": frente(c, passo=-1, bracos=("baixo", "balanca")),
        "baixo_anda2": frente(c, sobe=1),
        "baixo_anda3": frente(c, passo=1, bracos=("balanca", "baixo")),
        "baixo_anda4": frente(c, sobe=1),
        "cima_parado": costas(c),
        "cima_anda1": costas(c, passo=-1, bracos=("baixo", "balanca")),
        "cima_anda2": costas(c, sobe=1),
        "cima_anda3": costas(c, passo=1, bracos=("balanca", "baixo")),
        "cima_anda4": costas(c, sobe=1),
        "lado_parado": lado(c),
        "lado_anda1": lado(c, passo=1, braco="tras"),
        "lado_anda2": lado(c, sobe=1),
        "lado_anda3": lado(c, passo=-1, braco="frente"),
        "lado_anda4": lado(c, sobe=1),
        # toca aqui e comemoração
        "lado_mao": lado(c, braco="toca", boca=True),
        "lado_pulo": lado(c, passo=2, braco="toca", boca=True),
        "lado_toca": lado(c, passo=2, braco="toca", feliz=True, boca=True),
        "comemora1": frente(c, bracos=("cima", "cima"), feliz=True, boca=True),
        "comemora2": frente(c, passo=2, bracos=("cima", "cima"), feliz=True, boca=True, sobe=1),
    }


# ------------------------------------------------------------------ Vovó
def vovo():
    c = {"pele": cor("f2c7a2"), "pele_s": cor("d9a27c"), "cabelo": cor("e6e1ea"),
         "cabelo_c": cor("ffffff"), "cabelo_s": cor("b4adbe"), "vestido": cor("9260aa"),
         "vestido_s": cor("6e4486"), "avental": cor("f8f0dc"), "avental_s": cor("dcd0b4"),
         "oculos": cor("5a4632"), "olho": cor("2a2033"), "boca": cor("b04a4a"),
         "bochecha": cor("f0a08c"), "sapato": cor("6a4632")}
    t = Tela()
    y = Y0
    # vestido longo
    t.r(4, y + 10, 11, y + 19, c["vestido"])
    t.r(11, y + 10, 11, y + 19, c["vestido_s"])
    t.r(3, y + 17, 12, y + 19, c["vestido"])
    t.r(3, y + 19, 12, y + 19, c["vestido_s"])
    t.r(6, y + 11, 9, y + 18, c["avental"])
    t.r(9, y + 11, 9, y + 18, c["avental_s"])
    t.r(6, y + 10, 9, y + 10, c["avental_s"])
    # braços cruzados na frente
    t.r(4, y + 13, 11, y + 13, c["vestido_s"])
    t.r(5, y + 14, 10, y + 14, c["pele"])
    # sapatos
    t.r(4, y + 20, 6, y + 20, c["sapato"])
    t.r(9, y + 20, 11, y + 20, c["sapato"])
    # cabeça
    t.r(4, y + 4, 11, y + 8, c["pele"])
    t.r(5, y + 9, 10, y + 9, c["pele"])
    t.p(11, y + 8, c["pele_s"])
    # cabelo branquinho com coque
    t.r(6, y, 9, y + 1, c["cabelo"])          # coque
    t.r(7, y, 8, y, c["cabelo_c"])
    t.r(4, y + 2, 11, y + 2, c["cabelo"])
    t.r(3, y + 3, 12, y + 3, c["cabelo"])
    t.r(3, y + 4, 4, y + 6, c["cabelo"])
    t.r(11, y + 4, 12, y + 6, c["cabelo_s"])
    t.r(5, y + 4, 10, y + 4, c["cabelo"])
    t.p(5, y + 2, c["cabelo_c"])
    t.p(4, y + 3, c["cabelo_c"])
    t.r(9, y + 3, 12, y + 3, c["cabelo_s"])
    # óculos redondinhos
    for ex in (5, 10):
        t.p(ex - 1, y + 6, c["oculos"])
        t.p(ex + 1, y + 6, c["oculos"])
        t.p(ex, y + 5, c["oculos"])
        t.p(ex, y + 7, c["oculos"])
        t.p(ex, y + 6, c["olho"])
    t.p(4, y + 8, c["bochecha"])
    t.p(11, y + 8, c["bochecha"])
    t.r(7, y + 8, 8, y + 8, c["boca"])
    return t.imagem()


def main():
    saida = sys.argv[1]
    os.makedirs(saida, exist_ok=True)
    todas = {}
    for n in (1, 2):
        for nome, img in poses(n).items():
            img.save(os.path.join(saida, "p%d_%s.png" % (n, nome)))
            todas["p%d_%s" % (n, nome)] = img
    vovo().save(os.path.join(saida, "vovo_zefa.png"))
    todas["vovo_zefa"] = vovo()
    if len(sys.argv) > 2:
        esc = 6
        nomes = list(todas)
        cols = 10
        linhas = (len(nomes) + cols - 1) // cols
        prev = Image.new("RGBA", (cols * (W * esc + 10) + 10, linhas * (H * esc + 26) + 10), (70, 120, 60, 255))
        d = ImageDraw.Draw(prev)
        for i, nome in enumerate(nomes):
            x = 10 + (i % cols) * (W * esc + 10)
            y = 10 + (i // cols) * (H * esc + 26)
            prev.alpha_composite(todas[nome].resize((W * esc, H * esc), Image.NEAREST), (x, y))
            d.text((x, y + H * esc + 2), nome.replace("p1_", "").replace("p2_", ""), fill=(255, 255, 255, 255))
        prev.convert("RGB").save(sys.argv[2])
    print("ok", len(todas))


main()
