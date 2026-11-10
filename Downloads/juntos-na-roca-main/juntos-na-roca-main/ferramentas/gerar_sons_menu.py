"""Músicas e sons do menu e do prefácio (todas as melodias são originais).

Uso: python3 gerar_sons_menu.py <pasta assets/sons>
"""
import os
import subprocess
import sys
import wave

import numpy as np

SONS = sys.argv[1]
SR = 22050


def t(d):
    return np.linspace(0, d, int(SR * d), endpoint=False)


def salvar_wav(nome, s, ganho=0.8):
    s = np.clip(s, -1, 1)
    with wave.open(os.path.join(SONS, nome + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((s * 32767 * ganho).astype(np.int16).tobytes())


def para_ogg(nome, s):
    salvar_wav(nome + "_tmp", s / max(1e-6, np.max(np.abs(s))) * 0.9, 1.0)
    tmp = os.path.join(SONS, nome + "_tmp.wav")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "5",
                    os.path.join(SONS, nome + ".ogg")], check=True)
    os.remove(tmp)


def f(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def onda(freq, dur, forma):
    tt = t(dur)
    fase = 2 * np.pi * freq * tt
    if forma == "seno":
        return np.sin(fase)
    if forma == "tri":
        return 2 / np.pi * np.arcsin(np.sin(fase))
    if forma == "quad":
        return np.sign(np.sin(fase)) * 0.5
    if forma == "pulso":
        return np.where((fase / (2 * np.pi)) % 1 < 0.25, 0.5, -0.5)
    if forma == "serra":
        return 2 * ((fase / (2 * np.pi)) % 1) - 1


def filtro(s, k):
    return np.convolve(s, np.ones(k) / k, mode="same")


def nota(freq, dur, forma="tri", ataque=0.01, queda=4.0, vol=1.0, vibrato=0.0):
    tt = t(dur)
    if vibrato:
        fase = 2 * np.pi * np.cumsum(freq * (1 + vibrato * np.sin(2 * np.pi * 5.5 * tt))) / SR
        if forma == "serra":
            s = 2 * ((fase / (2 * np.pi)) % 1) - 1
        else:
            s = np.sin(fase)
    else:
        s = onda(freq, dur, forma)
    env = np.minimum(1, tt / max(ataque, 1e-4)) * np.exp(-tt * queda)
    return s * env * vol


def tocar(mix, inicio, s):
    k = int(SR * inicio)
    fim = min(len(mix), k + len(s))
    if k < len(mix):
        mix[k:fim] += s[: fim - k]


# ================================================================== sons do menu
s = np.zeros(int(SR * 0.1))
tocar(s, 0, nota(1320, 0.07, "quad", queda=40, vol=0.5))
tocar(s, 0, nota(1980, 0.05, "seno", queda=60, vol=0.3))
salvar_wav("menu_mover", s)
s = np.zeros(int(SR * 0.6))
for i, m in enumerate((72, 76, 79, 84, 88)):
    tocar(s, i * 0.055, nota(f(m), 0.35, "tri", queda=7, vol=0.5))
    tocar(s, i * 0.055, nota(f(m) * 2, 0.25, "seno", queda=12, vol=0.15))
salvar_wav("menu_ok", s)
s = np.zeros(int(SR * 0.9))
for i in range(14):
    tocar(s, i * 0.04, nota(f(84 + (i * 5) % 17), 0.25, "seno", queda=14, vol=0.25))
salvar_wav("menu_abrir", s)
s = np.zeros(int(SR * 0.25))
tocar(s, 0, nota(660, 0.12, "tri", queda=20, vol=0.5))
tocar(s, 0.06, nota(440, 0.15, "tri", queda=18, vol=0.3))
salvar_wav("menu_voltar", s)

# ================================================================== música do menu (calma, de aventura)
bpm = 92
b = 60 / bpm
# Ré maior, compasso 3/4. (melodia original)
D4, E4, Fs4, G4, A4, B4, Cs5, D5, E5, Fs5, G5, A5 = 62, 64, 66, 67, 69, 71, 73, 74, 76, 78, 79, 81
mel = [
    (A4, 1), (D5, 1), (E5, 1), (Fs5, 2), (E5, 1), (D5, 1), (B4, 1), (A4, 1), (B4, 3),
    (G4, 1), (B4, 1), (D5, 1), (E5, 2), (D5, 1), (Cs5, 1), (A4, 1), (B4, 1), (A4, 3),
    (A4, 1), (D5, 1), (Fs5, 1), (A5, 2), (G5, 1), (Fs5, 1), (E5, 1), (D5, 1), (E5, 3),
    (G5, 1), (Fs5, 1), (E5, 1), (D5, 2), (B4, 1), (Cs5, 1), (E5, 1), (Cs5, 1), (D5, 3),
]
acordes = [(50, [62, 66, 69]), (43, [62, 67, 71]), (45, [61, 64, 69]), (50, [62, 66, 69]),
           (47, [62, 66, 71]), (43, [62, 67, 71]), (45, [61, 64, 69]), (50, [62, 66, 69])]
compassos = 16
total = compassos * 3 * b
mix = np.zeros(int(SR * total) + SR)
pos = 0.0
for m, d in mel:
    tocar(mix, pos, nota(f(m), d * b * 0.95, "pulso", ataque=0.02, queda=1.2, vol=0.28))
    tocar(mix, pos, nota(f(m) * 2, d * b * 0.6, "seno", ataque=0.01, queda=3.0, vol=0.08))
    pos += d * b
for c in range(compassos):
    raiz, notas = acordes[c % len(acordes)]
    inicio = c * 3 * b
    tocar(mix, inicio, nota(f(raiz), 3 * b, "tri", ataque=0.02, queda=0.8, vol=0.4))
    # arpejo tipo harpa
    for i in range(6):
        m = notas[i % 3] + (12 if i >= 3 else 0)
        tocar(mix, inicio + i * b / 2, nota(f(m), 0.6, "seno", ataque=0.003, queda=5, vol=0.16))
mix = mix[: int(SR * total)]
para_ogg("musica_menu", mix)

# ================================================================== fanfarra do prefácio (original)
bpm = 100
b = 60 / bpm
C3, G2, F2, A2 = 48, 43, 41, 45
C4, D4, E4, F4, G4, A4, B4, C5, D5, E5, F5, G5 = 60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79
# frase heroica (arpejos e saltos de quarta)
tema = [
    (C4, 0.5), (E4, 0.5), (G4, 0.5), (C5, 2.5),
    (B4, 0.5), (A4, 0.5), (G4, 1), (E4, 2),
    (F4, 0.5), (A4, 0.5), (C5, 0.5), (F5, 2.5),
    (E5, 0.5), (D5, 0.5), (C5, 1), (G4, 2),
    (A4, 1), (C5, 1), (E5, 1.5), (D5, 0.5),
    (C5, 1), (A4, 1), (G4, 2),
    (F4, 1), (A4, 1), (D5, 1.5), (C5, 0.5),
    (B4, 1), (G4, 1), (C5, 4),
]
harmonia = [(C3, 4), (A2, 4), (F2, 4), (G2, 4), (A2, 4), (F2, 4), (F2, 4), (G2, 2), (C3, 6)]
dur_tema = sum(d for _, d in tema) * b
total = 3 * b * 4 + dur_tema * 2 + 8 * b * 4
mix = np.zeros(int(SR * total) + SR * 2)


def metal(m, d, vol=0.3):
    s = nota(f(m), d, "serra", ataque=0.05, queda=0.6, vol=vol, vibrato=0.004)
    s2 = nota(f(m) * 0.5, d, "serra", ataque=0.05, queda=0.6, vol=vol * 0.5, vibrato=0.004)
    n = min(len(s), len(s2))
    return filtro(s[:n] + s2[:n], 5)


def tambor(vol=0.6):
    tt = t(0.6)
    s = np.sin(2 * np.pi * np.cumsum(70 + 60 * np.exp(-tt * 8)) / SR) * np.exp(-tt * 5)
    s = s + np.random.default_rng(3).uniform(-1, 1, len(tt)) * np.exp(-tt * 30) * 0.3
    return s * vol


# introdução: rufar de tambores e acorde que cresce
inicio = 0.0
for i in range(24):
    tocar(mix, i * b / 2, tambor(0.15 + 0.02 * i))
for m in (C3, C4, G4, E4 + 12):
    s = nota(f(m), 12 * b, "serra", ataque=10 * b, queda=0.05, vol=0.12)
    tocar(mix, 0, filtro(s, 7))
pos = 12 * b
for repeticao in range(2):
    p = pos
    for m, d in tema:
        tocar(mix, p, metal(m, d * b * 0.95, 0.3))
        p += d * b
    p = pos
    for raiz, d in harmonia:
        tocar(mix, p, filtro(nota(f(raiz), d * b, "serra", ataque=0.08, queda=0.3, vol=0.22), 9))
        tocar(mix, p, filtro(nota(f(raiz + 12), d * b, "serra", ataque=0.3, queda=0.2, vol=0.08), 9))
        tocar(mix, p, filtro(nota(f(raiz + 19), d * b, "serra", ataque=0.3, queda=0.2, vol=0.06), 9))
        tocar(mix, p, tambor(0.5))
        p += d * b
    pos += dur_tema
# final: acorde grande que fica
for m in (C3, C4, E4, G4, C5):
    tocar(mix, pos, filtro(nota(f(m), 8 * b * 4, "serra", ataque=0.1, queda=0.25, vol=0.13), 7))
tocar(mix, pos, tambor(0.8))
mix = mix[: int(SR * total)]
fade = int(SR * 4)
mix[-fade:] *= np.linspace(1, 0, fade)
para_ogg("musica_prefacio", mix)
print("sons ok", round(total, 1), "s de prefácio")
