--========================================================--
-- STREETBALL V2.6 — DEBUG VERSION
--========================================================--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

print("✅ Script loaded successfully on", game:GetService("UserInputService").TouchEnabled and "Mobile" or "PC")

-- Shoot remote
local EventsFolder = ReplicatedStorage:FindFirstChild("Events") or ReplicatedStorage:FindFirstChild("Remotes")
local ShootRemote = EventsFolder and EventsFolder:WaitForChild("Shoot", 5)

if ShootRemote then
    print("✅ ShootRemote found:", ShootRemote)
else
    warn("❌ ShootRemote NOT FOUND!")
end

--========================================================--
-- DEBUGGED GetKey()
--========================================================--
local function GetKey()
    print("🔍 Starting GetKey() search...")
    
    local success, result = pcall(function()
        local gc = getgc(true)
        print("📊 getgc(true) returned", #gc, "items")
        
        for i, v in ipairs(gc) do
            if typeof(v) == "function" then
                local info = debug.getinfo(v)
                if info and info.name == "shoot" then
                    print("🔥 Found 'shoot' function at index", i)
                    
                    for j = 1, 20 do
                        local up = debug.getupvalue(v, j)
                        if typeof(up) == "string" and #up > 10 then
                            print("✅ KEY FOUND:", up)
                            return up
                        end
                    end
                    print("⚠️ 'shoot' function found but no valid key upvalue")
                end
            end
        end
        print("⚠️ No 'shoot' function found in getgc")
        return ""
    end)
    
    if not success then
        warn("❌ GetKey() CRASHED:", result)
    end
    
    print("🔄 GetKey() finished with:", result or "empty")
    return result or ""
end

local ShootKey = GetKey()

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
    print("🏀 Found", #Hoops, "hoops")
end

RefreshHoops()

local function GetNearestHoop()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        print("⚠️ No HumanoidRootPart")
        return nil, math.huge 
    end
    
    local nearest, dist = nil, math.huge
    for _, hoop in ipairs(Hoops) do
        local mag = (hrp.Position - hoop.Position).Magnitude
        if mag < dist then
            dist = mag
            nearest = hoop
        end
    end
    print("📍 Nearest hoop distance:", math.floor(dist))
    return nearest, dist
end

--========================================================--
-- GUI (unchanged but added debug)
--========================================================--
local screen = Instance.new("ScreenGui")
screen.Name = "DistanceDisplay"
screen.ResetOnSpawn = false
screen.Parent = player:WaitForChild("PlayerGui")

local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(0, 220, 0, 40)
distLabel.Position = UDim2.new(0.5, -110, 0.05, 0)
distLabel.BackgroundTransparency = 0.3
distLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
distLabel.TextSize = 18
distLabel.Font = Enum.Font.GothamBold
distLabel.Text = "Distance: --"
distLabel.Parent = screen

local powerLabel = Instance.new("TextLabel")
powerLabel.Size = UDim2.new(0, 220, 0, 40)
powerLabel.Position = UDim2.new(0.5, -110, 0.12, 0)
powerLabel.BackgroundTransparency = 0.3
powerLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
powerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
powerLabel.TextSize = 18
powerLabel.Font = Enum.Font.GothamBold
powerLabel.Text = "Power: --"
powerLabel.Parent = screen

print("✅ GUI created")

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
        return
    end
    
    dist = math.floor(dist)
    distLabel.Text = "Distance: " .. dist
    
    if dist >= 53 and dist <= 57 then
        powerLabel.Text = "Power: 75"
    elseif dist >= 58 and dist <= 62 then
        powerLabel.Text = "Power: 80"
    elseif dist >= 63 and dist <= 68 then
        powerLabel.Text = "Power: 85"
    else
        powerLabel.Text = "Power: --"
    end
end)

--========================================================--
-- SHOOT FUNCTION
--========================================================--
local function ShootBall()
    print("🔫 ShootBall() called")
    local hoop, distance = GetNearestHoop()
    if not hoop then 
        warn("❌ No hoop found when trying to shoot")
        return 
    end
    
    local data = getgenv().DistanceMap[math.floor(distance)]
    if not data then 
        warn("❌ No shot data for distance", distance)
        return 
    end
    
    if ShootKey == "" then
        warn("❌ NO SHOOT KEY! Shooting will probably fail")
    end
    
    local finalVector = hoop.Position + data.Vector
    local move = character.Humanoid.MoveDirection * 1.5
    finalVector -= Vector3.new(move.X, 0, move.Z)
    
    local head = character:FindFirstChild("Head")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    if not head or not hrp then 
        warn("❌ Missing Head or HRP")
        return 
    end
    
    local spawnPos = hrp.Position + (finalVector - head.Position).Unit * 4
    print("📤 Firing ShootRemote with key:", ShootKey)
    
    local success, err = pcall(function()
        ShootRemote:FireServer(finalVector, spawnPos, ShootKey)
    end)
    
    if success then
        print("✅ FireServer called successfully")
    else
        warn("❌ FireServer FAILED:", err)
    end
end

--========================================================--
-- INPUT
--========================================================--
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.B then
        print("🎮 B key pressed")
        if not character:FindFirstChild("Basketball") then 
            print("⚠️ No basketball in character")
            return 
        end
        
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        print("🦘 Jump state triggered")
        
        task.wait(0.26)
        ShootBall()
    end
end)

print("✅ Input connection active - Press B to test")

-- Character reset
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    print("♻️ Character reset")
end)
