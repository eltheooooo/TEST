--[[
	Exporte la géométrie + le visage d'un pet construit par CubeShibaBuilder
	en JSON, pour le viewer three.js (tools/viewer.html).

	Utilisation : lune run tools/preview_export.luau <dossier_sortie>
]]
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local process = require("@lune/process")

local Builder = require("../src/CubeShibaBuilder")

local outDir = process.args[1] or "tools"

local function v3(v)
	return { v.X, v.Y, v.Z }
end
local function col(c)
	return { c.R, c.G, c.B }
end
local function cf(c)
	return { c:GetComponents() }
end

local function boneOf(part)
	local w = part:FindFirstChild("Weld")
	if w and w:IsA("Weld") then
		return w.Part0.Name
	end
	return part.Name
end

local function guiNode(inst)
	if inst:IsA("Folder") then
		local children = {}
		for _, c in inst:GetChildren() do
			local n = guiNode(c)
			if n then
				table.insert(children, n)
			end
		end
		return { class = "Folder", name = inst.Name, children = children }
	end
	if not inst:IsA("GuiObject") then
		return nil
	end
	local corner = inst:FindFirstChildOfClass("UICorner")
	local children = {}
	for _, c in inst:GetChildren() do
		local n = guiNode(c)
		if n then
			table.insert(children, n)
		end
	end
	local p, s = inst.Position, inst.Size
	return {
		class = inst.ClassName,
		name = inst.Name,
		visible = inst.Visible,
		pos = { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset },
		size = { s.X.Scale, s.X.Offset, s.Y.Scale, s.Y.Offset },
		anchor = { inst.AnchorPoint.X, inst.AnchorPoint.Y },
		rot = inst.Rotation,
		color = col(inst.BackgroundColor3),
		bt = inst.BackgroundTransparency,
		z = inst.ZIndex,
		clip = inst.ClipsDescendants,
		corner = corner and {
			{ corner.TopLeftRadius.Scale, corner.TopLeftRadius.Offset },
			{ corner.TopRightRadius.Scale, corner.TopRightRadius.Offset },
			{ corner.BottomRightRadius.Scale, corner.BottomRightRadius.Offset },
			{ corner.BottomLeftRadius.Scale, corner.BottomLeftRadius.Offset },
		} or nil,
		children = children,
	}
end

local function export(model)
	local parts, bones, motors = {}, {}, {}
	local face
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Transparency < 1 then
				table.insert(parts, {
					name = d.Name,
					shape = if d:IsA("WedgePart") then "Wedge" else d.Shape.Name,
					size = v3(d.Size),
					cf = cf(d.CFrame),
					color = col(d.Color),
					refl = d.Reflectance,
					bone = boneOf(d),
				})
			end
			if d.Parent == model then
				bones[d.Name] = { cf = cf(d.CFrame), size = v3(d.Size) }
			end
			local gui = d:FindFirstChild("Face")
			if gui and gui:IsA("SurfaceGui") then
				face = {
					cf = cf(d.CFrame),
					size = v3(d.Size),
					canvas = { gui.CanvasSize.X, gui.CanvasSize.Y },
					root = guiNode(gui:FindFirstChild("Canvas")),
				}
			end
		elseif d:IsA("Motor6D") then
			table.insert(motors, { name = d.Name, part0 = d.Part0.Name, part1 = d.Part1.Name, c0 = cf(d.C0), c1 = cf(d.C1) })
		end
	end
	local outline = model:FindFirstChild("Outline")
	return {
		name = model.Name,
		variant = model:GetAttribute("Variant"),
		parts = parts,
		bones = bones,
		motors = motors,
		face = face,
		outline = outline and col(outline.OutlineColor) or nil,
	}
end

local all = {}
for _, variant in { "Normal", "Golden" } do
	local model = Builder.build({ variant = variant }, roblox)
	-- aller-retour par le format fichier : le viewer voit exactement ce que Studio chargera
	local loaded = roblox.deserializeModel(roblox.serializeModel({ model }, true))[1]
	all[variant] = export(loaded)
end
fs.writeFile(outDir .. "/pet_data.json", serde.encode("json", all, false))
print("pet_data.json written to " .. outDir)
