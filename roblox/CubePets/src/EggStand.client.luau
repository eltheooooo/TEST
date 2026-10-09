--[[
	EggFloat (Script, RunContext = Client) — placé dans le socle de l'œuf
	=====================================================================
	Pose le mesh de l'œuf au-dessus de la tige et le fait flotter et tourner
	doucement. Tourne sur chaque client (rien n'est répliqué, aucun coût serveur).

	Le mesh est cherché, dans l'ordre :
	  1. une pièce « Egg » placée directement dans le socle ;
	  2. ReplicatedStorage/Eggs/<EggId>/Egg (le modèle importé depuis OeufPrairie.glb).
	Sinon, l'œuf provisoire (EggPlaceholder) est animé à sa place.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local stand = script.Parent
local slot = stand:WaitForChild("EggSlot")
local placeholder = stand:FindFirstChild("EggPlaceholder")
local eggId = stand:GetAttribute("EggId") or "OeufPrairie"

local function findEgg()
	local own = stand:FindFirstChild("Egg")
	if own and own:IsA("BasePart") then
		return own
	end
	local eggs = ReplicatedStorage:WaitForChild("Eggs", 5)
	local source = eggs and eggs:FindFirstChild(eggId)
	local mesh = source and source:FindFirstChild("Egg", true)
	if mesh and mesh:IsA("BasePart") then
		local clone = mesh:Clone()
		clone.Name = "Egg"
		clone.Parent = stand
		return clone
	end
	return nil
end

local egg = findEgg()
if egg then
	-- même hauteur que l'emplacement, quelle que soit l'unité choisie à l'import
	egg.Size *= slot.Size.Y / egg.Size.Y
	egg.Anchored = true
	egg.CanCollide = false
	egg.CanTouch = false
	egg.CanQuery = false
	if placeholder then
		placeholder.Transparency = 1
	end
else
	egg = placeholder
end
if not egg then
	return
end

local base = slot.CFrame
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	egg.CFrame = base * CFrame.new(0, math.sin(t * 1.7) * 0.18, 0) * CFrame.Angles(0, t * 0.5, math.sin(t * 1.2) * 0.04)
end)
