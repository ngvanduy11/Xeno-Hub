local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

local Window = Library:CreateWindow({
    Title = "Blox Fruits Hub",
    SubTitle = "Nexus Combat",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {}
local Elements = {}
local ActiveThreads = {}

local TabOrder = {"Main", "Combat", "Player", "Visuals", "Settings"}
local TabIcons = {Main = "phosphor-users-bold", Combat = "swords", Player = "person-standing", Visuals = "eye", Settings = "settings"}

local SettingsFile = "ScriptHub_Settings.json"
local Settings = {}

local LoadSettings = function()
    local success, result = pcall(function()
        local data = readfile(SettingsFile)
        return data and data \~= "" and game:GetService("HttpService"):JSONDecode(data) or {}
    end)
    Settings = success and type(result) == "table" and result or {}
end

local SaveSettings = function()
    pcall(function()
        writefile(SettingsFile, game:GetService("HttpService"):JSONEncode(Settings))
    end)
end

LoadSettings()

local SpawnTracked = function(fn)
    local thread = task.spawn(fn)
    table.insert(ActiveThreads, thread)
    return thread
end

local StopAllLogic = function()
    for _, thread in ipairs(ActiveThreads) do 
        pcall(task.cancel, thread) 
    end
    ActiveThreads = {}
end

-- Services & Variables
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    humanoid = newChar:WaitForChild("Humanoid")
end)

local CombatConnections = {}
local IsAutoFarm = false
local SelectedTarget = nil
local SelectedFruit = "T-Rex"

local FruitConfigs = {
    ["T-Rex"] = {Tool = "T-Rex-T-Rex", Power = 3},
    ["Dragon"] = {Tool = "Dragon-Dragon", Power = 1},
    ["Kitsune"] = {Tool = "Kitsune-Kitsune", Power = 1},
    ["Empyrean"] = {Tool = "Empyrean (Kitsune)-Empyrean (Kitsune)", Power = 1},
    ["Pain"] = {Tool = "Pain-Pain", Power = 1},
    ["Control"] = {Tool = "Control-Control", Power = 1}
}

-- Functions
local function EquipFruit()
    local config = FruitConfigs[SelectedFruit]
    if not config then return end
    local tool = player.Backpack:FindFirstChild(config.Tool) or character:FindFirstChild(config.Tool)
    if tool and not character:FindFirstChild(config.Tool) then
        humanoid:EquipTool(tool)
        task.wait(0.1)
    end
    return character:FindFirstChild(config.Tool)
end

local function AttackTarget(target)
    if not target or not target.Character then return end
    local tool = EquipFruit()
    if not tool then return end
    local remote = tool:FindFirstChild("LeftClickRemote")
    if remote then
        local direction = (target.Character.HumanoidRootPart.Position - rootPart.Position).Unit
        pcall(function()
            remote:FireServer(direction * 2, FruitConfigs[SelectedFruit].Power)
        end)
    end
end

local function GetBestTarget()
    local best, bestScore = nil, 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == player or not plr.Character then continue end
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        local hum = plr.Character:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end
        local dist = (hrp.Position - rootPart.Position).Magnitude
        if dist > 350 then continue end
        local score = 1000 - dist
        if hum.Health < 4000 then score += 800 end
        if score > bestScore then 
            bestScore = score 
            best = plr 
        end
    end
    return best
end

local function StartAutoFarm()
    if IsAutoFarm then return end
    IsAutoFarm = true
    table.insert(CombatConnections, RunService.Heartbeat:Connect(function()
        if not IsAutoFarm then return end
        local target = GetBestTarget()
        if target then
            SelectedTarget = target
            rootPart.CFrame = CFrame.new(target.Character.HumanoidRootPart.Position + Vector3.new(0, 6, 0))
            AttackTarget(target)
        end
    end))
end

local function StopAutoFarm()
    IsAutoFarm = false
    for _, conn in ipairs(CombatConnections) do 
        pcall(function() conn:Disconnect() end) 
    end
    CombatConnections = {}
end

local function BusoKen()
    pcall(function()
        ReplicatedStorage.Remotes.CommE:FireServer("Ken", true)
        ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
    end)
end

-- UI Configuration
local UIConfig = {
    Main = {
        {Section = "Information"},
        {Id = "Welcome", Mode = "Label", Title = "Welcome", Content = "Nexus Combat Integrated"},
        {Section = "Farm Settings"},
        {Id = "AutoFarm", Mode = "Toggle", Title = "Auto Farm Bounty", Default = false, Callback = function(v) if v then StartAutoFarm() else StopAutoFarm() end end},
        {Id = "AutoQuest", Mode = "Toggle", Title = "Auto Quest", Default = false},
        {Id = "AutoCollect", Mode = "Toggle", Title = "Auto Collect", Default = false},
        {Id = "FarmDistance", Mode = "Slider", Title = "Farm Radius", Default = 300, Min = 50, Max = 500},
        {Id = "SelectedFruit", Mode = "Dropdown", Title = "Select Fruit", Values = {"T-Rex","Dragon","Kitsune","Empyrean","Pain","Control"}, Default = "T-Rex", Callback = function(v) SelectedFruit = v end},
        {Section = "Automation"},
        {Id = "AutoBuso", Mode = "Toggle", Title = "Auto Buso + Ken", Default = true, Callback = function(v) if v then SpawnTracked(function() while v do BusoKen() task.wait(4) end end) end end},
        {Id = "AntiAFK", Mode = "Toggle", Title = "Anti-AFK", Default = true},
        {Section = "Misc"},
        {Id = "Webhook", Mode = "TextBox", Title = "Discord Webhook", Default = ""},
    },

    Combat = {
        {Section = "Combat Settings"},
        {Id = "KillAura", Mode = "Toggle", Title = "Kill Aura", Default = false},
        {Id = "KillAuraRange", Mode = "Slider", Title = "Aura Range", Default = 25, Min = 10, Max = 80},
        {Id = "AutoParry", Mode = "Toggle", Title = "Auto Parry", Default = false},
        {Id = "AutoDodge", Mode = "Toggle", Title = "Auto Dodge", Default = false},
        {Id = "AimAssist", Mode = "Toggle", Title = "Aim Assist", Default = false},
    },

    Player = {
        {Section = "Movement"},
        {Id = "WalkSpeed", Mode = "Slider", Title = "Walk Speed", Default = 16, Min = 16, Max = 250, Callback = function(v) if humanoid then humanoid.WalkSpeed = v end end},
        {Id = "JumpPower", Mode = "Slider", Title = "Jump Power", Default = 50, Min = 50, Max = 300, Callback = function(v) if humanoid then humanoid.JumpPower = v end end},
        {Id = "Noclip", Mode = "Toggle", Title = "Noclip", Default = false},
        {Id = "Fly", Mode = "Toggle", Title = "Fly", Default = false},
        {Id = "FlySpeed", Mode = "Slider", Title = "Fly Speed", Default = 50, Min = 10, Max = 300},
        {Section = "Character"},
        {Id = "InfiniteStamina", Mode = "Toggle", Title = "Infinite Stamina", Default = false},
        {Id = "GodMode", Mode = "Toggle", Title = "God Mode", Default = false},
    },

    Visuals = {
        {Section = "ESP"},
        {Id = "ESP", Mode = "Toggle", Title = "ESP", Default = false},
        {Id = "ESPPlayers", Mode = "Toggle", Title = "Player ESP", Default = false},
        {Id = "ESPMobs", Mode = "Toggle", Title = "Mob ESP", Default = false},
    },

    Settings = {
        {Section = "Settings Manager"},
        {Id = "ResetSettings", Mode = "Button", Title = "Reset to Default", Callback = function() StopAllLogic() Settings = {} SaveSettings() Library:Notify({Title = "Reset", Content = "All settings reset", Duration = 3}) end}
    }
}

-- Build UI
for _, Name in ipairs(TabOrder) do
    Elements[Name] = {}
    Tabs[Name] = Window:CreateTab({Title = Name, Icon = TabIcons[Name]})
end

local BuildElement = function(Tab, Name, Element)
    if Element.Section then
        Tab:AddSection(Element.Section)
        return
    end
    if Element.Mode == "Toggle" then
        Elements[Name][Element.Id] = Tab:CreateToggle(Element.Id, {Title = Element.Title, Default = Element.Default or false, Callback = Element.Callback})
    elseif Element.Mode == "Slider" then
        Elements[Name][Element.Id] = Tab:CreateSlider(Element.Id, {Title = Element.Title, Default = Element.Default or 0, Min = Element.Min or 0, Max = Element.Max or 100, Callback = Element.Callback})
    elseif Element.Mode == "Dropdown" then
        Elements[Name][Element.Id] = Tab:CreateDropdown(Element.Id, {Title = Element.Title, Values = Element.Values or {}, Default = Element.Default, Callback = Element.Callback})
    elseif Element.Mode == "Button" then
        Tab:CreateButton({Title = Element.Title, Callback = Element.Callback})
    end
end

for _, Name in ipairs(TabOrder) do
    for _, Element in ipairs(UIConfig[Name]) do
        BuildElement(Tabs[Name], Name, Element)
    end
end

InterfaceManager:SetLibrary(Library)
InterfaceManager:SetFolder("ScriptHub")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

Window:SelectTab(1)

print("Blox Fruits Hub loaded successfully!")
