--[[
	Génère les fichiers Roblox de l'« Œuf de la Prairie ».

	    lune run tools/build_egg.luau

	Sorties (dans egg/) :
	  OeufPrairie_Socle.rbxmx  socle (base, tige, nom au sol, EggSlot + prompts, script EggFloat)
	  EggOpening.rbxmx         ModuleScript de la cinématique d'ouverture (ReplicatedStorage)
	  EggHatchDemo.rbxmx       LocalScript de démo (StarterPlayerScripts)
	et tools/egg_stand.json pour le viewer web.

	Le mesh de l'œuf (egg/OeufPrairie.glb) est généré par tools/egg_generate.py.
]]
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local StandBuilder = require("../src/EggStandBuilder")

local Instance = roblox.Instance

local function script(className, name, sourceFile)
	local s = Instance.new(className)
	s.Name = name
	s.Source = fs.readFile(sourceFile)
	return s
end

local function write(file, instance)
	local xml = roblox.serializeModel({ instance }, true)
	local loaded = roblox.deserializeModel(xml)[1]
	assert(loaded and loaded.Name == instance.Name, "relecture impossible : " .. file)
	assert(#loaded:GetDescendants() == #instance:GetDescendants(), "relecture incomplète : " .. file)
	fs.writeFile(file, xml)
	print(string.format("%-28s %4d instances, %6.1f Ko", file, #instance:GetDescendants() + 1, #xml / 1024))
	return loaded
end

-- Socle
local stand = StandBuilder.build({ eggId = "OeufPrairie", eggName = "Œuf de la Prairie" }, roblox)
local float = script("Script", "EggFloat", "src/EggStand.client.luau")
float.RunContext = roblox.Enum.RunContext.Client
float.Parent = stand
local loaded = write("egg/OeufPrairie_Socle.rbxmx", stand)
assert(loaded:FindFirstChild("EggFloat").RunContext == roblox.Enum.RunContext.Client, "RunContext perdu")

-- Scripts
write("egg/EggOpening.rbxmx", script("ModuleScript", "EggOpening", "src/EggOpening.luau"))
write("egg/EggHatchDemo.rbxmx", script("LocalScript", "EggHatchDemo", "src/EggHatchDemo.client.luau"))

-- Export du socle pour le viewer
local parts = {}
for _, p in loaded:GetDescendants() do
	if p:IsA("BasePart") and p.Transparency < 1 and p.Name ~= "EggPlaceholder" then
		local c = p.Color
		local shape = "Block"
		if p:IsA("Part") then
			shape = p.Shape.Name
		end
		table.insert(parts, {
			name = p.Name,
			shape = shape,
			size = { p.Size.X, p.Size.Y, p.Size.Z },
			cf = { p.CFrame:GetComponents() },
			color = { c.R, c.G, c.B },
			neon = p.Material == roblox.Enum.Material.Neon,
		})
	end
end
local slot = loaded:FindFirstChild("EggSlot")
fs.writeFile("tools/egg_stand.json", serde.encode("json", {
	parts = parts,
	eggCenter = { slot.CFrame.Position.X, slot.CFrame.Position.Y, slot.CFrame.Position.Z },
	eggHeight = slot.Size.Y,
	label = { text = loaded:GetAttribute("EggName"), cf = { loaded:FindFirstChild("NameLabel").CFrame:GetComponents() } },
}, false))
print("tools/egg_stand.json", #parts, "pièces")
print("OK")
