"""Génère le mesh et la texture de l'« Œuf de la Prairie ».

Sorties (dans ../egg/) :
  OeufPrairie.glb          3 meshes (Egg, ShellTop, ShellBottom) + texture intégrée
  OeufPrairie.obj / .mtl   même contenu au format OBJ
  OeufPrairie_texture.png  texture 1024 × 1024

- Egg : l'œuf entier, pour le socle.
- ShellTop / ShellBottom : les deux moitiés de coquille (avec épaisseur), séparées
  par une fissure en zigzag. Assemblées, elles redonnent exactement l'œuf. Elles sont
  placées à +8 studs en X dans le fichier pour ne pas se superposer à Egg dans Studio.

Unités : 1 unité = 1 stud. L'œuf fait 5 studs de haut et 4,3 de large.
Usage : python3 tools/egg_generate.py   (numpy + Pillow)
"""

import json
import math
import os
import struct

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "egg")

# ─── Forme ────────────────────────────────────────────────────────────────────
A = 2.5    # demi-hauteur
B = 2.15   # rayon à l'équateur
K = 0.13   # asymétrie : haut plus étroit que le bas
N_SEG = 40           # segments autour (pair : 20 dents de fissure)
N_RING = 28          # anneaux réguliers de haut en bas
CRACK_Y = 0.42       # hauteur de la fissure (le chapeau est un peu plus petit que le bas)
CRACK_AMP = 0.19     # demi-hauteur des dents (studs)
SHELL = 0.1          # épaisseur de la coquille
SHELLS_X = 8.0       # décalage des moitiés dans le fichier

TEX = 1024
SS = 2               # suréchantillonnage de la texture
MAIN_V = 0.93        # la coquille utilise v ∈ [0, MAIN_V], le reste = couleurs unies
UV_INNER = (0.25, 0.97)
UV_RIM = (0.75, 0.97)


def profile(t):
    """t ∈ [0, π] du haut vers le bas -> (y, r, dy/dt, dr/dt)."""
    y = A * np.cos(t)
    r = B * np.sin(t) * (1 - K * np.cos(t))
    dy = -A * np.sin(t)
    dr = B * (np.cos(t) - K * np.cos(2 * t))
    return y, r, dy, dr


# Abscisse curviligne normalisée s ∈ [0, 1] <-> t
_T = np.linspace(0, math.pi, 20001)
_y, _r, _dy, _dr = profile(_T)
_ds = np.sqrt(_dy ** 2 + _dr ** 2)
_S = np.concatenate([[0], np.cumsum((_ds[1:] + _ds[:-1]) / 2 * np.diff(_T))])
L_TOTAL = _S[-1]
_S /= L_TOTAL


def t_of_s(s):
    return np.interp(s, _S, _T)


def s_of_y(y):
    return float(np.interp(math.acos(y / A), _T, _S))


def surface(theta, s):
    """Point, normale extérieure et tangente « vers le bas » (dP/ds normalisée)."""
    t = t_of_s(s)
    y, r, dy, dr = profile(t)
    c, sn = np.cos(theta), np.sin(theta)
    p = np.stack([r * c, y, r * sn], -1)
    ln = np.sqrt(dy ** 2 + dr ** 2)
    nr, ny = -dy / ln, dr / ln
    n = np.stack([nr * c, ny, nr * sn], -1)
    down = np.stack([dr / ln * c, dy / ln, dr / ln * sn], -1)
    return p, n, down


# θ = 0 à l'arrière (+Z) pour cacher la couture ; l'avant d'un modèle Roblox est -Z.
def theta_of_u(u):
    return math.pi / 2 + 2 * math.pi * u


# ─── Texture ──────────────────────────────────────────────────────────────────
def lerp(a, b, t):
    return a + (b - a) * t


def rgb(*c):
    return np.array(c, dtype=np.float32) / 255.0


CREAM_TOP = rgb(255, 248, 222)
CREAM_LOW = rgb(254, 234, 192)
GRASS_BACK = rgb(88, 178, 68)
GRASS_BACK_LIGHT = rgb(116, 198, 84)
GRASS_FRONT = rgb(122, 208, 86)
GRASS_FRONT_LIGHT = rgb(170, 232, 124)
GRASS_RIM = rgb(66, 146, 54)
GRASS_DEEP = rgb(72, 156, 58)
INNER = rgb(255, 250, 238)
RIM = rgb(255, 242, 214)


def paint_texture():
    W = H = TEX * SS
    img = np.zeros((H, W, 3), np.float32)
    rows = int(H * MAIN_V)
    u = (np.arange(W) + 0.5) / W
    v = (np.arange(rows) + 0.5) / H
    s = v / MAIN_V
    theta = math.pi / 2 + 2 * math.pi * u
    TH, SV = np.meshgrid(theta, s)
    P, Nrm, _ = surface(TH, SV)
    Y = P[..., 1]
    R = np.sqrt(P[..., 0] ** 2 + P[..., 2] ** 2)
    rng = np.random.default_rng(7)

    # Fond crème
    g = np.clip((Y - 2.2) / (-3.4), 0, 1)[..., None]
    col = lerp(CREAM_TOP, CREAM_LOW, g)

    def paint(mask, color, alpha=1.0):
        nonlocal col
        m = mask.astype(np.float32)[..., None] * alpha
        col = col * (1 - m) + color * m

    def wrap(d):
        return (d + math.pi) % (2 * math.pi) - math.pi

    def local(theta_c, y_c):
        """Coordonnées locales (studs) dans le plan tangent : x vers +θ, y vers le haut."""
        s_c = s_of_y(y_c)
        c, n, down = surface(np.array(theta_c), np.array(s_c))
        e = np.array([-math.sin(theta_c), 0.0, math.cos(theta_c)])
        up = -down
        d = P - c
        lx = d @ e
        ly = d @ up
        front = (d @ n) > -1.0  # même côté de l'œuf
        return lx, ly, front

    # Herbe : deux rangées de brins arrondis qui montent depuis le bas
    def blades(n, base, hmin, hmax, wmin, wmax, phase):
        out = []
        for i in range(n):
            th = phase + (i + rng.uniform(-0.28, 0.28)) / n * 2 * math.pi
            out.append((th, rng.uniform(hmin, hmax), rng.uniform(wmin, wmax), rng.uniform(-0.35, 0.35)))
        return base, out

    def grass_mask(layer, grow=0.0):
        base, bl = layer
        m = Y < base + grow
        hi = np.zeros_like(Y, dtype=bool)
        for th, h, w, tilt in bl:
            yr = Y - base
            arc = wrap(TH - th) * R
            x = (arc - tilt * np.clip(yr, 0, None)) / (w / 2 + grow)
            hh = (h + grow) * np.clip(1 - np.abs(x) ** 1.7, 0, None) ** 0.9
            m |= (yr < hh) & (np.abs(x) < 1)
            hi |= (yr < hh * 0.78) & (yr > hh * 0.12 + 0.05) & (np.abs(x + 0.12) < 0.2) & (hh > 0.18)
        return m, hi

    back = blades(30, -1.12, 0.42, 0.78, 0.42, 0.62, 0.0)
    front = blades(34, -1.38, 0.26, 0.55, 0.36, 0.56, 0.09)
    bm, bhi = grass_mask(back)
    bm_rim, _ = grass_mask(back, 0.045)
    paint(bm_rim & ~bm, GRASS_RIM)
    paint(bm, GRASS_BACK)
    paint(bhi & bm, GRASS_BACK_LIGHT)
    fm, fhi = grass_mask(front)
    fm_rim, _ = grass_mask(front, 0.045)
    paint(fm_rim & ~fm, GRASS_RIM)
    paint(fm, GRASS_FRONT)
    paint(fhi & fm, GRASS_FRONT_LIGHT)
    deep = np.clip((Y + 1.75) / -0.75, 0, 1) * (Y < -1.75)
    col = lerp(col, GRASS_DEEP, deep[..., None] * fm[..., None])

    # Fleurs dans l'herbe : marguerites, fleurs roses, boutons d'or
    kinds = [
        dict(n=8, petal=rgb(255, 255, 255), line=rgb(232, 228, 240), heart=rgb(255, 206, 64), heart2=rgb(244, 160, 40), r=0.32),
        dict(n=5, petal=rgb(255, 156, 188), line=rgb(238, 120, 160), heart=rgb(255, 222, 100), heart2=rgb(246, 176, 60), r=0.29),
        dict(n=5, petal=rgb(255, 214, 72), line=rgb(240, 180, 40), heart=rgb(255, 150, 50), heart2=rgb(226, 112, 30), r=0.26),
    ]
    order = [0, 1, 0, 2, 0, 1, 2, 0, 1, 0, 2, 1]
    n_fl = len(order)
    for i, kind in enumerate(order):
        f = kinds[kind]
        # la première marguerite est pile devant (-Z, θ = 3π/2)
        th = 3 * math.pi / 2 + i / n_fl * 2 * math.pi + rng.uniform(-0.12, 0.12)
        y = -0.95 - (i % 3) * 0.32 + rng.uniform(-0.08, 0.08)
        rad = f["r"] * rng.uniform(0.9, 1.12) * (1.25 if i == 0 else 1.0)
        lx, ly, frontside = local(th, y)
        rho = np.sqrt(lx ** 2 + ly ** 2)
        phi = np.arctan2(ly, lx) + rng.uniform(0, math.pi)
        lobes = np.abs(np.cos(f["n"] * phi / 2))
        rr = rad * (0.58 + 0.42 * lobes ** 0.55)
        petals = (rho < rr) & frontside
        paint((rho < rr + 0.03) & frontside, GRASS_RIM, 0.5)
        paint(petals, f["petal"])
        paint(petals & (lobes < 0.16) & (rho > rad * 0.36), f["line"])
        heart = (rho < rad * 0.36) & frontside
        paint(heart, f["heart"])
        paint(heart & (np.sqrt((lx + 0.06 * rad) ** 2 + (ly + 0.08 * rad) ** 2) > rad * 0.3), f["heart2"])
        paint(heart & (np.sqrt((lx - 0.1 * rad) ** 2 + (ly - 0.12 * rad) ** 2) < rad * 0.09), rgb(255, 250, 220))

    img[:rows] = col
    # Bande de couleurs unies pour l'intérieur et la tranche de la coquille
    img[rows:, : W // 2] = INNER
    img[rows:, W // 2:] = RIM
    im = Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8))
    return im.resize((TEX, TEX), Image.LANCZOS)


# ─── Mesh ─────────────────────────────────────────────────────────────────────
def ring_list():
    s_c = s_of_y(CRACK_Y)
    gap = 0.045
    rings = [k / N_RING for k in range(N_RING + 1) if abs(k / N_RING - s_c) > gap]
    rings.append(s_c)
    rings.sort()
    return rings, rings.index(s_c), s_c


RINGS, CRACK_K, S_CRACK = ring_list()
A_S = CRACK_AMP / L_TOTAL


def grid():
    """Sommets de la surface extérieure : [anneau][colonne] (N_SEG + 1 colonnes)."""
    pos, nrm, down, uv = [], [], [], []
    last = len(RINGS) - 1
    for k, s in enumerate(RINGS):
        P, Nn, D, U = [], [], [], []
        for j in range(N_SEG + 1):
            u = j / N_SEG
            if k in (0, last):
                u = (j + 0.5) / N_SEG
            sj = s
            if k == CRACK_K:
                sj = s + (A_S if j % 2 == 0 else -A_S)
            p, n, d = surface(np.array(theta_of_u(u)), np.array(sj))
            if k == 0:
                p, n, d = np.array([0, A, 0.0]), np.array([0, 1.0, 0]), d
            if k == last:
                p, n, d = np.array([0, -A, 0.0]), np.array([0, -1.0, 0]), d
            P.append(p)
            Nn.append(n)
            D.append(d)
            U.append((u, sj * MAIN_V))
        pos.append(P)
        nrm.append(Nn)
        down.append(D)
        uv.append(U)
    return pos, nrm, down, uv


class MeshBuilder:
    def __init__(self, name):
        self.name = name
        self.p, self.n, self.uv, self.tri = [], [], [], []

    def vert(self, p, n, uv):
        self.p.append(np.asarray(p, float))
        self.n.append(np.asarray(n, float) / np.linalg.norm(n))
        self.uv.append(uv)
        return len(self.p) - 1

    def face(self, a, b, c, ref):
        pa, pb, pc = self.p[a], self.p[b], self.p[c]
        fn = np.cross(pb - pa, pc - pa)
        if np.linalg.norm(fn) < 1e-12:
            return
        if fn @ ref < 0:
            b, c = c, b
        self.tri.append((a, b, c))


def build_surface(mb, pos, nrm, uv, k0, k1, inward=0.0, flip=False, uv_override=None):
    """Ajoute les anneaux k0..k1. inward > 0 : surface intérieure décalée et retournée."""
    idx = {}
    for k in range(k0, k1 + 1):
        for j in range(N_SEG + 1):
            p = pos[k][j] - nrm[k][j] * inward
            n = -nrm[k][j] if flip else nrm[k][j]
            idx[k, j] = mb.vert(p, n, uv_override or uv[k][j])
    for k in range(k0, k1):
        for j in range(N_SEG):
            a, b, c, d = idx[k, j], idx[k, j + 1], idx[k + 1, j + 1], idx[k + 1, j]
            ref = nrm[k][j] + nrm[k][j + 1] + nrm[k + 1][j] + nrm[k + 1][j + 1]
            if flip:
                ref = -ref
            # Diagonale qui suit le zigzag pour garder des triangles réguliers
            if (k + 1 == CRACK_K and j % 2 == 1) or (k == CRACK_K and j % 2 == 0):
                mb.face(a, b, d, ref)
                mb.face(b, c, d, ref)
            else:
                mb.face(a, b, c, ref)
                mb.face(a, c, d, ref)
    return idx


def build_rim(mb, pos, nrm, down, top_shell):
    k = CRACK_K
    outer, inner = {}, {}
    for j in range(N_SEG + 1):
        d = down[k][j] if top_shell else -down[k][j]
        outer[j] = mb.vert(pos[k][j], d, UV_RIM)
        inner[j] = mb.vert(pos[k][j] - nrm[k][j] * SHELL, d, UV_RIM)
    for j in range(N_SEG):
        ref = (down[k][j] + down[k][j + 1]) * (1 if top_shell else -1)
        mb.face(outer[j], outer[j + 1], inner[j + 1], ref)
        mb.face(outer[j], inner[j + 1], inner[j], ref)


def build_meshes():
    pos, nrm, down, uv = grid()
    last = len(RINGS) - 1
    egg = MeshBuilder("Egg")
    build_surface(egg, pos, nrm, uv, 0, last)
    top = MeshBuilder("ShellTop")
    build_surface(top, pos, nrm, uv, 0, CRACK_K)
    build_surface(top, pos, nrm, uv, 0, CRACK_K, inward=SHELL, flip=True, uv_override=UV_INNER)
    build_rim(top, pos, nrm, down, True)
    bottom = MeshBuilder("ShellBottom")
    build_surface(bottom, pos, nrm, uv, CRACK_K, last)
    build_surface(bottom, pos, nrm, uv, CRACK_K, last, inward=SHELL, flip=True, uv_override=UV_INNER)
    build_rim(bottom, pos, nrm, down, False)
    return [egg, top, bottom]


def offsets():
    return {"Egg": np.zeros(3), "ShellTop": np.array([SHELLS_X, 0, 0]), "ShellBottom": np.array([SHELLS_X, 0, 0])}


# ─── Export ───────────────────────────────────────────────────────────────────
def write_glb(meshes, png_bytes, path):
    off = offsets()
    blob = bytearray()
    views, accessors, gl_meshes, nodes = [], [], [], []

    def add_view(data, target=None):
        while len(blob) % 4:
            blob.append(0)
        v = {"buffer": 0, "byteOffset": len(blob), "byteLength": len(data)}
        if target:
            v["target"] = target
        blob.extend(data)
        views.append(v)
        return len(views) - 1

    for i, m in enumerate(meshes):
        P = np.array(m.p, np.float32)
        Nn = np.array(m.n, np.float32)
        U = np.array(m.uv, np.float32)
        I = np.array(m.tri, np.uint32).ravel()
        vp = add_view(P.tobytes(), 34962)
        vn = add_view(Nn.tobytes(), 34962)
        vu = add_view(U.tobytes(), 34962)
        vi = add_view(I.tobytes(), 34963)
        base = len(accessors)
        accessors += [
            {"bufferView": vp, "componentType": 5126, "count": len(P), "type": "VEC3",
             "min": P.min(0).tolist(), "max": P.max(0).tolist()},
            {"bufferView": vn, "componentType": 5126, "count": len(P), "type": "VEC3"},
            {"bufferView": vu, "componentType": 5126, "count": len(P), "type": "VEC2"},
            {"bufferView": vi, "componentType": 5125, "count": len(I), "type": "SCALAR"},
        ]
        gl_meshes.append({"name": m.name, "primitives": [{
            "attributes": {"POSITION": base, "NORMAL": base + 1, "TEXCOORD_0": base + 2},
            "indices": base + 3, "material": 0}]})
        nodes.append({"name": m.name, "mesh": i, "translation": off[m.name].tolist()})
    vimg = add_view(png_bytes)
    while len(blob) % 4:
        blob.append(0)
    gltf = {
        "asset": {"version": "2.0", "generator": "CubePets egg_generate.py"},
        "scene": 0,
        "scenes": [{"name": "OeufPrairie", "nodes": list(range(len(nodes)))}],
        "nodes": nodes,
        "meshes": gl_meshes,
        "materials": [{"name": "OeufPrairie", "pbrMetallicRoughness": {
            "baseColorTexture": {"index": 0}, "metallicFactor": 0.0, "roughnessFactor": 0.6}}],
        "textures": [{"sampler": 0, "source": 0}],
        "samplers": [{"magFilter": 9729, "minFilter": 9987, "wrapS": 10497, "wrapT": 33071}],
        "images": [{"name": "OeufPrairie_texture", "bufferView": vimg, "mimeType": "image/png"}],
        "accessors": accessors,
        "bufferViews": views,
        "buffers": [{"byteLength": len(blob)}],
    }
    js = json.dumps(gltf, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    total = 12 + 8 + len(js) + 8 + len(blob)
    with open(path, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(js), 0x4E4F534A))
        f.write(js)
        f.write(struct.pack("<II", len(blob), 0x004E4942))
        f.write(blob)


def write_obj(meshes, obj_path, mtl_name, tex_name):
    off = offsets()
    lines = ["# Oeuf de la Prairie (CubePets) - 1 unité = 1 stud", f"mtllib {mtl_name}"]
    base = 1
    for m in meshes:
        lines.append(f"o {m.name}")
        o = off[m.name]
        for p in m.p:
            lines.append("v %.5f %.5f %.5f" % tuple(p + o))
        for n in m.n:
            lines.append("vn %.5f %.5f %.5f" % tuple(n))
        for u, v in m.uv:
            lines.append("vt %.5f %.5f" % (u, 1 - v))
        lines.append("usemtl OeufPrairie")
        lines.append("s 1")
        for a, b, c in m.tri:
            a, b, c = a + base, b + base, c + base
            lines.append(f"f {a}/{a}/{a} {b}/{b}/{b} {c}/{c}/{c}")
        base += len(m.p)
    with open(obj_path, "w") as f:
        f.write("\n".join(lines) + "\n")
    with open(os.path.join(os.path.dirname(obj_path), mtl_name), "w") as f:
        f.write("newmtl OeufPrairie\nKa 1 1 1\nKd 1 1 1\nKs 0 0 0\nd 1\nillum 1\n"
                f"map_Kd {tex_name}\n")


def check(meshes):
    for m in meshes:
        P = np.array(m.p)
        T = np.array(m.tri)
        # Chaque arête doit être partagée par exactement 2 triangles (mesh fermé)
        # pour l'œuf entier ; les coquilles sont fermées aussi grâce à la tranche.
        edges = {}
        for a, b, c in m.tri:
            for e in ((a, b), (b, c), (c, a)):
                key = tuple(sorted(e))
                edges[key] = edges.get(key, 0) + 1
        # les sommets dupliqués (couture, pôles, tranche) ouvrent des arêtes : on fusionne par position
        keyp = {i: tuple(np.round(p, 5)) for i, p in enumerate(P)}
        pedges = {}
        for (a, b), cnt in edges.items():
            k = tuple(sorted((keyp[a], keyp[b])))
            if k[0] != k[1]:
                pedges[k] = pedges.get(k, 0) + cnt
        bad = sum(1 for c in pedges.values() if c != 2)
        print(f"{m.name:12s} {len(P):5d} sommets  {len(T):5d} triangles  arêtes non fermées : {bad}  "
              f"taille {np.ptp(P, 0).round(3).tolist()}")


def main():
    os.makedirs(OUT, exist_ok=True)
    meshes = build_meshes()
    check(meshes)
    tex = paint_texture()
    tex_path = os.path.join(OUT, "OeufPrairie_texture.png")
    tex.save(tex_path, optimize=True)
    with open(tex_path, "rb") as f:
        png = f.read()
    write_glb(meshes, png, os.path.join(OUT, "OeufPrairie.glb"))
    write_obj(meshes, os.path.join(OUT, "OeufPrairie.obj"), "OeufPrairie.mtl", "OeufPrairie_texture.png")
    print("fissure : y = %.2f, %d dents ; L = %.3f studs" % (CRACK_Y, N_SEG // 2, L_TOTAL))


if __name__ == "__main__":
    main()
