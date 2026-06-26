--========================================================--
-- STREETBALL V2.6 — PRESS B TO JUMP + AUTO SHOOT
-- DISTANCE MAP + POWER INDICATOR + BLUE TORSO HIGHLIGHT
--========================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Shoot remote
local EventsFolder = ReplicatedStorage:FindFirstChild("Events") or ReplicatedStorage:FindFirstChild("Remotes")
local ShootRemote = EventsFolder:WaitForChild("Shoot")

--========================================================--
-- YOUR DISTANCE → VECTOR → POWER TABLE
--========================================================--

getgenv().DistanceMap = {
    [54] = {Vector = Vector3.new(0, 51, 0), Power = 75},
    [55] = {Vector = Vector3.new(0, 50, 0), Power = 75},
    [56] = {Vector = Vector3.new(0, 46, 0), Power = 75},
    [57] = {Vector = Vector3.new(0, 38, 0), Power = 75},

    [58] = {Vector = Vector3.new(0, 61, 0), Power = 80},
    [59] = {Vector = Vector3.new(0, 58, 0), Power = 80},
    [60] = {Vector = Vector3.new(0, 56, 0), Power = 80},
    [61] = {Vector = Vector3.new(0, 54, 0), Power = 80},
    [62] = {Vector = Vector3.new(0, 52, 0), Power = 80},

    [63] = {Vector = Vector3.new(0, 72, 0), Power = 85},
    [64] = {Vector = Vector3.new(0, 70, 0), Power = 85},
    [65] = {Vector = Vector3.new(0, 64, 0), Power = 85},
    [66] = {Vector = Vector3.new(0, 62, 0), Power = 85},
    [67] = {Vector = Vector3.new(0, 54, 0), Power = 85},
    [68] = {Vector = Vector3.new(0, 50, 0), Power = 85},
}

local function GetShotData(distance)
    return getgenv().DistanceMap[math.floor(distance)]
end

--========================================================--
-- GET SHOOT KEY
--========================================================--

local function GetKey()
    for _, v in pairs(getgc(true)) do
        if typeof(v) == "function" and debug.getinfo(v).name == "shoot" then
            for _, up in pairs(debug.getupvalues(v)) do
                if typeof(up) == "string" and #up > 10 then
                    return up
                end
            end
        end
    end
    return ""
end

--========================================================--
-- HOOP DETECTION
--========================================================--

local Hoops = {}

local function RefreshHoops()
    table.clear(Hoops)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "SHEESH" then
            table.insert(Hoops, obj)
        end
    end
end

RefreshHoops()

local function GetNearestHoop()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, math.huge end

    local nearest, dist = nil, math.huge
    for _, hoop in ipairs(Hoops) do
        local mag = (hrp.Position - hoop.Position).Magnitude
        if mag < dist then
            dist = mag
            nearest = hoop
        end
    end
    return nearest, dist
end

--========================================================--
-- DISTANCE DISPLAY + POWER INDICATOR
--========================================================--

local screen = Instance.new("ScreenGui")
screen.Name = "DistanceDisplay"
screen.Parent = player.PlayerGui

-- Distance label
local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(0, 200, 0, 40)
distLabel.Position = UDim2.new(0.5, -100, 0.05, 0)
distLabel.BackgroundTransparency = 0.3
distLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
distLabel.TextSize = 20
distLabel.Font = Enum.Font.GothamBold
distLabel.Text = "Distance: --"
distLabel.Parent = screen

-- Power label
local powerLabel = Instance.new("TextLabel")
powerLabel.Size = UDim2.new(0, 200, 0, 40)
powerLabel.Position = UDim2.new(0.5, -100, 0.10, 0)
powerLabel.BackgroundTransparency = 0.3
powerLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
powerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
powerLabel.TextSize = 20
powerLabel.Font = Enum.Font.GothamBold
powerLabel.Text = "Power: --"
powerLabel.Parent = screen

--========================================================--
-- BLUE TORSO HIGHLIGHT
--========================================================--

local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.fromRGB(0, 140, 255)
highlight.OutlineColor = Color3.fromRGB(0, 140, 255)
highlight.FillTransparency = 0.5
highlight.Enabled = false
highlight.Parent = character

--========================================================--
-- LIVE UPDATE LOOP
--========================================================--

RunService.RenderStepped:Connect(function()
    character = player.Character
    if not character then return end

    local hoop, dist = GetNearestHoop()
    if not hoop then
        distLabel.Text = "Distance: --"
        powerLabel.Text = "Power: --"
        highlight.Enabled = false
        return
    end

    dist = math.floor(dist)
    distLabel.Text = "Distance: " .. dist

    -- Power indicator
    if dist >= 53 and dist <= 57 then
        powerLabel.Text = "Power: 75"
    elseif dist >= 58 and dist <= 62 then
        powerLabel.Text = "Power: 80"
    elseif dist >= 63 and dist <= 68 then
        powerLabel.Text = "Power: 85"
    else
        powerLabel.Text = "Power: --"
    end

    -- Torso highlight (blue)
    if dist >= 54 and dist <= 68 then
        highlight.Enabled = true
        highlight.Adornee = character
    else
        highlight.Enabled = false
    end
end)

--========================================================--
-- SHOOT FUNCTION
--========================================================--

local function ShootBall()
    local hoop, distance = GetNearestHoop()
    if not hoop then return end

    local data = GetShotData(distance)
    if not data then return end

    local finalVector = hoop.Position + data.Vector

    local move = character.Humanoid.MoveDirection * 1.5
    finalVector -= Vector3.new(move.X, 0, move.Z)

    local head = character:FindFirstChild("Head")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not head or not hrp then return end

    local unit = (finalVector - head.Position).Unit
    local spawnPos = hrp.Position + unit * 4

    ShootRemote:FireServer(finalVector, spawnPos, GetKey())
end

--========================================================--
-- PRESS B → FORCE JUMP → AUTO SHOOT
--========================================================--

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.B then

        if not character:FindFirstChild("Basketball") then return end

        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

        task.wait(0.26)
        ShootBall()
    end
end)

--========================================================--
-- CHARACTER RESET SUPPORT
--========================================================--

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    highlight.Parent = char
end)
