// Viewer three.js des Cube Pets : reproduit la géométrie des primitives Roblox
// (Block / Ball / Cylinder / Wedge), le rig Motor6D et le visage SurfaceGui à partir
// de pet_data.json (exporté par tools/preview_export.luau).
//
// API : createViewer(container, data, opts) -> { setVariant, setLineup, setOutline, setView, setPose, project, render, ... }
import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { RoomEnvironment } from "three/addons/environments/RoomEnvironment.js";

// ─── Maths CFrame (Roblox : R00..R22 en ligne) ───────────────────────────────
function cfToMatrix(c) {
  const [x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22] = c;
  const m = new THREE.Matrix4();
  m.set(r00, r01, r02, x, r10, r11, r12, y, r20, r21, r22, z, 0, 0, 0, 1);
  return m;
}
const tmpM = new THREE.Matrix4();
function angles(rx, ry, rz) {
  // CFrame.Angles(rx, ry, rz) = Rx * Ry * Rz
  const m = new THREE.Matrix4().makeRotationX(rx);
  m.multiply(tmpM.makeRotationY(ry));
  m.multiply(tmpM.makeRotationZ(rz));
  return m;
}
function cfn(x, y, z) {
  return new THREE.Matrix4().makeTranslation(x, y, z);
}

// ─── Géométries des primitives Roblox ─────────────────────────────────────────
function wedgeGeometry(sx, sy, sz) {
  const x = sx / 2, y = sy / 2, z = sz / 2;
  // pente vers l'avant (-Z) : arête haute à l'arrière (+Z)
  const v = [
    [-x, -y, -z], [x, -y, -z], [x, -y, z], [-x, -y, z], // bas
    [-x, y, z], [x, y, z], // arête haute arrière
  ];
  const faces = [
    [0, 2, 1], [0, 3, 2], // bas
    [3, 5, 4], [3, 2, 5], // arrière
    [0, 1, 5], [0, 5, 4], // pente
    [0, 4, 3], // côté gauche
    [1, 2, 5], // côté droit
  ];
  // orientation des triangles vers l'extérieur (forme convexe)
  const cx = 0, cy = (-y * 4 + y * 2) / 6, cz = (-z * 2 + z * 4) / 6;
  const pos = [];
  for (const f of faces) {
    let [a, b, c] = f.map((i) => v[i]);
    const e1 = [b[0] - a[0], b[1] - a[1], b[2] - a[2]];
    const e2 = [c[0] - a[0], c[1] - a[1], c[2] - a[2]];
    const n = [e1[1] * e2[2] - e1[2] * e2[1], e1[2] * e2[0] - e1[0] * e2[2], e1[0] * e2[1] - e1[1] * e2[0]];
    const m = [(a[0] + b[0] + c[0]) / 3 - cx, (a[1] + b[1] + c[1]) / 3 - cy, (a[2] + b[2] + c[2]) / 3 - cz];
    if (n[0] * m[0] + n[1] * m[1] + n[2] * m[2] < 0) [b, c] = [c, b];
    pos.push(...a, ...b, ...c);
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  g.computeVertexNormals();
  return g;
}

function partGeometry(p) {
  const [sx, sy, sz] = p.size;
  switch (p.shape) {
    case "Ball":
      return new THREE.SphereGeometry(sx / 2, 48, 32);
    case "Cylinder": {
      const g = new THREE.CylinderGeometry(Math.min(sy, sz) / 2, Math.min(sy, sz) / 2, sx, 48, 1);
      g.rotateZ(-Math.PI / 2); // axe Y -> axe X (convention Roblox)
      return g;
    }
    case "Wedge":
      return wedgeGeometry(sx, sy, sz);
    default:
      return new THREE.BoxGeometry(sx, sy, sz);
  }
}

// ─── Rendu de la SurfaceGui dans un canvas 2D ────────────────────────────────
function drawGui(ctx, node, rect, scale) {
  // rect = {x, y, w, h} en pixels canvas Roblox ; scale = facteur de suréchantillonnage
  const kids = flatten(node.children || []);
  kids.sort((a, b) => a.z - b.z);
  for (const k of kids) drawNode(ctx, k, rect, scale);
}
function flatten(list) {
  const out = [];
  if (!Array.isArray(list)) return out;
  for (const n of list) {
    if (n.class === "Folder") out.push(...flatten(n.children || []));
    else out.push(n);
  }
  return out;
}
function drawNode(ctx, n, parent, scale) {
  if (!n.visible) return;
  const w = n.size[0] * parent.w + n.size[1];
  const h = n.size[2] * parent.h + n.size[3];
  const x = parent.x + n.pos[0] * parent.w + n.pos[1] - n.anchor[0] * w;
  const y = parent.y + n.pos[2] * parent.h + n.pos[3] - n.anchor[1] * h;
  ctx.save();
  if (n.rot) {
    ctx.translate((x + w / 2) * scale, (y + h / 2) * scale);
    ctx.rotate((n.rot * Math.PI) / 180);
    ctx.translate(-(x + w / 2) * scale, -(y + h / 2) * scale);
  }
  if (n.bt < 1) {
    const [r, g, b] = n.color;
    ctx.fillStyle = `rgba(${r * 255},${g * 255},${b * 255},${1 - n.bt})`;
    let radii = [0, 0, 0, 0];
    if (n.corner) {
      // UICorner : Scale relatif au plus petit côté, rayon borné à la moitié de ce côté
      // (si les 4 coins sont égaux) ; par coin, borne façon CSS.
      const m = Math.min(w, h);
      radii = n.corner.map(([sc, off]) => Math.max(0, sc * m + off));
      const uniform = radii.every((r) => r === radii[0]);
      if (uniform) radii = radii.map((r) => Math.min(r, m / 2));
      else {
        const f = Math.min(1, w / (radii[0] + radii[1] || 1), w / (radii[3] + radii[2] || 1), h / (radii[0] + radii[3] || 1), h / (radii[1] + radii[2] || 1));
        radii = radii.map((r) => r * f);
      }
    }
    ctx.beginPath();
    ctx.roundRect(x * scale, y * scale, w * scale, h * scale, radii.map((r) => r * scale));
    ctx.fill();
  }
  if (n.clip && !n.rot) {
    ctx.beginPath();
    ctx.rect(x * scale, y * scale, w * scale, h * scale);
    ctx.clip();
  }
  drawGui(ctx, n, { x, y, w, h }, scale);
  ctx.restore();
}

// ─── Scène ───────────────────────────────────────────────────────────────────
export async function createViewer(container, data, opts = {}) {
  const renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: true, alpha: false });
  renderer.setPixelRatio(opts.pixelRatio || Math.min(window.devicePixelRatio, 2));
  renderer.setSize(container.clientWidth, container.clientHeight);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.NoToneMapping;
  container.appendChild(renderer.domElement);

  const scene = new THREE.Scene();
  const bg = new THREE.Color(opts.background || "#eef3e6");
  scene.background = bg;
  const pmrem = new THREE.PMREMGenerator(renderer);
  scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;

  const camera = new THREE.PerspectiveCamera(30, container.clientWidth / container.clientHeight, 0.1, 200);
  camera.position.set(-6.5, 4.2, -8.5);
  const controls = new OrbitControls(camera, renderer.domElement);
  controls.target.set(0, 1.45, 0);
  controls.enableDamping = true;
  controls.minDistance = 4;
  controls.maxDistance = 60;
  controls.update();

  const hemi = new THREE.HemisphereLight(0xffffff, 0xc9c2b6, 1.85);
  scene.add(hemi);
  const sun = new THREE.DirectionalLight(0xfffaf0, 1.9);
  sun.position.set(-4, 9, -6);
  sun.castShadow = true;
  sun.shadow.mapSize.set(2048, 2048);
  sun.shadow.camera.left = -9; sun.shadow.camera.right = 9;
  sun.shadow.camera.top = 9; sun.shadow.camera.bottom = -9;
  sun.shadow.bias = -0.0004;
  sun.shadow.radius = 4;
  scene.add(sun);

  const ground = new THREE.Mesh(
    new THREE.CircleGeometry(30, 64),
    new THREE.ShadowMaterial({ opacity: 0.22 })
  );
  ground.rotation.x = -Math.PI / 2;
  ground.receiveShadow = true;
  scene.add(ground);

  const petRoot = new THREE.Group();
  scene.add(petRoot);

  // Outline (équivalent Highlight Roblox) : masque + dilatation en post-process
  const maskTarget = new THREE.WebGLRenderTarget(1, 1);
  const sceneTarget = new THREE.WebGLRenderTarget(1, 1, { samples: 4 });
  const maskMaterial = new THREE.MeshBasicMaterial({ color: 0xffffff });
  const quadCam = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
  const quadMat = new THREE.ShaderMaterial({
    uniforms: {
      tScene: { value: null },
      tMask: { value: null },
      texel: { value: new THREE.Vector2() },
      thickness: { value: 3.0 },
      color: { value: new THREE.Color(0x3a221a) },
      enabled: { value: 1 },
    },
    vertexShader: `varying vec2 vUv; void main(){ vUv = uv; gl_Position = vec4(position.xy, 0., 1.); }`,
    fragmentShader: `
      uniform sampler2D tScene; uniform sampler2D tMask; uniform vec2 texel; uniform float thickness; uniform vec3 color; uniform float enabled;
      varying vec2 vUv;
      void main(){
        vec4 base = texture2D(tScene, vUv);
        float m = texture2D(tMask, vUv).r;
        float edge = 0.0;
        if (enabled > 0.5 && m < 0.5) {
          for (int i = 0; i < 16; i++) {
            float a = float(i) / 16.0 * 6.2831853;
            for (int j = 1; j <= 3; j++) {
              vec2 o = vec2(cos(a), sin(a)) * texel * thickness * float(j) / 3.0;
              edge = max(edge, texture2D(tMask, vUv + o).r);
            }
          }
        }
        gl_FragColor = vec4(mix(base.rgb, color, edge), 1.0);
        #include <colorspace_fragment>
      }`,
    depthTest: false,
    depthWrite: false,
  });
  const quad = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), quadMat);
  const quadScene = new THREE.Scene();
  quadScene.add(quad);

  const state = {
    variant: opts.variant || "Shiba/Normal",
    outline: opts.outline !== false,
    pose: null, // fonction(t) -> {bone: Matrix4 additionnelle}
    t0: performance.now(),
    frozenTime: null,
  };

  let pets = []; // [{ group, boneGroups, boneRest, motors, faceTex, faceCanvas, ... }]

  function clearPets() {
    for (const pet of pets) {
      petRoot.remove(pet.group);
      pet.group.traverse((o) => { if (o.geometry) o.geometry.dispose(); if (o.material) { o.material.map?.dispose?.(); o.material.dispose(); } });
    }
    pets = [];
  }

  // Ajoute un pet dans la scène, décalé de x studs et mis à l'échelle depuis son pivot
  // au sol (comme Model:ScaleTo dans Roblox). Plusieurs pets = vue côte à côte.
  function buildPet(variantName, x = 0, scale = 1) {
    const d = data[variantName];
    const group = new THREE.Group();
    group.position.x = x;
    group.scale.setScalar(scale);
    const boneRest = {};
    const boneGroups = {};
    for (const [name, b] of Object.entries(d.bones)) {
      boneRest[name] = cfToMatrix(b.cf);
      const g = new THREE.Group();
      g.matrixAutoUpdate = false;
      g.matrix.copy(boneRest[name]);
      boneGroups[name] = g;
      group.add(g);
    }
    const meshes = [];
    for (const p of d.parts) {
      const mat = new THREE.MeshStandardMaterial({
        color: new THREE.Color().setRGB(p.color[0], p.color[1], p.color[2], THREE.SRGBColorSpace),
        roughness: p.refl > 0.1 ? 0.28 : 0.55,
        metalness: p.refl > 0.1 ? 0.25 : 0.0,
        envMapIntensity: 0.35 + p.refl * 2.5,
      });
      const mesh = new THREE.Mesh(partGeometry(p), mat);
      mesh.castShadow = true;
      mesh.receiveShadow = true;
      mesh.matrixAutoUpdate = false;
      const bone = boneGroups[p.bone] ? p.bone : "Body";
      mesh.matrix.copy(boneRest[bone].clone().invert().multiply(cfToMatrix(p.cf)));
      mesh.userData = p;
      boneGroups[bone].add(mesh);
      meshes.push(mesh);
    }
    // Visage
    const f = d.face;
    const SS = 4; // suréchantillonnage
    const faceCanvas = document.createElement("canvas");
    faceCanvas.width = f.canvas[0] * SS;
    faceCanvas.height = f.canvas[1] * SS;
    const faceTex = new THREE.CanvasTexture(faceCanvas);
    faceTex.colorSpace = THREE.SRGBColorSpace;
    faceTex.anisotropy = 8;
    const faceMat = new THREE.MeshStandardMaterial({
      map: faceTex, transparent: true, roughness: 0.6, metalness: 0, envMapIntensity: 0.3,
      polygonOffset: true, polygonOffsetFactor: -2, polygonOffsetUnits: -2,
    });
    const plane = new THREE.Mesh(new THREE.PlaneGeometry(f.size[0], f.size[1]), faceMat);
    plane.matrixAutoUpdate = false;
    const faceFront = cfToMatrix(f.cf).multiply(cfn(0, 0, -f.size[2] / 2)).multiply(new THREE.Matrix4().makeRotationY(Math.PI));
    plane.matrix.copy(boneRest.Body.clone().invert().multiply(faceFront));
    boneGroups.Body.add(plane);

    petRoot.add(group);
    const pet = { group, boneGroups, boneRest, motors: d.motors, faceCanvas, faceTex, face: f, meshes, data: d, SS };
    pets.push(pet);
    quadMat.uniforms.color.value.setRGB(...d.outline, THREE.SRGBColorSpace);
    drawFace(pet);
  }

  function drawFace(pet) {
    const { faceCanvas, faceTex, face, SS } = pet;
    const ctx = faceCanvas.getContext("2d");
    ctx.clearRect(0, 0, faceCanvas.width, faceCanvas.height);
    const rect = { x: 0, y: 0, w: face.canvas[0], h: face.canvas[1] };
    ctx.save();
    ctx.beginPath();
    ctx.rect(0, 0, faceCanvas.width, faceCanvas.height);
    ctx.clip();
    // le noeud racine (Canvas) occupe tout
    drawNode(ctx, face.root, rect, SS);
    ctx.restore();
    faceTex.needsUpdate = true;
  }

  // ─── Rig : Part1 = Part0 * C0 * anim * C1^-1 ───────────────────────────────
  function applyPose(pet, offsets) {
    const world = { RootPart: pet.boneRest.RootPart.clone() };
    const order = ["RootJoint", "EarL", "EarR", "Tail", "LegFL", "LegFR", "LegBL", "LegBR"];
    for (const name of order) {
      const m = pet.motors.find((x) => x.name === name);
      if (!m) continue;
      const parent = world[m.part0];
      const c0 = cfToMatrix(m.c0);
      const c1inv = cfToMatrix(m.c1).invert();
      const anim = (offsets && offsets[name]) || new THREE.Matrix4();
      world[m.part1] = parent.clone().multiply(c0).multiply(anim).multiply(c1inv);
    }
    for (const [name, g] of Object.entries(pet.boneGroups)) {
      if (world[name]) g.matrix.copy(world[name]);
      g.matrixWorldNeedsUpdate = true;
    }
  }

  function resize() {
    const w = container.clientWidth, h = container.clientHeight;
    renderer.setSize(w, h);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
    const pr = renderer.getPixelRatio();
    maskTarget.setSize(w * pr, h * pr);
    sceneTarget.setSize(w * pr, h * pr);
    quadMat.uniforms.texel.value.set(1 / (w * pr), 1 / (h * pr));
    quadMat.uniforms.thickness.value = 2.2 * pr;
  }
  window.addEventListener("resize", resize);
  resize();

  function render() {
    const now = state.frozenTime !== null ? state.frozenTime : (performance.now() - state.t0) / 1000;
    for (const pet of pets) applyPose(pet, state.pose ? state.pose(now, api) : null);
    controls.update();
    // passe principale
    renderer.setRenderTarget(sceneTarget);
    renderer.render(scene, camera);
    // masque (pet seulement)
    const prevBg = scene.background, prevOverride = scene.overrideMaterial;
    scene.background = new THREE.Color(0x000000);
    scene.overrideMaterial = maskMaterial;
    const hidden = [];
    scene.traverse((o) => { if ((o === ground || o.material?.map) && o.visible) { hidden.push(o); o.visible = false; } });
    renderer.setRenderTarget(maskTarget);
    renderer.render(scene, camera);
    hidden.forEach((o) => (o.visible = true));
    scene.background = prevBg;
    scene.overrideMaterial = prevOverride;
    // composition
    renderer.setRenderTarget(null);
    quadMat.uniforms.tScene.value = sceneTarget.texture;
    quadMat.uniforms.tMask.value = maskTarget.texture;
    quadMat.uniforms.enabled.value = state.outline ? 1 : 0;
    renderer.render(quadScene, quadCam);
  }

  let running = true;
  function loop() {
    if (!running) return;
    render();
    requestAnimationFrame(loop);
  }

  const api = {
    THREE, angles, cfn, renderer, scene, camera, controls,
    setVariant(v) { state.variant = v; clearPets(); buildPet(v); },
    // ex. setLineup([{ key: "Shiba/Normal", x: 2.6, scale: 2 }, { key: "Dog/Normal", x: -3.9 }])
    setLineup(list) { clearPets(); for (const it of list) buildPet(it.key, it.x || 0, it.scale || 1); },
    // position écran (pixels CSS) d'un point du monde
    project(p) {
      const v = new THREE.Vector3(...p).project(camera);
      return [(v.x + 1) / 2 * container.clientWidth, (1 - v.y) / 2 * container.clientHeight];
    },
    setOutline(on) { state.outline = on; },
    setPose(fn) { state.pose = fn; },
    freeze(t) { state.frozenTime = t; },
    setView(pos, target) {
      camera.position.set(...pos);
      controls.target.set(...(target || [0, 1.45, 0]));
      controls.update();
    },
    setFov(f) { camera.fov = f; camera.updateProjectionMatrix(); },
    render,
    stop() { running = false; },
    start() { if (!running) { running = true; loop(); } },
  };

  if (opts.lineup) api.setLineup(opts.lineup);
  else buildPet(state.variant);
  if (opts.autoLoop !== false) loop();
  return api;
}
