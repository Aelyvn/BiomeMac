
-- Chlomy :3

local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

if CoreGui:FindFirstChild("SolsTrackerV5") then
    CoreGui:FindFirstChild("SolsTrackerV5"):Destroy()
end

local player = Players.LocalPlayer

-- Dữ liệu quét
local BIOME_KEYWORDS = {"NORMAL", "WINDY", "RAINY", "SNOWY", "SANDSTORM", "HELL", "STARFALL", "CORRUPTION", "GLITCHED", "DREAMSPACE", "CYBERSPACE", "SINGULARITY"}
local MERCHANT_NAMES = {"Mari", "Rin", "Jester"}

-- ==========================================
-- 1. GIAO DIỆN SỬ DỤNG (GUI)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SolsTrackerV5"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 260)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "🌤️ Sol's RNG Tracker V5"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local WebhookBox = Instance.new("TextBox")
WebhookBox.Size = UDim2.new(0, 310, 0, 35)
WebhookBox.Position = UDim2.new(0, 20, 0, 50)
WebhookBox.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
WebhookBox.TextColor3 = Color3.fromRGB(255, 255, 255)
WebhookBox.Text = "https://discord.com/api/webhooks/1487712046421250130/JhmxMX0rQ_zvkeWjZGjIHz2oaBDYTQeB4W67cU4oealPF4jm_XFtOu1w6AvFHUk_6w0U"
WebhookBox.TextSize = 10
WebhookBox.ClearTextOnFocus = false
WebhookBox.Parent = MainFrame
Instance.new("UICorner", WebhookBox).CornerRadius = UDim.new(0, 6)

local TestBtn = Instance.new("TextButton")
TestBtn.Size = UDim2.new(0, 310, 0, 35)
TestBtn.Position = UDim2.new(0, 20, 0, 95)
TestBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
TestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TestBtn.Text = "Kiểm Tra Webhook (Test)"
TestBtn.TextSize = 14
TestBtn.Font = Enum.Font.GothamSemibold
TestBtn.Parent = MainFrame
Instance.new("UICorner", TestBtn).CornerRadius = UDim.new(0, 6)

local BiomeStatus = Instance.new("TextLabel")
BiomeStatus.Size = UDim2.new(0, 310, 0, 20)
BiomeStatus.Position = UDim2.new(0, 20, 0, 140)
BiomeStatus.BackgroundTransparency = 1
BiomeStatus.Text = "🌍 Biome: Đang dừng ⏹️"
BiomeStatus.TextColor3 = Color3.fromRGB(180, 180, 180)
BiomeStatus.TextSize = 13
BiomeStatus.Font = Enum.Font.Gotham
BiomeStatus.TextXAlignment = Enum.TextXAlignment.Left
BiomeStatus.Parent = MainFrame

local MerchantStatus = Instance.new("TextLabel")
MerchantStatus.Size = UDim2.new(0, 310, 0, 20)
MerchantStatus.Position = UDim2.new(0, 20, 0, 165)
MerchantStatus.BackgroundTransparency = 1
MerchantStatus.Text = "🛒 NPC: Đang dừng ⏹️"
MerchantStatus.TextColor3 = Color3.fromRGB(180, 180, 180)
MerchantStatus.TextSize = 13
MerchantStatus.Font = Enum.Font.Gotham
MerchantStatus.TextXAlignment = Enum.TextXAlignment.Left
MerchantStatus.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 310, 0, 35)
ToggleBtn.Position = UDim2.new(0, 20, 0, 205)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "▶ Bắt Đầu Quét Toàn Diện"
ToggleBtn.TextSize = 14
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

-- Drag GUI
local UserInputService = game:GetService("UserInputService")
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
MainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ==========================================
-- 2. HÀM XỬ LÝ DỮ LIỆU
-- ==========================================
local isRunning = false
local currentBiome = ""
local activeMerchants = {}
local targetObject = nil
local targetProperty = ""

local function sendWebhook(url, title, description, color)
    if string.find(url, "discord.com") then url = string.gsub(url, "discord.com", "webhook.lewisakura.moe") end
    local data = {["embeds"] = {{["title"] = title, ["description"] = description, ["color"] = tonumber(color)}}}
    local jsonData = HttpService:JSONEncode(data)
    local httprequest = (syn and syn.request) or (http and http.request) or http_request or fluxus.request or request
    if httprequest then httprequest({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = jsonData}) return true end
    return false
end

TestBtn.MouseButton1Click:Connect(function()
    TestBtn.Text = "Đang gửi..."
    local success = sendWebhook(WebhookBox.Text, "🛠️ Test Webhook", "Biome & Merchant Tracker V5 hoạt động tốt!", 0x5865F2)
    TestBtn.Text = success and "✅ Thành công!" or "❌ Thất bại!"
    task.wait(2)
    TestBtn.Text = "Kiểm Tra Webhook (Test)"
end)

local function cleanAndCheckBiome(text)
    if not text or text == "" then return nil end
    local upperText = string.upper(text)
    for _, biome in ipairs(BIOME_KEYWORDS) do
        if string.find(upperText, biome) then return biome end
    end
    return nil
end

local function scanForBiomeTarget()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("StringValue") and (v.Name:lower() == "biome" or cleanAndCheckBiome(v.Value)) then return v, "Value" end
    end
    if player and player:FindFirstChild("PlayerGui") then
        for _, v in ipairs(player.PlayerGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Visible and cleanAndCheckBiome(v.Text) and #v.Text < 30 then return v, "Text" end
        end
    end
    return nil, nil
end

-- THUẬT TOÁN DEEP SCAN NPC MỚI
local function scanForMerchants()
    local found = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        -- 1. Quét Nút Tương Tác (ProximityPrompt - cái chữ E trong ảnh)
        if v:IsA("ProximityPrompt") then
            local textToCheck = (v.ObjectText or "") .. " " .. (v.ActionText or "")
            for _, name in ipairs(MERCHANT_NAMES) do
                if string.find(textToCheck, name) then found[name] = true end
            end
        end
        
        -- 2. Quét Chữ nổi trên đầu (BillboardGui)
        if v:IsA("TextLabel") and v:FindFirstAncestorWhichIsA("BillboardGui") then
            local txt = v.Text or ""
            for _, name in ipairs(MERCHANT_NAMES) do
                if string.find(txt, name) then found[name] = true end
            end
        end

        -- 3. Quét theo Tên Model (Dự phòng)
        if v:IsA("Model") and not Players:FindFirstChild(v.Name) then
            for _, name in ipairs(MERCHANT_NAMES) do
                if string.find(v.Name, name) then found[name] = true end
            end
        end
    end
    return found
end

-- ==========================================
-- 3. VÒNG LẶP XỬ LÝ CHÍNH
-- ==========================================
ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    
    if isRunning then
        ToggleBtn.Text = "⏹ Bấm Để Dừng Quét"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        BiomeStatus.Text = "🌍 Đang dò tìm vị trí Biome..."
        MerchantStatus.Text = "🛒 Đang theo dõi NPC..."
        
        task.spawn(function()
            while isRunning do
                -- XỬ LÝ BIOME
                if not targetObject or not targetObject:IsDescendantOf(game) then
                    targetObject, targetProperty = scanForBiomeTarget()
                end
                
                if targetObject then
                    local rawValue = targetObject[targetProperty]
                    local detectedBiome = cleanAndCheckBiome(rawValue)
                    if detectedBiome and detectedBiome ~= currentBiome then
                        currentBiome = detectedBiome
                        BiomeStatus.Text = "🌍 Biome hiện tại: " .. currentBiome
                        BiomeStatus.TextColor3 = Color3.fromRGB(46, 204, 113)
                        sendWebhook(WebhookBox.Text, "🌤️ Sol's RNG - Đổi Biome!", "Thời tiết vừa chuyển sang: **" .. currentBiome .. "**", 0xF1C40F)
                    end
                end

                -- XỬ LÝ NPC (DEEP SCAN)
                local currentlyFoundMerchants = scanForMerchants()
                
                -- Kiểm tra xem có NPC mới xuất hiện không
                for merchantName, _ in pairs(currentlyFoundMerchants) do
                    if not activeMerchants[merchantName] then
                        activeMerchants[merchantName] = true
                        sendWebhook(
                            WebhookBox.Text, 
                            "🎁 THƯƠNG NHÂN XUẤT HIỆN!", 
                            "NPC **" .. merchantName .. "** vừa xuất hiện trên bản đồ!\nVào game ngay!", 
                            0xE91E63
                        )
                    end
                end
                
                -- Kiểm tra xem NPC đã biến mất chưa
                for merchantName, _ in pairs(activeMerchants) do
                    if not currentlyFoundMerchants[merchantName] then
                        activeMerchants[merchantName] = nil
                    end
                end
                
                -- Cập nhật giao diện NPC
                local textUI = ""
                for name, _ in pairs(activeMerchants) do textUI = textUI .. name .. ", " end
                if textUI == "" then 
                    MerchantStatus.Text = "🛒 NPC: Không có ai trong map"
                    MerchantStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
                else
                    MerchantStatus.Text = "🛒 NPC Đang Có: " .. string.sub(textUI, 1, -3)
                    MerchantStatus.TextColor3 = Color3.fromRGB(233, 30, 99)
                end

                task.wait(2.5) -- Chu kỳ quét mỗi 2.5s để chống giật lag
            end
        end)
    else
        ToggleBtn.Text = "▶ Bắt Đầu Quét Toàn Diện"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        BiomeStatus.Text = "🌍 Biome: Đang dừng ⏹️"
        BiomeStatus.TextColor3 = Color3.fromRGB(180, 180, 180)
        MerchantStatus.Text = "🛒 NPC: Đang dừng ⏹️"
        MerchantStatus.TextColor3 = Color3.fromRGB(180, 180, 180)
        targetObject = nil
        currentBiome = ""
        activeMerchants = {}
    end
end)
