#!/usr/bin/env python3
"""Ponte entre o controle de ESP32 (Bluetooth) e o jogo Juntos na Roça.

O ESP32 (firmware joystick_esp32_dois.ino) manda pelo Bluetooth linhas assim:
    J,X1,Y1,B1,X2,Y2,B2
No Windows, depois de parear o "Joystick-ESP32", ele vira uma porta COM.
O Godot não lê porta COM, então esta ponte lê a porta e repassa cada linha
para o jogo por UDP (127.0.0.1:4242). O autoload ControleESP32 faz o resto.

Uso:
    python ferramentas/ponte_esp32.py              (acha a porta sozinha)
    python ferramentas/ponte_esp32.py --porta COM5 (porta fixa)

O jogo já abre esta ponte sozinho quando roda pela pasta do projeto.
Precisa do pyserial:  python -m pip install pyserial
"""

import argparse
import os
import socket
import sys
import time

try:
    import serial
    import serial.tools.list_ports
except ImportError:
    print("Falta o pyserial. Instale com:  python -m pip install pyserial")
    sys.exit(1)

BAUD = 115200            # no Bluetooth SPP o baud não importa, mas a porta pede um
NOME_BT = "Joystick-ESP32"


def processo_vivo(pid):
    """True enquanto o jogo (pid) ainda está aberto."""
    if pid <= 0:
        return True
    if os.name == "nt":
        import ctypes
        k = ctypes.windll.kernel32
        h = k.OpenProcess(0x1000, False, pid)   # PROCESS_QUERY_LIMITED_INFORMATION
        if not h:
            return False
        codigo = ctypes.c_ulong()
        k.GetExitCodeProcess(h, ctypes.byref(codigo))
        k.CloseHandle(h)
        return codigo.value == 259   # STILL_ACTIVE
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def portas_candidatas():
    """Portas COM, com as de Bluetooth primeiro."""
    portas = list(serial.tools.list_ports.comports())

    def nota(p):
        texto = f"{p.description} {p.hwid} {p.name}".lower()
        if NOME_BT.lower() in texto:
            return 0
        if "bluetooth" in texto or "bthenum" in texto:
            return 1
        return 2
    return [p.device for p in sorted(portas, key=nota)]


def testar_porta(dispositivo, espera=4.0):
    """Abre a porta e vê se chegam linhas 'J,...'. Devolve a porta aberta ou None."""
    try:
        s = serial.Serial(dispositivo, BAUD, timeout=0.3, write_timeout=1)
    except (serial.SerialException, OSError):
        return None
    fim = time.time() + espera
    while time.time() < fim:
        try:
            linha = s.readline().decode("ascii", "ignore").strip()
        except (serial.SerialException, OSError):
            break
        if linha.startswith("J,") and linha.count(",") == 6:
            return s
    s.close()
    return None


def achar_porta(fixa):
    if fixa:
        return testar_porta(fixa, espera=6.0)
    for p in portas_candidatas():
        print(f"  testando {p}...")
        s = testar_porta(p)
        if s:
            return s
    return None


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--porta", help="porta COM do ESP32 (ex.: COM5). Sem isso, procura sozinha.")
    ap.add_argument("--udp", type=int, default=4242, help="porta UDP do jogo (padrão 4242)")
    ap.add_argument("--sair-com-pid", type=int, default=0, help="fecha quando este processo (o jogo) fechar")
    args = ap.parse_args()

    destino = ("127.0.0.1", args.udp)
    udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    print(f"Ponte ESP32 -> jogo (UDP {destino[0]}:{destino[1]})")

    while processo_vivo(args.sair_com_pid):
        print("Procurando o controle (ligue o ESP32 e pareie o Bluetooth)...")
        s = achar_porta(args.porta)
        if not s:
            time.sleep(2)
            continue
        print(f"Controle encontrado em {s.port}!")
        ultimo_aviso = time.time()
        try:
            while processo_vivo(args.sair_com_pid):
                linha = s.readline().decode("ascii", "ignore").strip()
                if linha.startswith("J,"):
                    udp.sendto(linha.encode("ascii"), destino)
                    ultimo_aviso = time.time()
                elif time.time() - ultimo_aviso > 3.0:
                    print("Sem sinal do controle há 3 s, procurando de novo...")
                    break
        except (serial.SerialException, OSError) as e:
            print(f"Conexão caiu: {e}")
        finally:
            try:
                s.close()
            except Exception:
                pass
        time.sleep(1)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
