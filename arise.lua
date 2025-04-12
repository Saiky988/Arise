local player = game.Players.LocalPlayer
local playerGui = player:FindFirstChildOfClass("PlayerGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

if not playerGui then return end

-- Tạo ScreenGui
local gui = Instance.new("ScreenGui")
gui.Parent = playerGui
gui.Name = "FloatingButtonGui"
gui.ResetOnSpawn = false

-- Tạo Floating Button
local FloatingButton = Instance.new("ImageButton")
FloatingButton.Size = UDim2.new(0, 48, 0, 48) 
FloatingButton.Position = UDim2.new(0.4, 0, 0.1, 0)
FloatingButton.AnchorPoint = Vector2.new(0.5, 0.5)
FloatingButton.BackgroundTransparency = 1
FloatingButton.Image = "rbxassetid://77582364465717" 
FloatingButton.ImageTransparency = 0.5
FloatingButton.ScaleType = Enum.ScaleType.Fit
FloatingButton.Parent = gui
FloatingButton.Draggable = true 
FloatingButton.ZIndex = 10

FloatingButton.MouseButton1Click:Connect(function()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
    task.wait(0.1) 
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
end)

-- Tải Fluent
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Tạo cửa sổ Fluent
local Window = Fluent:CreateWindow({
    Title = "Saryn Hub | Arise crossover",
    SubTitle = "   v0.2beta",
    TabWidth = 160,
    Size = UDim2.fromOffset(490, 360),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Home = Window:AddTab({ Title = "Home", Icon = "heart" }),
    Main = Window:AddTab({ Title = "Main", Icon = "swords" }),
    Infernal = Window:AddTab({ Title = "Infernal", Icon = "inbox" }),
    Config = Window:AddTab({ Title = "Config", Icon = "menu" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "plane" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

--<>----<>----<>----< Home >----<>----<>----<>--
local _25ms=Tabs.Home:AddButton({
        Title = "Copy Discord Invite",
        Description = "discord.gg/8Qev5g6r, join for more leaks",
        Callback = function()
            setclipboard("https://discord.gg/8Qev5g6r")
        end
    })


--<>----<>----<>----< Getting Services >----<>----<>----<>--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = game.Players.LocalPlayer

--<>----<>----<>----< Main >----<>----<>----<>--

local Section = Tabs.Main:AddSection(" [ Farming ]")

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local enemyFolder = workspace:WaitForChild("__Main"):WaitForChild("__Enemies"):WaitForChild("Client")
local dataRemote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

local autoFarm = false
local isTweening = false
local farmRange = 1000000000000
local tweenSpeed = 200  -- Mặc định là 2

player.CharacterAdded:Connect(function(char)
    character = char
    hrp = char:WaitForChild("HumanoidRootPart")
end)

-- Kiểm tra enemy còn sống (máu khác 0)
local function isEnemyAlive(enemy)
    local amount = enemy:FindFirstChild("HealthBar")
        and enemy.HealthBar:FindFirstChild("Main")
        and enemy.HealthBar.Main:FindFirstChild("Bar")
        and enemy.HealthBar.Main.Bar:FindFirstChild("Amount")
    if amount and amount:IsA("TextLabel") then
        local hpText = amount.Text
        return not (hpText == "" or hpText == "0" or hpText:find("0 HP"))
    end
    return false
end

-- Tìm enemy gần nhất còn sống
local function getNearestEnemy()
    local closest, shortestDist = nil, math.huge
    for _, enemy in pairs(enemyFolder:GetChildren()) do
        if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") and isEnemyAlive(enemy) then
            local dist = (enemy.HumanoidRootPart.Position - hrp.Position).Magnitude
            if dist < shortestDist and dist <= farmRange then
                shortestDist = dist
                closest = enemy
            end
        end
    end
    return closest
end

-- Tween đến enemy
local function tweenTo(pos)
    local distance = (hrp.Position - pos).Magnitude
    local travelTime = distance / tweenSpeed
    local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(pos)})
    isTweening = true
    tween:Play()
    tween.Completed:Wait()
    isTweening = false
end

-- Gửi PunchAttack
local function punchEnemy(enemy)
    local args = {
        [1] = {
            [1] = {
                ["Event"] = "PunchAttack",
                ["Enemy"] = enemy.Name
            },
            [2] = "\4"
        }
    }
    dataRemote:FireServer(unpack(args))
end

task.spawn(function()
    while task.wait(0.00001) do
        if autoFarm and hrp and not isTweening then
            local enemy = getNearestEnemy()
            if enemy and enemy:FindFirstChild("HumanoidRootPart") then
                -- Tween tới bên trái
                tweenTo(enemy.HumanoidRootPart.Position + Vector3.new(0, 0, 3))
                punchEnemy(enemy)
            end
        end
    end
end)

-- Gắn Toggle UI
Tabs.Main:AddToggle("AutoFarmEnemies", {
    Title = "Auto Farm Nearest",
    Default = false,
    Callback = function(state)
        autoFarm = state
    end
})

local Slider = Tabs.Main:AddSlider("Slider", {
    Title = "Tween Speed",
    Default = 200,  -- Giá trị mặc định
    Min = 100,      -- Giá trị tối thiểu
    Max = 450,      -- Giá trị tối đa
    Rounding = 1,  -- Làm tròn đến 1 chữ số thập phân
    Callback = function(Value)
        tweenSpeed = Value  -- Cập nhật giá trị tweenSpeed từ slider
        print("Tween speed changed to:", tweenSpeed)  -- In ra giá trị speed mới
    end
})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local enemyFolder = workspace:WaitForChild("__Main"):WaitForChild("__Enemies"):WaitForChild("Client")
local dataRemote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

local autoBoss = false
local farmRange = 1000000000000000000000000000000000000000000000000000000000000000000000000000
local targetSize = Vector3.new(8, 12, 2.5)

player.CharacterAdded:Connect(function(char)
	character = char
	hrp = char:WaitForChild("HumanoidRootPart")
end)

local function isEnemyAlive(enemy)
	local amount = enemy:FindFirstChild("HealthBar")
		and enemy.HealthBar:FindFirstChild("Main")
		and enemy.HealthBar.Main:FindFirstChild("Bar")
		and enemy.HealthBar.Main.Bar:FindFirstChild("Amount")
	if amount and amount:IsA("TextLabel") then
		local hpText = amount.Text
		return not (hpText == "" or hpText == "0" or hpText:find("0 HP"))
	end
	return false
end

local function getNearestEnemy()
	local closest, shortestDist = nil, math.huge
	for _, enemy in pairs(enemyFolder:GetChildren()) do
		local hitbox = enemy:FindFirstChild("Hitbox")
		if enemy:IsA("Model") and hitbox and isEnemyAlive(enemy) and hitbox.Size == targetSize then
			local dist = (hitbox.Position - hrp.Position).Magnitude
			if dist < shortestDist and dist <= farmRange then
				shortestDist = dist
				closest = enemy
			end
		end
	end
	return closest
end

local function punchEnemy(enemy)
	local args = {
		[1] = {
			[1] = {
				["Event"] = "PunchAttack",
				["Enemy"] = enemy.Name
			},
			[2] = "\4"
		}
	}
	dataRemote:FireServer(unpack(args))
end

-- Teleport 6 lần, mỗi lần 0.01s
task.spawn(function()
	while task.wait(0.01) do
		if autoBoss and hrp then
			local enemy = getNearestEnemy()
			if enemy then
				local hitbox = enemy:FindFirstChild("Hitbox")
				if hitbox then
					for i = 1, 6 do
						hrp.CFrame = CFrame.new(hitbox.Position + Vector3.new(0, 0, 3))
						punchEnemy(enemy)
						task.wait(0.01)
					end
				end
			end
		end
	end
end)

-- Toggle UI
Tabs.Main:AddToggle("AutoFarmBoss", {
	Title = "Auto Farm Boss",
	Default = false,
	Callback = function(state)
		autoBoss = state
	end
})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local enemyFolder = workspace:WaitForChild("__Main"):WaitForChild("__Enemies"):WaitForChild("Client")
local dataRemote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

local autoBoss = false

local priorityPositions = {
    Vector3.new(10, 15, 3.15), -- Ưu tiên cao nhất
    Vector3.new(14, 21, 4.375),
    Vector3.new(11.4, 17.1, 3.562)
}

-- Reset nhân vật khi respawn
player.CharacterAdded:Connect(function(char)
    character = char
    hrp = char:WaitForChild("HumanoidRootPart")
end)

-- Kiểm tra còn sống
local function isEnemyAlive(enemy)
    local amount = enemy:FindFirstChild("HealthBar")
        and enemy.HealthBar:FindFirstChild("Main")
        and enemy.HealthBar.Main:FindFirstChild("Bar")
        and enemy.HealthBar.Main.Bar:FindFirstChild("Amount")
    if amount and amount:IsA("TextLabel") then
        local hpText = amount.Text
        return not (hpText == "" or hpText == "0" or hpText:find("0 HP"))
    end
    return false
end

-- Tìm enemy theo ưu tiên vị trí
local function getPriorityEnemy()
    for _, pos in ipairs(priorityPositions) do
        for _, enemy in pairs(enemyFolder:GetChildren()) do
            if enemy:IsA("Model") and isEnemyAlive(enemy) then
                local hitbox = enemy:FindFirstChild("Hitbox")
                if hitbox and (hitbox.Size - pos).Magnitude < 0.1 then
                    return enemy
                end
            end
        end
    end
    return nil
end

-- Gửi lệnh Punch
local function punchEnemy(enemy)
    local args = {
        [1] = {
            [1] = {
                ["Event"] = "PunchAttack",
                ["Enemy"] = enemy.Name
            },
            [2] = "\4"
        }
    }
    dataRemote:FireServer(unpack(args))
end

-- AutoFarm logic
task.spawn(function()
    while task.wait(0.1) do
        if autoBoss and hrp then
            local enemy = getPriorityEnemy()
            if enemy and enemy:FindFirstChild("Hitbox") then
                for i = 1, 5 do
                    hrp.CFrame = CFrame.new(enemy.Hitbox.Position + Vector3.new(0, -5, 3))
                    punchEnemy(enemy)
                    task.wait(0.1)
                end
            else
                -- Không có enemy -> loop về vị trí cố định
                hrp.CFrame = CFrame.new(3877.32227, 60.1332474, 3074.55664)
            end
        end
    end
end)

local Section = Tabs.Main:AddSection(" [ Dedu Farm ]")
-- Toggle UI
Tabs.Main:AddToggle("AutoFarmBoss", {
    Title = "Auto Beru",
    Default = false,
    Callback = function(state)
        autoBoss = state
    end
})


local Section = Tabs.Main:AddSection(" [ Dungeon ]")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local enemyFolder = workspace:WaitForChild("__Main"):WaitForChild("__Enemies"):WaitForChild("Client")
local worldFolder = workspace:WaitForChild("__Main"):WaitForChild("__World")
local dataRemote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

local autoFarm = false
local isTweening = false
local farmRange = 100000
local tweenSpeed = 130
local roomIndex = 1

player.CharacterAdded:Connect(function(char)
	character = char
	hrp = char:WaitForChild("HumanoidRootPart")
end)

-- Kiểm tra enemy còn sống
local function isEnemyAlive(enemy)
	local amount = enemy:FindFirstChild("HealthBar")
		and enemy.HealthBar:FindFirstChild("Main")
		and enemy.HealthBar.Main:FindFirstChild("Bar")
		and enemy.HealthBar.Main.Bar:FindFirstChild("Amount")
	if amount and amount:IsA("TextLabel") then
		local hpText = amount.Text
		return not (hpText == "" or hpText == "0" or hpText:find("0 HP"))
	end
	return false
end

-- Tìm enemy gần nhất còn sống
local function getNearestEnemy()
	local closest, shortestDist = nil, math.huge
	for _, enemy in pairs(enemyFolder:GetChildren()) do
		if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") and isEnemyAlive(enemy) then
			local dist = (enemy.HumanoidRootPart.Position - hrp.Position).Magnitude
			if dist < shortestDist and dist <= farmRange then
				shortestDist = dist
				closest = enemy
			end
		end
	end
	return closest
end

-- Tween tới vị trí
local function tweenTo(pos)
	local distance = (hrp.Position - pos).Magnitude
	local travelTime = distance / tweenSpeed
	local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(pos)})
	isTweening = true
	tween:Play()
	tween.Completed:Wait()
	isTweening = false
end

-- Gửi PunchAttack
local function punchEnemy(enemy)
	local args = {
		[1] = {
			[1] = {
				["Event"] = "PunchAttack",
				["Enemy"] = enemy.Name
			},
			[2] = "\4"
		}
	}
	dataRemote:FireServer(unpack(args))
end

-- Kiểm tra còn enemy không
local function areEnemiesAlive()
	for _, enemy in pairs(enemyFolder:GetChildren()) do
		if enemy:IsA("Model") and isEnemyAlive(enemy) then
			return true
		end
	end
	return false
end

-- Tìm room hiện tại theo vị trí
local function getCurrentRoom()
	for i = 1, 100 do
		local room = worldFolder:FindFirstChild("Room_" .. tostring(i))
		if room and (hrp.Position - room.Position).Magnitude <= 80 then
			return i
		end
	end
	return nil
end

-- Tìm cửa phòng tiếp theo
local function getNextRoomDoorPosition()
	local nextRoom = worldFolder:FindFirstChild("Room_" .. tostring(roomIndex + 1))
	if nextRoom then
		local door = nextRoom:FindFirstChild("UpDoor")
		if door and door:IsA("BasePart") then
			return door.Position, roomIndex + 1
		end
	end
	return nil, nil
end

-- Auto Farm Enemy
task.spawn(function()
	while task.wait(0.01) do
		if autoFarm and hrp and not isTweening then
			local enemy = getNearestEnemy()
			if enemy and enemy:FindFirstChild("HumanoidRootPart") then
				tweenTo(enemy.HumanoidRootPart.Position + Vector3.new(0, 0, 3))
				punchEnemy(enemy)
			end
		end
	end
end)

-- Auto chuyển phòng khi clear quái
task.spawn(function()
	while task.wait(0.1) do
		if autoFarm and not areEnemiesAlive() and not isTweening then
			local doorPos, newIndex = getNextRoomDoorPosition()
			if doorPos then
				for i = 1, 5 do
					hrp.CFrame = CFrame.new(doorPos + Vector3.new(0, -6, 0))
					task.wait(0.01)
				end
				roomIndex = newIndex
			end
		end
	end
end)

-- Luôn cập nhật Room hiện tại
task.spawn(function()
	while task.wait(1) do
		if hrp then
			local current = getCurrentRoom()
			if current then
				roomIndex = current
			end
		end
	end
end)

-- Toggle UI Rayfield
Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "Auto Farm Dungeon",
    Default = false,
    Callback = function(value)
        autoFarm = value
    end
})


-- Mua vé Dungeon
local function buyDungeonTicket()
	local args = {
		[1] = {
			[1] = {
				["Type"] = "Gems",
				["Event"] = "DungeonAction",
				["Action"] = "BuyTicket"
			},
			[2] = "\n"
		}
	}
	dataRemote:FireServer(unpack(args))
end

-- Tạo Dungeon
local function createDungeon()
	local args = {
		[1] = {
			[1] = {
				["Event"] = "DungeonAction",
				["Action"] = "Create"
			},
			[2] = "\n"
		}
	}
	dataRemote:FireServer(unpack(args))
end

-- Bắt đầu Dungeon
local function startDungeon()
	local args = {
		[1] = {
			[1] = {
				["Dungeon"] = tonumber(correctID),
				["Event"] = "DungeonAction",
				["Action"] = "Start"
			},
			[2] = "\n"
		}
	}
	dataRemote:FireServer(unpack(args))
end

-- Toggle: Auto Start Dungeon
Tabs.Main:AddToggle("AutoDungeonStart", {
    Title = "Auto Start Dungeon",
	Default = false,
	Callback = function(state)
		if state and game.PlaceId ~= expectedPlaceID then
			task.spawn(function()
				buyDungeonTicket()
				task.wait(0.5)
				createDungeon()
				task.wait(0.01)
				startDungeon()
			end)
		end
	end
})


local Section = Tabs.Main:AddSection(" [ Ranking ]")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local dataRemote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")
local expectedPlaceID = 128336380114944
local autoTestRank = false

Tabs.Main:AddToggle("AutoTestRank", {
    Title = "Auto Test Rank",
    Default = false,
    Callback = function(state)
        autoTestRank = state
    end
})

task.spawn(function()
    while task.wait(1) do
        if autoTestRank and game.PlaceId ~= expectedPlaceID then
            local args = {
                [1] = {
                    [1] = {
                        ["Event"] = "DungeonAction",
                        ["Action"] = "TestEnter"
                    },
                    [2] = "\n"
                }
            }
            dataRemote:FireServer(unpack(args))
        end
    end
end)

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local enemyFolder = workspace:WaitForChild("__Main"):WaitForChild("__Enemies"):WaitForChild("Client")
local worldFolder = workspace:WaitForChild("__Main"):WaitForChild("__World")
local dataRemote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

local expectedPlaceID = 128336380114944
local autoRank = false
local isTweening = false
local farmRange = 10000
local tweenSpeed = 160
local roomIndex = 1

player.CharacterAdded:Connect(function(char)
	character = char
	hrp = char:WaitForChild("HumanoidRootPart")
end)

-- Kiểm tra enemy còn sống
local function isEnemyAlive(enemy)
	local amount = enemy:FindFirstChild("HealthBar")
		and enemy.HealthBar:FindFirstChild("Main")
		and enemy.HealthBar.Main:FindFirstChild("Bar")
		and enemy.HealthBar.Main.Bar:FindFirstChild("Amount")
	if amount and amount:IsA("TextLabel") then
		local hpText = amount.Text
		return not (hpText == "" or hpText == "0" or hpText:find("0 HP"))
	end
	return false
end

-- Tìm enemy gần nhất còn sống
local function getNearestEnemy()
	local closest, shortestDist = nil, math.huge
	for _, enemy in pairs(enemyFolder:GetChildren()) do
		if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") and isEnemyAlive(enemy) then
			local dist = (enemy.HumanoidRootPart.Position - hrp.Position).Magnitude
			if dist < shortestDist and dist <= farmRange then
				shortestDist = dist
				closest = enemy
			end
		end
	end
	return closest
end

-- Tween tới vị trí
local function tweenTo(pos)
	local distance = (hrp.Position - pos).Magnitude
	local travelTime = distance / tweenSpeed
	local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(pos)})
	isTweening = true
	tween:Play()
	tween.Completed:Wait()
	isTweening = false
end

-- Gửi PunchAttack
local function punchEnemy(enemy)
	local args = {
		[1] = {
			[1] = {
				["Event"] = "PunchAttack",
				["Enemy"] = enemy.Name
			},
			[2] = "\4"
		}
	}
	dataRemote:FireServer(unpack(args))
end

-- Kiểm tra còn enemy không
local function areEnemiesAlive()
	for _, enemy in pairs(enemyFolder:GetChildren()) do
		if enemy:IsA("Model") and isEnemyAlive(enemy) then
			return true
		end
	end
	return false
end

-- Tìm cửa phòng tiếp theo
local function getNextRoomDoorPosition()
	roomIndex += 1
	local nextRoom = worldFolder:FindFirstChild("Room_" .. tostring(roomIndex))
	if nextRoom then
		local door = nextRoom:FindFirstChild("UpDoor")
		if door and door:IsA("BasePart") then
			print("Đang chuyển tới Room_" .. roomIndex)
			return door.Position
		end
	end
	return nil
end

-- Auto Farm
task.spawn(function()
	while task.wait(0.01) do
		if autoRank and hrp and not isTweening then
			local enemy = getNearestEnemy()
			if enemy and enemy:FindFirstChild("HumanoidRootPart") then
				tweenTo(enemy.HumanoidRootPart.Position + Vector3.new(0, 0, 3))
				punchEnemy(enemy)
			end
		end
	end
end)

-- Dịch chuyển khi clear quái
task.spawn(function()
    while task.wait(0.1) do
        if autoRank and not areEnemiesAlive() then
            local doorPos = getNextRoomDoorPosition()
            if doorPos then
                for i = 1, 6 do
                    hrp.CFrame = CFrame.new(doorPos + Vector3.new(0, -6, 0))
                    task.wait(0.01)
                end
            end
        end
    end
end)

Tabs.Main:AddToggle("AutoRankToggle", {
    Title = "Auto Rank",
    Default = false,
    Callback = function(value)
        autoRank = value
    end
})

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local enemyFolder = workspace:WaitForChild("__Main"):WaitForChild("__Enemies"):WaitForChild("Client")
local dataRemote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")
local world = workspace:WaitForChild("__Main"):WaitForChild("__World")

local autoInfernoFarm = false
local isTweening = false
local farmRange = 1e12
local tweenSpeed = 120
local roomIndex = 1

player.CharacterAdded:Connect(function(char)
	character = char
	hrp = char:WaitForChild("HumanoidRootPart")
end)

local function isEnemyAlive(enemy)
	local amount = enemy:FindFirstChild("HealthBar")
		and enemy.HealthBar:FindFirstChild("Main")
		and enemy.HealthBar.Main:FindFirstChild("Bar")
		and enemy.HealthBar.Main.Bar:FindFirstChild("Amount")
	if amount and amount:IsA("TextLabel") then
		local hpText = amount.Text
		return not (hpText == "" or hpText == "0" or hpText:find("0 HP"))
	end
	return false
end

local function getNearestEnemy()
	local closest, shortestDist = nil, math.huge
	for _, enemy in pairs(enemyFolder:GetChildren()) do
		if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") and isEnemyAlive(enemy) then
			local dist = (enemy.HumanoidRootPart.Position - hrp.Position).Magnitude
			if dist < shortestDist and dist <= farmRange then
				shortestDist = dist
				closest = enemy
			end
		end
	end
	return closest
end

local function tweenTo(pos)
	local distance = (hrp.Position - pos).Magnitude
	local travelTime = distance / tweenSpeed
	local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(pos)})
	isTweening = true
	tween:Play()
	tween.Completed:Wait()
	isTweening = false
end

local function punchEnemy(enemy)
	local args = {
		[1] = {
			[1] = {
				["Event"] = "PunchAttack",
				["Enemy"] = enemy.Name
			},
			[2] = "\4"
		}
	}
	dataRemote:FireServer(unpack(args))
end

-- Auto Farm + Auto Promote
task.spawn(function()
	while task.wait(0.05) do
		if autoInfernoFarm then
			-- Promote
			local room = world:FindFirstChild("Room_" .. tostring(roomIndex))
			if room and room:FindFirstChild("FirePortal") and room.FirePortal:FindFirstChild("ProximityPrompt") then
				local pos = room.FirePortal.Position
				if hrp then
					hrp.CFrame = CFrame.new(pos + Vector3.new(math.random(-2, 2), -3, math.random(-2, 2)))
				end
				dataRemote:FireServer({
					[1] = {["Event"] = "Promote"},
					[2] = "\4"
				})
			else
				roomIndex += 1
			end

			-- Auto Farm Nearest
			if not isTweening and hrp then
				local enemy = getNearestEnemy()
				if enemy and enemy:FindFirstChild("HumanoidRootPart") then
					tweenTo(enemy.HumanoidRootPart.Position + Vector3.new(0, 0, 3))
					punchEnemy(enemy)
				end
			end
		end
	end
end)

local Section = Tabs.Infernal:AddSection(" [ Infernal Castle ]")
-- Toggle UI
Tabs.Infernal:AddToggle("AutoInfernoFarm", {
	Title = "Auto Inferno Farm",
	Default = false,
	Callback = function(state)
		autoInfernoFarm = state
	end
})


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local dataRemote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

local expectedPlaceID = 128336380114944
local autoStartInferno = false

-- Spam JoinCastle nếu KHÔNG ở đúng PlaceID
task.spawn(function()
    while task.wait(1) do
        if autoStartInferno and game.PlaceId ~= expectedPlaceID then
            local args = {
                [1] = {
                    [1] = {
                        ["Event"] = "JoinCastle"
                    },
                    [2] = "\n"
                }
            }
            dataRemote:FireServer(unpack(args))
        end
    end
end)

-- UI Toggle
Tabs.Infernal:AddToggle("AutoStartInferno", {
    Title = "Auto Start Inferno",
    Default = false,
    Callback = function(state)
        autoStartInferno = state
    end
})

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local autoRoom = false
local range = 5000
local visited = {}

Tabs.Infernal:AddToggle("AutoRoom", {
    Title = "Auto Next Room",
    Default = false,
    Callback = function(state)
        autoRoom = state
    end
})

-- Hàm tìm FirePortal chưa tới gần nhất
local function getNearestUnvisitedFirePortal()
    local nearestPrompt, nearestPos, nearestRoomName
    local shortestDistance = math.huge

    local world = workspace:FindFirstChild("__Main") and workspace.__Main:FindFirstChild("__World")
    if not world then return end

    for _, room in ipairs(world:GetChildren()) do
        if not visited[room.Name] and room:FindFirstChild("FirePortal") then
            local portal = room.FirePortal
            local prompt = portal:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                local dist = (hrp.Position - portal.Position).Magnitude
                if dist < shortestDistance and dist <= range then
                    shortestDistance = dist
                    nearestPrompt = prompt
                    nearestPos = portal.Position
                    nearestRoomName = room.Name
                end
            end
        end
    end

    return nearestPrompt, nearestPos, nearestRoomName
end

-- Loop AutoRoom
task.spawn(function()
    while true do
        task.wait(0.1)
        if autoRoom and hrp then
            local prompt, pos, roomName = getNearestUnvisitedFirePortal()
            if prompt and pos and roomName then
                -- Spam teleport 5 lần
                for i = 1, 5 do
                    character:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0)))
                    task.wait(0.01)
                end

                -- Fire prompt 5 lần
                for i = 1, 50 do
                    fireproximityprompt(prompt)
                    task.wait(0.01)
                end

                visited[roomName] = true
            end
        end
    end
end)

local Section = Tabs.Config:AddSection(" [ Configs ]")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local hrp
local autoPunch = false
local punchRange = 100  -- khoảng cách tối đa

local enemyFolder = workspace:WaitForChild("__Main"):WaitForChild("__Enemies"):WaitForChild("Client")
local dataRemote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

-- Cập nhật hrp khi respawn
player.CharacterAdded:Connect(function(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end)

-- Lấy hrp lần đầu nếu nhân vật đã tồn tại
if player.Character then
    hrp = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:WaitForChild("HumanoidRootPart")
end

-- Tìm enemy gần nhất
local function getNearestEnemy()
    local closest, shortestDist = nil, math.huge
    for _, enemy in pairs(enemyFolder:GetChildren()) do
        if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") then
            local dist = (enemy.HumanoidRootPart.Position - hrp.Position).Magnitude
            if dist < shortestDist and dist <= punchRange then
                shortestDist = dist
                closest = enemy
            end
        end
    end
    return closest
end

-- Gửi Punch
local function punchEnemy(enemy)
    if enemy then
        local args = {
            [1] = {
                [1] = {
                    ["Event"] = "PunchAttack",
                    ["Enemy"] = enemy.Name
                },
                [2] = "\4"
            }
        }
        dataRemote:FireServer(unpack(args))
    end
end

-- Lặp
task.spawn(function()
    while task.wait(0.01) do
        if autoPunch and hrp then
            local target = getNearestEnemy()
            if target then
                punchEnemy(target)
            end
        end
    end
end)

-- Toggle UI
Tabs.Config:AddToggle("AutoPunch", {
    Title = "Auto Click [Fast]",
    Default = false,
    Callback = function(state)
        autoPunch = state
    end
})


local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local hrp
local autoArise = false
local ariseRange = 100

local enemyFolder = workspace:WaitForChild("__Main"):WaitForChild("__Enemies"):WaitForChild("Client")
local dataRemote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

-- Cập nhật HumanoidRootPart
player.CharacterAdded:Connect(function(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end)
if player.Character then
    hrp = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:WaitForChild("HumanoidRootPart")
end

-- Tìm enemy gần nhất
local function getNearestEnemy()
    local closest, shortestDist = nil, math.huge
    for _, enemy in pairs(enemyFolder:GetChildren()) do
        if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") then
            local dist = (enemy.HumanoidRootPart.Position - hrp.Position).Magnitude
            if dist < shortestDist and dist <= ariseRange then
                shortestDist = dist
                closest = enemy
            end
        end
    end
    return closest
end

-- Gửi yêu cầu Arise
local function ariseEnemy(enemy)
    if enemy then
        local args = {
            [1] = {
                [1] = {
                    ["Event"] = "EnemyCapture",
                    ["Enemy"] = enemy.Name
                },
                [2] = "\4"
            }
        }
        dataRemote:FireServer(unpack(args))
    end
end

-- Auto loop
task.spawn(function()
    while task.wait(0.01) do
        if autoArise and hrp then
            local target = getNearestEnemy()
            if target then
                ariseEnemy(target)
            end
        end
    end
end)
-- Toggle UI
Tabs.Config:AddToggle("AutoArise", {
    Title = "Auto Arise",
    Default = false,
    Callback = function(state)
        autoArise = state
    end
})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local hrp
local autoDestroy = false
local destroyRange = 1000

local enemyFolder = workspace:WaitForChild("__Main"):WaitForChild("__Enemies"):WaitForChild("Client")
local dataRemote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

-- Cập nhật HRP
player.CharacterAdded:Connect(function(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end)
if player.Character then
    hrp = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:WaitForChild("HumanoidRootPart")
end

-- Tìm enemy gần nhất
local function getNearestEnemy()
    local closest, shortestDist = nil, math.huge
    for _, enemy in pairs(enemyFolder:GetChildren()) do
        if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") then
            local dist = (enemy.HumanoidRootPart.Position - hrp.Position).Magnitude
            if dist < shortestDist and dist <= destroyRange then
                shortestDist = dist
                closest = enemy
            end
        end
    end
    return closest
end

-- Gửi EnemyDestroy
local function destroyEnemy(enemy)
    if enemy then
        local args = {
            [1] = {
                [1] = {
                    ["Event"] = "EnemyDestroy",
                    ["Enemy"] = enemy.Name
                },
                [2] = "\4"
            }
        }
        dataRemote:FireServer(unpack(args))
    end
end

-- Loop
task.spawn(function()
    while task.wait(0.01) do
        if autoDestroy and hrp then
            local target = getNearestEnemy()
            if target then
                destroyEnemy(target)
            end
        end
    end
end)

-- UI Toggle
Tabs.Config:AddToggle("AutoDestroy", {
    Title = "Auto Destroy",
    Default = false,
    Callback = function(state)
        autoDestroy = state
    end
})

local isAutoAttackEnabled = false

Toggle = Tabs.Config:AddToggle("AutoAttack", {
    Title = "Auto Attack",
    Default = true,
    Callback = function(state)
        if state then
            -- Bật AutoAttack
            isAutoAttackEnabled = true
            local args = {
                [1] = {
                    [1] = {
                        ["Event"] = "SettingsChange",
                        ["Setting"] = "AutoAttack"
                    },
                    [2] = "\n"
                }
            }
            game:GetService("ReplicatedStorage").BridgeNet2.dataRemoteEvent:FireServer(unpack(args))
            -- Đoạn code khi AutoAttack được bật có thể cho vào đây
        else
            -- Tắt AutoAttack
            isAutoAttackEnabled = false
            local args = {
                [1] = {
                    [1] = {
                        ["Event"] = "SettingsChange",
                        ["Setting"] = "AutoAttack"
                    },
                    [2] = "\n"
                }
            }
            game:GetService("ReplicatedStorage").BridgeNet2.dataRemoteEvent:FireServer(unpack(args))
            -- Đoạn code khi AutoAttack được tắt có thể cho vào đây
        end
    end,
})

-- Hàm chạy khi tắt UI nhưng vẫn giữ trạng thái của AutoAttack
local function handleAutoAttackState()
    if isAutoAttackEnabled then
        -- Code khi AutoAttack đang bật
    else
        -- Code khi AutoAttack đang tắt
    end
end






local Section = Tabs.Teleport:AddSection(" [ Teleport ]")


local player = game.Players.LocalPlayer
local character, hrp

local function updateCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    hrp = character:WaitForChild("HumanoidRootPart")
end

-- Gọi ngay lúc đầu
updateCharacter()

-- Cập nhật lại khi reset/spawn mới
player.CharacterAdded:Connect(function()
    task.wait(0.02)
    updateCharacter()
end)

local worldPositions = {
    ["SoloWorld"] = Vector3.new(577.968262, 26.9623756, 261.452271),
    ["ChainsawWorld"] = Vector3.new(236.932678, 32.3960934, -4301.60547),
    ["BCWorld"] = CFrame.new(198.338684, 38.2076797, 4296.10938, 0.993159413, -0, -0.116766132, 0, 1, -0, 0.116766132, 0, 0.993159413),
    ["BleachWorld"] = CFrame.new(2641.79517, 44.9265289, -2645.07568, 0.780932784, -0, -0.624615133, 0, 1, -0, 0.624615133, 0, 0.780932784),
    ["OpWorld"] = CFrame.new(-2851.1062, 48.8987885, -2011.39526, 0.739920259, -0.0159788765, 0.672504723, 0.0134891849, 0.999869287, 0.0089157233, -0.672559321, 0.00247461651, 0.74003911),
    ["NarutoWorld"] = Vector3.new(-3380.2373, 28.8265285, 2257.26196),
    ["JojoWorld"] = Vector3.new(4816.31641, 29.4423409, -120.22998),
    ["Dedu"] = CFrame.new(4072.3396, 65.590126, 3325.87012, -0.852027357, 0, -0.523497283, 0, 1, 0, 0.523497283, 0, -0.852027357),
}

local selectedWorld = "None"

Tabs.Teleport:AddDropdown("TeleportW", {
    Title = "Select Island",
    Values = {"None", "SoloWorld", "ChainsawWorld", "BCWorld", "BleachWorld", "OpWorld", "NarutoWorld", "JojoWorld", "Dedu"},
    Multi = false,
    Default = 1,
    Callback = function(v)
        selectedWorld = v
    end
})

Tabs.Teleport:AddButton({
    Title = "Teleport Island",
    Callback = function()
        local pos = worldPositions[selectedWorld]
        if pos and hrp then
            for i = 1, 8 do
                if typeof(pos) == "CFrame" then
                    character:PivotTo(pos)
                else
                    character:PivotTo(CFrame.new(pos))
                end
                task.wait(0.01)
            end
        end
    end
})

local Section = Tabs.Teleport:AddSection(" [ Teleport Reset ]")
--<>----<>----<>----< Teleport >----<>----<>----<>--
Tabs.Teleport:AddButton({
    Title = "JojoWorld",
    Callback = function()
        game.Players.LocalPlayer.Character:BreakJoints()
        
        local args = {
            [1] = {
                [1] = {
                    ["Event"] = "ChangeSpawn",
                    ["Spawn"] = "JojoWorld"
                },
                [2] = "\n"
            }
        }

        game:GetService("ReplicatedStorage").BridgeNet2.dataRemoteEvent:FireServer(unpack(args))
    end
})

Tabs.Teleport:AddButton({
    Title = "NarutoWorld",
    Callback = function()
        game.Players.LocalPlayer.Character:BreakJoints()
        
        local args = {
    [1] = {
        [1] = {
            ["Event"] = "ChangeSpawn",
            ["Spawn"] = "NarutoWorld"
        },
        [2] = "\n"
    }
}

game:GetService("ReplicatedStorage").BridgeNet2.dataRemoteEvent:FireServer(unpack(args))
    end
})

Tabs.Teleport:AddButton({
    Title = "OPWorld",
    Callback = function()
        game.Players.LocalPlayer.Character:BreakJoints()
        
        local args = {
    [1] = {
        [1] = {
            ["Event"] = "ChangeSpawn",
            ["Spawn"] = "OPWorld"
        },
        [2] = "\n"
    }
}

game:GetService("ReplicatedStorage").BridgeNet2.dataRemoteEvent:FireServer(unpack(args))
    end
})

Tabs.Teleport:AddButton({
    Title = "SoloWorld",
    Callback = function()
        game.Players.LocalPlayer.Character:BreakJoints()
        
        local args = {
    [1] = {
        [1] = {
            ["Event"] = "ChangeSpawn",
            ["Spawn"] = "SoloWorld"
        },
        [2] = "\n"
    }
}

game:GetService("ReplicatedStorage").BridgeNet2.dataRemoteEvent:FireServer(unpack(args))
    end
})

Tabs.Teleport:AddButton({
    Title = "BleachWorld",
    Callback = function()
        game.Players.LocalPlayer.Character:BreakJoints()
        
        local args = {
    [1] = {
        [1] = {
            ["Event"] = "ChangeSpawn",
            ["Spawn"] = "BleachWorld"
        },
        [2] = "\n"
    }
}

game:GetService("ReplicatedStorage").BridgeNet2.dataRemoteEvent:FireServer(unpack(args))
    end
})

Tabs.Teleport:AddButton({
    Title = "ChainsawWorld",
    Callback = function()
        game.Players.LocalPlayer.Character:BreakJoints()
        
        local args = {
    [1] = {
        [1] = {
            ["Event"] = "ChangeSpawn",
            ["Spawn"] = "ChainsawWorld"
        },
        [2] = "\n"
    }
}

game:GetService("ReplicatedStorage").BridgeNet2.dataRemoteEvent:FireServer(unpack(args))
    end
})

Tabs.Teleport:AddButton({
    Title = "BCWorld",
    Callback = function()
        game.Players.LocalPlayer.Character:BreakJoints()
        
        local args = {
    [1] = {
        [1] = {
            ["Event"] = "ChangeSpawn",
            ["Spawn"] = "BCWorld"
        },
        [2] = "\n"
    }
}

game:GetService("ReplicatedStorage").BridgeNet2.dataRemoteEvent:FireServer(unpack(args))
    end
})








local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local AntiAFKEnabled = true -- Bật sẵn
local AntiAFKConnection = nil

-- Auto AFK Prevention
local function ToggleAntiAFK(state)
    if state then
        AntiAFKConnection = LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        print("Anti AFK Enabled")
    else
        if AntiAFKConnection then
            AntiAFKConnection:Disconnect()
            AntiAFKConnection = nil
        end
        print("Anti AFK Disabled")
    end
end

-- Kích hoạt AntiAFK ngay khi script chạy
ToggleAntiAFK(AntiAFKEnabled)

-- Full Bright Toggle
local FullBrightEnabled = false
local storedSettings = {}
local loopConnection = nil

local function ToggleFullBright(state)
    if state then
        storedSettings.Brightness = Lighting.Brightness
        storedSettings.ClockTime = Lighting.ClockTime
        storedSettings.FogEnd = Lighting.FogEnd
        storedSettings.GlobalShadows = Lighting.GlobalShadows

        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1000000
        Lighting.GlobalShadows = false

        loopConnection = RunService.RenderStepped:Connect(function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 12
            Lighting.FogEnd = 1000000
            Lighting.GlobalShadows = false
        end)
    else
        if loopConnection then
            loopConnection:Disconnect()
            loopConnection = nil
        end

        Lighting.Brightness = storedSettings.Brightness or 1
        Lighting.ClockTime = storedSettings.ClockTime or 14
        Lighting.FogEnd = storedSettings.FogEnd or 1000
        Lighting.GlobalShadows = storedSettings.GlobalShadows or true
    end
end

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local PlaceId = 87039211657390

-- Hàm ServerHop
local function ServerHop()
    print("Đang tìm server khác...")
    local cursor = ""
    local servers = {}

    local function getServers()
        local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"..(cursor ~= "" and "&cursor="..cursor or "")
        local data = HttpService:JSONDecode(game:HttpGet(url))
        cursor = data.nextPageCursor or ""
        return data.data
    end

    repeat
        for _, server in ipairs(getServers()) do
            if server.playing < 30 and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id)
                return
            end
        end
    until cursor == ""

    warn("Không tìm thấy server khác phù hợp.")
end

-- Hàm RejoinServer
local function RejoinServer()
    print("Đang rejoin server...")
    TeleportService:Teleport(PlaceId, Players.LocalPlayer)
end

-- Hàm ServerHopEmpty (ít hơn 4 người chơi)
local function ServerHopEmpty()
    print("Đang tìm server vắng (dưới 4 người)...")
    local cursor = ""
    local function getServers()
        local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"..(cursor ~= "" and "&cursor="..cursor or "")
        local data = HttpService:JSONDecode(game:HttpGet(url))
        cursor = data.nextPageCursor or ""
        return data.data
    end

    repeat
        for _, server in ipairs(getServers()) do
            if server.playing < 4 and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id)
                return
            end
        end
    until cursor == ""

    warn("Không tìm thấy server vắng.")
end
local Section = Tabs.Settings:AddSection(" [ Server ]")
-- Thêm buttons vào UI
Tabs.Settings:AddButton({
    Title = "ServerHop",
    Callback = function()
        ServerHop()
    end
})

Tabs.Settings:AddButton({
    Title = "RejoinServer",
    Callback = function()
        RejoinServer()
    end
})

Tabs.Settings:AddButton({
    Title = "ServerHopEmpty",
    Callback = function()
        ServerHopEmpty()
    end
})
local Section = Tabs.Settings:AddSection(" [ Settings ]")
-- Tạo 2 Toggle trên UI
Tabs.Settings:AddToggle("Anti AFK", {
    Title = "Anti AFK",
    Default = true,
    Callback = function(state)
        ToggleAntiAFK(state)
    end
})

Tabs.Settings:AddToggle("Full Bright", {
    Title = "Full Bright",
    Default = false,
    Callback = function(state)
        ToggleFullBright(state)
    end
})

Tabs.Settings:AddButton({
    Title = "Shader",
    Callback = function()
         loadstring(game:HttpGet('https://raw.githubusercontent.com/randomstring0/pshade-ultimate/refs/heads/main/src/cd.lua'))()
    end
})

-- Hand the library over to our managers
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- You can add indexes of elements the save manager should ignore
SaveManager:SetIgnoreIndexes({})

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
InterfaceManager:SetFolder("SarynHub")
SaveManager:SetFolder("SarynHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)


Window:SelectTab(1)

Fluent:Notify({
    Title = "Saryn Hub",
    Content = "The script has been loaded.",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()