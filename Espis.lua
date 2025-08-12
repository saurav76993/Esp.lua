-- Place this LocalScript in StarterPlayerScripts
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ESP settings
local ESP_COLOR = Color3.fromRGB(0, 255, 0)  -- Green
local ESP_THICKNESS = 1
local ESP_TRANSPARENCY = 0.7

local espObjects = {}

-- Create ESP for a character
local function createEsp(character, player)
    local drawings = {}
    
    -- Create drawing objects
    local box = Drawing.new("Quad")
    box.Visible = false
    box.Color = player.Team and player.TeamColor.Color or ESP_COLOR
    box.Thickness = ESP_THICKNESS
    box.Transparency = ESP_TRANSPARENCY
    box.Filled = false
    
    local nameTag = Drawing.new("Text")
    nameTag.Visible = false
    nameTag.Text = player.Name
    nameTag.Color = player.Team and player.TeamColor.Color or ESP_COLOR
    nameTag.Size = 18
    nameTag.Center = true
    nameTag.Outline = true
    
    drawings.box = box
    drawings.nameTag = nameTag
    
    espObjects[character] = drawings
end

-- Update ESP positions
local function updateEsp()
    for character, drawings in pairs(espObjects) do
        if character and character:FindFirstChild("HumanoidRootPart") then
            local rootPart = character.HumanoidRootPart
            local rootPos, rootVis = Camera:WorldToViewportPoint(rootPart.Position)
            
            if rootVis then
                -- Calculate box dimensions
                local size = Vector2.new(4, 6) * (rootPos.Z / 100)
                local offset = Vector2.new(size.X / 2, size.Y / 2)
                
                -- Update box position
                drawings.box.PointA = Vector2.new(rootPos.X - offset.X, rootPos.Y - offset.Y)
                drawings.box.PointB = Vector2.new(rootPos.X + offset.X, rootPos.Y - offset.Y)
                drawings.box.PointC = Vector2.new(rootPos.X + offset.X, rootPos.Y + offset.Y)
                drawings.box.PointD = Vector2.new(rootPos.X - offset.X, rootPos.Y + offset.Y)
                drawings.box.Visible = true
                
                -- Update name tag position
                drawings.nameTag.Position = Vector2.new(rootPos.X, rootPos.Y - offset.Y - 20)
                drawings.nameTag.Visible = true
            else
                drawings.box.Visible = false
                drawings.nameTag.Visible = false
            end
        else
            drawings.box.Visible = false
            drawings.nameTag.Visible = false
        end
    end
end

-- Remove ESP when character is gone
local function characterRemoved(character)
    if espObjects[character] then
        for _, drawing in pairs(espObjects[character]) do
            drawing:Remove()
        end
        espObjects[character] = nil
    end
end

-- Initialize ESP for players
local function initPlayer(player)
    if player == LocalPlayer then return end
    
    local function characterAdded(character)
        createEsp(character, player)
        character:GetPropertyChangedSignal("Parent"):Connect(function()
            if not character.Parent then
                characterRemoved(character)
            end
        end)
    end
    
    if player.Character then
        characterAdded(player.Character)
    end
    player.CharacterAdded:Connect(characterAdded)
    player.CharacterRemoving:Connect(characterRemoved)
end

-- Initialize existing players
for _, player in ipairs(Players:GetPlayers()) do
    initPlayer(player)
end

-- Listen for new players
Players.PlayerAdded:Connect(initPlayer)

-- Listen for player leaving
Players.PlayerRemoving:Connect(function(player)
    if player.Character and espObjects[player.Character] then
        characterRemoved(player.Character)
    end
end)

-- Main update loop
RunService.RenderStepped:Connect(updateEsp)
