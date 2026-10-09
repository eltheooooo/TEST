--!nonstrict
--[[
	CubePetBuilder
	==============
	Construit les pets cubiques (style Pet Simulator) uniquement avec des
	primitives Roblox + une SurfaceGui pour le visage : aucun asset à uploader,
	aucun MeshId, les modèles marchent tels quels dans n'importe quel jeu.

	Espèces : "Shiba" (Cube Shiba), "Dog" (Cube Dog), "Cat" (Cube Cat). Même corps, mêmes
	proportions ; seuls les oreilles, la queue, le visage et les couleurs changent.

	Ce module est la *source* des fichiers .rbxmx fournis. Il tourne :
	  • dans Lune (export des fichiers, voir tools/build.luau)
	        Builder.build({ species = "Dog", variant = "Golden" }, require("@lune/roblox"))
	  • dans Roblox Studio (ModuleScript), pour régénérer / créer tes variantes :
	        require(path.to.CubePetBuilder).build({ species = "Dog" }).Parent = workspace

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

Builder.Version = "1.2.0"

-- ─────────────────────────────────────────────────────────────────────────────
-- Corps commun (studs) — identique pour toutes les espèces
-- ─────────────────────────────────────────────────────────────────────────────
local W, H, D = 2.4, 2.0, 2.0 -- corps : largeur, hauteur, profondeur
local R = 0.15 -- rayon des arêtes arrondies du corps
local LEG_H = 0.45 -- hauteur visible des pattes
local LEG_EMBED = 0.15 -- partie des pattes cachée dans le corps (pour les rotations)
local LEG_W, LEG_D = 0.62, 0.46
local LEG_X, LEG_Z = 0.65, 0.54
local LIP = 0.01 -- débord minuscule anti z-fighting des taches crème des flancs
local PX = 200 -- pixels par stud du canvas du visage

Builder.Dimensions = {
	BodySize = { W, H, D },
	LegHeight = LEG_H,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Espèces
--   Couleurs (RGB 0-255) : Primary = pelage, Secondary = crème, Accent = oreilles
--   tombantes. Coordonnées du visage en studs, origine au centre de la face
--   avant, x vers la droite de l'écran, y vers le haut.
-- ─────────────────────────────────────────────────────────────────────────────
local SPECIES = {
	Shiba = {
		ModelName = "CubeShiba",
		PetName = "Cube Shiba",
		SplitY = 0.045, -- frontière pelage / crème sur l'avant (depuis le centre du corps)
		BellyTint = "Secondary",
		Patch = { Depth = 0.57, Radius = 0.3 }, -- tache crème bas-avant des flancs
		Ears = {
			Type = "Pointy",
			Base = 0.8,
			Height = 0.75,
			Thickness = 0.32,
			X = 0.7,
			Z = -0.12,
			Embed = 0.08,
			OutTilt = 6,
			BackTilt = 8,
			Inner = { Base = 0.56, Height = 0.56, Thickness = 0.06, Y = 0.06 },
		},
		-- Queue : spirale de sphères enroulée derrière le corps, vers le haut
		Tail = {
			Center = { 0, 0.3, 1.3 },
			Out = { 0, 0, 1 },
			Radius = 0.3,
			From = -125,
			To = 110,
			Count = 24,
			Thickness = { 0.21, 0.33, 0.13 }, -- rayon base / milieu / pointe
			TipStart = 0.8,
			Lining = true, -- doublure crème à l'intérieur de la boucle
		},
		Face = {
			Muzzle = { Shape = "Circle", R = 0.32, Y = -0.08 },
			Brows = { X = 0.47, Y = 0.57, W = 0.25, H = 0.13, Tilt = 8 },
			Eyes = { X = 0.63, Y = 0.12, Sclera = 0.56, Pupil = 0.4, Inward = 0.06, Down = 0.03 },
			Nose = { Y = -0.035 },
			Mouth = { Y = -0.13, R = 0.13 },
			Cheeks = { X = 0.86, Y = -0.27, W = 0.29, H = 0.23 },
		},
		Palettes = {
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
				Reflectance = 0.15,
			},
		},
	},

	Dog = {
		ModelName = "CubeDog",
		PetName = "Cube Dog",
		SplitY = -0.3,
		BellyTint = "Primary",
		Patch = { Depth = 0.5, Radius = 0.25 },
		-- Oreilles tombantes : un rabat posé sur le dessus de la tête + un pan qui
		-- pend en biais. Le pli est en diagonale sur le coin de la tête, pour que
		-- l'oreille se voie de face comme de profil.
		Ears = {
			Type = "Floppy",
			Back = { 0.8, 0.5 }, -- extrémité arrière du pli (x, z depuis le centre du corps)
			Yaw = 22, -- rotation du pli : l'avant de l'oreille part vers l'extérieur (degrés)
			FoldY = 1.0, -- hauteur du pli (dessus de la tête)
			Depth = 1.02, -- longueur du pli (largeur de l'oreille)
			Thickness = 0.2,
			TopWidth = 0.38, -- largeur du rabat posé sur la tête
			Length = 1.05, -- longueur du pan qui pend
			Angle = 34, -- écartement du pan par rapport à la verticale (degrés)
		},
		-- Liste blanche du front qui continue sur le dessus de la tête
		TopStripe = { Length = 0.75 },
		-- Queue relevée en croissant, pointe blanche
		Tail = {
			Center = { -0.42, 0.1, 1.36 },
			Out = { -0.55, 0, 0.84 },
			Radius = 0.4,
			From = -150,
			To = 30,
			Count = 20,
			Thickness = { 0.2, 0.27, 0.19 },
			TipStart = 0.72,
			Lining = false,
		},
		Face = {
			Blaze = { W = 0.44 }, -- liste blanche du front
			Muzzle = { Shape = "Pill", W = 1.0, H = 0.62, Y = -0.2 },
			Eyes = { X = 0.66, Y = -0.03, Sclera = 0.68, Pupil = 0.44, Inward = 0.03, Down = 0 },
			Nose = { Y = -0.17 },
			Mouth = { Y = -0.32, R = 0.14 },
			Cheeks = { X = 0.86, Y = -0.44, W = 0.28, H = 0.22 },
		},
		Palettes = {
			Normal = {
				Primary = { 244, 172, 100 },
				Secondary = { 255, 240, 226 },
				Accent = { 176, 100, 64 },
				Cheek = { 248, 184, 168 },
				Eye = { 64, 31, 27 },
				Sclera = { 255, 255, 255 },
				Shine = { 255, 255, 255 },
				Outline = { 56, 30, 22 },
				Reflectance = 0,
			},
			Golden = {
				Primary = { 255, 193, 48 },
				Secondary = { 255, 236, 150 },
				Accent = { 214, 138, 22 },
				Cheek = { 255, 160, 92 },
				Eye = { 96, 54, 12 },
				Sclera = { 255, 255, 255 },
				Shine = { 255, 255, 255 },
				Outline = { 122, 74, 8 },
				Reflectance = 0.15,
			},
		},
	},

	Cat = {
		ModelName = "CubeCat",
		PetName = "Cube Cat",
		SplitY = -0.1, -- dessus gris, dessous blanc
		BellyTint = "Secondary",
		-- Bande blanche tout autour du bas du corps, limite ondulée (petites bosses)
		LowerBand = {
			SideBumps = { { -0.55, 0.17 }, { 0.0, 0.2 }, { 0.5, 0.16 } }, -- { z, rayon }
			BackBumps = { { -0.5, 0.16 }, { 0.35, 0.19 } }, -- { x, rayon }
		},
		Ears = {
			Type = "Pointy",
			Base = 0.8,
			Height = 0.8,
			Thickness = 0.3,
			X = 0.72,
			Z = -0.1,
			Embed = 0.08,
			OutTilt = 5,
			BackTilt = 6,
			Inner = { Base = 0.56, Height = 0.6, Thickness = 0.06, Y = 0.06 },
		},
		-- Longue queue dressée vers le haut et l'arrière (courbe de Bézier), pointe blanche
		Tail = {
			Path = { { -0.45, -0.15, 0.9 }, { -0.5, 0.85, 1.5 }, { -0.5, 1.72, 1.86 } },
			Count = 10,
			Smooth = true, -- tube lisse : boules + cylindres entre elles
			Thickness = { 0.19, 0.2, 0.19 },
			TipStart = 0.78,
			Lining = false,
		},
		Face = {
			Base = "Secondary", -- face blanche...
			Patches = { -- ...avec deux taches grises en haut (cercles coupés par le bord)
				{ X = -1.15, Y = 0.95, R = 1.0 },
				{ X = 1.2, Y = 0.75, R = 1.12 },
			},
			Eyes = { X = 0.58, Y = 0.02, Sclera = 0.66, Pupil = 0.42, Inward = 0.02, Down = 0 },
			Nose = { Y = -0.17, Scale = 0.72, Color = "Nose" },
			Mouth = { Y = -0.27, R = 0.115 },
			Cheeks = { X = 0.84, Y = -0.36, W = 0.3, H = 0.24 },
			Whiskers = { -- { x0, y0, x1, y1 } côté droit de l'écran, recopiés en miroir
				{ 0.7, -0.33, 0.98, -0.28 },
				{ 0.7, -0.44, 0.98, -0.49 },
			},
		},
		Palettes = {
			Normal = {
				Primary = { 152, 150, 178 },
				Secondary = { 246, 245, 249 },
				EarInner = { 248, 184, 226 },
				Cheek = { 251, 206, 224 },
				Eye = { 32, 30, 46 },
				Nose = { 238, 168, 212 },
				Sclera = { 255, 255, 255 },
				Shine = { 255, 255, 255 },
				Outline = { 40, 36, 58 },
				Reflectance = 0,
			},
			Golden = {
				Primary = { 255, 193, 48 },
				Secondary = { 255, 236, 150 },
				EarInner = { 255, 212, 104 },
				Cheek = { 255, 160, 92 },
				Eye = { 96, 54, 12 },
				Nose = { 232, 120, 60 },
				Sclera = { 255, 255, 255 },
				Shine = { 255, 255, 255 },
				Outline = { 122, 74, 8 },
				Reflectance = 0.15,
			},
		},
	},
}
Builder.Species = SPECIES

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
	  species   "Shiba" | "Dog" | "Cat"             (défaut "Shiba")
	  variant   "Normal" | "Golden"                 (défaut "Normal")
	  name      nom du Model                        (défaut "CubeShiba", "CubeDog_Golden"...)
	  outline   contour cartoon (Highlight)         (défaut true)
	rbx : table des types Roblox (Lune). Laisser nil dans Studio.
]]
function Builder.build(options, rbx)
	options = options or {}
	local env = rbx or getGlobals()
	local Instance, Vector3, Vector2, CFrame, Color3 = env.Instance, env.Vector3, env.Vector2, env.CFrame, env.Color3
	local UDim, UDim2, Enum = env.UDim, env.UDim2, env.Enum

	local speciesName = options.species or "Shiba"
	local spec = SPECIES[speciesName]
	assert(spec, "Espèce inconnue : " .. tostring(speciesName))
	local variant = options.variant or "Normal"
	local pal = spec.Palettes[variant]
	assert(pal, "Variante inconnue : " .. tostring(variant))

	local function rgb(t)
		return Color3.fromRGB(t[1], t[2], t[3])
	end
	local V3 = Vector3.new
	local CF = CFrame.new
	local rad = math.rad

	local material = Enum.Material.SmoothPlastic
	local SPLIT_Y = spec.SplitY

	local model = Instance.new("Model")
	model.Name = options.name or (variant == "Normal" and spec.ModelName or (spec.ModelName .. "_" .. variant))

	local BODY_CENTER = CF(0, LEG_H + H / 2, 0)

	-- ── Helpers ───────────────────────────────────────────────────────────────
	local function folder(name, parent)
		local f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
		return f
	end

	-- Applique une couleur de la palette et note sa teinte logique dans l'attribut
	-- « Tint » (pratique pour recolorer le pet par script).
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

	-- Cylindres : axe X par défaut
	local AY = CFrame.Angles(0, 0, math.pi / 2)
	local AZ = CFrame.Angles(0, math.pi / 2, 0)

	-- Repère centré en pos dont l'axe X suit dir (pour orienter un cylindre).
	-- Matrice construite à la main (repère direct, X × Y = Z).
	local function alongX(pos, dir)
		local x = dir.Unit
		local up = if math.abs(x.Y) < 0.99 then V3(0, 1, 0) else V3(1, 0, 0)
		local z = x:Cross(up).Unit
		local y = z:Cross(x).Unit
		return CF(pos.X, pos.Y, pos.Z, x.X, y.X, z.X, x.Y, y.Y, z.Y, x.Z, y.Z, z.Z)
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

	-- Noyau : 3 dalles qui se croisent. La face avant de CoreFront porte la
	-- SurfaceGui « Face » qui peint tout le devant : aucun écart d'éclairage.
	bodyPiece("CoreSides", "Block", V3(W, H - 2 * R, D - 2 * R), CF(), "Primary")
	bodyPiece("CoreTop", "Block", V3(W - 2 * R, H / 2, D - 2 * R), CF(0, H / 4, 0), "Primary")
	bodyPiece("CoreBelly", "Block", V3(W - 2 * R, H / 2, D - 2 * R), CF(0, -H / 4, 0), spec.BellyTint)
	local coreFront = bodyPiece("CoreFront", "Block", V3(W - 2 * R, H - 2 * R, D), CF(), "Primary")

	local function edge(name, length, x, y, z, rot, tintName)
		return bodyPiece(name, "Cylinder", V3(length, 2 * R, 2 * R), CF(x, y, z) * rot, tintName)
	end
	local function corner(name, x, y, z, tintName)
		return bodyPiece(name, "Ball", V3(2 * R, 2 * R, 2 * R), CF(x, y, z), tintName)
	end

	if spec.TopStripe then
		-- arête avant-haut en 3 morceaux : la liste blanche passe par-dessus
		local bw = spec.Face.Blaze.W
		local sideLen = (W - 2 * R - bw) / 2
		edge("EdgeTopFrontL", sideLen, -(bw / 2 + sideLen / 2), hy, -hz, CF(), "Primary")
		edge("EdgeTopFrontStripe", bw, 0, hy, -hz, CF(), "Secondary")
		edge("EdgeTopFrontR", sideLen, bw / 2 + sideLen / 2, hy, -hz, CF(), "Primary")
		local len = spec.TopStripe.Length
		bodyPiece("TopStripe", "Block", V3(bw, 0.02, len), CF(0, H / 2 - 0.01 + LIP, -hz + len / 2), "Secondary")
		bodyPiece("TopStripeEnd", "Cylinder", V3(0.02, bw, bw), CF(0, H / 2 - 0.01 + LIP, -hz + len) * AY, "Secondary")
	else
		edge("EdgeTopFront", W - 2 * R, 0, hy, -hz, CF(), "Primary")
	end
	edge("EdgeTopBack", W - 2 * R, 0, hy, hz, CF(), "Primary")
	edge("EdgeBottomFront", W - 2 * R, 0, -hy, -hz, CF(), "Secondary")
	local band = spec.LowerBand -- bas du corps entièrement clair (chat)
	edge("EdgeBottomBack", W - 2 * R, 0, -hy, hz, CF(), band and "Secondary" or "Primary")

	local pw = W + 2 * LIP
	if band then
		for _, sx in { -1, 1 } do
			local s = sx < 0 and "L" or "R"
			local x = sx * hx
			edge("EdgeFront" .. s .. "Lower", lowerH, x, SPLIT_Y - lowerH / 2, -hz, AY, "Secondary")
			edge("EdgeFront" .. s .. "Upper", upperH, x, SPLIT_Y + upperH / 2, -hz, AY, "Primary")
			edge("EdgeBack" .. s .. "Lower", lowerH, x, SPLIT_Y - lowerH / 2, hz, AY, "Secondary")
			edge("EdgeBack" .. s .. "Upper", upperH, x, SPLIT_Y + upperH / 2, hz, AY, "Primary")
			edge("EdgeTop" .. s, D - 2 * R, x, hy, 0, AZ, "Primary")
			edge("EdgeBottom" .. s, D - 2 * R, x, -hy, 0, AZ, "Secondary")

			corner("Corner" .. s .. "TopFront", x, hy, -hz, "Primary")
			corner("Corner" .. s .. "TopBack", x, hy, hz, "Primary")
			corner("Corner" .. s .. "BottomFront", x, -hy, -hz, "Secondary")
			corner("Corner" .. s .. "BottomBack", x, -hy, hz, "Secondary")
		end
		-- bande claire sur les flancs et le dos, limite ondulée
		bodyPiece("SideBand", "Block", V3(pw, lowerH, D - 2 * R), CF(0, SPLIT_Y - lowerH / 2, 0), "Secondary")
		bodyPiece("BackBand", "Block", V3(W - 2 * R, lowerH, 0.02), CF(0, SPLIT_Y - lowerH / 2, D / 2 + LIP - 0.01), "Secondary")
		for i, b in band.SideBumps do
			bodyPiece("SideWave" .. i, "Cylinder", V3(pw, 2 * b[2], 2 * b[2]), CF(0, SPLIT_Y, b[1]), "Secondary")
		end
		for i, b in band.BackBumps do
			bodyPiece("BackWave" .. i, "Cylinder", V3(0.02, 2 * b[2], 2 * b[2]), CF(b[1], SPLIT_Y, D / 2 + LIP - 0.01) * AZ, "Secondary")
		end
	else
		local patchDepth, rc = spec.Patch.Depth, spec.Patch.Radius
		local zPatch = -hz + patchDepth
		for _, sx in { -1, 1 } do
			local s = sx < 0 and "L" or "R"
			local x = sx * hx
			edge("EdgeFront" .. s .. "Lower", lowerH, x, SPLIT_Y - lowerH / 2, -hz, AY, "Secondary")
			edge("EdgeFront" .. s .. "Upper", upperH, x, SPLIT_Y + upperH / 2, -hz, AY, "Primary")
			edge("EdgeBack" .. s, H - 2 * R, x, 0, hz, AY, "Primary")
			edge("EdgeTop" .. s, D - 2 * R, x, hy, 0, AZ, "Primary")
			edge("EdgeBottom" .. s .. "Front", patchDepth, x, -hy, -hz + patchDepth / 2, AZ, "Secondary")
			local backLen = hz - zPatch
			edge("EdgeBottom" .. s .. "Back", backLen, x, -hy, zPatch + backLen / 2, AZ, "Primary")

			corner("Corner" .. s .. "TopFront", x, hy, -hz, "Primary")
			corner("Corner" .. s .. "TopBack", x, hy, hz, "Primary")
			corner("Corner" .. s .. "BottomFront", x, -hy, -hz, "Secondary")
			corner("Corner" .. s .. "BottomBack", x, -hy, hz, "Primary")
		end

		-- Taches crème des flancs (bas-avant, coin haut-arrière arrondi)
		bodyPiece("SidePatchFront", "Block", V3(pw, lowerH, patchDepth - rc), CF(0, SPLIT_Y - lowerH / 2, -hz + (patchDepth - rc) / 2), "Secondary")
		bodyPiece("SidePatchBack", "Block", V3(pw, lowerH - rc, rc), CF(0, -hy + (lowerH - rc) / 2, zPatch - rc / 2), "Secondary")
		bodyPiece("SidePatchRound", "Cylinder", V3(pw, 2 * rc, 2 * rc), CF(0, SPLIT_Y - rc, zPatch - rc), "Secondary")
	end

	-- ── Oreilles ─────────────────────────────────────────────────────────────
	local ears = spec.Ears
	for _, sx in { -1, 1 } do
		local s = sx < 0 and "L" or "R"
		local earFolder = folder("Ear" .. s, visual)

		if ears.Type == "Pointy" then
			-- Prisme triangulaire (2 WedgeParts) + intérieur rose
			local base = BODY_CENTER
				* CF(sx * ears.X, H / 2 - ears.Embed, ears.Z)
				* CFrame.Angles(rad(ears.BackTilt), 0, -sx * rad(ears.OutTilt))
			local earBone = makeBone("Ear" .. s, V3(0.2, 0.2, 0.2), base)
			motor("Ear" .. s, body, earBone, base)
			local function earPiece(name, size, localCF, tintName)
				local p = makePart("WedgePart", name, size, base * localCF, tintName, earFolder)
				weld(earBone, p)
				return p
			end
			-- Un WedgePart a sa pente vers l'avant (-Z) : tourné de ±90° autour de Y,
			-- son côté vertical se retrouve sur l'axe de l'oreille.
			local b, h, t = ears.Base, ears.Height, ears.Thickness
			earPiece("OuterL", V3(t, h, b / 2), CF(-b / 4, h / 2, 0) * CFrame.Angles(0, math.pi / 2, 0), "Primary")
			earPiece("OuterR", V3(t, h, b / 2), CF(b / 4, h / 2, 0) * CFrame.Angles(0, -math.pi / 2, 0), "Primary")
			local inner = ears.Inner
			local iz = -t / 2 - 0.015 + inner.Thickness / 2
			earPiece("InnerL", V3(inner.Thickness, inner.Height, inner.Base / 2), CF(-inner.Base / 4, inner.Y + inner.Height / 2, iz) * CFrame.Angles(0, math.pi / 2, 0), "EarInner")
			earPiece("InnerR", V3(inner.Thickness, inner.Height, inner.Base / 2), CF(inner.Base / 4, inner.Y + inner.Height / 2, iz) * CFrame.Angles(0, -math.pi / 2, 0), "EarInner")
		elseif ears.Type == "Floppy" then
			-- Repère du pli : origine au milieu du pli, axe Z le long du pli (avant = -Z)
			local t, depth = ears.Thickness, ears.Depth
			local fold = BODY_CENTER
				* CF(sx * ears.Back[1], ears.FoldY, ears.Back[2])
				* CFrame.Angles(0, -sx * rad(ears.Yaw), 0)
				* CF(0, 0, -depth / 2)
			local earBone = makeBone("Ear" .. s, V3(0.2, 0.2, 0.2), fold)
			motor("Ear" .. s, body, earBone, fold)
			local function earPiece(name, shape, size, cf)
				local p = makePart("Part", name, size, cf, "Accent", earFolder, shape)
				weld(earBone, p)
				return p
			end
			local tw = ears.TopWidth
			-- rabat posé sur la tête, bords arrondis par des cylindres
			earPiece("Top", "Block", V3(tw, t, depth), fold * CF(-sx * tw / 2, 0, 0))
			earPiece("TopEdge", "Cylinder", V3(depth, t, t), fold * CF(-sx * tw, 0, 0) * AZ)
			earPiece("Fold", "Cylinder", V3(depth, t, t), fold * AZ)
			-- pan qui pend vers l'extérieur
			local hang = fold * CFrame.Angles(0, 0, sx * rad(ears.Angle))
			earPiece("Flap", "Block", V3(t, ears.Length, depth), hang * CF(0, -ears.Length / 2, 0))
			earPiece("FlapEdge", "Cylinder", V3(depth, t, t), hang * CF(0, -ears.Length, 0) * AZ)
		end
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

	-- ── Queue ────────────────────────────────────────────────────────────────
	do
		local tail = spec.Tail
		local at, c
		if tail.Path then
			-- courbe de Bézier quadratique (queue dressée)
			local P0, P1, P2 = V3(table.unpack(tail.Path[1])), V3(table.unpack(tail.Path[2])), V3(table.unpack(tail.Path[3]))
			at = function(t)
				return P0 * ((1 - t) ^ 2) + P1 * (2 * (1 - t) * t) + P2 * (t ^ 2)
			end
		else
			-- arc de cercle (queue enroulée)
			c = V3(tail.Center[1], tail.Center[2], tail.Center[3])
			local eOut = V3(tail.Out[1], tail.Out[2], tail.Out[3]).Unit
			local eUp = V3(0, 1, 0)
			at = function(t)
				local th = rad(tail.From + (tail.To - tail.From) * t)
				return c + (eOut * math.cos(th) + eUp * math.sin(th)) * tail.Radius
			end
		end
		local r0, r1, r2 = tail.Thickness[1], tail.Thickness[2], tail.Thickness[3]
		local function radiusAt(t)
			-- base fine, milieu touffu, pointe effilée
			if t < 0.4 then
				return r0 + (r1 - r0) * math.sin(t / 0.4 * math.pi / 2)
			end
			local u = (t - 0.4) / 0.6
			return r1 - (r1 - r2) * u * u
		end

		local rootPos = BODY_CENTER * at(0)
		local tailBone = makeBone("Tail", V3(0.2, 0.2, 0.2), CF(rootPos))
		motor("Tail", body, tailBone, CF(rootPos))
		local tailFolder = folder("Tail", visual)

		local prevP, prevR
		for i = 1, tail.Count do
			local t = (i - 1) / (tail.Count - 1)
			local p = at(t)
			local r = radiusAt(t)
			local isTip = t >= tail.TipStart
			local ball = makePart("Part", string.format("Fur%02d", i), V3(2 * r, 2 * r, 2 * r), BODY_CENTER * CF(p), isTip and "Secondary" or "Primary", tailFolder, "Ball")
			weld(tailBone, ball)
			if tail.Smooth and prevP then
				-- cylindre entre deux boules : axe X aligné sur le segment
				local mid = (prevP + p) / 2
				local seg = makePart("Part", string.format("Seg%02d", i - 1), V3((p - prevP).Magnitude, 2 * math.min(r, prevR), 2 * math.min(r, prevR)), BODY_CENTER * alongX(mid, p - prevP), (t - 0.5 / (tail.Count - 1)) >= tail.TipStart and "Secondary" or "Primary", tailFolder, "Cylinder")
				weld(tailBone, seg)
			end
			prevP, prevR = p, r
			-- Doublure crème à l'intérieur de la boucle (une sphère sur deux suffit)
			if tail.Lining and c and t > 0.22 and not isTip and i % 2 == 0 then
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

	local F = spec.Face
	local STROKE = 0.045 -- épaisseur des traits (bouche)
	local canvas = shape(gui, canvasSpace, "Canvas", 0, 0, FW, FH, nil, 1, { clip = true })

	-- Fond : pelage, masque crème du bas, museau (liste blanche du chien, taches du chat)
	local background = shape(canvas, canvasSpace, "Background", 0, 0, FW, FH, nil, 1)
	local base = F.Base or "Primary"
	tint(shape(background, canvasSpace, "Fur", 0, 0, FW, FH, C[base], 1), base)
	if base == "Primary" then
		local maskH = SPLIT_Y + FH / 2
		tint(shape(background, canvasSpace, "Mask", 0, SPLIT_Y - maskH / 2, FW, maskH, C.Secondary, 2), "Secondary")
	end
	for i, pt in F.Patches or {} do
		tint(shape(background, canvasSpace, "Patch" .. i, pt.X, pt.Y, 2 * pt.R, 2 * pt.R, C.Primary, 2, { round = true }), "Primary")
	end
	local m = F.Muzzle
	if m and m.Shape == "Circle" then
		tint(shape(background, canvasSpace, "Muzzle", 0, m.Y, 2 * m.R, 2 * m.R, C.Secondary, 3, { round = true }), "Secondary")
	elseif m then
		tint(shape(background, canvasSpace, "Muzzle", 0, m.Y, m.W, m.H, C.Secondary, 3, { round = true }), "Secondary")
	end
	if F.Blaze then
		local top = FH / 2
		local bottom = m.Y
		tint(shape(background, canvasSpace, "Blaze", 0, (top + bottom) / 2, F.Blaze.W, top - bottom, C.Secondary, 3), "Secondary")
	end

	-- Joues
	local ch = F.Cheeks
	local cheeks = shape(canvas, canvasSpace, "Cheeks", 0, 0, FW, FH, nil, 2)
	for _, sx in { -1, 1 } do
		shape(cheeks, canvasSpace, sx < 0 and "CheekR" or "CheekL", sx * ch.X, ch.Y, ch.W, ch.H, C.Cheek, 1, { round = true })
	end

	-- Moustaches (chat)
	if F.Whiskers then
		local whiskers = shape(canvas, canvasSpace, "Whiskers", 0, 0, FW, FH, nil, 4)
		for _, sx in { -1, 1 } do
			for i, wk in F.Whiskers do
				line(whiskers, canvasSpace, (sx < 0 and "R" or "L") .. i, sx * wk[1], wk[2], sx * wk[3], wk[4], 0.04, C.Eye, 1)
			end
		end
	end

	-- Sourcils (taches claires du shiba)
	if F.Brows then
		local b = F.Brows
		local brows = shape(canvas, canvasSpace, "Brows", 0, 0, FW, FH, nil, 3)
		for _, sx in { -1, 1 } do
			shape(brows, canvasSpace, sx < 0 and "BrowR" or "BrowL", sx * b.X, b.Y, b.W, b.H, rgb(pal.Brow), 1, { round = true, rotation = -sx * b.Tilt })
		end
	end

	-- Yeux : blanc + rond noir (sans reflet)
	local e = F.Eyes
	local eyes = shape(canvas, canvasSpace, "Eyes", 0, 0, FW, FH, nil, 3)
	for _, sx in { -1, 1 } do
		local eye, es = shape(eyes, canvasSpace, sx < 0 and "EyeR" or "EyeL", sx * e.X, e.Y, e.Sclera, e.Sclera, nil, 1)
		shape(eye, es, "Sclera", es.cx, es.cy, e.Sclera, e.Sclera, C.Sclera, 1, { round = true })
		shape(eye, es, "Pupil", es.cx - sx * e.Inward, es.cy - e.Down, e.Pupil, e.Pupil, C.Eye, 2, { round = true })
	end

	-- Bouche « ω » + philtrum
	local noseY = F.Nose.Y
	local ns_ = F.Nose.Scale or 1
	local noseColor = F.Nose.Color and rgb(pal[F.Nose.Color]) or C.Eye
	local mo = F.Mouth
	local mouth = shape(canvas, canvasSpace, "Mouth", 0, 0, FW, FH, nil, 4)
	line(mouth, canvasSpace, "Philtrum", 0, noseY - 0.08 * ns_, 0, mo.Y, STROKE, C.Eye, 1)
	arc(mouth, canvasSpace, "LipL", -mo.R, mo.Y, mo.R, 180, 360, STROKE, C.Eye, 1, 10)
	arc(mouth, canvasSpace, "LipR", mo.R, mo.Y, mo.R, 180, 360, STROKE, C.Eye, 1, 10)

	-- Truffe
	local nose, ns = shape(canvas, canvasSpace, "Nose", 0, noseY, 0.24 * ns_, 0.2 * ns_, nil, 5)
	shape(nose, ns, "Top", 0, noseY + 0.03 * ns_, 0.22 * ns_, 0.1 * ns_, noseColor, 1, { round = true })
	shape(nose, ns, "Tip", 0, noseY - 0.01 * ns_, 0.13 * ns_, 0.13 * ns_, noseColor, 1, { round = 4, rotation = 45 })
	shape(nose, ns, "Shine", -0.045 * ns_, noseY + 0.05 * ns_, 0.06 * ns_, 0.03 * ns_, C.Shine, 2, { round = true, transparency = 0.35 })

	-- ── Contour cartoon (comme les traits noirs des planches) ────────────────
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

	model:SetAttribute("PetName", spec.PetName)
	model:SetAttribute("Species", speciesName)
	model:SetAttribute("Variant", variant)
	model:SetAttribute("BuilderVersion", Builder.Version)

	return model
end

return Builder
