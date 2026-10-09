--[[
	Génère les modèles Roblox à partir de src/CubePetBuilder.luau.

	    lune run tools/build.luau

	Sorties (à la racine du dossier CubePets/) :
	  CubeShiba.rbxmx, CubeShiba_Golden.rbxmx
	  CubeDog.rbxmx,   CubeDog_Golden.rbxmx
	  CubeCat.rbxmx,   CubeCat_Golden.rbxmx
	  CubeHamster.rbxmx, CubeHamster_Golden.rbxmx
]]
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local process = require("@lune/process")

local Builder = require("../src/CubePetBuilder")

local OUT = "."

local function fuzzyEq(a, b)
	local ca, cb = { a:GetComponents() }, { b:GetComponents() }
	for i = 1, 12 do
		if math.abs(ca[i] - cb[i]) > 1e-4 then
			return false
		end
	end
	return true
end

-- Vérifie que chaque Weld / Motor6D reproduit exactement la pose enregistrée.
local function checkJoints(model)
	local errors = 0
	for _, d in model:GetDescendants() do
		if d:IsA("Weld") or d:IsA("Motor6D") then
			local lhs = d.Part0.CFrame * d.C0
			local rhs = d.Part1.CFrame * d.C1
			if not fuzzyEq(lhs, rhs) then
				warn("Joint incohérent : " .. d:GetFullName())
				errors += 1
			end
		elseif d:IsA("BasePart") and d.Parent ~= model then
			-- toute pièce visuelle doit être soudée à un os
			if not d:FindFirstChildWhichIsA("Weld") then
				warn("Pièce non soudée : " .. d:GetFullName())
				errors += 1
			end
		end
	end
	return errors
end

local function stats(model)
	local parts, guis = 0, 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		elseif d:IsA("GuiObject") then
			guis += 1
		end
	end
	return parts, guis, #model:GetDescendants()
end

local failures = 0
for _, job in { { "Shiba", "Normal" }, { "Shiba", "Golden" }, { "Dog", "Normal" }, { "Dog", "Golden" }, { "Cat", "Normal" }, { "Cat", "Golden" }, { "Hamster", "Normal" }, { "Hamster", "Golden" } } do
	local model = Builder.build({ species = job[1], variant = job[2] }, roblox)
	failures += checkJoints(model)

	local xml = roblox.serializeModel({ model }, true)
	-- aller-retour : le fichier doit se relire à l'identique
	local loaded = roblox.deserializeModel(xml)[1]
	assert(loaded and loaded.Name == model.Name, "relecture impossible")
	assert(#loaded:GetDescendants() == #model:GetDescendants(), "relecture incomplète")
	assert(loaded.PrimaryPart and loaded.PrimaryPart.Name == "RootPart", "PrimaryPart perdue")
	failures += checkJoints(loaded)

	local file = OUT .. "/" .. model.Name .. ".rbxmx"
	fs.writeFile(file, xml)
	local parts, guis, total = stats(model)
	print(string.format("%-24s %3d pièces, %3d éléments de visage, %4d instances, %6.1f Ko", file, parts, guis, total, #xml / 1024))
end

if failures > 0 then
	print(failures .. " problème(s) détecté(s)")
	process.exit(1)
end
print("OK")
