#!/usr/bin/env python3
"""Gera toda a arte do Monkey Adventure como ilustrações SVG (com degradê e sombra).

Rodar:  python3 ferramentas/gerar_arte.py
Saída:  arte/*.svg  e  arte/manifesto.json  (tamanho e âncora de cada desenho)

Os bichos olham para a esquerda (vêm na direção do Macaco); o Macaco olha para a direita.
"""
import json
import math
import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "arte")
ESCALA = 2  # desenha com o dobro de pixels para ficar nítido no celular
MANIFESTO = {}
_gid = [0]


# ------------------------------------------------------------------ utilidades

def hexrgb(h):
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def tom(h, f):
    """f>1 clareia, f<1 escurece."""
    r, g, b = hexrgb(h)
    if f >= 1:
        k = f - 1
        r, g, b = [int(c + (255 - c) * k) for c in (r, g, b)]
    else:
        r, g, b = [int(c * f) for c in (r, g, b)]
    return "#%02x%02x%02x" % tuple(max(0, min(255, c)) for c in (r, g, b))


class Arte:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.defs = []
        self.corpo = []

    def gid(self, p):
        _gid[0] += 1
        return "%s%d" % (p, _gid[0])

    def radial(self, cor, cx=0.38, cy=0.3, r=0.75, claro=1.35, escuro=0.62):
        i = self.gid("r")
        self.defs.append(
            f'<radialGradient id="{i}" cx="{cx}" cy="{cy}" r="{r}">'
            f'<stop offset="0" stop-color="{tom(cor, claro)}"/>'
            f'<stop offset="0.55" stop-color="{cor}"/>'
            f'<stop offset="1" stop-color="{tom(cor, escuro)}"/></radialGradient>')
        return f"url(#{i})"

    def linear(self, cores, x1=0, y1=0, x2=0, y2=1, ops=None):
        i = self.gid("l")
        n = len(cores)
        stops = "".join(
            f'<stop offset="{k / (n - 1) if n > 1 else 0:.3f}" stop-color="{c}"'
            + (f' stop-opacity="{ops[k]}"' if ops else "") + "/>"
            for k, c in enumerate(cores))
        self.defs.append(f'<linearGradient id="{i}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{stops}</linearGradient>')
        return f"url(#{i})"

    def add(self, s):
        self.corpo.append(s)

    # formas com contorno
    def elipse(self, cx, cy, rx, ry, cor, contorno=True, grad=True, extra=""):
        fill = self.radial(cor) if grad else cor
        st = f' stroke="{tom(cor, 0.45)}" stroke-width="1.6"' if contorno else ""
        self.add(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{fill}"{st} {extra}/>')

    def circ(self, cx, cy, r, cor, contorno=True, grad=True):
        self.elipse(cx, cy, r, r, cor, contorno, grad)

    def caminho(self, d, cor, contorno=True, grad=True, larg=1.6, extra=""):
        fill = self.radial(cor) if grad else cor
        st = f' stroke="{tom(cor, 0.45)}" stroke-width="{larg}" stroke-linejoin="round"' if contorno else ""
        self.add(f'<path d="{d}" fill="{fill}"{st} {extra}/>')

    def linha(self, d, cor, larg, cap="round", op=1.0):
        self.add(f'<path d="{d}" fill="none" stroke="{cor}" stroke-width="{larg}" stroke-linecap="{cap}" stroke-linejoin="round" opacity="{op}"/>')

    def membro(self, pts, cor, larg):
        """Perna/braço grosso com contorno."""
        d = "M" + " L".join(f"{x},{y}" for x, y in pts)
        self.linha(d, tom(cor, 0.45), larg + 2.4)
        self.linha(d, cor, larg)

    def sombra(self, cx, cy, rx, ry=None):
        ry = ry or rx * 0.22
        f = self.radial("#000000", 0.5, 0.5, 0.5, 1, 1)
        i = self.gid("s")
        self.defs.append(f'<radialGradient id="{i}"><stop offset="0" stop-color="#000" stop-opacity="0.35"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>')
        self.add(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="url(#{i})"/>')

    def olho(self, cx, cy, r=4.0, pupila=None, irritado=False, cor_iris=None):
        self.add(f'<ellipse cx="{cx}" cy="{cy}" rx="{r}" ry="{r * 1.15}" fill="#ffffff" stroke="#222" stroke-width="0.9"/>')
        pr = pupila or r * 0.55
        if cor_iris:
            self.add(f'<circle cx="{cx - r * 0.25}" cy="{cy + r * 0.1}" r="{pr * 1.35}" fill="{cor_iris}"/>')
        self.add(f'<circle cx="{cx - r * 0.25}" cy="{cy + r * 0.1}" r="{pr}" fill="#1a1a1a"/>')
        self.add(f'<circle cx="{cx - r * 0.45}" cy="{cy - r * 0.3}" r="{r * 0.28}" fill="#fff"/>')
        if irritado:
            self.linha(f"M{cx - r * 1.3},{cy - r * 1.6} L{cx + r * 1.1},{cy - r * 0.9}", "#222", r * 0.5)

    def texto(self):
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w * ESCALA}" height="{self.h * ESCALA}" '
                f'viewBox="0 0 {self.w} {self.h}"><defs>{"".join(self.defs)}</defs>{"".join(self.corpo)}</svg>')


def salvar(nome, arte, ancora="base", dy=0):
    os.makedirs(SAIDA, exist_ok=True)
    with open(os.path.join(SAIDA, nome + ".svg"), "w", encoding="utf-8") as f:
        f.write(arte.texto())
    MANIFESTO[nome] = {"w": arte.w, "h": arte.h, "ancora": ancora, "dy": dy}


# ------------------------------------------------------------------ Macaco

MARROM = "#8a5a2b"
BEGE = "#f0d2a8"


def macaco(nome, pose):
    a = Arte(96, 104)
    base = 100
    a.sombra(46, base, 26, 5)
    g = []
    if pose == "abaixado":
        a.add('<g transform="translate(0,23) scale(1,0.77)">')
    # rabo
    a.linha("M30,74 C10,78 4,58 15,50 C22,45 28,52 22,56", tom(MARROM, 0.45), 7.5)
    a.linha("M30,74 C10,78 4,58 15,50 C22,45 28,52 22,56", MARROM, 5)
    # pernas
    pernas = {
        "corre1": [[(40, 78), (32, 88), (26, 97)], [(50, 78), (58, 87), (64, 97)]],
        "corre2": [[(40, 78), (42, 89), (38, 97)], [(50, 78), (48, 89), (53, 97)]],
        "pulo": [[(40, 78), (32, 84), (28, 92)], [(50, 78), (60, 82), (66, 90)]],
        "abaixado": [[(40, 78), (34, 89), (30, 97)], [(50, 78), (56, 89), (60, 97)]],
        "pendurado": [[(40, 78), (38, 90), (36, 99)], [(50, 78), (54, 90), (56, 99)]],
    }[pose]
    escuro = tom(MARROM, 0.78)
    a.membro(pernas[0], escuro, 7)
    px, py = pernas[0][-1]
    a.elipse(px, py, 6, 3.2, "#5a3a1c", grad=False)
    # braço de trás
    bracos = {
        "corre1": [[(38, 52), (30, 60), (24, 66)], [(52, 52), (60, 58), (66, 62)]],
        "corre2": [[(38, 52), (44, 62), (50, 66)], [(52, 52), (46, 60), (40, 64)]],
        "pulo": [[(38, 50), (30, 40), (26, 30)], [(52, 50), (60, 40), (66, 30)]],
        "abaixado": [[(38, 54), (32, 64), (28, 72)], [(52, 54), (58, 64), (62, 72)]],
        "pendurado": [[(40, 48), (44, 30), (50, 12)], [(52, 50), (56, 30), (54, 12)]],
    }[pose]
    a.membro(bracos[0], escuro, 6)
    # sacolinha
    a.linha("M45,44 L28,64", "#7a4b12", 2.2)
    a.caminho("M20,62 Q20,58 24,58 L34,58 Q38,58 38,62 L37,74 Q37,77 33,77 L25,77 Q21,77 21,74 Z", "#d9a441")
    a.linha("M24,60 Q29,52 34,60", "#f2c94c", 3)
    # corpo
    a.elipse(44, 63, 17, 20, MARROM)
    a.elipse(48, 67, 10, 13, BEGE, contorno=False)
    # perna da frente
    a.membro(pernas[1], MARROM, 7.5)
    px, py = pernas[1][-1]
    a.elipse(px + 1, py, 6.5, 3.4, "#5a3a1c", grad=False)
    # braço da frente
    a.membro(bracos[1], MARROM, 6.5)
    hx, hy = bracos[1][-1]
    a.circ(hx, hy, 3.6, "#c89a6a")
    # cabeça
    a.circ(33, 30, 8.5, MARROM)
    a.circ(33, 30, 4.8, "#e3b98a", contorno=False)
    a.circ(52, 30, 19.5, MARROM)
    a.circ(70, 28, 8, MARROM)
    a.circ(70, 28, 4.5, "#e3b98a", contorno=False)
    a.caminho("M42,29 C42,20 52,19 54,25 C56,19 66,20 66,29 C68,40 62,47 54,47 C46,47 40,40 42,29 Z", BEGE, contorno=False)
    a.linha("M44,13 Q48,7 50,12 Q53,5 55,12 Q59,8 60,14", tom(MARROM, 0.7), 3)
    a.olho(49, 29, 4.3, irritado=False)
    a.olho(60, 29, 4.3)
    a.add('<circle cx="54" cy="36" r="1" fill="#3a2410"/><circle cx="57" cy="36" r="1" fill="#3a2410"/>')
    a.linha("M49,40 Q55,45 62,39", "#3a2410", 1.6)
    a.add('<path d="M52,41.5 Q55,44 59,41" fill="#e8737a"/>')
    if pose == "abaixado":
        a.add("</g>")
    salvar(nome, a)


# ------------------------------------------------------------------ bananas

BANANAS = {
    "banana_normal": ("#ffe14d", "#e6a800"),
    "banana_bronze": ("#f0b070", "#8c4a1a"),
    "banana_prata": ("#ffffff", "#8d96a3"),
    "banana_metalica": ("#d0dbe8", "#3f4c5c"),
    "banana_verde": ("#a8ec72", "#3a8a22"),
    "banana_ouro": ("#fff6b0", "#d99a00"),
}


def banana(nome, claro, escuro):
    a = Arte(44, 40)
    if nome in ("banana_ouro", "banana_prata", "banana_metalica"):
        i = a.gid("b")
        a.defs.append(f'<radialGradient id="{i}"><stop offset="0" stop-color="{claro}" stop-opacity="0.75"/><stop offset="1" stop-color="{claro}" stop-opacity="0"/></radialGradient>')
        a.add(f'<circle cx="22" cy="20" r="20" fill="url(#{i})"/>')
    for k, ang in enumerate((-22, 0, 22)):
        g = a.linear([claro, tom(escuro, 1.15), escuro], 0, 0, 0, 1)
        a.add(f'<g transform="rotate({ang} 22 8)">'
              f'<path d="M21,8 C16,16 14,26 20,34 C24,38 30,38 33,36 C26,34 22,26 24,16 C24.5,13 24,10 23,8 Z" '
              f'fill="{g}" stroke="{tom(escuro, 0.6)}" stroke-width="1.2" stroke-linejoin="round"/>'
              f'<path d="M22,12 C19,20 19,27 23,32" fill="none" stroke="#ffffff" stroke-opacity="0.55" stroke-width="1.4" stroke-linecap="round"/>'
              f'<circle cx="32.5" cy="35.6" r="1.4" fill="{tom(escuro, 0.45)}"/></g>')
    a.add(f'<rect x="19" y="3" width="6" height="7" rx="2" fill="{tom(escuro, 0.55)}"/>')
    if nome in ("banana_prata", "banana_metalica", "banana_ouro"):
        a.add('<path d="M10,8 l2,-5 l2,5 l5,2 l-5,2 l-2,5 l-2,-5 l-5,-2 Z" fill="#fff"/>')
    salvar(nome, a, "centro")


# ------------------------------------------------------------------ famílias de bichos (olhando para a esquerda)

def quadrupede(nome, w, h, cor, barriga=None, **o):
    """Bicho de quatro patas. Opções: listras, juba, chifres, tromba, orelhas, rabo, manchas, barba, chifre_nariz."""
    a = Arte(w, h)
    S = w / 100.0  # escala: desenhado num corpo de 100 de largura
    base = h - 2
    a.sombra(w * 0.5, base, w * 0.42, h * 0.05)
    perna_h = o.get("perna", 0.36) * h
    corpo_cy = base - perna_h - h * 0.16
    corpo_rx = w * 0.31
    corpo_ry = h * o.get("corpo", 0.22)
    cx = w * o.get("cx", 0.57)
    escuro = tom(cor, 0.72)
    # patas de trás (mais escuras)
    for px in (cx - corpo_rx * 0.6, cx + corpo_rx * 0.65):
        a.membro([(px + 4 * S, corpo_cy + corpo_ry * 0.4), (px + 6 * S, base - 3)], escuro, 9 * S)
    # rabo
    if o.get("rabo", True):
        tx = cx + corpo_rx * 0.95
        a.linha(f"M{tx},{corpo_cy - corpo_ry * 0.3} Q{tx + 11 * S},{corpo_cy - corpo_ry} {tx + 12 * S},{corpo_cy + corpo_ry * 0.6}", tom(cor, 0.5), 4.5 * S)
        a.linha(f"M{tx},{corpo_cy - corpo_ry * 0.3} Q{tx + 11 * S},{corpo_cy - corpo_ry} {tx + 12 * S},{corpo_cy + corpo_ry * 0.6}", cor, 3 * S)
        if o.get("rabo_tufo"):
            a.circ(tx + 12 * S, corpo_cy + corpo_ry * 0.7, 4.5 * S, o["rabo_tufo"])
    # corpo
    a.elipse(cx, corpo_cy, corpo_rx, corpo_ry, cor)
    if barriga:
        a.elipse(cx, corpo_cy + corpo_ry * 0.45, corpo_rx * 0.75, corpo_ry * 0.45, barriga, contorno=False)
    if o.get("listras"):
        for k in range(6):
            x = cx - corpo_rx * 0.75 + k * corpo_rx * 0.3
            a.linha(f"M{x},{corpo_cy - corpo_ry * 0.95} Q{x - 6 * S},{corpo_cy} {x + 2 * S},{corpo_cy + corpo_ry * 0.9}", "#1a1a1a", 4.5 * S)
    if o.get("manchas"):
        for k in range(7):
            x = cx - corpo_rx * 0.7 + (k * 37 % 100) / 100 * corpo_rx * 1.4
            y = corpo_cy - corpo_ry * 0.5 + (k * 53 % 100) / 100 * corpo_ry * 0.9
            a.circ(x, y, 3.2 * S, o["manchas"], contorno=False, grad=False)
    # patas da frente
    for px in (cx - corpo_rx * 0.75, cx + corpo_rx * 0.5):
        a.membro([(px, corpo_cy + corpo_ry * 0.3), (px - 2 * S, base - 3)], cor, 10 * S)
        a.elipse(px - 2 * S, base - 2.5, 6 * S, 3 * S, o.get("casco", tom(cor, 0.4)), grad=False)
    # pescoço e cabeça
    hx = cx - corpo_rx * 1.05
    hy = corpo_cy - corpo_ry * o.get("pescoco", 1.0)
    hr = w * o.get("cabeca", 0.13)
    if o.get("juba"):
        a.circ(hx + 2 * S, hy + 2 * S, hr * 1.75, o["juba"])
        for k in range(10):
            ang = k / 10 * math.tau
            a.circ(hx + 2 * S + math.cos(ang) * hr * 1.6, hy + 2 * S + math.sin(ang) * hr * 1.6, hr * 0.45, o["juba"], contorno=False)
    a.caminho(f"M{hx + hr * 0.4},{hy + hr * 0.6} L{cx - corpo_rx * 0.6},{corpo_cy - corpo_ry * 0.2} L{cx - corpo_rx * 0.4},{corpo_cy + corpo_ry * 0.5} L{hx + hr * 0.9},{hy + hr * 1.2} Z", cor, contorno=False)
    if o.get("orelhas"):
        ox, oy = hx + hr * 0.45, hy - hr * 0.7
        if o["orelhas"] == "pontuda":
            a.caminho(f"M{ox - 4 * S},{oy + 4 * S} L{ox},{oy - 10 * S} L{ox + 5 * S},{oy + 4 * S} Z", cor)
        elif o["orelhas"] == "redonda":
            a.circ(ox + 2 * S, oy + 2 * S, hr * 0.42, cor)
        elif o["orelhas"] == "caida":
            a.elipse(ox + 3 * S, oy + hr * 0.6, hr * 0.32, hr * 0.7, escuro)
        elif o["orelhas"] == "elefante":
            a.elipse(hx + hr * 0.9, hy + hr * 0.2, hr * 0.95, hr * 1.25, tom(cor, 0.9))
            a.elipse(hx + hr * 0.95, hy + hr * 0.25, hr * 0.65, hr * 0.95, "#d9a0a0", contorno=False)
    a.elipse(hx, hy, hr * 1.05, hr * 0.95, cor)
    # focinho
    fx = hx - hr * o.get("focinho", 0.75)
    a.elipse(fx, hy + hr * 0.3, hr * 0.62, hr * 0.48, o.get("cor_focinho", tom(cor, 1.15)))
    a.add(f'<ellipse cx="{fx - hr * 0.45}" cy="{hy + hr * 0.15}" rx="{hr * 0.13}" ry="{hr * 0.1}" fill="#1a1a1a"/>')
    a.linha(f"M{fx - hr * 0.4},{hy + hr * 0.6} Q{fx},{hy + hr * 0.75} {fx + hr * 0.3},{hy + hr * 0.55}", "#2a1a10", 1.2 * S)
    if o.get("dentes"):
        a.add(f'<path d="M{fx - hr * 0.3},{hy + hr * 0.62} l{hr * 0.12},{hr * 0.3} l{hr * 0.12},{-hr * 0.3} Z" fill="#fff"/>')
    if o.get("tromba"):
        a.linha(f"M{hx - hr * 0.6},{hy + hr * 0.2} C{hx - hr * 1.6},{hy + hr * 0.5} {hx - hr * 1.5},{hy + hr * 2.3} {hx - hr * 1.9},{hy + hr * 2.6}", tom(cor, 0.5), hr * 0.62)
        a.linha(f"M{hx - hr * 0.6},{hy + hr * 0.2} C{hx - hr * 1.6},{hy + hr * 0.5} {hx - hr * 1.5},{hy + hr * 2.3} {hx - hr * 1.9},{hy + hr * 2.6}", cor, hr * 0.5)
        a.caminho(f"M{hx - hr * 0.3},{hy + hr * 0.7} q{-hr * 0.6},{hr * 0.4} {-hr * 0.9},{hr * 0.1} q{hr * 0.4},{hr * 0.1} {hr * 0.9},{-hr * 0.4} Z", "#fffbe8")
    if o.get("chifres"):
        c = o["chifres"]
        a.caminho(f"M{hx},{hy - hr * 0.7} C{hx - 2 * S},{hy - hr * 1.6} {hx + hr * 0.6},{hy - hr * 2.1} {hx + hr * 1.3},{hy - hr * 1.9} C{hx + hr * 0.6},{hy - hr * 1.6} {hx + hr * 0.4},{hy - hr * 1.2} {hx + hr * 0.5},{hy - hr * 0.6} Z", c)
    if o.get("chifre_nariz"):
        a.caminho(f"M{fx - hr * 0.2},{hy - hr * 0.1} L{fx - hr * 0.6},{hy - hr * 1.3} L{fx + hr * 0.35},{hy - hr * 0.2} Z", "#efe6d0")
    if o.get("barba"):
        a.caminho(f"M{fx + hr * 0.1},{hy + hr * 0.7} l{-hr * 0.2},{hr * 0.9} l{hr * 0.45},{-hr * 0.8} Z", tom(cor, 0.8))
    a.olho(hx - hr * 0.15, hy - hr * 0.25, hr * 0.27, irritado=o.get("bravo", True))
    salvar(nome, a)


def ave(nome, w, h, cor, **o):
    """Ave. Opções: voando, bico (curto/gancho/longo/pato), crista, pernas (curta/longa), asa_cor, peito."""
    a = Arte(w, h)
    S = w / 100.0
    voando = o.get("voando", False)
    if not voando:
        a.sombra(w * 0.5, h - 2, w * 0.35, h * 0.05)
    cx, cy = (w * 0.45, h * 0.62) if voando else (w * 0.55, h * 0.48)
    rx, ry = w * 0.32, h * (0.24 if voando else 0.26)
    asa = o.get("asa_cor", tom(cor, 0.8))
    if voando:
        a.caminho(f"M{cx},{cy - ry * 0.3} C{cx + rx * 0.2},{cy - h * 0.52} {cx + rx * 1.3},{cy - h * 0.58} {cx + rx * 1.55},{cy - h * 0.42} C{cx + rx * 1.1},{cy - h * 0.3} {cx + rx * 0.7},{cy - ry * 0.4} {cx + rx * 0.4},{cy} Z", tom(asa, 0.8))
    # cauda
    a.caminho(f"M{cx + rx * 0.8},{cy} L{cx + rx * 1.55},{cy - ry * 0.4} L{cx + rx * 1.6},{cy + ry * 0.5} Z", o.get("cauda", asa))
    if o.get("pernas") and not voando:
        comp = h * (0.42 if o["pernas"] == "longa" else 0.14)
        for dx in (-rx * 0.15, rx * 0.2):
            a.membro([(cx + dx, cy + ry * 0.8), (cx + dx, cy + ry * 0.8 + comp)], o.get("cor_pernas", "#e0a020"), 2.6 * S)
            a.linha(f"M{cx + dx - 5 * S},{cy + ry * 0.8 + comp} L{cx + dx + 3 * S},{cy + ry * 0.8 + comp}", o.get("cor_pernas", "#e0a020"), 2.4 * S)
    a.elipse(cx, cy, rx, ry, cor)
    if o.get("peito"):
        a.elipse(cx - rx * 0.35, cy + ry * 0.25, rx * 0.5, ry * 0.6, o["peito"], contorno=False)
    # cabeça
    hx, hy = cx - rx * 0.95, cy - ry * (0.9 if not o.get("pescoco_longo") else 2.2)
    hr = min(w, h) * o.get("cabeca", 0.17)
    if o.get("pescoco_longo"):
        a.linha(f"M{cx - rx * 0.6},{cy - ry * 0.3} Q{hx + hr},{cy - ry} {hx + hr * 0.3},{hy + hr * 0.5}", tom(cor, 0.5), hr * 0.9)
        a.linha(f"M{cx - rx * 0.6},{cy - ry * 0.3} Q{hx + hr},{cy - ry} {hx + hr * 0.3},{hy + hr * 0.5}", cor, hr * 0.7)
    a.circ(hx, hy, hr, o.get("cabeca_cor", cor))
    if o.get("crista"):
        a.caminho(f"M{hx - hr * 0.5},{hy - hr * 0.7} q{hr * 0.2},{-hr * 0.9} {hr * 0.5},{-hr * 0.2} q{hr * 0.2},{-hr * 0.9} {hr * 0.5},{-hr * 0.1} q{hr * 0.3},{-hr * 0.7} {hr * 0.5},{hr * 0.2} Z", o["crista"])
    bico = o.get("bico", "curto")
    bc = o.get("bico_cor", "#f2b233")
    if bico == "curto":
        a.caminho(f"M{hx - hr * 0.8},{hy - hr * 0.1} L{hx - hr * 1.6},{hy + hr * 0.15} L{hx - hr * 0.75},{hy + hr * 0.4} Z", bc)
    elif bico == "gancho":
        a.caminho(f"M{hx - hr * 0.7},{hy - hr * 0.3} C{hx - hr * 1.6},{hy - hr * 0.4} {hx - hr * 1.8},{hy + hr * 0.3} {hx - hr * 1.5},{hy + hr * 0.7} C{hx - hr * 1.3},{hy + hr * 0.3} {hx - hr},{hy + hr * 0.4} {hx - hr * 0.7},{hy + hr * 0.4} Z", bc)
    elif bico == "longo":
        a.caminho(f"M{hx - hr * 0.7},{hy - hr * 0.2} L{hx - hr * 2.6},{hy + hr * 0.6} L{hx - hr * 0.7},{hy + hr * 0.35} Z", bc)
    elif bico == "torto":
        a.caminho(f"M{hx - hr * 0.7},{hy - hr * 0.2} L{hx - hr * 1.8},{hy + hr * 0.1} Q{hx - hr * 2.2},{hy + hr * 0.8} {hx - hr * 1.6},{hy + hr * 1.1} L{hx - hr * 0.7},{hy + hr * 0.4} Z", bc)
    if o.get("barbela"):
        a.elipse(hx - hr * 0.85, hy + hr * 0.75, hr * 0.22, hr * 0.38, o["barbela"])
    if o.get("olhos_coruja"):
        for dx in (-hr * 0.45, hr * 0.35):
            a.circ(hx + dx, hy - hr * 0.1, hr * 0.42, "#fff3c4")
            a.olho(hx + dx, hy - hr * 0.1, hr * 0.28, cor_iris="#f2a900", irritado=True)
    else:
        a.olho(hx - hr * 0.25, hy - hr * 0.2, hr * 0.3, irritado=o.get("bravo", True))
    # asa da frente
    if voando:
        a.caminho(f"M{cx - rx * 0.2},{cy - ry * 0.2} C{cx - rx * 0.3},{cy - h * 0.56} {cx + rx * 0.9},{cy - h * 0.6} {cx + rx * 1.2},{cy - h * 0.48} C{cx + rx * 0.7},{cy - h * 0.35} {cx + rx * 0.4},{cy - ry * 0.3} {cx + rx * 0.2},{cy + ry * 0.2} Z", asa)
        for k in range(3):
            x = cx + rx * (0.2 + k * 0.3)
            a.linha(f"M{x},{cy - h * 0.3 - k * 2} L{x + 6 * S},{cy - h * 0.45 - k * 3}", tom(asa, 0.6), 1.2 * S)
    else:
        a.caminho(f"M{cx - rx * 0.3},{cy - ry * 0.3} C{cx + rx * 0.4},{cy - ry * 0.8} {cx + rx * 1.1},{cy - ry * 0.1} {cx + rx * 1.0},{cy + ry * 0.4} C{cx + rx * 0.4},{cy + ry * 0.6} {cx - rx * 0.1},{cy + ry * 0.4} {cx - rx * 0.3},{cy - ry * 0.3} Z", asa)
    salvar(nome, a, "centro" if voando else "base")


def primata(nome, w, h, cor, rosto, **o):
    """Gorila, babuíno, macaco bagunceiro (olhando para a esquerda)."""
    a = Arte(w, h)
    S = w / 100.0
    base = h - 2
    a.sombra(w * 0.5, base, w * 0.4, h * 0.05)
    escuro = tom(cor, 0.7)
    peito = o.get("peito", 0.34)
    cx, cy = w * 0.54, base - h * 0.42
    # perna de trás e braço de trás
    a.membro([(cx + w * 0.1, cy + h * 0.15), (cx + w * 0.16, base - 4)], escuro, 13 * S)
    a.membro([(cx + w * 0.16, cy - h * 0.12), (cx + w * 0.26, cy + h * 0.15), (cx + w * 0.22, base - 6)], escuro, 12 * S)
    if o.get("rabo"):
        a.linha(f"M{cx + w * 0.2},{cy + h * 0.1} C{cx + w * 0.45},{cy} {cx + w * 0.42},{cy - h * 0.3} {cx + w * 0.3},{cy - h * 0.3}", escuro, 5 * S)
    a.elipse(cx, cy, w * peito, h * 0.3, cor)
    if o.get("costas_prata"):
        a.elipse(cx + w * 0.08, cy - h * 0.08, w * peito * 0.7, h * 0.16, "#b9bcc2", contorno=False)
    a.elipse(cx - w * 0.06, cy + h * 0.04, w * peito * 0.6, h * 0.2, rosto, contorno=False)
    a.membro([(cx - w * 0.04, cy + h * 0.15), (cx - w * 0.1, base - 4)], cor, 14 * S)
    a.elipse(cx - w * 0.14, base - 3, 9 * S, 4 * S, tom(cor, 0.5), grad=False)
    # braço da frente (comprido, apoiado no chão)
    a.membro([(cx - w * 0.16, cy - h * 0.14), (cx - w * 0.3, cy + h * 0.1), (cx - w * 0.3, base - 6)], cor, 14 * S)
    a.circ(cx - w * 0.3, base - 6, 7 * S, rosto)
    # cabeça
    hx, hy, hr = cx - w * 0.2, cy - h * 0.3, w * o.get("cabeca", 0.16)
    a.circ(hx, hy, hr, cor)
    if o.get("orelhas", True):
        a.circ(hx + hr * 0.9, hy - hr * 0.1, hr * 0.3, rosto)
    if o.get("focinho_longo"):
        a.elipse(hx - hr * 0.75, hy + hr * 0.3, hr * 0.7, hr * 0.42, rosto)
        a.add(f'<circle cx="{hx - hr * 1.3}" cy="{hy + hr * 0.2}" r="{hr * 0.1}" fill="#222"/>')
    else:
        a.elipse(hx - hr * 0.3, hy + hr * 0.15, hr * 0.7, hr * 0.62, rosto, contorno=False)
        a.add(f'<ellipse cx="{hx - hr * 0.55}" cy="{hy + hr * 0.3}" rx="{hr * 0.2}" ry="{hr * 0.12}" fill="#2a1a12"/>')
    a.linha(f"M{hx - hr * 0.75},{hy - hr * 0.45} L{hx + hr * 0.2},{hy - hr * 0.5}", tom(cor, 0.5), hr * 0.18)
    a.olho(hx - hr * 0.45, hy - hr * 0.2, hr * 0.2, irritado=True)
    a.olho(hx + hr * 0.05, hy - hr * 0.2, hr * 0.2, irritado=True)
    if o.get("boca_aberta"):
        a.add(f'<ellipse cx="{hx - hr * 0.4}" cy="{hy + hr * 0.6}" rx="{hr * 0.28}" ry="{hr * 0.16}" fill="#5a1a1a"/>')
    salvar(nome, a)


def humano(nome, w, h, roupa, **o):
    a = Arte(w, h)
    S = h / 100.0
    base = h - 2
    a.sombra(w * 0.5, base, w * 0.35, h * 0.04)
    cx = w * 0.5
    pele = o.get("pele", "#d8a27a")
    calca = o.get("calca", "#334466")
    a.membro([(cx + 3 * S, base - 46 * S), (cx + 6 * S, base - 4)], tom(calca, 0.8), 8 * S)
    a.membro([(cx - 3 * S, base - 46 * S), (cx - 7 * S, base - 4)], calca, 8 * S)
    a.elipse(cx - 9 * S, base - 3, 7 * S, 3.5 * S, "#2a2a2a", grad=False)
    a.elipse(cx + 3 * S, base - 3, 7 * S, 3.5 * S, "#2a2a2a", grad=False)
    a.caminho(f"M{cx - 11 * S},{base - 74 * S} Q{cx},{base - 80 * S} {cx + 11 * S},{base - 74 * S} L{cx + 12 * S},{base - 44 * S} L{cx - 12 * S},{base - 44 * S} Z", roupa)
    # braço segurando algo à frente
    a.membro([(cx - 6 * S, base - 70 * S), (cx - 16 * S, base - 58 * S), (cx - 24 * S, base - 64 * S)], roupa, 6 * S)
    a.circ(cx - 25 * S, base - 64 * S, 3.5 * S, pele)
    a.circ(cx, base - 86 * S, 10 * S, pele)
    a.caminho(f"M{cx - 11 * S},{base - 88 * S} Q{cx},{base - 102 * S} {cx + 11 * S},{base - 88 * S} L{cx + 14 * S},{base - 86 * S} L{cx - 14 * S},{base - 86 * S} Z", o.get("bone", tom(roupa, 0.8)))
    a.olho(cx - 4 * S, base - 85 * S, 2.6 * S, irritado=True)
    a.linha(f"M{cx - 7 * S},{base - 79 * S} Q{cx - 3 * S},{base - 81 * S} {cx + 1 * S},{base - 79 * S}", "#5a2a1a", 1.2 * S)
    if o.get("rede"):
        a.linha(f"M{cx - 24 * S},{base - 64 * S} L{cx - 30 * S},{base - 98 * S}", "#8a6a3a", 2.4 * S)
        a.add(f'<circle cx="{cx - 33 * S}" cy="{base - 108 * S}" r="{12 * S}" fill="none" stroke="#8a6a3a" stroke-width="{2 * S}"/>')
        for k in range(5):
            a.linha(f"M{cx - 44 * S + k * 5 * S},{base - 112 * S} L{cx - 38 * S + k * 4 * S},{base - 100 * S}", "#cfc6b0", 0.8 * S)
    if o.get("apito"):
        a.add(f'<rect x="{cx - 12 * S}" y="{base - 82 * S}" width="{4 * S}" height="{2.5 * S}" fill="#ddd" stroke="#555" stroke-width="0.5"/>')
    if o.get("balde"):
        a.caminho(f"M{cx - 32 * S},{base - 66 * S} L{cx - 18 * S},{base - 66 * S} L{cx - 20 * S},{base - 52 * S} L{cx - 30 * S},{base - 52 * S} Z", "#4a7ad0")
    salvar(nome, a)


# ------------------------------------------------------------------ bichos únicos

def cobra():
    a = Arte(76, 40)
    a.sombra(38, 37, 32, 3)
    d = "M70,32 C60,40 50,24 40,32 C30,40 22,26 14,28"
    a.linha(d, "#2c5a1a", 12)
    a.linha(d, "#5aa63a", 9)
    for k in range(5):
        x = 62 - k * 11
        a.add(f'<path d="M{x},{29 + (k % 2) * 3} l3,-3 l3,3 Z" fill="#e8d24a" opacity="0.85"/>')
    a.elipse(12, 25, 10, 7, "#5aa63a")
    a.olho(9, 22, 2.6, irritado=True, cor_iris="#e8c400")
    a.linha("M2,27 L-4,25 M2,27 L-4,30", "#d42a2a", 1.4)
    a.add('<path d="M70,32 l6,-6 l1,4 l-1,4 Z" fill="#c9b15a"/>')
    salvar("cobra", a)


def piranha():
    a = Arte(44, 36)
    a.caminho("M36,18 L44,8 L44,28 Z", "#a33a3a")
    a.elipse(20, 18, 17, 13, "#c94a4a")
    a.elipse(18, 23, 12, 6, "#f0b04a", contorno=False)
    a.caminho("M14,6 Q22,0 28,7 Z", "#a33a3a")
    a.caminho("M3,18 L13,16 L13,24 L4,22 Z", "#3a0a0a", contorno=False)
    a.add('<path d="M5,17 l2,3 l2,-3 l2,3 l2,-3 M5,23 l2,-3 l2,3 l2,-3 l2,3" fill="#fff" stroke="#fff" stroke-width="0.8"/>')
    a.olho(12, 12, 3, irritado=True)
    salvar("piranha", a, "centro")


def pedra_rolando():
    a = Arte(56, 56)
    a.sombra(28, 54, 22, 3)
    a.caminho("M28,4 C42,4 52,14 52,28 C52,44 42,52 28,52 C12,52 4,42 4,28 C4,14 14,4 28,4 Z", "#8a8478")
    a.linha("M14,20 Q20,26 18,34 M34,12 Q38,22 46,24 M30,38 L40,44", "#5a554a", 1.8)
    a.add('<ellipse cx="20" cy="16" rx="6" ry="3.5" fill="#fff" opacity="0.25"/>')
    salvar("pedra", a)


def estalactite():
    a = Arte(34, 60)
    g = a.linear(["#c9cfdb", "#7a8094"], 0, 0, 1, 0)
    a.add(f'<path d="M2,2 L32,2 L22,30 L18,58 L13,30 Z" fill="{g}" stroke="#4a5060" stroke-width="1.2" stroke-linejoin="round"/>')
    a.add('<path d="M10,4 L15,24" stroke="#fff" stroke-opacity="0.5" stroke-width="1.5"/>')
    salvar("estalactite", a, "centro")


def aranha():
    a = Arte(54, 44)
    for k in range(4):
        ang = -0.9 + k * 0.6
        for lado in (-1, 1):
            x2 = 27 + lado * (14 + k * 2)
            a.linha(f"M27,24 Q{27 + lado * 10},{8 + k * 6} {x2},{18 + k * 7}", "#111", 2.4)
    a.elipse(27, 28, 12, 10, "#2a2a2a")
    a.elipse(27, 16, 8, 7, "#3a3a3a")
    a.add('<path d="M22,30 l5,-6 l5,6 l-5,6 Z" fill="#c92a2a"/>')
    for dx in (-4, -1.5, 1.5, 4):
        a.add(f'<circle cx="{27 + dx}" cy="14" r="1.6" fill="#ff4040"/>')
    salvar("aranha", a, "centro")


def morcego(nome="morcego", w=56, h=34, cor="#5a3a6a"):
    a = Arte(w, h)
    S = w / 56
    a.caminho(f"M{28 * S},{16 * S} C{20 * S},{2 * S} {6 * S},{2 * S} {1 * S},{8 * S} C{6 * S},{12 * S} {6 * S},{20 * S} {10 * S},{24 * S} C{14 * S},{18 * S} {20 * S},{22 * S} {28 * S},{24 * S} Z", tom(cor, 0.8))
    a.caminho(f"M{28 * S},{16 * S} C{36 * S},{2 * S} {50 * S},{2 * S} {55 * S},{8 * S} C{50 * S},{12 * S} {50 * S},{20 * S} {46 * S},{24 * S} C{42 * S},{18 * S} {36 * S},{22 * S} {28 * S},{24 * S} Z", tom(cor, 0.8))
    a.elipse(28 * S, 20 * S, 7 * S, 9 * S, cor)
    a.caminho(f"M{23 * S},{13 * S} L{22 * S},{5 * S} L{26 * S},{11 * S} Z M{33 * S},{13 * S} L{34 * S},{5 * S} L{30 * S},{11 * S} Z", cor)
    a.olho(25.5 * S, 16 * S, 1.8 * S, irritado=True, cor_iris="#ff3030")
    a.olho(30.5 * S, 16 * S, 1.8 * S, irritado=True, cor_iris="#ff3030")
    salvar(nome, a, "centro")


def urso():
    a = Arte(80, 100)
    a.sombra(40, 98, 30, 5)
    c = "#6b4423"
    a.membro([(46, 70), (50, 96)], tom(c, 0.75), 12)
    a.membro([(32, 70), (28, 96)], c, 13)
    a.elipse(26, 96, 9, 4, "#3a2410", grad=False)
    a.elipse(40, 58, 22, 28, c)
    a.elipse(36, 64, 13, 17, "#a9794a", contorno=False)
    # braços abertos para o abraço
    a.membro([(54, 44), (68, 30), (76, 22)], tom(c, 0.8), 11)
    a.membro([(26, 44), (12, 30), (4, 22)], c, 11)
    for x in (4, 76):
        a.circ(x, 21, 6, "#a9794a")
        a.add(f'<path d="M{x - 4},16 l-1,-4 M{x},15 l0,-4 M{x + 4},16 l1,-4" stroke="#eee" stroke-width="1.2"/>')
    a.circ(30, 15, 6, c)
    a.circ(52, 15, 6, c)
    a.circ(40, 24, 15, c)
    a.elipse(36, 30, 8, 6, "#c9996a", contorno=False)
    a.add('<ellipse cx="33" cy="27" rx="3" ry="2.2" fill="#1a1a1a"/>')
    a.add('<path d="M30,33 Q36,38 42,33 Z" fill="#7a1a1a"/>')
    a.olho(33, 20, 3, irritado=True)
    a.olho(43, 20, 3, irritado=True)
    salvar("urso", a)


def carro():
    a = Arte(124, 64)
    a.sombra(62, 61, 56, 4)
    a.caminho("M6,46 L8,30 Q10,26 18,25 L34,24 L46,10 Q50,6 58,6 L90,6 Q98,6 102,12 L110,24 L116,26 Q122,28 122,36 L122,46 Z", "#d02a2a")
    a.caminho("M50,12 L60,12 L60,24 L40,24 Z M66,12 L92,12 Q96,12 98,16 L104,24 L66,24 Z", "#9fd4f0")
    a.add('<rect x="2" y="34" width="10" height="6" rx="2" fill="#ffe680"/>')
    a.add('<rect x="114" y="34" width="8" height="5" rx="2" fill="#ff5a3a"/>')
    a.linha("M14,38 L118,38", "#8a1010", 1.2)
    for x in (30, 96):
        a.circ(x, 48, 12, "#222")
        a.circ(x, 48, 6, "#bbb")
    salvar("carro", a)


def bicicleta():
    a = Arte(80, 76)
    a.sombra(40, 73, 34, 3)
    for x in (16, 62):
        a.add(f'<circle cx="{x}" cy="58" r="14" fill="none" stroke="#222" stroke-width="3"/>')
        a.add(f'<circle cx="{x}" cy="58" r="2" fill="#555"/>')
    a.linha("M16,58 L32,40 L54,40 L62,58 M32,40 L40,58 L54,40 M28,30 L32,40 M52,32 L54,40", "#2a5ad0", 3)
    a.humano_cor = None
    # ciclista simples
    a.membro([(42, 30), (40, 46), (40, 58)], "#334466", 5)
    a.caminho("M36,10 Q44,8 48,12 L50,32 L38,32 Z", "#f2a33a")
    a.membro([(40, 16), (30, 28), (28, 30)], "#f2a33a", 4.5)
    a.circ(40, 6, 6.5, "#d8a27a")
    a.caminho("M33,5 Q40,-4 47,5 Z", "#2a5ad0")
    a.olho(37, 6, 1.8)
    salvar("bicicleta", a)


def onda():
    a = Arte(100, 60)
    g = a.linear(["#bfe6ff", "#3a8ad8"])
    a.add(f'<path d="M4,58 C10,30 30,6 60,6 C82,6 96,20 92,34 C88,24 74,20 66,28 C60,34 66,44 74,42 C64,52 40,58 4,58 Z" fill="{g}" stroke="#1d5f9e" stroke-width="1.6"/>')
    a.linha("M20,46 C30,30 44,18 60,14", "#ffffff", 3, op=0.7)
    for k in range(5):
        a.add(f'<circle cx="{62 + k * 6}" cy="{10 + (k % 2) * 3}" r="2.4" fill="#fff"/>')
    salvar("onda", a)


def caranguejo():
    a = Arte(56, 36)
    a.sombra(28, 34, 22, 3)
    for k in range(3):
        for lado in (-1, 1):
            a.linha(f"M{28 + lado * 8},{24} L{28 + lado * (16 + k * 4)},{30 - k} L{28 + lado * (18 + k * 4)},{35}", "#b22a1a", 2.2)
    a.elipse(28, 22, 16, 10, "#e04a2a")
    for lado in (-1, 1):
        a.membro([(28 + lado * 12, 18), (28 + lado * 20, 10)], "#e04a2a", 3)
        a.caminho(f"M{28 + lado * 20},{10} q{lado * 8},{-8} {lado * 6},{2} q{-lado * 3},{-1} {-lado * 3},{2} Z", "#e04a2a")
    a.linha("M24,14 L23,7 M32,14 L33,7", "#b22a1a", 1.6)
    a.olho(23, 6, 2.4)
    a.olho(33, 6, 2.4)
    salvar("caranguejo", a)


def pinguim():
    a = Arte(44, 52)
    a.sombra(22, 50, 16, 2.5)
    a.elipse(22, 30, 15, 20, "#1e2430")
    a.elipse(20, 33, 10, 15, "#f4f4f4", contorno=False)
    a.circ(18, 13, 9, "#1e2430")
    a.caminho("M10,13 L2,15 L10,17 Z", "#f2a33a")
    a.olho(15, 11, 2.4)
    a.caminho("M32,24 Q40,34 34,40 Q32,32 30,28 Z", "#1e2430")
    a.elipse(14, 49, 5, 2.4, "#f2a33a", grad=False)
    a.elipse(26, 49, 5, 2.4, "#f2a33a", grad=False)
    salvar("pinguim", a)


def tronco():
    a = Arte(260, 30)
    g = a.linear(["#a3743e", "#6b4520", "#4a2e12"])
    a.add(f'<rect x="8" y="4" width="244" height="22" rx="11" fill="{g}" stroke="#3a2410" stroke-width="1.6"/>')
    for k in range(9):
        x = 26 + k * 26
        a.linha(f"M{x},8 Q{x + 8},14 {x},22", "#4a2e12", 1.2, op=0.6)
    a.add('<ellipse cx="12" cy="15" rx="8" ry="11" fill="#c9965a" stroke="#3a2410" stroke-width="1.4"/><ellipse cx="12" cy="15" rx="4" ry="6" fill="none" stroke="#8a5a2a" stroke-width="1"/>')
    a.add('<ellipse cx="248" cy="15" rx="8" ry="11" fill="#c9965a" stroke="#3a2410" stroke-width="1.4"/>')
    a.add('<path d="M120,4 q4,-6 10,-4 q-4,2 -6,6 Z" fill="#4aa63a"/>')
    salvar("tronco", a, "topo")


def folha():
    a = Arte(90, 22)
    a.caminho("M2,10 C20,-2 70,-2 88,10 C70,22 20,22 2,10 Z", "#4ab83a")
    a.linha("M4,10 L86,10", "#2a7a22", 1.4)
    for k in range(6):
        x = 14 + k * 12
        a.linha(f"M{x},10 L{x + 6},4 M{x},10 L{x + 6},16", "#2a7a22", 0.9)
    salvar("folha", a, "topo")


def cipo():
    a = Arte(40, 440)
    a.linha("M20,0 C14,100 26,200 18,300 C14,360 22,400 20,436", "#2d6a1a", 7)
    a.linha("M20,0 C14,100 26,200 18,300 C14,360 22,400 20,436", "#4f9a2a", 4.5)
    for k in range(10):
        y = 20 + k * 42
        lado = 1 if k % 2 else -1
        a.caminho(f"M20,{y} q{lado * 14},{-8} {lado * 16},{4} q{-lado * 10},{4} {-lado * 16},{-4} Z", "#5ab83a")
    salvar("cipo", a, "fundo_cipo")


def jaula(aberta):
    a = Arte(120, 130)
    a.sombra(60, 128, 56, 4)
    a.add('<rect x="6" y="120" width="108" height="8" rx="2" fill="#555"/>')
    a.add('<rect x="4" y="4" width="112" height="10" rx="3" fill="#666" stroke="#333" stroke-width="1.2"/>')
    if not aberta:
        # macaco preso
        a.circ(60, 60, 13, MARROM)
        a.caminho("M50,58 C50,52 56,51 58,55 C60,51 66,52 66,58 C67,66 63,70 58,70 C53,70 49,66 50,58 Z", BEGE, contorno=False)
        a.olho(55, 58, 2.8)
        a.olho(62, 58, 2.8)
        a.add('<path d="M54,66 Q58,63 62,66" fill="none" stroke="#3a2410" stroke-width="1.2"/>')
        a.elipse(60, 96, 15, 20, MARROM)
        for k in range(8):
            x = 10 + k * 14
            a.linha(f"M{x},14 L{x},120", "#3a3a40", 4)
            a.linha(f"M{x - 1},14 L{x - 1},120", "#8a8a95", 1.2)
    else:
        for k in (0, 7):
            x = 10 + k * 14
            a.linha(f"M{x},14 L{x},120", "#3a3a40", 4)
        a.add('<path d="M24,14 L4,30 L4,120 L24,108 Z" fill="none" stroke="#3a3a40" stroke-width="3"/>')
    salvar("jaula_aberta" if aberta else "jaula", a)


def armadilha(nome, tipo):
    a = Arte(60, 40)
    if tipo == "espinho":
        for k in range(5):
            x = 4 + k * 11
            a.caminho(f"M{x},38 L{x + 5.5},6 L{x + 11},38 Z", "#a9aeb8")
    elif tipo == "lanca":
        for k in range(4):
            x = 8 + k * 14
            a.linha(f"M{x},38 L{x},12", "#6b4a2a", 3)
            a.caminho(f"M{x - 4},14 L{x},0 L{x + 4},14 Z", "#c9ccd4")
    elif tipo == "agua_viva":
        g = a.linear(["#f6c2ff", "#b06ad8"], ops=[0.95, 0.8])
        a.add(f'<path d="M8,22 C8,6 52,6 52,22 Z" fill="{g}" stroke="#8a3ab0" stroke-width="1.4"/>')
        for k in range(6):
            x = 12 + k * 7
            a.linha(f"M{x},22 Q{x - 3},30 {x},38", "#c07ae0", 1.6)
    elif tipo == "bueiro":
        a.add('<ellipse cx="30" cy="34" rx="28" ry="6" fill="#1a1a1a" stroke="#555" stroke-width="2"/>')
        a.caminho("M10,30 L50,30 L46,18 L14,18 Z", "#6a6a6a")
        a.add('<path d="M14,22 L46,22 M15,26 L45,26" stroke="#ffcc00" stroke-width="2"/>')
    salvar(nome, a)


def bandeira():
    a = Arte(40, 100)
    a.linha("M6,98 L6,6", "#ddd", 3)
    g = a.linear(["#ffe14d", "#f29a00"], 0, 0, 1, 0)
    a.add(f'<path d="M7,8 Q22,4 36,12 Q22,18 7,24 Z" fill="{g}" stroke="#a86a00" stroke-width="1"/>')
    a.add('<path d="M14,14 q4,-4 8,0 q-4,4 -8,0" fill="#fff" opacity="0.6"/>')
    salvar("checkpoint", a)


def milharal():
    a = Arte(120, 170)
    for k in range(5):
        x = 10 + k * 25
        a.linha(f"M{x},170 Q{x + 4},90 {x - 2},10", "#3a7a1a", 5)
        a.caminho(f"M{x},110 q16,-14 26,-6 q-12,0 -26,14 Z", "#5ab83a")
        a.caminho(f"M{x},70 q-16,-10 -22,0 q10,-2 22,8 Z", "#5ab83a")
        a.elipse(x + 6, 84, 5, 12, "#f2d04a")
        a.linha(f"M{x + 6},70 l3,-8 M{x + 6},70 l-2,-8", "#c9a24a", 1)
    salvar("milharal", a)


def objeto(nome, cor, forma):
    a = Arte(30, 30)
    if forma == "redondo":
        a.circ(15, 15, 11, cor)
    elif forma == "pedra":
        a.caminho("M5,20 C3,10 10,4 17,5 C25,6 28,14 25,22 C22,27 9,27 5,20 Z", cor)
    elif forma == "graveto":
        a.linha("M4,24 L26,6 M15,15 L22,18", tom(cor, 0.5), 5)
        a.linha("M4,24 L26,6 M15,15 L22,18", cor, 3)
    elif forma == "cristal":
        a.caminho("M15,1 L24,10 L20,28 L10,28 L6,10 Z", cor)
        a.add('<path d="M15,1 L15,28 M6,10 L24,10" stroke="#fff" stroke-opacity="0.6" stroke-width="1"/>')
    elif forma == "ovo":
        a.elipse(15, 16, 9, 12, cor)
    elif forma == "espiga":
        a.elipse(15, 15, 6, 13, cor)
        a.caminho("M10,26 q-6,-10 0,-18 q2,10 4,18 Z", "#6ab83a")
    elif forma == "lata":
        a.add(f'<rect x="8" y="5" width="14" height="21" rx="3" fill="{a.linear([tom(cor, 1.3), cor, tom(cor, 0.6)], 0, 0, 1, 0)}" stroke="#555" stroke-width="1"/>')
        a.add('<rect x="8" y="12" width="14" height="6" fill="#d02a2a"/>')
    elif forma == "balde":
        a.caminho("M6,8 L24,8 L21,27 L9,27 Z", cor)
        a.linha("M6,8 Q15,-2 24,8", "#555", 1.4)
    elif forma == "peixe":
        a.elipse(13, 15, 10, 6, cor)
        a.caminho("M22,15 L29,9 L29,21 Z", cor)
        a.add('<circle cx="8" cy="13" r="1.5" fill="#111"/>')
    elif forma == "concha":
        a.caminho("M15,4 L27,24 Q15,29 3,24 Z", cor)
        for k in range(5):
            a.linha(f"M15,5 L{5 + k * 5},25", tom(cor, 0.7), 0.9)
    elif forma == "coco":
        a.circ(15, 15, 11, cor)
        a.add('<circle cx="11" cy="12" r="1.6" fill="#2a1a0a"/><circle cx="16" cy="10" r="1.6" fill="#2a1a0a"/><circle cx="14" cy="15" r="1.6" fill="#2a1a0a"/>')
    elif forma == "casca":
        g = a.linear(["#ffe14d", "#d99a00"])
        a.add(f'<path d="M15,6 C8,10 4,20 6,26 C10,20 12,16 15,14 C18,16 20,20 24,26 C26,20 22,10 15,6 Z" fill="{g}" stroke="#8a6000" stroke-width="1"/>')
        a.add('<rect x="13" y="2" width="4" height="6" rx="1" fill="#6a4a10"/>')
    salvar("obj_" + nome, a, "centro")


# ------------------------------------------------------------------ chefes e bichos

def bichos():
    cobra()
    primata("bagunceiro", 46, 60, "#a0683a", "#e8c49a", rabo=True, cabeca=0.2, boca_aberta=True)
    ave("papagaio", 56, 46, "#e8322a", voando=True, asa_cor="#2a6ad0", cauda="#f2c22a", bico="torto", bico_cor="#f2f2e8", cabeca_cor="#f05a2a")
    piranha()
    quadrupede("zebra", 82, 76, "#f4f4f4", listras=True, orelhas="pontuda", rabo_tufo="#1a1a1a", juba=None, cabeca=0.12, focinho=0.9, cor_focinho="#3a3a3a")
    quadrupede("hiena", 70, 54, "#c9a46a", "#e8d4a8", manchas="#5a4020", orelhas="redonda", dentes=True, cabeca=0.15)
    pedra_rolando()
    quadrupede("cabra", 66, 64, "#e8e4dc", chifres="#8a7a5a", barba=True, orelhas="caida", cabeca=0.14, casco="#4a4030")
    ave("aguia", 66, 44, "#6a4424", voando=True, cabeca_cor="#f4f4f0", bico="gancho", bico_cor="#f2c22a", asa_cor="#4a2e14", cauda="#f0ece0")
    urso()
    estalactite()
    aranha()
    morcego()
    ave("galinha", 42, 44, "#fafafa", crista="#e02a2a", barbela="#e02a2a", bico="curto", pernas="curta", bravo=True)
    quadrupede("bode", 68, 64, "#c9b08a", chifres="#5a4a30", barba=True, orelhas="caida", cabeca=0.14, casco="#3a3020")
    quadrupede("cachorro", 64, 52, "#9a6a3a", "#e8cfa8", orelhas="caida", dentes=True, cabeca=0.16, focinho=0.85)
    ave("pombo", 42, 34, "#8a95a8", voando=True, peito="#9a8aa8", bico="curto", bico_cor="#555", asa_cor="#6a7588")
    quadrupede("gato", 54, 44, "#f29a3a", "#fde0b8", listras=False, orelhas="pontuda", cabeca=0.17, focinho=0.6, perna=0.32)
    carro()
    bicicleta()
    humano("tratador", 52, 90, "#4a7a3a", calca="#3a5a2a", bone="#2a4a1a", apito=True)
    ave("flamingo", 46, 80, "#f58ab0", pernas="longa", cor_pernas="#e06a90", pescoco_longo=True, bico="torto", bico_cor="#2a2a2a", cabeca=0.13)
    pinguim()
    caranguejo()
    ave("gaivota", 56, 36, "#f8f8f8", voando=True, asa_cor="#b8c0cc", bico="curto", bico_cor="#f2c22a")
    onda()
    primata("babuino", 50, 56, "#8a7a4a", "#d89a8a", rabo=True, focinho_longo=True, cabeca=0.18)
    primata("gorilinha", 66, 76, "#3a3a3e", "#5a5560", cabeca=0.17, peito=0.36)


def chefes():
    ave("chefe_coruja", 120, 120, "#8a6a4a", olhos_coruja=True, bico="gancho", bico_cor="#d9a43a", peito="#e8d4b0", cabeca=0.3, pernas="curta", asa_cor="#6a4a2a")
    # crocodilo
    a = Arte(220, 80)
    a.sombra(110, 77, 100, 5)
    c = "#3a7a3a"
    a.caminho("M200,46 C214,44 220,40 218,34 C210,40 196,38 186,38 Z", c)
    a.caminho("M40,40 C60,26 160,24 200,40 C190,58 70,62 40,56 Z", c)
    for k in range(9):
        x = 70 + k * 14
        a.caminho(f"M{x},30 l5,-8 l5,8 Z", tom(c, 0.7))
    a.caminho("M44,38 L4,40 Q0,46 6,48 L44,50 Z", c)
    a.caminho("M44,52 L8,52 Q4,58 10,60 L46,58 Z", tom(c, 0.9))
    a.add('<path d="M10,48 l3,4 l3,-4 l3,4 l3,-4 l3,4 l3,-4 l3,4 l3,-4 l3,4" fill="#fff" stroke="#fff" stroke-width="1"/>')
    for x in (70, 160):
        a.membro([(x, 54), (x - 6, 74)], tom(c, 0.8), 9)
        a.elipse(x - 8, 75, 7, 3, tom(c, 0.6), grad=False)
    a.circ(42, 32, 9, c)
    a.olho(42, 30, 5, irritado=True, cor_iris="#e8c400")
    a.elipse(120, 52, 60, 6, "#c9d48a", contorno=False)
    salvar("chefe_crocodilo", a)
    quadrupede("chefe_elefante", 190, 180, "#9a9aa4", cx=0.64, tromba=True, orelhas="elefante", cabeca=0.17, perna=0.34, corpo=0.25, rabo=True, casco="#5a5a64", focinho=0.3, cor_focinho="#9a9aa4")
    quadrupede("chefe_leoa", 140, 96, "#d9a85a", "#f2d8a8", orelhas="redonda", dentes=True, cabeca=0.13, rabo_tufo="#8a5a2a")
    quadrupede("chefe_leao", 160, 120, "#d99a4a", "#f2d0a0", juba="#8a4a1a", orelhas="redonda", dentes=True, cabeca=0.12, rabo_tufo="#6a3a1a")
    ave("chefe_gaviao", 130, 90, "#7a5434", voando=True, bico="gancho", bico_cor="#f2c22a", asa_cor="#5a3a1a", peito="#e8d4b0", cauda="#a87a4a")
    # bando de morcegos gigantes
    a = Arte(170, 90)
    for (dx, dy, s) in ((10, 10, 0.75), (90, 0, 0.8), (45, 30, 1.0)):
        a.add(f'<g transform="translate({dx},{dy}) scale({s})">')
        a.caminho("M50,28 C36,4 12,4 2,14 C12,20 12,34 18,42 C26,32 36,38 50,42 Z", "#3a2a4a")
        a.caminho("M50,28 C64,4 88,4 98,14 C88,20 88,34 82,42 C74,32 64,38 50,42 Z", "#3a2a4a")
        a.elipse(50, 36, 12, 16, "#5a3a6a")
        a.caminho("M42,24 L40,10 L47,20 Z M58,24 L60,10 L53,20 Z", "#5a3a6a")
        a.olho(46, 30, 3, irritado=True, cor_iris="#ff2020")
        a.olho(54, 30, 3, irritado=True, cor_iris="#ff2020")
        a.add("</g>")
    salvar("chefe_morcegos", a, "centro")
    quadrupede("chefe_touro", 170, 130, "#4a2a1a", "#6a3e28", chifres="#f2ead8", orelhas="pontuda", cabeca=0.14, perna=0.32, corpo=0.26, rabo_tufo="#2a1a10", casco="#1a1a1a", bravo=True)
    humano("chefe_carrocinha", 80, 160, "#3a4a8a", calca="#2a2a3a", rede=True, bone="#1a2a5a")
    quadrupede("chefe_rinoceronte", 200, 130, "#8a8a92", chifre_nariz=True, orelhas="pontuda", cabeca=0.14, perna=0.3, corpo=0.27, casco="#4a4a52", focinho=0.7)
    # tartaruga gigante
    a = Arte(210, 120)
    a.sombra(105, 117, 95, 6)
    for x in (50, 150):
        a.membro([(x, 90), (x - 6, 114)], "#6aa84a", 16)
    a.caminho("M30,92 C30,30 80,10 120,10 C170,10 196,50 190,92 Z", "#4a7a3a")
    for (x, y) in ((70, 44), (110, 32), (150, 46), (90, 70), (130, 70), (170, 74), (50, 74)):
        a.caminho(f"M{x - 14},{y} L{x - 7},{y - 12} L{x + 7},{y - 12} L{x + 14},{y} L{x + 7},{y + 12} L{x - 7},{y + 12} Z", "#6a9a4a")
    a.add('<path d="M30,92 L190,92" stroke="#2a4a1a" stroke-width="5"/>')
    a.caminho("M34,80 C10,74 2,60 8,52 C16,46 30,56 40,70 Z", "#7ab85a")
    a.olho(14, 56, 4.5, irritado=True)
    a.linha("M6,64 Q12,66 18,63", "#2a4a1a", 1.6)
    salvar("chefe_tartaruga", a)
    primata("chefe_gorila", 200, 220, "#2e2e33", "#4a4550", costas_prata=True, cabeca=0.15, peito=0.38, boca_aberta=True)


def macaco_aliado():
    a = Arte(46, 56)
    a.sombra(23, 54, 16, 3)
    a.elipse(23, 38, 11, 14, "#a0683a")
    a.elipse(25, 41, 6, 8, BEGE, contorno=False)
    a.circ(25, 17, 11, "#a0683a")
    a.circ(14, 17, 4.5, "#a0683a")
    a.caminho("M19,17 C19,12 24,11 25,14 C26,11 31,12 31,17 C32,23 28,26 25,26 C21,26 18,23 19,17 Z", BEGE, contorno=False)
    a.olho(23, 16, 2.4)
    a.olho(28, 16, 2.4)
    a.linha("M22,22 Q25,25 29,22", "#3a2410", 1.2)
    a.linha("M14,44 C4,46 2,34 8,30", "#a0683a", 3)
    a.membro([(20, 50), (18, 55)], "#7a4a24", 4)
    a.membro([(27, 50), (29, 55)], "#7a4a24", 4)
    salvar("aliado", a)


# ------------------------------------------------------------------ cenários

def nuvem(a, x, y, s, op=0.95):
    for dx, dy, r in ((0, 0, 22), (24, -10, 26), (52, 0, 22), (26, 8, 22)):
        a.add(f'<circle cx="{x + dx * s}" cy="{y + dy * s}" r="{r * s}" fill="#ffffff" opacity="{op}"/>')


def ceu(nome, topo, horizonte, extra):
    a = Arte(1280, 720)
    g = a.linear([topo, horizonte])
    a.add(f'<rect width="1280" height="720" fill="{g}"/>')
    extra(a)
    salvar("ceu_" + nome, a, "tela")


def tile(nome, w, h, desenho, ancora="fundo"):
    a = Arte(w, h)
    desenho(a)
    salvar(nome, a, ancora)


def cenarios():
    # ---------------- 1 selva
    def ceu_selva(a):
        a.add('<circle cx="1050" cy="120" r="70" fill="#fff6c0" opacity="0.9"/>')
        for x, y, s in ((120, 120, 1.2), (500, 80, 0.9), (820, 160, 1.1)):
            nuvem(a, x, y, s)
    ceu("selva", "#6fc3e8", "#d8f2d0", ceu_selva)

    def longe_selva(a):
        a.add('<path d="M0,400 L0,200 Q80,120 160,190 Q240,90 340,180 Q420,110 520,170 Q620,80 720,180 Q820,120 900,170 Q1000,90 1100,180 Q1190,130 1280,200 L1280,400 Z" fill="#5a9a6a" opacity="0.85"/>')
        for k in range(14):
            x = k * 92 + 20
            a.add(f'<circle cx="{x}" cy="{250 + (k * 37) % 40}" r="{50 + (k * 13) % 25}" fill="#3f8a50" opacity="0.9"/>')
        a.add('<rect x="0" y="300" width="1280" height="100" fill="#3a7a48"/>')
    tile("longe_selva", 1280, 400, longe_selva)

    def perto_selva(a):
        for k in range(4):
            x = 60 + k * 330
            g = a.linear(["#7a5230", "#4a2e16"], 0, 0, 1, 0)
            a.add(f'<path d="M{x},500 L{x + 10},200 Q{x + 20},180 {x + 34},200 L{x + 44},500 Z" fill="{g}"/>')
            for j, (dx, dy, r) in enumerate(((-40, 180, 70), (40, 170, 75), (0, 120, 80), (-60, 230, 50), (70, 230, 55))):
                a.add(f'<circle cx="{x + 22 + dx}" cy="{dy}" r="{r}" fill="{["#2f8a3a", "#3a9a44", "#45aa4e", "#2a7a34", "#3a9a44"][j]}"/>')
            a.add(f'<path d="M{x + 30},220 C{x + 90},260 {x + 70},380 {x + 110},470" stroke="#3a7a22" stroke-width="5" fill="none"/>')
            for j in range(6):
                fx = x + 160 + j * 24
                a.add(f'<path d="M{fx},500 Q{fx - 10},440 {fx - 30},430 Q{fx - 4},446 {fx},500 Z M{fx},500 Q{fx + 10},450 {fx + 34},440 Q{fx + 6},456 {fx},500 Z" fill="#3aa04a"/>')
        a.add('<circle cx="250" cy="485" r="7" fill="#ff5a8a"/><circle cx="900" cy="490" r="7" fill="#ffd23a"/>')
    tile("perto_selva", 1280, 500, perto_selva)

    # ---------------- 2 rio
    def ceu_rio(a):
        a.add('<circle cx="200" cy="110" r="60" fill="#fffbe0" opacity="0.95"/>')
        for x, y, s in ((420, 100, 1.0), (760, 70, 1.3), (1100, 140, 0.9)):
            nuvem(a, x, y, s)
    ceu("rio", "#5ab4e8", "#d4f0ff", ceu_rio)
    tile("longe_rio", 1280, 400, longe_selva)

    def perto_rio(a):
        for k in range(5):
            x = 40 + k * 260
            a.add(f'<path d="M{x},500 Q{x + 6},360 {x - 30},300 M{x},500 Q{x + 10},360 {x + 40},290" stroke="#3a7a22" stroke-width="6" fill="none"/>')
            a.add(f'<ellipse cx="{x - 30}" cy="300" rx="14" ry="30" fill="#6a4a2a"/><ellipse cx="{x + 40}" cy="290" rx="14" ry="30" fill="#6a4a2a"/>')
            a.add(f'<path d="M{x + 60},500 Q{x + 80},430 {x + 130},420 Q{x + 90},450 {x + 90},500 Z" fill="#4aa84a"/>')
    tile("perto_rio", 1280, 500, perto_rio)

    # ---------------- 3 savana
    def ceu_savana(a):
        a.add('<circle cx="640" cy="330" r="110" fill="#ffd27a" opacity="0.9"/>')
        a.add('<circle cx="640" cy="330" r="160" fill="#ffe7a8" opacity="0.35"/>')
        nuvem(a, 200, 120, 1.1, 0.7)
        nuvem(a, 980, 90, 1.0, 0.7)
    ceu("savana", "#f2a24a", "#ffe0a0", ceu_savana)

    def longe_savana(a):
        a.add('<path d="M0,400 L0,290 Q200,250 420,280 Q640,240 860,280 Q1080,250 1280,290 L1280,400 Z" fill="#c98a4a"/>')
        a.add('<path d="M150,290 L230,200 L310,290 Z M900,285 L990,180 L1080,285 Z" fill="#b07a44" opacity="0.8"/>')
        a.add('<path d="M0,400 L0,320 Q300,300 640,320 Q980,300 1280,320 L1280,400 Z" fill="#d9a85a"/>')
    tile("longe_savana", 1280, 400, longe_savana)

    def perto_savana(a):
        for k in range(3):
            x = 120 + k * 430
            a.add(f'<path d="M{x},500 L{x + 8},330 Q{x - 40},300 {x - 70},290 M{x + 8},330 Q{x + 40},300 {x + 80},300" stroke="#5a3a1a" stroke-width="10" fill="none"/>')
            a.add(f'<ellipse cx="{x + 4}" cy="282" rx="150" ry="34" fill="#4a7a2a"/><ellipse cx="{x - 20}" cy="270" rx="90" ry="22" fill="#5a8a34"/>')
        for k in range(40):
            x = k * 32
            a.add(f'<path d="M{x},500 L{x + 6},{450 + (k * 7) % 25} L{x + 12},500 Z" fill="#c9a44a"/>')
    tile("perto_savana", 1280, 500, perto_savana)

    # ---------------- 4 montanha
    def ceu_montanha(a):
        for x, y, s in ((150, 160, 1.3), (600, 110, 1.0), (1000, 180, 1.4)):
            nuvem(a, x, y, s, 0.85)
    ceu("montanha", "#7aa8d8", "#e8f0f8", ceu_montanha)

    def longe_montanha(a):
        a.add('<path d="M0,400 L0,260 L180,40 L330,240 L470,90 L640,260 L800,20 L960,250 L1100,80 L1280,260 L1280,400 Z" fill="#8a94a8"/>')
        for (x, y) in ((180, 40), (470, 90), (800, 20), (1100, 80)):
            a.add(f'<path d="M{x - 50},{y + 70} L{x},{y} L{x + 50},{y + 70} Q{x + 20},{y + 56} {x},{y + 72} Q{x - 20},{y + 56} {x - 50},{y + 70} Z" fill="#ffffff"/>')
        a.add('<path d="M0,400 L0,300 L240,200 L420,300 L700,190 L980,300 L1280,220 L1280,400 Z" fill="#6a7488"/>')
    tile("longe_montanha", 1280, 400, longe_montanha)

    def perto_montanha(a):
        for k in range(5):
            x = 30 + k * 270
            a.add(f'<path d="M{x},500 L{x + 40},380 L{x + 90},410 L{x + 140},360 L{x + 190},500 Z" fill="#7a7468"/>')
            a.add(f'<path d="M{x + 40},380 L{x + 60},420 L{x + 30},460 Z" fill="#9a9488"/>')
            a.add(f'<path d="M{x + 220},500 L{x + 240},400 L{x + 260},500 Z M{x + 230},440 L{x + 250},380 L{x + 270},440 Z" fill="#2a5a3a"/>')
    tile("perto_montanha", 1280, 500, perto_montanha)

    # ---------------- 5 caverna
    def ceu_caverna(a):
        for k in range(40):
            x = (k * 131) % 1280
            y = (k * 71) % 500
            a.add(f'<circle cx="{x}" cy="{y}" r="{1.2 + (k % 3)}" fill="#7affd8" opacity="{0.25 + (k % 4) * 0.12}"/>')
    ceu("caverna", "#0e0a18", "#2a2238", ceu_caverna)

    def longe_caverna(a):
        a.add('<rect width="1280" height="400" fill="#1e1828"/>')
        for k in range(16):
            x = k * 80
            a.add(f'<path d="M{x},0 L{x + 40},0 L{x + 22},{90 + (k * 37) % 80} Z" fill="#2e2638"/>')
            a.add(f'<path d="M{x + 10},400 L{x + 30},{300 + (k * 29) % 60} L{x + 50},400 Z" fill="#2a2234"/>')
    tile("longe_caverna", 1280, 400, longe_caverna)

    def perto_caverna(a):
        for k in range(6):
            x = 60 + k * 210
            for j in range(3):
                cx = x + j * 18
                r = 10 - j * 2
                a.add(f'<rect x="{cx - 2}" y="{500 - 18 + j * 2}" width="4" height="{18 - j * 2}" fill="#d8d0e0"/>')
                a.add(f'<ellipse cx="{cx}" cy="{482 + j * 2}" rx="{r}" ry="{r * 0.6}" fill="#3affc8" opacity="0.95"/>')
                a.add(f'<circle cx="{cx}" cy="{482 + j * 2}" r="{r * 2.4}" fill="#3affc8" opacity="0.15"/>')
            a.add(f'<path d="M{x + 100},500 L{x + 120},410 L{x + 140},500 Z" fill="#6a5a8a" opacity="0.7"/>')
            a.add(f'<path d="M{x + 116},430 L{x + 120},410 L{x + 124},430 Z" fill="#b8a0ff"/>')
    tile("perto_caverna", 1280, 500, perto_caverna)

    # ---------------- 6 fazenda
    def ceu_fazenda(a):
        a.add('<circle cx="1080" cy="110" r="60" fill="#fff3b0"/>')
        for x, y, s in ((160, 100, 1.2), (560, 140, 0.9), (820, 80, 1.1)):
            nuvem(a, x, y, s)
    ceu("fazenda", "#62b8f0", "#e0f4ff", ceu_fazenda)

    def longe_fazenda(a):
        a.add('<path d="M0,400 L0,250 Q160,180 340,240 Q540,170 740,240 Q940,180 1120,240 Q1200,220 1280,250 L1280,400 Z" fill="#7ac25a"/>')
        a.add('<path d="M0,400 L0,300 Q320,260 640,300 Q960,260 1280,300 L1280,400 Z" fill="#5aa84a"/>')
        for k in range(10):
            y = 300 + k * 10
            a.add(f'<path d="M0,{y} Q640,{y - 30} 1280,{y}" stroke="#4a9a3a" stroke-width="2" fill="none" opacity="0.6"/>')
        a.add('<rect x="880" y="200" width="16" height="70" fill="#d0d0d8"/><circle cx="888" cy="200" r="26" fill="none" stroke="#aaa" stroke-width="3"/>')
    tile("longe_fazenda", 1280, 400, longe_fazenda)

    def perto_fazenda(a):
        a.add('<path d="M100,500 L100,310 L240,230 L380,310 L380,500 Z" fill="#c0392b" stroke="#7a1a10" stroke-width="3"/>')
        a.add('<path d="M84,316 L240,214 L396,316" fill="none" stroke="#f4f4f4" stroke-width="12"/>')
        a.add('<rect x="200" y="380" width="80" height="120" fill="#7a1a10"/><path d="M200,380 L280,500 M280,380 L200,500" stroke="#f4f4f4" stroke-width="6"/>')
        a.add('<rect x="220" y="290" width="40" height="40" fill="#f4e8c0"/>')
        for k in range(16):
            x = 460 + k * 50
            a.add(f'<rect x="{x}" y="420" width="10" height="80" fill="#c9a46a"/>')
        a.add('<rect x="460" y="430" width="800" height="10" fill="#d9b47a"/><rect x="460" y="460" width="800" height="10" fill="#d9b47a"/>')
        for k in range(4):
            x = 560 + k * 170
            a.add(f'<ellipse cx="{x}" cy="490" rx="40" ry="26" fill="#f2d06a"/><path d="M{x - 30},480 L{x + 30},480 M{x - 32},494 L{x + 32},494" stroke="#c9a44a" stroke-width="3"/>')
    tile("perto_fazenda", 1280, 500, perto_fazenda)

    # ---------------- 7 cidade
    def ceu_cidade(a):
        a.add('<circle cx="300" cy="120" r="55" fill="#fff0c8" opacity="0.9"/>')
        nuvem(a, 700, 90, 1.2, 0.8)
    ceu("cidade", "#8ab4d8", "#f2d8c8", ceu_cidade)

    def longe_cidade(a):
        x = 0
        k = 0
        while x < 1280:
            larg = 70 + (k * 37) % 60
            alt = 140 + (k * 53) % 200
            a.add(f'<rect x="{x}" y="{400 - alt}" width="{larg}" height="{alt}" fill="#7a88a0"/>')
            for j in range(int(alt / 26)):
                for i in range(int(larg / 22)):
                    a.add(f'<rect x="{x + 6 + i * 22}" y="{400 - alt + 10 + j * 26}" width="10" height="12" fill="#c9d4e8" opacity="0.7"/>')
            x += larg + 6
            k += 1
    tile("longe_cidade", 1280, 400, longe_cidade)

    def perto_cidade(a):
        cores = ["#c9734a", "#5a7ab0", "#e0b04a", "#8a5a9a"]
        for k in range(4):
            x = 20 + k * 320
            alt = 300 + (k % 2) * 80
            c = cores[k]
            g = a.linear([tom(c, 1.15), tom(c, 0.75)], 0, 0, 1, 0)
            a.add(f'<rect x="{x}" y="{500 - alt}" width="260" height="{alt}" fill="{g}"/>')
            a.add(f'<rect x="{x - 8}" y="{500 - alt - 12}" width="276" height="16" fill="{tom(c, 0.6)}"/>')
            for j in range(int((alt - 80) / 70)):
                for i in range(4):
                    a.add(f'<rect x="{x + 22 + i * 60}" y="{500 - alt + 30 + j * 70}" width="34" height="44" fill="#fff6c8" stroke="{tom(c, 0.5)}" stroke-width="4"/>')
            a.add(f'<rect x="{x + 100}" y="420" width="60" height="80" fill="#4a2a1a"/>')
        a.add('<path d="M0,230 Q320,270 640,230 Q960,270 1280,230" stroke="#222" stroke-width="3" fill="none"/>')
    tile("perto_cidade", 1280, 500, perto_cidade)

    # ---------------- 8 zoológico
    ceu("zoo", "#6ac0f0", "#e4f8ec", ceu_fazenda)

    def longe_zoo(a):
        a.add('<path d="M0,400 L0,260 Q200,200 400,250 Q640,190 860,250 Q1080,200 1280,250 L1280,400 Z" fill="#6aaa5a"/>')
        a.add('<rect x="560" y="180" width="160" height="120" fill="#e8d8b0"/><path d="M540,190 L640,120 L740,190 Z" fill="#c9502a"/>')
        a.add('<text x="590" y="250" font-size="28" font-family="sans-serif" fill="#8a3a1a">ZOO</text>')
        for k in range(8):
            x = 40 + k * 160
            a.add(f'<circle cx="{x}" cy="290" r="40" fill="#4a8a44"/>')
    tile("longe_zoo", 1280, 400, longe_zoo)

    def perto_zoo(a):
        for k in range(27):
            x = k * 48
            a.add(f'<rect x="{x}" y="360" width="6" height="140" fill="#5a5a60"/>')
        a.add('<rect x="0" y="360" width="1280" height="8" fill="#6a6a70"/><rect x="0" y="430" width="1280" height="6" fill="#6a6a70"/>')
        for k in range(3):
            x = 180 + k * 420
            a.add(f'<path d="M{x},360 L{x + 10},180 Q{x - 40},150 {x - 60},170 M{x + 10},180 Q{x + 50},140 {x + 80},160" stroke="#6a4a2a" stroke-width="8" fill="none"/>')
            a.add(f'<ellipse cx="{x + 10}" cy="160" rx="90" ry="50" fill="#3a8a3a"/>')
    tile("perto_zoo", 1280, 500, perto_zoo)

    # ---------------- 9 praia
    def ceu_praia(a):
        a.add('<circle cx="980" cy="140" r="70" fill="#fff8d0"/>')
        for x, y, s in ((140, 110, 1.0), (520, 70, 1.2)):
            nuvem(a, x, y, s)
        a.add('<path d="M300,200 q10,-8 20,0 q10,-8 20,0" stroke="#333" stroke-width="2" fill="none"/>')
    ceu("praia", "#3ab0f0", "#d8f6ff", ceu_praia)

    def longe_praia(a):
        g = a.linear(["#1a8ad8", "#5ac8f0"])
        a.add(f'<rect x="0" y="230" width="1280" height="170" fill="{g}"/>')
        for k in range(16):
            x = k * 80
            a.add(f'<path d="M{x},{260 + (k % 3) * 30} q20,-8 40,0" stroke="#ffffff" stroke-width="3" fill="none" opacity="0.7"/>')
        a.add('<path d="M900,230 L960,150 L1020,230 Z" fill="#4a9a5a" opacity="0.7"/>')
        a.add('<path d="M200,230 L230,200 L300,200 L320,230 Z" fill="#f4f4f4"/><path d="M250,200 L250,140 L290,195 Z" fill="#ffffff"/>')
        a.add('<rect x="0" y="360" width="1280" height="40" fill="#f2e0a8"/>')
    tile("longe_praia", 1280, 400, longe_praia)

    def perto_praia(a):
        for k in range(3):
            x = 150 + k * 440
            a.add(f'<path d="M{x},500 Q{x + 30},350 {x + 80},220" stroke="#8a6a3a" stroke-width="16" fill="none"/>')
            for j in range(8):
                ang = math.pi + j * math.pi / 7
                ex = x + 80 + math.cos(ang) * 130
                ey = 220 + math.sin(ang) * 40 + 60
                a.add(f'<path d="M{x + 80},220 Q{(x + 80 + ex) / 2},{min(ey, 220) - 40} {ex},{ey}" stroke="#2a9a3a" stroke-width="14" fill="none" stroke-linecap="round"/>')
            a.add(f'<circle cx="{x + 72}" cy="232" r="9" fill="#6a4a1a"/><circle cx="{x + 88}" cy="234" r="9" fill="#6a4a1a"/>')
        a.add('<path d="M640,500 Q650,470 680,470 Q700,470 704,500 Z" fill="#e8b0a0"/>')
    tile("perto_praia", 1280, 500, perto_praia)

    # ---------------- 10 templo
    def ceu_templo(a):
        a.add('<circle cx="1000" cy="160" r="90" fill="#ff8a3a" opacity="0.6"/>')
        for k in range(30):
            a.add(f'<circle cx="{(k * 97) % 1280}" cy="{(k * 61) % 400}" r="2" fill="#ffcc6a" opacity="0.6"/>')
    ceu("templo", "#3a1a2a", "#c9502a", ceu_templo)

    def longe_templo(a):
        a.add('<path d="M300,400 L520,100 L580,110 L640,90 L860,400 Z" fill="#4a2a2a"/>')
        a.add('<path d="M520,100 Q580,40 640,90 Q600,20 560,60 Z" fill="#ff7a2a" opacity="0.8"/>')
        a.add('<path d="M560,110 L540,240 L580,160 L600,260 L620,120 Z" fill="#ff5a1a" opacity="0.7"/>')
        a.add('<path d="M0,400 L0,300 L200,240 L320,320 L860,320 L1050,230 L1280,300 L1280,400 Z" fill="#3a2222"/>')
    tile("longe_templo", 1280, 400, longe_templo)

    def perto_templo(a):
        for k in range(4):
            x = 80 + k * 320
            g = a.linear(["#b89a7a", "#7a6248"], 0, 0, 1, 0)
            a.add(f'<rect x="{x}" y="160" width="70" height="340" fill="{g}"/>')
            a.add(f'<rect x="{x - 14}" y="140" width="98" height="26" fill="#9a8264"/><rect x="{x - 14}" y="480" width="98" height="20" fill="#9a8264"/>')
            for j in range(5):
                a.add(f'<path d="M{x + 14 + j * 10},170 L{x + 14 + j * 10},475" stroke="#6a5238" stroke-width="2"/>')
            a.add(f'<path d="M{x + 180},500 L{x + 180},440 Q{x + 200},420 {x + 220},440 L{x + 220},500 Z" fill="#6a5a4a"/>')
            a.add(f'<circle cx="{x + 200}" cy="425" r="10" fill="#ff9a2a" opacity="0.9"/><circle cx="{x + 200}" cy="425" r="24" fill="#ff9a2a" opacity="0.2"/>')
    tile("perto_templo", 1280, 500, perto_templo)


def chaos():
    """Chão de cada fase: textura repetível (256x320) + borda de cima (256x40)."""
    estilos = {
        "selva": ("#5a3a1e", "#3a2410", "#3aa83a", "grama"),
        "rio": ("#5a4026", "#3a2a14", "#4ab84a", "grama"),
        "savana": ("#b8863a", "#8a5e24", "#c9b04a", "grama_seca"),
        "montanha": ("#6a6460", "#45403c", "#e8eef4", "neve"),
        "caverna": ("#3a3044", "#221a2a", "#5a4a6a", "pedra"),
        "fazenda": ("#7a4e26", "#52321a", "#4ab83a", "grama"),
        "cidade": ("#5a5a60", "#3a3a40", "#9a9aa2", "calcada"),
        "zoo": ("#8a6a42", "#5a442a", "#4ab84a", "grama"),
        "praia": ("#f0d898", "#d8b870", "#f8e8b8", "areia"),
        "templo": ("#6a5240", "#45342a", "#9a8264", "pedra"),
    }
    for nome, (c1, c2, topo, tipo) in estilos.items():
        a = Arte(256, 320)
        g = a.linear([c1, c2])
        a.add(f'<rect width="256" height="320" fill="{g}"/>')
        if tipo in ("pedra", "calcada"):
            for j in range(6):
                for i in range(4):
                    off = 32 if j % 2 else 0
                    a.add(f'<rect x="{i * 64 + off - 32}" y="{j * 54}" width="62" height="52" fill="none" stroke="{tom(c2, 0.7)}" stroke-width="2"/>')
        else:
            for k in range(26):
                x = (k * 97) % 256
                y = 30 + (k * 59) % 280
                r = 3 + (k * 7) % 6
                a.add(f'<ellipse cx="{x}" cy="{y}" rx="{r * 1.4}" ry="{r}" fill="{tom(c1, 0.75 if k % 2 else 1.2)}" opacity="0.7"/>')
        salvar("chao_" + nome, a, "tile")
        b = Arte(256, 40)
        if tipo in ("grama", "grama_seca"):
            b.add(f'<rect x="0" y="8" width="256" height="14" fill="{topo}"/>')
            for k in range(32):
                x = k * 8
                h = 8 + (k * 7) % 10
                b.add(f'<path d="M{x},16 L{x + 4},{16 - h} L{x + 8},16 Z" fill="{tom(topo, 1.15 if k % 2 else 0.85)}"/>')
            b.add(f'<rect x="0" y="20" width="256" height="6" fill="{tom(topo, 0.65)}"/>')
        elif tipo == "neve":
            b.add('<path d="M0,10 Q32,2 64,10 Q96,2 128,10 Q160,2 192,10 Q224,2 256,10 L256,24 L0,24 Z" fill="#f4f8ff"/>')
            b.add('<rect x="0" y="20" width="256" height="4" fill="#c8d4e4"/>')
        elif tipo == "areia":
            b.add('<path d="M0,12 Q64,6 128,12 Q192,18 256,12 L256,24 L0,24 Z" fill="#f8ecc4"/>')
        else:
            b.add(f'<rect x="0" y="10" width="256" height="14" fill="{topo}"/>')
            b.add(f'<rect x="0" y="10" width="256" height="3" fill="{tom(topo, 1.3)}"/>')
        salvar("borda_" + nome, b, "tile")
    a = Arte(256, 60)
    g = a.linear(["#4ab0e8", "#1a5a9a"])
    a.add(f'<rect width="256" height="60" fill="{g}" opacity="0.92"/>')
    a.add('<path d="M0,6 Q32,0 64,6 Q96,12 128,6 Q160,0 192,6 Q224,12 256,6" stroke="#e0f6ff" stroke-width="3" fill="none"/>')
    salvar("agua", a, "tile")
    a = Arte(110, 320)
    a.add('<rect width="110" height="320" fill="#5a4436"/>')
    a.add('<path d="M20,0 L40,40 L28,80 M70,0 L60,50 L84,90" stroke="#1a1010" stroke-width="3" fill="none"/>')
    a.add('<rect width="110" height="10" fill="#8a7464"/>')
    salvar("piso", a, "tile")


def torre():
    a = Arte(140, 520)
    g = a.linear(["#9a8264", "#6a5238"], 0, 0, 1, 0)
    a.add(f'<rect x="10" y="20" width="120" height="500" fill="{g}" stroke="#3a2a1a" stroke-width="2"/>')
    for k in range(11):
        y = 20 + k * 45
        a.add(f'<rect x="4" y="{y}" width="132" height="8" fill="#7a6248"/>')
    a.linha("M70,20 C40,120 100,240 60,360 C40,430 80,480 70,520", "#3a7a22", 5)
    a.add('<path d="M0,20 L70,-0 L140,20 Z" fill="#7a5a3a"/>')
    salvar("torre", a, "base")


def main():
    for pose in ("corre1", "corre2", "pulo", "abaixado", "pendurado"):
        macaco("macaco_" + pose, pose)
    for nome, (c1, c2) in BANANAS.items():
        banana(nome, c1, c2)
    bichos()
    chefes()
    macaco_aliado()
    for aberta in (False, True):
        jaula(aberta)
    armadilha("arm_espinho", "espinho")
    armadilha("arm_lanca", "lanca")
    armadilha("arm_agua_viva", "agua_viva")
    armadilha("arm_bueiro", "bueiro")
    bandeira()
    milharal()
    cipo()
    tronco()
    folha()
    torre()
    objs = {
        "graveto": ("#7a5a30", "graveto"), "frutinha": ("#d02a5a", "redondo"), "pedrinha": ("#9a9a9a", "pedra"),
        "concha_rio": ("#f0e0d0", "concha"), "pedra": ("#8a8478", "pedra"), "galho": ("#8a6a40", "graveto"),
        "pinha": ("#8a5a2a", "ovo"), "cristal": ("#7ae0ff", "cristal"), "ovo": ("#fff8e8", "ovo"),
        "espiga": ("#ffd23a", "espiga"), "latinha": ("#c0c4cc", "lata"), "tampinha": ("#d02a2a", "redondo"),
        "balde": ("#4a7ad0", "balde"), "peixinho": ("#8ab0d8", "peixe"), "coco": ("#6a4a22", "coco"),
        "concha": ("#ffc0b0", "concha"), "pedra_templo": ("#9a8264", "pedra"), "estatua": ("#c9c0a8", "pedra"),
        "casca": ("#ffe14d", "casca"),
    }
    for nome, (cor, forma) in objs.items():
        objeto(nome, cor, forma)
    cenarios()
    chaos()
    with open(os.path.join(SAIDA, "manifesto.json"), "w", encoding="utf-8") as f:
        json.dump(MANIFESTO, f, indent=1, ensure_ascii=False)
    # o mesmo manifesto como script do Godot (entra no APK sem configuração extra)
    linhas = ["extends RefCounted", "## Gerado por ferramentas/gerar_arte.py. Não edite à mão.", "", "const INFO := {"]
    for nome, i in sorted(MANIFESTO.items()):
        linhas.append(f'\t"{nome}": {{"w": {i["w"]}, "h": {i["h"]}, "ancora": "{i["ancora"]}"}},')
    linhas.append("}")
    with open(os.path.join(RAIZ, "scripts", "arte_info.gd"), "w", encoding="utf-8") as f:
        f.write("\n".join(linhas) + "\n")
    print("Desenhos gerados:", len(MANIFESTO))


if __name__ == "__main__":
    main()
