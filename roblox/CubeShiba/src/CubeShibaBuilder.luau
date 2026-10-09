--!nonstrict
--[[
	CubeShibaBuilder
	================
	Construit le pet « Cube Shiba » (style Pet Simulator) uniquement avec des
	primitives Roblox + une SurfaceGui pour le visage : aucun asset à uploader,
	aucun MeshId, le modèle marche tel quel dans n'importe quel jeu.

	Ce module est la *source* des fichiers .rbxmx fournis. Il tourne :
	  • dans Lune (export des fichiers, voir tools/build.luau)
	        Builder.build({ variant = "Golden" }, require("@lune/roblox"))
	  • dans Roblox Studio (ModuleScript), pour régénérer / créer tes variantes :
	        require(path.to.CubeShibaBuilder).build({ variant = "Golden" }).Parent = workspace

	Repère du modèle
	  • Pivot (PrimaryPart.PivotOffset) = sol, sous le centre du corps.
	  • Le pet regarde vers -Z (LookVector) : model:PivotTo(CFrame.lookAt(pos, pos + dir)).
	  • L / R = gauche / droite DU PET (L = -X, R = +X).

	Rig (Motor6D, animable avec l'Animation Editor ou par script)
	  RootPart ─RootJoint─▶ Body ─┬─ EarL / EarR
	                              ├─ Tail
	                              └─ LegFL / LegFR / LegBL / LegBR
]]

local Builder = {}

Builder.Version = "1.1.0"

-- ─────────────────────────────────────────────────────────────────────────────
-- Dimensions (studs)
-- ─────────────────────────────────────────────────────────────────────────────
local W, H, D = 2.4, 2.0, 2.0 -- corps : largeur, hauteur, profondeur
local R = 0.15 -- rayon des arêtes arrondies du corps
local LEG_H = 0.45 -- hauteur visible des pattes
local LEG_EMBED = 0.15 -- partie des pattes cachée dans le corps (pour les rotations)
local LEG_W, LEG_D = 0.62, 0.46
local LEG_X, LEG_Z = 0.65, 0.54
local SPLIT_Y = 0.045 -- frontière orange / crème sur la face avant (depuis le centre du corps)
local PATCH_DEPTH = 0.57 -- profondeur de la tache crème sur les flancs
local PATCH_RADIUS = 0.3 -- arrondi du coin haut-arrière de cette tache
local MUZZLE_R, MUZZLE_Y = 0.32, -0.08 -- « bosse » crème du museau, entre les yeux
local LIP = 0.01 -- débord minuscule anti z-fighting des taches crème des flancs

local EAR_B, EAR_H, EAR_T = 0.8, 0.75, 0.32 -- oreille : base, hauteur, épaisseur
local EAR_X, EAR_Z = 0.7, -0.12
local EAR_EMBED = 0.08
local EAR_OUT_TILT, EAR_BACK_TILT = 6, 8 -- degrés
local INNER_B, INNER_H, INNER_T, INNER_Y = 0.56, 0.56, 0.06, 0.06

-- Queue : une spirale de sphères qui s'enroule derrière le flanc gauche.
local TAIL = {
	Center = { -1.36, 0.02, 1.0 }, -- centre de l'enroulement (repère du corps)
	Out = { -0.85, 0, 0.53 }, -- direction « vers l'extérieur » du plan de la queue
	Radius = 0.3,
	From = -125, -- angle de départ (degrés) : racine plantée dans le corps
	To = 110, -- angle de fin (pointe)
	Count = 24, -- sphères serrées => tube lisse
	TipStart = 0.8, -- au-delà de cette fraction, la pointe est crème
}

-- Visage (studs, origine au centre de la face avant, x vers la droite de l'écran, y vers le haut)
local FACE = {
	EyeX = 0.63,
	EyeY = 0.12,
	Sclera = 0.56, -- blanc de l'œil
	Pupil = 0.4, -- rond noir
	PupilInward = 0.06, -- pupilles légèrement tournées vers le museau
	PupilDown = 0.03,
	BrowX = 0.47,
	BrowY = 0.57,
	BrowW = 0.25,
	BrowH = 0.13,
	BrowTilt = 8, -- degrés, bout intérieur plus bas
	NoseY = -0.035,
	MouthY = -0.13,
	MouthR = 0.13, -- rayon de chaque arc du « ω »
	Stroke = 0.045, -- épaisseur des traits
	CheekX = 0.86,
	CheekY = -0.27,
	CheekW = 0.29,
	CheekH = 0.23,
}

local PX = 200 -- pixels par stud du canvas du visage

Builder.Dimensions = {
	BodySize = { W, H, D },
	LegHeight = LEG_H,
	TotalHeight = LEG_H + H + EAR_H - EAR_EMBED,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Palettes (RGB 0-255). Primary = orange, Secondary = crème.
-- ─────────────────────────────────────────────────────────────────────────────
local PALETTES = {
	Normal = {
		Primary = { 243, 161, 86 },
		Secondary = { 255, 239, 223 },
		EarInner = { 250, 186, 186 },
		Cheek = { 255, 176, 172 },
		Brow = { 255, 229, 196 },
		Eye = { 64, 35, 29 },
		Sclera = { 255, 255, 255 },
		Shine = { 255, 255, 255 },
		Outline = { 58, 34, 26 },
		Material = "SmoothPlastic",
		Reflectance = 0,
	},
	Golden = {
		Primary = { 255, 193, 48 },
		Secondary = { 255, 236, 150 },
		EarInner = { 255, 212, 104 },
		Cheek = { 255, 160, 92 },
		Brow = { 255, 241, 178 },
		Eye = { 96, 54, 12 },
		Sclera = { 255, 255, 255 },
		Shine = { 255, 255, 255 },
		Outline = { 122, 74, 8 },
		Material = "SmoothPlastic",
		Reflectance = 0.15,
	},
}
Builder.Palettes = PALETTES

local function getGlobals()
	-- Dans Studio, les types Roblox sont des globales.
	return {
		Instance = Instance,
		Vector3 = Vector3,
		Vector2 = Vector2,
		CFrame = CFrame,
		Color3 = Color3,
		UDim = UDim,
		UDim2 = UDim2,
		Enum = Enum,
	}
end

--[[
	options :
	  variant   "Normal" | "Golden"                (défaut "Normal")
	  name      nom du Model                        (défaut "CubeShiba[_Variant]")
	  outline   contour cartoon (Highlight)         (défaut true)
	rbx : table des types Roblox (Lune). Laisser nil dans Studio.
]]
function Builder.build(options, rbx)
	options = options or {}
	local env = rbx or getGlobals()
	local Instance, Vector3, Vector2, CFrame, Color3 = env.Instance, env.Vector3, env.Vector2, env.CFrame, env.Color3
	local UDim, UDim2, Enum = env.UDim, env.UDim2, env.Enum

	local variant = options.variant or "Normal"
	local pal = PALETTES[variant]
	assert(pal, "Variante inconnue : " .. tostring(variant))

	local function rgb(t)
		return Color3.fromRGB(t[1], t[2], t[3])
	end
	local V3 = Vector3.new
	local CF = CFrame.new
	local rad = math.rad

	local material = Enum.Material[pal.Material]

	local model = Instance.new("Model")
	model.Name = options.name or (variant == "Normal" and "CubeShiba" or ("CubeShiba_" .. variant))

	local BODY_CENTER = CF(0, LEG_H + H / 2, 0)

	-- ── Helpers ───────────────────────────────────────────────────────────────
	local function folder(name, parent)
		local f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
		return f
	end

	-- Applique une couleur de la palette et note sa teinte logique dans l'attribut
	-- « Tint » (pratique pour recolorer le pet par script : Primary / Secondary / EarInner).
	local function tint(inst, tintName)
		inst:SetAttribute("Tint", tintName)
		if inst:IsA("BasePart") then
			inst.Color = rgb(pal[tintName])
		else
			inst.BackgroundColor3 = rgb(pal[tintName])
		end
	end

	local function makePart(className, name, size, cf, tintName, parent, shape)
		local p = Instance.new(className)
		p.Name = name
		if shape then
			p.Shape = Enum.PartType[shape]
		end
		p.Size = size
		p.CFrame = cf
		p.Material = material
		p.Reflectance = pal.Reflectance
		p.Anchored = false
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.CastShadow = true
		p.Locked = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if tintName then
			tint(p, tintName)
		end
		p.Parent = parent
		return p
	end

	local function makeBone(name, size, cf)
		local p = makePart("Part", name, size, cf, nil, model, "Block")
		p.Transparency = 1
		p.CastShadow = false
		p.Color = Color3.fromRGB(255, 255, 255)
		return p
	end

	local function motor(name, part0, part1, pivotWorld)
		local m = Instance.new("Motor6D")
		m.Name = name
		m.Part0 = part0
		m.Part1 = part1
		m.C0 = part0.CFrame:ToObjectSpace(pivotWorld)
		m.C1 = part1.CFrame:ToObjectSpace(pivotWorld)
		m.Parent = part0
		return m
	end

	local function weld(bone, part)
		local w = Instance.new("Weld")
		w.Name = "Weld"
		w.Part0 = bone
		w.Part1 = part
		w.C0 = bone.CFrame:ToObjectSpace(part.CFrame)
		w.C1 = CF()
		w.Parent = part
		return w
	end

	-- ── Racine / hitbox ──────────────────────────────────────────────────────
	local rootH = LEG_H + H
	local root = makePart("Part", "RootPart", V3(W, rootH, D), CF(0, rootH / 2, 0), nil, model, "Block")
	root.Transparency = 1
	root.CastShadow = false
	root.Anchored = true
	root.Massless = false
	root.CanQuery = true -- clics / raycasts sur le pet (hitbox)
	root.Color = Color3.fromRGB(255, 255, 255)
	root.PivotOffset = CF(0, -rootH / 2, 0)
	model.PrimaryPart = root
	model.WorldPivot = CF(0, 0, 0)

	local body = makeBone("Body", V3(W, H, D), BODY_CENTER)
	motor("RootJoint", root, body, CF(0, LEG_H, 0))

	local visual = folder("Visual", model)

	-- ── Corps : cube aux arêtes arrondies, bicolore ──────────────────────────
	local bodyFolder = folder("Body", visual)
	local function bodyPiece(name, shape, size, offset, tintName)
		local p = makePart("Part", name, size, BODY_CENTER * offset, tintName, bodyFolder, shape)
		weld(body, p)
		return p
	end

	local hx, hy, hz = W / 2 - R, H / 2 - R, D / 2 - R
	local upperH = hy - SPLIT_Y
	local lowerH = SPLIT_Y + hy

	-- Noyau : 3 dalles qui se croisent (dessus orange, ventre crème).
	-- La face avant de CoreFront porte la SurfaceGui « Face » qui peint tout le
	-- devant (pelage, masque crème, museau, yeux...) : aucun écart d'éclairage.
	bodyPiece("CoreSides", "Block", V3(W, H - 2 * R, D - 2 * R), CF(), "Primary")
	bodyPiece("CoreTop", "Block", V3(W - 2 * R, H / 2, D - 2 * R), CF(0, H / 4, 0), "Primary")
	bodyPiece("CoreBelly", "Block", V3(W - 2 * R, H / 2, D - 2 * R), CF(0, -H / 4, 0), "Secondary")
	local coreFront = bodyPiece("CoreFront", "Block", V3(W - 2 * R, H - 2 * R, D), CF(), "Primary")

	-- Arêtes (cylindres, axe X par défaut) et coins (boules)
	local AX = CF()
	local AY = CFrame.Angles(0, 0, math.pi / 2)
	local AZ = CFrame.Angles(0, math.pi / 2, 0)
	local function edge(name, length, x, y, z, rot, tintName)
		return bodyPiece(name, "Cylinder", V3(length, 2 * R, 2 * R), CF(x, y, z) * rot, tintName)
	end
	local function corner(name, x, y, z, tintName)
		return bodyPiece(name, "Ball", V3(2 * R, 2 * R, 2 * R), CF(x, y, z), tintName)
	end

	edge("EdgeTopFront", W - 2 * R, 0, hy, -hz, AX, "Primary")
	edge("EdgeTopBack", W - 2 * R, 0, hy, hz, AX, "Primary")
	edge("EdgeBottomFront", W - 2 * R, 0, -hy, -hz, AX, "Secondary")
	edge("EdgeBottomBack", W - 2 * R, 0, -hy, hz, AX, "Primary")

	local zPatch = -hz + PATCH_DEPTH
	for _, sx in { -1, 1 } do
		local s = sx < 0 and "L" or "R"
		local x = sx * hx
		edge("EdgeFront" .. s .. "Lower", lowerH, x, SPLIT_Y - lowerH / 2, -hz, AY, "Secondary")
		edge("EdgeFront" .. s .. "Upper", upperH, x, SPLIT_Y + upperH / 2, -hz, AY, "Primary")
		edge("EdgeBack" .. s, H - 2 * R, x, 0, hz, AY, "Primary")
		edge("EdgeTop" .. s, D - 2 * R, x, hy, 0, AZ, "Primary")
		edge("EdgeBottom" .. s .. "Front", PATCH_DEPTH, x, -hy, -hz + PATCH_DEPTH / 2, AZ, "Secondary")
		local backLen = hz - zPatch
		edge("EdgeBottom" .. s .. "Back", backLen, x, -hy, zPatch + backLen / 2, AZ, "Primary")

		corner("Corner" .. s .. "TopFront", x, hy, -hz, "Primary")
		corner("Corner" .. s .. "TopBack", x, hy, hz, "Primary")
		corner("Corner" .. s .. "BottomFront", x, -hy, -hz, "Secondary")
		corner("Corner" .. s .. "BottomBack", x, -hy, hz, "Primary")
	end

	-- Taches crème des flancs (bas-avant, coin haut-arrière arrondi)
	local pw = W + 2 * LIP
	local rc = PATCH_RADIUS
	bodyPiece("SidePatchFront", "Block", V3(pw, lowerH, PATCH_DEPTH - rc), CF(0, SPLIT_Y - lowerH / 2, -hz + (PATCH_DEPTH - rc) / 2), "Secondary")
	bodyPiece("SidePatchBack", "Block", V3(pw, lowerH - rc, rc), CF(0, -hy + (lowerH - rc) / 2, zPatch - rc / 2), "Secondary")
	bodyPiece("SidePatchRound", "Cylinder", V3(pw, 2 * rc, 2 * rc), CF(0, SPLIT_Y - rc, zPatch - rc), "Secondary")

	-- ── Oreilles (prismes triangulaires, intérieur rose) ─────────────────────
	for _, sx in { -1, 1 } do
		local s = sx < 0 and "L" or "R"
		local base = BODY_CENTER
			* CF(sx * EAR_X, H / 2 - EAR_EMBED, EAR_Z)
			* CFrame.Angles(rad(EAR_BACK_TILT), 0, -sx * rad(EAR_OUT_TILT))
		local earBone = makeBone("Ear" .. s, V3(0.2, 0.2, 0.2), base)
		motor("Ear" .. s, body, earBone, base)
		local earFolder = folder("Ear" .. s, visual)
		local function earPiece(name, size, localCF, tintName)
			local p = makePart("WedgePart", name, size, base * localCF, tintName, earFolder)
			weld(earBone, p)
			return p
		end
		-- Un WedgePart a sa pente vers l'avant (-Z) : tourné de ±90° autour de Y,
		-- son côté vertical se retrouve sur l'axe de l'oreille.
		earPiece("OuterL", V3(EAR_T, EAR_H, EAR_B / 2), CF(-EAR_B / 4, EAR_H / 2, 0) * CFrame.Angles(0, math.pi / 2, 0), "Primary")
		earPiece("OuterR", V3(EAR_T, EAR_H, EAR_B / 2), CF(EAR_B / 4, EAR_H / 2, 0) * CFrame.Angles(0, -math.pi / 2, 0), "Primary")
		local iz = -EAR_T / 2 - 0.015 + INNER_T / 2
		earPiece("InnerL", V3(INNER_T, INNER_H, INNER_B / 2), CF(-INNER_B / 4, INNER_Y + INNER_H / 2, iz) * CFrame.Angles(0, math.pi / 2, 0), "EarInner")
		earPiece("InnerR", V3(INNER_T, INNER_H, INNER_B / 2), CF(INNER_B / 4, INNER_Y + INNER_H / 2, iz) * CFrame.Angles(0, -math.pi / 2, 0), "EarInner")
	end

	-- ── Pattes ───────────────────────────────────────────────────────────────
	for _, fz in { -1, 1 } do
		for _, sx in { -1, 1 } do
			local legName = "Leg" .. (fz < 0 and "F" or "B") .. (sx < 0 and "L" or "R")
			local legLen = LEG_H + LEG_EMBED
			local leg = makePart("Part", legName, V3(LEG_W, legLen, LEG_D), CF(sx * LEG_X, legLen / 2, fz * LEG_Z), "Secondary", model, "Block")
			motor(legName, body, leg, CF(sx * LEG_X, LEG_H, fz * LEG_Z))
		end
	end

	-- ── Queue enroulée ───────────────────────────────────────────────────────
	do
		local c = V3(TAIL.Center[1], TAIL.Center[2], TAIL.Center[3])
		local eOut = V3(TAIL.Out[1], TAIL.Out[2], TAIL.Out[3]).Unit
		local eUp = V3(0, 1, 0)
		local function at(t)
			local th = rad(TAIL.From + (TAIL.To - TAIL.From) * t)
			return c + (eOut * math.cos(th) + eUp * math.sin(th)) * TAIL.Radius
		end
		local function radiusAt(t)
			-- base fine, milieu touffu, pointe effilée
			if t < 0.4 then
				return 0.21 + (0.33 - 0.21) * math.sin(t / 0.4 * math.pi / 2)
			end
			local u = (t - 0.4) / 0.6
			return 0.33 - (0.33 - 0.13) * u * u
		end

		local rootPos = BODY_CENTER * at(0)
		local tailBone = makeBone("Tail", V3(0.2, 0.2, 0.2), CF(rootPos))
		motor("Tail", body, tailBone, CF(rootPos))
		local tailFolder = folder("Tail", visual)

		for i = 1, TAIL.Count do
			local t = (i - 1) / (TAIL.Count - 1)
			local p = at(t)
			local r = radiusAt(t)
			local isTip = t >= TAIL.TipStart
			local ball = makePart("Part", string.format("Fur%02d", i), V3(2 * r, 2 * r, 2 * r), BODY_CENTER * CF(p), isTip and "Secondary" or "Primary", tailFolder, "Ball")
			weld(tailBone, ball)
			-- Doublure crème à l'intérieur de la boucle (une sphère sur deux suffit)
			if t > 0.22 and not isTip and i % 2 == 0 then
				local inward = (c - p).Unit
				local lr = r * 0.72
				local lining = makePart("Part", string.format("Lining%02d", i), V3(2 * lr, 2 * lr, 2 * lr), BODY_CENTER * CF(p + inward * (r * 0.42)), "Secondary", tailFolder, "Ball")
				weld(tailBone, lining)
			end
		end
	end

	-- ── Visage (SurfaceGui vectorielle, aucune image) ────────────────────────
	local FW, FH = W - 2 * R, H - 2 * R

	local gui = Instance.new("SurfaceGui")
	gui.Name = "Face"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(math.floor(FW * PX + 0.5), math.floor(FH * PX + 0.5))
	gui.LightInfluence = 1
	gui.Brightness = 1
	gui.AlwaysOnTop = false
	gui.ClipsDescendants = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = coreFront

	local canvasSpace = { cx = 0, cy = 0, w = FW, h = FH }
	local C = {
		Eye = rgb(pal.Eye),
		Sclera = rgb(pal.Sclera),
		Shine = rgb(pal.Shine),
		Brow = rgb(pal.Brow),
		Cheek = rgb(pal.Cheek),
		Primary = rgb(pal.Primary),
		Secondary = rgb(pal.Secondary),
	}

	-- Crée un Frame centré en (x, y) de taille (w, h), coordonnées en studs dans `space`.
	-- opts : round (true = cercle / pilule, nombre = rayon en px), rotation (deg), clip, transparency
	local function shape(parent, space, name, x, y, w, h, color, z, opts)
		opts = opts or {}
		local f = Instance.new("Frame")
		f.Name = name
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale((x - space.cx) / space.w + 0.5, (space.cy - y) / space.h + 0.5)
		f.Size = UDim2.fromScale(w / space.w, h / space.h)
		f.BorderSizePixel = 0
		if color then
			f.BackgroundColor3 = color
			f.BackgroundTransparency = opts.transparency or 0
		else
			f.BackgroundTransparency = 1
		end
		f.ZIndex = z or 1
		if opts.rotation and opts.rotation ~= 0 then
			f.Rotation = opts.rotation
		end
		if opts.round then
			local c = Instance.new("UICorner")
			c.CornerRadius = if type(opts.round) == "number" then UDim.new(0, opts.round) else UDim.new(0.5, 0)
			c.Parent = f
		end
		if opts.clip then
			f.ClipsDescendants = true
		end
		f.Parent = parent
		return f, { cx = x, cy = y, w = w, h = h }
	end

	-- Segment épais à bouts ronds entre deux points.
	local function line(parent, space, name, x0, y0, x1, y1, thick, color, z)
		local len = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2) + thick
		local ang = math.deg(math.atan2(y1 - y0, x1 - x0))
		return shape(parent, space, name, (x0 + x1) / 2, (y0 + y1) / 2, len, thick, color, z, { round = true, rotation = -ang })
	end

	-- Arc de cercle épais (angles en degrés, 0 = droite, 90 = haut), construit avec
	-- des « pilules » qui se chevauchent : rendu lisse, bouts arrondis.
	local function arc(parent, space, name, cx, cy, r, a0, a1, thick, color, z, n)
		local g = folder(name, parent)
		for i = 1, n do
			local t0 = rad(a0 + (a1 - a0) * (i - 1) / n)
			local t1 = rad(a0 + (a1 - a0) * i / n)
			line(g, space, "Seg" .. i, cx + r * math.cos(t0), cy + r * math.sin(t0), cx + r * math.cos(t1), cy + r * math.sin(t1), thick, color, z)
		end
		return g
	end

	local F = FACE
	local canvas = shape(gui, canvasSpace, "Canvas", 0, 0, FW, FH, nil, 1, { clip = true })

	-- Fond : pelage orange, masque crème (bas du visage) et bosse du museau
	local background = shape(canvas, canvasSpace, "Background", 0, 0, FW, FH, nil, 1)
	tint(shape(background, canvasSpace, "Fur", 0, 0, FW, FH, C.Primary, 1), "Primary")
	local maskH = SPLIT_Y + FH / 2
	tint(shape(background, canvasSpace, "Mask", 0, SPLIT_Y - maskH / 2, FW, maskH, C.Secondary, 2), "Secondary")
	tint(shape(background, canvasSpace, "Muzzle", 0, MUZZLE_Y, 2 * MUZZLE_R, 2 * MUZZLE_R, C.Secondary, 3, { round = true }), "Secondary")

	-- Joues
	local cheeks = shape(canvas, canvasSpace, "Cheeks", 0, 0, FW, FH, nil, 2)
	for _, sx in { -1, 1 } do
		shape(cheeks, canvasSpace, sx < 0 and "CheekR" or "CheekL", sx * F.CheekX, F.CheekY, F.CheekW, F.CheekH, C.Cheek, 1, { round = true })
	end

	-- Sourcils (taches claires typiques du shiba)
	local brows = shape(canvas, canvasSpace, "Brows", 0, 0, FW, FH, nil, 3)
	for _, sx in { -1, 1 } do
		shape(brows, canvasSpace, sx < 0 and "BrowR" or "BrowL", sx * F.BrowX, F.BrowY, F.BrowW, F.BrowH, C.Brow, 1, { round = true, rotation = -sx * F.BrowTilt })
	end

	-- Yeux : blanc + rond noir (sans reflet)
	local eyes = shape(canvas, canvasSpace, "Eyes", 0, 0, FW, FH, nil, 3)
	for _, sx in { -1, 1 } do
		local eye, es = shape(eyes, canvasSpace, sx < 0 and "EyeR" or "EyeL", sx * F.EyeX, F.EyeY, F.Sclera, F.Sclera, nil, 1)
		shape(eye, es, "Sclera", es.cx, es.cy, F.Sclera, F.Sclera, C.Sclera, 1, { round = true })
		shape(eye, es, "Pupil", es.cx - sx * F.PupilInward, es.cy - F.PupilDown, F.Pupil, F.Pupil, C.Eye, 2, { round = true })
	end

	-- Bouche « ω » + philtrum
	local noseBottom = F.NoseY - 0.1
	local mouth = shape(canvas, canvasSpace, "Mouth", 0, 0, FW, FH, nil, 4)
	line(mouth, canvasSpace, "Philtrum", 0, noseBottom + 0.02, 0, F.MouthY, F.Stroke, C.Eye, 1)
	arc(mouth, canvasSpace, "LipL", -F.MouthR, F.MouthY, F.MouthR, 180, 360, F.Stroke, C.Eye, 1, 10)
	arc(mouth, canvasSpace, "LipR", F.MouthR, F.MouthY, F.MouthR, 180, 360, F.Stroke, C.Eye, 1, 10)

	-- Truffe
	local nose, ns = shape(canvas, canvasSpace, "Nose", 0, F.NoseY, 0.24, 0.2, nil, 5)
	shape(nose, ns, "Top", 0, F.NoseY + 0.03, 0.22, 0.1, C.Eye, 1, { round = true })
	shape(nose, ns, "Tip", 0, F.NoseY - 0.01, 0.13, 0.13, C.Eye, 1, { round = 4, rotation = 45 })
	shape(nose, ns, "Shine", -0.045, F.NoseY + 0.05, 0.06, 0.03, C.Shine, 2, { round = true, transparency = 0.35 })

	-- ── Contour cartoon (comme les traits noirs de la planche) ───────────────
	local outline = Instance.new("Highlight")
	outline.Name = "Outline"
	outline.FillTransparency = 1
	outline.OutlineColor = rgb(pal.Outline)
	outline.OutlineTransparency = 0
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Enabled = options.outline ~= false
	outline.Parent = model

	local animController = Instance.new("AnimationController")
	animController.Name = "AnimationController"
	animController.Parent = model
	local animator = Instance.new("Animator")
	animator.Parent = animController

	model:SetAttribute("PetName", "Cube Shiba")
	model:SetAttribute("Variant", variant)
	model:SetAttribute("BuilderVersion", Builder.Version)

	return model
end

return Builder
