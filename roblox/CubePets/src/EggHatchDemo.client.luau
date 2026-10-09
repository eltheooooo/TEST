--[[
	EggHatchDemo (LocalScript, StarterPlayerScripts)
	================================================
	Démo de l'ouverture : approche-toi d'un socle d'œuf et utilise ses prompts
	(E = Éclosion 1x, Q = Éclosion 3x, R = MAXIMUM).

	⚠ DÉMO UNIQUEMENT : ici le tirage est fait sur le client pour tester l'animation.
	Dans ton jeu, le client demande l'ouverture au serveur (RemoteFunction), le
	serveur vérifie l'argent, tire les pets, les ajoute à l'inventaire et renvoie
	les résultats ; le client appelle alors EggOpening.play avec ces résultats.

	Il faut dans ReplicatedStorage :
	  EggOpening              (ModuleScript, src/EggOpening.luau)
	  Pets/CubeDog, CubeCat, CubeHamster, CubeShiba
	  Eggs/OeufPrairie        (modèle importé depuis egg/OeufPrairie.glb)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EggOpening = require(ReplicatedStorage:WaitForChild("EggOpening"))

local EGGS = {
	OeufPrairie = {
		{ model = "CubeDog", name = "Chien", rarity = "Common", chance = "1/2", weight = 1 / 2 },
		{ model = "CubeCat", name = "Chat", rarity = "Uncommon", chance = "1/3", weight = 1 / 3 },
		{ model = "CubeHamster", name = "Hamster", rarity = "Rare", chance = "1/10", weight = 1 / 10 },
		{ model = "CubeShiba", name = "Shiba", rarity = "Big", chance = "1/10 000", weight = 1 / 10000 },
	},
}

local function roll(pets)
	local total = 0
	for _, p in pets do
		total += p.weight
	end
	local r = math.random() * total
	for _, p in pets do
		r -= p.weight
		if r <= 0 then
			return p
		end
	end
	return pets[#pets]
end

local function open(stand, count)
	if EggOpening.isPlaying() then
		return
	end
	local eggId = stand:GetAttribute("EggId")
	local pets = EGGS[eggId]
	if not pets then
		warn("EggHatchDemo : pas de table de pets pour " .. tostring(eggId))
		return
	end
	local eggs = ReplicatedStorage:FindFirstChild("Eggs")
	-- sans mesh importé, on ouvre l'œuf du socle (une seule pièce)
	local eggModel = (eggs and eggs:FindFirstChild(eggId)) or stand
	local petsFolder = ReplicatedStorage:WaitForChild("Pets")
	local results = {}
	for _ = 1, count do
		local p = roll(pets)
		table.insert(results, {
			model = petsFolder:WaitForChild(p.model),
			name = p.name,
			rarity = p.rarity,
			chance = p.chance,
		})
	end
	EggOpening.play({ egg = eggModel, results = results })
end

local hooked = {}
local function hook(stand)
	if hooked[stand] then
		return
	end
	hooked[stand] = true
	local slot = stand:WaitForChild("EggSlot", 10)
	if not slot then
		return
	end
	for _, prompt in slot:GetChildren() do
		if prompt:IsA("ProximityPrompt") then
			prompt.Triggered:Connect(function()
				open(stand, prompt:GetAttribute("Count") or 1)
			end)
		end
	end
end

local function scan(inst)
	if inst:IsA("Model") and inst:GetAttribute("EggId") then
		task.spawn(hook, inst)
	end
end
for _, d in workspace:GetDescendants() do
	scan(d)
end
workspace.DescendantAdded:Connect(scan)
