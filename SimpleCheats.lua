-- Configuración
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Window = Rayfield:CreateWindow({
	Name = "Simple Cheats",
	Icon = 0,
	LoadingTitle = "Simple Cheats",
	LoadingSubtitle = "by TheVictxX",
	Theme = "Default",
	ConfigurationSaving = { Enabled = true, FileName = "Simple Cheats" },
})

-- Depuración
local debug = false
local debugHumanoid = false
local debugItems = false
local debugItemsTag = false

-- Variables de ESP
local espDistanceLimit = 500
local espEnabled = false
local itemsESPEnabled = false

-- Colores
local WhiteColor = Color3.fromRGB(255, 255, 255)
local RedColor = Color3.fromRGB(255, 0, 0)
local GreenColor = Color3.fromRGB(0, 255, 0)

local taggedCharacters = {}

-- 🎯 Lista de ítems a rastrear (en minúsculas)
local items = {
	["tec9"] = true,
	["revolver"] = true,
	["shiv"] = true,
	["bottle"] = true,
	["medkit"] = true,
	["primaryammo"] = true,
	["secondaryammo"] = true,
	["beans"] = true,
	["candy bar"] = true,
	["shellsammo"] = true,
	["m1911"] = true,
	["doublebarrel"] = true,
	----
	["Tec9"] = true,
	["Revolver"] = true,
	["Shiv"] = true,
	["Bottle"] = true,
	["Medkit"] = true,
	["PrimaryAmmo"] = true,
	["SecondaryAmmo"] = true,
	["Beans"] = true,
	["Candy Bar"] = true,
	["CandyBar"] = true,
	["ShellsAmmo"] = true,
	["M1911"] = true,
	["DoubleBarrel"] = true,
	["BackPacks"] = true,
}

-- =====================================================
-- FUNCIONES DE ESP HUMANOIDES (igual que antes)
-- =====================================================

local function clearOldStuff(character)
	if not character then
		return
	end
	if character:FindFirstChild("RoleHighlight") then
		character.RoleHighlight:Destroy()
	end
	local head = character:FindFirstChild("Head")
	if head and head:FindFirstChild("RoleBillboard") then
		head.RoleBillboard:Destroy()
	end
	taggedCharacters[character] = nil
	if debugHumanoid then
		print("[ESP] Limpieza:", character.Name)
	end
end

local function addNameTag(character, text)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "RoleBillboard"
	bb.Size = UDim2.new(0, 100, 0, 20)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.Adornee = head
	bb.AlwaysOnTop = true
	bb.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 0, 0) -- Rojo
	label.TextStrokeTransparency = 1
	label.TextScaled = false
	label.Font = Enum.Font.SourceSansBold
	label.Parent = bb
end

local function tagNPC(character, _, labelText) -- Ignorar el parámetro roleColor
	if character:FindFirstChild("RoleHighlight") then
		return
	end

	local red = Color3.new(1, 0, 0) -- Rojo

	local highlight = Instance.new("Highlight", character)
	highlight.Name = "RoleHighlight"
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = red
	highlight.OutlineColor = red
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0.7

	addNameTag(character, labelText)
	taggedCharacters[character] = true
	if debugHumanoid then
		print("[ESP] Etiquetado NPC:", labelText)
	end
end

local function detectHumanoids()
	if not espEnabled or not LocalPlayer.Character or not Camera then
		return
	end
	local camPos = Camera.CFrame.Position

	local enemyFolder = workspace:FindFirstChild("Enemy")
	if enemyFolder then
		for _, enemy in ipairs(enemyFolder:GetChildren()) do
			if enemy:IsA("Model") and enemy:FindFirstChildOfClass("Humanoid") and enemy:FindFirstChild("Head") then
				local dist = (enemy.Head.Position - camPos).Magnitude
				if dist <= espDistanceLimit then
					if not taggedCharacters[enemy] then
						tagNPC(enemy, RedColor, enemy.Name)
					end
				else
					if taggedCharacters[enemy] then
						clearOldStuff(enemy)
					end
				end
			end
		end
	end

	for _, obj in ipairs(workspace:GetChildren()) do
		if
			obj:IsA("Model")
			and obj:FindFirstChildOfClass("Humanoid")
			and obj:FindFirstChild("Head")
			and obj ~= LocalPlayer.Character
		then
			if not (enemyFolder and obj:IsDescendantOf(enemyFolder)) then
				local dist = (obj.Head.Position - camPos).Magnitude
				if dist <= espDistanceLimit then
					if not taggedCharacters[obj] then
						tagNPC(obj, WhiteColor, obj.Name)
					end
				else
					if taggedCharacters[obj] then
						clearOldStuff(obj)
					end
				end
			end
		end
	end
end

-- =====================================================
-- FUNCIONES DE ESP ITEMS OPTIMIZADO Y FUNCIONAL CON BILLBOARD
-- =====================================================

local taggedItems = {}
local descendantAddedConnection

-- Revisa si el nombre está en la lista
local function isTrackedItem(name)
	return items[string.lower(name)] == true
end

-- Devuelve un adornee válido, o nil
local function getAdornee(obj)
	if obj:IsA("BasePart") or obj:IsA("MeshPart") then
		return obj
	elseif obj:IsA("Model") then
		for _, part in pairs(obj:GetDescendants()) do
			if part:IsA("BasePart") then
				return part
			end
		end
	end
	return nil
end

-- Crea un adornee falso si no hay partes
local function createFakeAdornee(obj)
	local fakePart = Instance.new("Part")
	fakePart.Name = "FakeAdornee"
	fakePart.Anchored = true
	fakePart.CanCollide = false
	fakePart.Transparency = 1 -- invisible
	fakePart.Size = Vector3.new(1, 1, 1)

	if obj:IsA("Model") then
		local cframe, _ = obj:GetBoundingBox()
		fakePart.CFrame = cframe
	elseif obj:IsA("BasePart") then
		fakePart.CFrame = obj.CFrame
	else
		fakePart.CFrame = CFrame.new(0, 0, 0)
	end

	fakePart.Parent = workspace
	return fakePart
end

-- Crea y asigna un BillboardGui con el nombre del ítem
local function createBillboard(obj, adornee)
	local existingBillboard = adornee:FindFirstChild("ItemBillboard")
	if existingBillboard then
		-- Si ya existe, simplemente devolverlo y no crear otro
		return existingBillboard
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ItemBillboard"
	billboard.Adornee = adornee
	billboard.Size = UDim2.new(0, 120, 0, 30) -- tamaño fijo, un poco más ancho para mejor lectura
	billboard.AlwaysOnTop = true
	billboard.ExtentsOffset = Vector3.new(0, 2, 0)

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = WhiteColor
	textLabel.TextStrokeTransparency = 1 -- sin borde (stroke)
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.TextScaled = false -- sin escalado automático
	textLabel.TextSize = 14 --tamaño fijo para que se vea bien
	textLabel.Text = obj.Name
	textLabel.TextWrapped = true -- para que el texto haga salto de línea si es muy largo
	textLabel.Parent = billboard

	billboard.Parent = adornee

	return billboard
end

-- Resalta el ítem con BillboardGui
local function highlightItem(obj)
	if taggedItems[obj] then
		taggedItems[obj].billboard.Enabled = true
		return
	end

	local adornee = getAdornee(obj)
	if not adornee then
		if debugItemsTag then
			print("[ESP Items] No se encontró adornee válido para:", obj:GetFullName())
		end
		adornee = createFakeAdornee(obj)
	end

	local billboard = createBillboard(obj, adornee)

	taggedItems[obj] = {
		billboard = billboard,
		adornee = adornee,
	}

	if debugItemsTag then
		print("[ESP Items] Resaltado con Billboard:", obj:GetFullName(), "Adornee asignado:", adornee.Name)
	end
end

-- Oculta el BillboardGui sin destruirlo
local function unhighlightItem(obj)
	local data = taggedItems[obj]
	if data and data.billboard then
		data.billboard.Enabled = false
		if debugItemsTag then
			print("[ESP Items] Billboard oculto:", obj.Name)
		end
	end
end

local maxESPItems = 20
local espCount = 0
local camPos = workspace.CurrentCamera.CFrame.Position

local function recoverExistingBillboards()
	local MapFolder = workspace:FindFirstChild("Map") or workspace
	for _, obj in ipairs(MapFolder:GetDescendants()) do
		if espCount >= maxESPItems then
			break
		end
		if isTrackedItem(obj.Name) then
			local adornee = getAdornee(obj)
			if adornee then
				local dist = (adornee.Position - camPos).Magnitude
				if dist <= espDistanceLimit then
					local existingBB = adornee:FindFirstChild("ItemBillboard")
					if existingBB then
						taggedItems[obj] = { billboard = existingBB, adornee = adornee }
						existingBB.Enabled = true
						print("[ESP Items] Billboard existente activado para:", obj.Name)
					else
						highlightItem(obj)
					end
					espCount = espCount + 1
				end
			end
		end
	end
end

-- Activa o desactiva ESP de ítems con Billboard
local function toggleItemsESP(state)
	if state then
		recoverExistingBillboards()

		descendantAddedConnection = workspace.DescendantAdded:Connect(function(descendant)
			if
				(descendant:IsA("BasePart") or descendant:IsA("MeshPart") or descendant:IsA("Model"))
				and isTrackedItem(descendant.Name)
			then
				highlightItem(descendant)
				if debugItemsTag then
					print("[ESP Items] Nuevo ítem detectado y resaltado:", descendant:GetFullName())
				end
			end
		end)
	else
		for obj, _ in pairs(taggedItems) do
			unhighlightItem(obj)
		end
		taggedItems = {}

		if descendantAddedConnection then
			descendantAddedConnection:Disconnect()
			descendantAddedConnection = nil
		end
	end
end

-- =====================================================
-- INTERFAZ CON RAYFIELD PARA ITEMS ESP CON BILLBOARD
-- =====================================================

local Tab = Window:CreateTab("ESP", 6034304892) -- Mira tipo shooter

-- Toggle para activar/desactivar ESP Universal (por ejemplo para humanoides)
Tab:CreateToggle({
	Name = "ESP Enemy",
	CurrentValue = espEnabled,
	Callback = function(state)
		espEnabled = state
		if espEnabled then
			Rayfield:Notify({
				Title = "ESP Activated",
				Content = "Detecting humanoids...",
				Duration = 3,
				Image = 4483362458,
			})
			task.spawn(function()
				while espEnabled do
					detectHumanoids()
					task.wait(1.5)
				end
			end)
		else
			for character in pairs(taggedCharacters) do
				clearOldStuff(character)
			end
			taggedCharacters = {}
			Rayfield:Notify({ Title = "ESP Disabled", Content = "Detection stopped.", Duration = 3, Image = 4483362458 })
		end
	end,
})

-- Slider para controlar distancia máxima de ESP (si quieres filtrar por distancia)
Tab:CreateSlider({
	Name = "Maximum ESP Distance",
	Range = { 100, 800 },
	Increment = 100,
	CurrentValue = espDistanceLimit,
	Callback = function(val)
		espDistanceLimit = val
		if debugHumanoid then
			print("[ESP] Distance adjusted to:", val)
		end
	end,
})

-- Toggle para activar/desactivar ESP Items con Billboard
Tab:CreateToggle({
	Name = "ESP Items",
	CurrentValue = itemsESPEnabled,
	Callback = function(state)
		itemsESPEnabled = state
		toggleItemsESP(state)

		Rayfield:Notify({
			Title = "ESP Items",
			Content = state and "Activado" or "Desactivado",
			Duration = 3,
			Image = 4483362458,
		})
	end,
})

-- ===============================
-- Interfaz con Player
-- ===============================

local Tab = Window:CreateTab("Player", 4483362458)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- 🚀 Variables
local noclip = false
local speed = 16
local jump = 50

-- Estado de Noclip
local noclipActive = false
local noclipConnection = nil

-- Función para activar noclip
local function activateNoclip()
	noclipActive = true
	noclipConnection = game:GetService("RunService").Stepped:Connect(function()
		local character = game.Players.LocalPlayer.Character
		if character and noclipActive then
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end
		end
		task.wait(0.2)
	end)
end

-- Función para desactivar noclip
local function deactivateNoclip()
	noclipActive = false
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end
end

-- Toggle de Rayfield para Noclip
Tab:CreateToggle({
	Name = "Noclip (Buggy)",
	CurrentValue = false,
	Callback = function(state)
		if state then
			activateNoclip()
			Rayfield:Notify({
				Title = "Noclip Activated",
				Content = "You can now pass through objects.",
				Duration = 3,
				Image = 4483362458,
			})
		else
			deactivateNoclip()
			Rayfield:Notify({
				Title = "Noclip Disabled",
				Content = "You can no longer pass through objects.",
				Duration = 3,
				Image = 4483362458,
			})
		end
	end,
})

-- ===============================
-- Interfaz con Rayfield
-- ===============================

Tab:CreateSlider({
	Name = "Speed",
	Range = { 16, 200 },
	Increment = 1,
	CurrentValue = 16,
	Callback = function(val)
		speed = val
		if Humanoid then
			Humanoid.WalkSpeed = speed
		end
	end,
})

Tab:CreateSlider({
	Name = "Power Jump",
	Range = { 50, 300 },
	Increment = 5,
	CurrentValue = 50,
	Callback = function(val)
		jump = val
		if Humanoid then
			Humanoid.JumpPower = jump
		end
	end,
})

-- Asegura que se actualice si el personaje muere o cambia
LocalPlayer.CharacterAdded:Connect(function(char)
	Character = char
	Humanoid = char:WaitForChild("Humanoid")
	Humanoid.WalkSpeed = speed
	Humanoid.JumpPower = jump
end)

-- ===============================
-- Visual
-- ===============================

local Tab = Window:CreateTab("Visuals", 6031075931) -- Cubo básico

local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")

local visualSettings = {
	noFog = false,
	noEffects = false,
	forceDay = false,
	nightVision = false,
	customFOV = false,
	noRain = false,
}

-- 🌧️ Remove Rain
Tab:CreateToggle({
	Name = "Remove Rain",
	CurrentValue = false,
	Callback = function(state)
		visualSettings.noRain = state
		for _, obj in ipairs(workspace:GetDescendants()) do
			-- Si es ParticleEmitter relacionado a lluvia, activa/desactiva Enabled
			if obj:IsA("ParticleEmitter") and obj.Parent and obj.Parent.Name:lower():find("rain") then
				obj.Enabled = not state
			-- Si es BasePart llamado "rain" (u otro nombre con "rain") cambia transparencia y colisión
			elseif obj:IsA("BasePart") and obj.Name:lower():find("rain") then
				obj.Transparency = state and 1 or 0
				obj.CanCollide = not state
			end
		end
		-- Adicional: Revisa también hijos dentro de la cámara para evitar error
		local camera = workspace.CurrentCamera
		for _, obj in ipairs(camera:GetDescendants()) do
			if obj:IsA("ParticleEmitter") and obj.Parent and obj.Parent.Name:lower():find("rain") then
				obj.Enabled = not state
			elseif obj:IsA("BasePart") and obj.Name:lower():find("rain") then
				obj.Transparency = state and 1 or 0
				obj.CanCollide = not state
			end
		end
	end,
})

-- 🌫️ Remove Fog
Tab:CreateToggle({
	Name = "Remove Fog",
	CurrentValue = false,
	Callback = function(state)
		visualSettings.noFog = state
		if state then
			Lighting.FogEnd = 1e6
			Lighting.FogStart = 1e6
		else
			Lighting.FogEnd = 1000
			Lighting.FogStart = 0
		end
	end,
})

-- 🔭 Extend max FOV
Tab:CreateToggle({
	Name = "Extended FOV (max)",
	CurrentValue = false,
	Callback = function(state)
		visualSettings.customFOV = state
		if state then
			Camera.FieldOfView = 120
		else
			Camera.FieldOfView = 70
		end
	end,
})

-- 💡 Remove visual effects (Blur, ColorCorrection, etc.)
Tab:CreateToggle({
	Name = "Remove Visual Effects (Blur, Color, etc.)",
	CurrentValue = false,
	Callback = function(state)
		visualSettings.noEffects = state
		for _, v in ipairs(Lighting:GetChildren()) do
			if
				v:IsA("BlurEffect")
				or v:IsA("ColorCorrectionEffect")
				or v:IsA("SunRaysEffect")
				or v:IsA("BloomEffect")
				or v:IsA("DepthOfFieldEffect")
			then
				v.Enabled = not state
			end
		end
	end,
})

-- ☀️ Force Daytime (Time = 14)
Tab:CreateToggle({
	Name = "Force Daytime (Time = 14)",
	CurrentValue = false,
	Callback = function(state)
		visualSettings.forceDay = state
		if state then
			Lighting.ClockTime = 14
			visualSettings._forceDayConnection = game:GetService("RunService").RenderStepped:Connect(function()
				if visualSettings.forceDay then
					Lighting.ClockTime = 14
				end
			end)
		else
			if visualSettings._forceDayConnection then
				visualSettings._forceDayConnection:Disconnect()
				visualSettings._forceDayConnection = nil
			end
		end
	end,
})

-- 🌙 Night Vision (light dark mode)
Tab:CreateToggle({
	Name = "Night Vision (light dark mode)",
	CurrentValue = false,
	Callback = function(state)
		visualSettings.nightVision = state
		if state then
			local nv = Instance.new("ColorCorrectionEffect")
			nv.Name = "NightVision"
			nv.Brightness = 0.1
			nv.Contrast = 0.3
			nv.Saturation = -0.2
			nv.TintColor = Color3.fromRGB(180, 255, 180)
			nv.Parent = Lighting
		else
			local nv = Lighting:FindFirstChild("NightVision")
			if nv then
				nv:Destroy()
			end
		end
	end,
})

Rayfield:Notify({ Title = "Simple cheats", Content = "loading cheats", Duration = 5, Image = 4483362458 })
