--!nonstrict
--[[
	EggStandBuilder
	===============
	Construit le socle d'un œuf (style Pet Simulator) uniquement avec des
	primitives Roblox : base ronde lavande, tige lumineuse, nom de
	l'œuf écrit au sol, et l'emplacement de l'œuf (EggSlot) avec ses trois
	ProximityPrompt (« Éclosion 1x » / « Éclosion 3x » / « MAXIMUM »).

	L'œuf lui-même est un mesh texturé (egg/OeufPrairie.glb) à importer dans Studio :
	le script client « EggFloat » du socle le place au-dessus de la tige et le fait
	flotter. Tant que le mesh n'est pas importé, un œuf provisoire (ellipsoïde
	crème) est affiché.

	Repère : sol à y = 0, centre du socle à l'origine, l'avant (côté du nom) vers -Z.

	    Builder.build({ eggId = "OeufPrairie", eggName = "Œuf de la Prairie" }, require("@lune/roblox"))
]]

local Builder = {}

Builder.Version = "1.1.0"

-- Dimensions (studs)
local EGG_W, EGG_H = 4.335, 5 -- taille de l'œuf (cf. tools/egg_generate.py)
local BASE_H = 0.5 -- hauteur de la base
local TOP_H = 0.08 -- couche claire du dessus
local BASE_D = 4.4 -- diamètre de la base
local POLE_D = 0.16
local POLE_H = 2.2
local EGG_Y = BASE_H + TOP_H + POLE_H + EGG_H / 2 -- centre de l'œuf

Builder.Dimensions = { EggSize = { EGG_W, EGG_H, EGG_W }, EggCenterY = EGG_Y }

local COLORS = {
	Base = { 168, 172, 232 },
	Top = { 190, 194, 248 },
	Socket = { 160, 164, 226 },
	Pole = { 255, 255, 255 },
	Placeholder = { 255, 244, 214 },
	Label = { 255, 255, 255 },
	LabelStroke = { 70, 74, 140 },
}

local function getGlobals()
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

function Builder.build(options, rbx)
	options = options or {}
	local env = rbx or getGlobals()
	local Instance, Vector3, Vector2, CFrame, Color3 = env.Instance, env.Vector3, env.Vector2, env.CFrame, env.Color3
	local UDim, UDim2, Enum = env.UDim, env.UDim2, env.Enum

	local eggId = options.eggId or "OeufPrairie"
	local eggName = options.eggName or "Œuf de la Prairie"

	local V3 = Vector3.new
	local CF = CFrame.new
	local function rgb(t)
		return Color3.fromRGB(t[1], t[2], t[3])
	end

	local model = Instance.new("Model")
	model.Name = eggId .. "_Socle"
	model:SetAttribute("EggId", eggId)
	model:SetAttribute("EggName", eggName)
	model:SetAttribute("BuilderVersion", Builder.Version)

	local function part(name, size, cf, color, props)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = rgb(color)
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		for k, v in props or {} do
			p[k] = v
		end
		p.Parent = model
		return p
	end

	-- Cylindre vertical (l'axe des cylindres Roblox est X)
	local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2)
	local function disc(name, d, h, x, y, z, color, props)
		local p = part(name, V3(h, d, d), CF(x, y, z) * UPRIGHT, color, props)
		p.Shape = Enum.PartType.Cylinder
		return p
	end

	-- ── Base ronde ────────────────────────────────────────────────────────────
	local base = disc("Base", BASE_D, BASE_H, 0, BASE_H / 2, 0, COLORS.Base, { CanCollide = true, CanQuery = true })
	disc("BaseTop", BASE_D - 0.3, TOP_H, 0, BASE_H + TOP_H / 2 - 0.001, 0, COLORS.Top)
	disc("Socket", 0.62, 0.05, 0, BASE_H + TOP_H + 0.02, 0, COLORS.Socket)

	-- ── Tige lumineuse ────────────────────────────────────────────────────────
	local poleY = BASE_H + TOP_H + POLE_H / 2
	disc("Pole", POLE_D, POLE_H + 0.3, 0, poleY + 0.1, 0, COLORS.Pole, { Material = Enum.Material.Neon, CastShadow = false })

	-- ── Emplacement de l'œuf (hitbox + prompts) ───────────────────────────────
	local slot = part("EggSlot", V3(EGG_W, EGG_H, EGG_W), CF(0, EGG_Y, 0), { 255, 255, 255 }, {
		Transparency = 1,
		CanQuery = true,
		CastShadow = false,
	})
	local prompts = {
		{ "Hatch1", "Éclosion 1x", Enum.KeyCode.E, 1 },
		{ "Hatch3", "Éclosion 3x", Enum.KeyCode.Q, 3 },
		{ "HatchMax", "MAXIMUM", Enum.KeyCode.R, 8 },
	}
	for _, pr in prompts do
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = pr[1]
		prompt.ActionText = pr[2]
		prompt.ObjectText = eggName
		prompt.KeyboardKeyCode = pr[3]
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Count", pr[4])
		prompt.Parent = slot
	end

	-- Œuf provisoire (remplacé automatiquement par le mesh importé)
	local placeholder = part("EggPlaceholder", V3(EGG_W, EGG_H, EGG_W), CF(0, EGG_Y, 0), COLORS.Placeholder, {
		CastShadow = true,
	})
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = placeholder

	-- ── Nom de l'œuf au sol, devant le socle ──────────────────────────────────
	-- Face avant tournée vers le haut : le texte se lit depuis l'avant (-Z).
	local label = part("NameLabel", V3(7, 1.5, 0.05), CF(0, 0.03, -3.25) * CFrame.Angles(math.pi / 2, 0, 0), { 255, 255, 255 }, {
		Transparency = 1,
		CastShadow = false,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Label"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(700, 150)
	gui.LightInfluence = 0
	gui.Brightness = 1.2
	gui.Parent = label
	local text = Instance.new("TextLabel")
	text.Name = "Name"
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.FredokaOne
	text.Text = eggName
	text.TextScaled = true
	text.TextColor3 = rgb(COLORS.Label)
	text.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = rgb(COLORS.LabelStroke)
	stroke.Thickness = 5
	stroke.Transparency = 0.25
	stroke.Parent = text
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.12, 0)
	pad.PaddingBottom = UDim.new(0.12, 0)
	pad.Parent = text

	model.PrimaryPart = base
	model.WorldPivot = CF(0, 0, 0)
	return model
end

return Builder
