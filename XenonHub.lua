local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local API_URL = "https://my-key.onrender.com"
local SAVE_FILE = "XenonHub_SavedKey.txt"

local function getHWID()
    local ok, val = pcall(function() return getexecutorinfo().hwid end)
    if ok and val and val ~= "" then return tostring(val) end

    ok, val = pcall(function() return syn.get_hwid() end)
    if ok and val and val ~= "" then return tostring(val) end

    ok, val = pcall(function() return HWID end)
    if ok and val and val ~= "" then return tostring(val) end

    ok, val = pcall(function() return fluxus.get_hwid() end)
    if ok and val and val ~= "" then return tostring(val) end

    ok, val = pcall(function() return evon.get_hwid() end)
    if ok and val and val ~= "" then return tostring(val) end

    ok, val = pcall(function() return solara.get_hwid() end)
    if ok and val and val ~= "" then return tostring(val) end

    ok, val = pcall(function() return wave.get_hwid() end)
    if ok and val and val ~= "" then return tostring(val) end

    ok, val = pcall(function()
        local info = getexecutorinfo()
        return info.hwid or info.id or info.fingerprint
    end)
    if ok and val and val ~= "" then return tostring(val) end

    ok, val = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and val and val ~= "" then return tostring(val) end

    return tostring(player.UserId)
end

local function showNotify(title, message, link, duration)
    local ng = Instance.new("ScreenGui")
    ng.Name = "XenonNotify"
    ng.ResetOnSpawn = false
    ng.Parent = (game:GetService("CoreGui") or player.PlayerGui)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 90)
    frame.Position = UDim2.new(1, 10, 1, -110)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Parent = ng
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 140, 0)
    stroke.Thickness = 2
    stroke.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = title
    titleLabel.Size = UDim2.new(1, -10, 0, 25)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 140, 0)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Text = message
    msgLabel.Size = UDim2.new(1, -10, 0, 25)
    msgLabel.Position = UDim2.new(0, 10, 0, 28)
    msgLabel.BackgroundTransparency = 1
    msgLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    msgLabel.TextSize = 12
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.Parent = frame

    if link then
        local clickBtn = Instance.new("TextButton")
        clickBtn.Text = "🔗 Click to copy link"
        clickBtn.Size = UDim2.new(1, -20, 0, 22)
        clickBtn.Position = UDim2.new(0, 10, 0, 60)
        clickBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        clickBtn.TextColor3 = Color3.fromRGB(100, 180, 255)
        clickBtn.TextSize = 11
        clickBtn.Font = Enum.Font.Gotham
        clickBtn.BorderSizePixel = 0
        clickBtn.Parent = frame
        Instance.new("UICorner", clickBtn).CornerRadius = UDim.new(0, 6)
        clickBtn.MouseButton1Click:Connect(function()
            if setclipboard then
                setclipboard(link)
                clickBtn.Text = "✅ Copied!"
                clickBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
            end
        end)
    end

    TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Position = UDim2.new(1, -290, 1, -110)
    }):Play()
    task.wait(duration or 3)
    TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
        Position = UDim2.new(1, 10, 1, -110)
    }):Play()
    task.wait(0.4)
    ng:Destroy()
end

local function saveKey(key, hwid)
    pcall(function()
        if writefile then writefile(SAVE_FILE, key .. "|" .. hwid) end
    end)
end

local function loadKey(hwid)
    local ok, result = pcall(function()
        if isfile and readfile and isfile(SAVE_FILE) then
            return readfile(SAVE_FILE)
        end
        return nil
    end)
    if not ok or not result or result == "" then return nil end
    local savedKey, savedHwid = result:match("^(.+)|(.+)$")
    if not savedKey then return result end
    if savedHwid ~= hwid then return nil end
    return savedKey
end

local function clearKey()
    pcall(function()
        if isfile and delfile and isfile(SAVE_FILE) then
            delfile(SAVE_FILE)
        end
    end)
end

-- ✅ validateKey gửi kèm username cho webhook
local function validateKey(key, hwid)
    key = key:match("^%s*(.-)%s*$")
    local username = player.Name

    -- Thử redeem (key mới lấy về)
    local redeemOk, redeemRes = pcall(function()
        return request({
            Url = API_URL .. "/v1/redeem",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            -- ✅ Gửi kèm username để webhook hiển thị tên
            Body = HttpService:JSONEncode({ hwid = hwid, key = key, username = username })
        })
    end)

    if redeemOk and redeemRes and redeemRes.StatusCode == 200 then
        local parseOk, data = pcall(HttpService.JSONDecode, HttpService, redeemRes.Body)
        if parseOk and data.ok then
            return true, "24 hours"
        end
    end

    -- Kiểm tra key đã active chưa (gửi kèm username)
    local checkOk, checkRes = pcall(function()
        return request({
            Url = API_URL .. "/v1/check?hwid=" .. hwid .. "&username=" .. username,
            Method = "GET",
            Headers = { ["Content-Type"] = "application/json" }
        })
    end)

    if not checkOk or not checkRes then return false, "No response from server!" end
    if checkRes.StatusCode ~= 200 then return false, "HTTP Error: " .. tostring(checkRes.StatusCode) end

    local parseOk, data = pcall(HttpService.JSONDecode, HttpService, checkRes.Body)
    if not parseOk then return false, "JSON Error!" end

    if data.ok then
        -- ✅ Hiển thị thời gian còn lại nếu server trả về
        local remaining = data.timeLeft or "24 hours"
        return true, remaining
    else
        clearKey()
        return false, "Invalid or expired key!"
    end
end

local function runMainScript()
    getgenv().team = "Pirates"
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ngvanduy11/Xenon-Hub/refs/heads/main/XenonHub.lua.txt"))()
end

local function createUI(hwid)
    local GET_KEY_URL = API_URL .. "/getkey?hwid=" .. hwid

    local gui = Instance.new("ScreenGui")
    gui.Name = "XenonKeySystem"
    gui.ResetOnSpawn = false
    gui.Parent = (game:GetService("CoreGui") or player.PlayerGui)

    task.spawn(function()
        showNotify("Xenon Hub", "Get key link copied! Paste in browser.", GET_KEY_URL, 5)
    end)

    local MainContainer = Instance.new("Frame")
    MainContainer.Size = UDim2.new(0, 380, 0, 300)
    MainContainer.Position = UDim2.new(0.5, -190, 0.5, -150)
    MainContainer.BackgroundTransparency = 1
    MainContainer.Parent = gui

    local BackgroundImage = Instance.new("ImageLabel")
    BackgroundImage.Image = "rbxassetid://95047762650303"
    BackgroundImage.Size = UDim2.new(1, 0, 1, 0)
    BackgroundImage.BackgroundTransparency = 1
    BackgroundImage.Parent = MainContainer
    Instance.new("UICorner", BackgroundImage).CornerRadius = UDim.new(0, 10)

    local Overlay = Instance.new("Frame")
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 0.5
    Overlay.Parent = BackgroundImage
    Instance.new("UICorner", Overlay).CornerRadius = UDim.new(0, 10)

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(1, 0, 1, 0)
    MainFrame.BackgroundTransparency = 1
    MainFrame.Parent = BackgroundImage

    local Title = Instance.new("TextLabel")
    Title.Text = "Xenon Hub  |  Key System"
    Title.Size = UDim2.new(1, -20, 0, 30)
    Title.Position = UDim2.new(0, 10, 0, 8)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(255, 200, 100)
    Title.TextSize = 17
    Title.Font = Enum.Font.GothamBold
    Title.TextStrokeTransparency = 0.5
    Title.Parent = MainFrame

    local Step1Label = Instance.new("TextLabel")
    Step1Label.Text = "Step 1 : Press [Get Key] → Paste Link In Browser"
    Step1Label.Size = UDim2.new(1, -20, 0, 22)
    Step1Label.Position = UDim2.new(0, 10, 0, 45)
    Step1Label.BackgroundTransparency = 1
    Step1Label.TextColor3 = Color3.fromRGB(255, 200, 80)
    Step1Label.TextSize = 12
    Step1Label.Font = Enum.Font.GothamBold
    Step1Label.TextXAlignment = Enum.TextXAlignment.Left
    Step1Label.TextWrapped = true
    Step1Label.Parent = MainFrame

    local Step2Label = Instance.new("TextLabel")
    Step2Label.Text = "Step 2 : Complete Link4m → Get Key → Enter Key For Script"
    Step2Label.Size = UDim2.new(1, -20, 0, 22)
    Step2Label.Position = UDim2.new(0, 10, 0, 70)
    Step2Label.BackgroundTransparency = 1
    Step2Label.TextColor3 = Color3.fromRGB(255, 200, 80)
    Step2Label.TextSize = 12
    Step2Label.Font = Enum.Font.GothamBold
    Step2Label.TextXAlignment = Enum.TextXAlignment.Left
    Step2Label.TextWrapped = true
    Step2Label.Parent = MainFrame

    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, -20, 0, 1)
    Divider.Position = UDim2.new(0, 10, 0, 100)
    Divider.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    Divider.BackgroundTransparency = 0.6
    Divider.BorderSizePixel = 0
    Divider.Parent = MainFrame

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Text = "Status : Waiting for key..."
    StatusLabel.Size = UDim2.new(1, -20, 0, 22)
    StatusLabel.Position = UDim2.new(0, 10, 0, 108)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusLabel.TextSize = 12
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = MainFrame

    local InputBox = Instance.new("TextBox")
    InputBox.PlaceholderText = "Enter your key here..."
    InputBox.Text = ""
    InputBox.ClearTextOnFocus = false
    InputBox.Size = UDim2.new(0, 340, 0, 35)
    InputBox.Position = UDim2.new(0.5, -170, 0, 140)
    InputBox.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    InputBox.BackgroundTransparency = 0.4
    InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    InputBox.Font = Enum.Font.GothamMedium
    InputBox.TextSize = 13
    InputBox.Parent = MainFrame
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 6)
    local inputStroke = Instance.new("UIStroke", InputBox)
    inputStroke.Color = Color3.fromRGB(255, 140, 0)
    inputStroke.Thickness = 1.5

    local ButtonHolder = Instance.new("Frame")
    ButtonHolder.Size = UDim2.new(0, 340, 0, 40)
    ButtonHolder.Position = UDim2.new(0.5, -170, 0, 188)
    ButtonHolder.BackgroundTransparency = 1
    ButtonHolder.Parent = MainFrame

    local Layout = Instance.new("UIListLayout")
    Layout.FillDirection = Enum.FillDirection.Horizontal
    Layout.Padding = UDim.new(0, 15)
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Layout.Parent = ButtonHolder

    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Text = "🔑  Get Key"
    GetKeyBtn.Size = UDim2.new(0, 155, 1, 0)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    GetKeyBtn.BackgroundTransparency = 0.3
    GetKeyBtn.TextColor3 = Color3.fromRGB(255, 200, 100)
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.TextSize = 13
    GetKeyBtn.Parent = ButtonHolder
    Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 6)
    local btnStroke1 = Instance.new("UIStroke", GetKeyBtn)
    btnStroke1.Color = Color3.fromRGB(255, 140, 0)
    btnStroke1.Thickness = 1.5

    local VerifyBtn = Instance.new("TextButton")
    VerifyBtn.Text = "✅  Verify Key"
    VerifyBtn.Size = UDim2.new(0, 155, 1, 0)
    VerifyBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    VerifyBtn.BackgroundTransparency = 0.2
    VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    VerifyBtn.Font = Enum.Font.GothamBold
    VerifyBtn.TextSize = 13
    VerifyBtn.Parent = ButtonHolder
    Instance.new("UICorner", VerifyBtn).CornerRadius = UDim.new(0, 6)
    local btnStroke2 = Instance.new("UIStroke", VerifyBtn)
    btnStroke2.Color = Color3.fromRGB(255, 200, 100)
    btnStroke2.Thickness = 1.5

    local MessageLabel = Instance.new("TextLabel")
    MessageLabel.Text = "Press [Get Key] to start!"
    MessageLabel.Size = UDim2.new(1, -20, 0, 25)
    MessageLabel.Position = UDim2.new(0, 10, 0, 248)
    MessageLabel.BackgroundTransparency = 1
    MessageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    MessageLabel.TextSize = 11
    MessageLabel.Font = Enum.Font.Gotham
    MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
    MessageLabel.TextWrapped = true
    MessageLabel.Parent = MainFrame

    GetKeyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(GET_KEY_URL)
            StatusLabel.Text = "Status : Link copied! Paste in browser."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
            MessageLabel.Text = "✅ Link copied! Open browser and paste it."
            MessageLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
            task.spawn(function()
                showNotify("Xenon Hub", "Link copied! Paste in browser.", GET_KEY_URL, 4)
            end)
            task.wait(2)
            StatusLabel.Text = "Status : Waiting for key..."
            StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            MessageLabel.Text = "After getting key, paste it above & verify."
            MessageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        else
            MessageLabel.Text = GET_KEY_URL
            MessageLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
    end)

    VerifyBtn.MouseButton1Click:Connect(function()
        local key = InputBox.Text
        if key == "" then
            MessageLabel.Text = "❌ Key cannot be empty!"
            MessageLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end

        VerifyBtn.Text = "Checking..."
        VerifyBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
        StatusLabel.Text = "Status : Verifying key..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
        MessageLabel.Text = "Please wait..."
        MessageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)

        local success, msg = validateKey(key, hwid)

        if success then
            saveKey(key, hwid)
            -- ✅ Hiển thị thời gian còn lại từ server
            StatusLabel.Text = "Status : Key Active — Time Left: " .. msg
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            MessageLabel.Text = "✅ Key verified! Loading script..."
            MessageLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
            task.spawn(function()
                showNotify("Xenon Hub", "✅ Key verified! " .. msg .. " remaining", nil, 3)
            end)
            task.wait(1)
            gui:Destroy()
            runMainScript()
        else
            StatusLabel.Text = "Status : Verification failed!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            MessageLabel.Text = "❌ Error: " .. msg
            MessageLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            VerifyBtn.Text = "✅  Verify Key"
            VerifyBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
            task.spawn(function()
                showNotify("Xenon Hub", "❌ " .. msg, nil, 3)
            end)
        end
    end)
end

-- ==================== STARTUP ====================
local HWID = getHWID()
local savedKey = loadKey(HWID)

if savedKey then
    local ok, msg = validateKey(savedKey, HWID)
    if ok then
        task.spawn(function()
            showNotify("Xenon Hub", "Welcome back! Time left: " .. msg, nil, 3)
        end)
        task.wait(0.5)
        runMainScript()
    else
        clearKey()
        task.spawn(function()
            showNotify("Xenon Hub", "Key expired! Please get a new key.", nil, 4)
        end)
        task.wait(1)
        createUI(HWID)
    end
else
    createUI(HWID)
end
