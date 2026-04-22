-- Dexter Mobile - Ultimate Debugging Suite Injector
-- Theme: Zinc-950, Emerald Accent, RobotoMono Font
-- Features: Net Spy, Audit Scanner, Quick Save .rbxm (Mobile Grid Edition)

local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")

-- Fallback UI Mount safely
local gethui = gethui or function() return CoreGui end
local guiParent = pcall(gethui) and gethui() or CoreGui

--------------------------------------------------------------------------------
-- 1. Helper: UI Builder for Custom Content Panels (Zinc-950)
--------------------------------------------------------------------------------
local function CreateMobilePanel(name)
    local Panel = Instance.new("Frame")
    Panel.Name = "Dexter_" .. string.gsub(name, " ", "") .. "Panel"
    Panel.Size = UDim2.new(1, 0, 1, 0)
    Panel.Position = UDim2.new(0, 0, 0, 0)
    Panel.BackgroundColor3 = Color3.fromRGB(9, 9, 11) -- Zinc-950
    Panel.BorderSizePixel = 0
    Panel.Visible = false
    Panel.ZIndex = 100

    -- Top Navigation Bar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 45)
    TopBar.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Panel

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.Position = UDim2.new(0, 50, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = name:upper()
    Title.Font = Enum.Font.RobotoMono
    Title.TextSize = 18
    Title.TextColor3 = Color3.fromRGB(16, 185, 129) -- Emerald
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    local BackBtn = Instance.new("TextButton")
    BackBtn.Name = "BackButton"
    BackBtn.Size = UDim2.new(0, 45, 1, 0)
    BackBtn.BackgroundTransparency = 1
    BackBtn.Text = "X"
    BackBtn.Font = Enum.Font.RobotoMono
    BackBtn.TextSize = 22
    BackBtn.TextColor3 = Color3.fromRGB(248, 113, 113) -- Red for close/back
    BackBtn.Parent = TopBar

    -- Log Area
    local LogScroll = Instance.new("ScrollingFrame")
    LogScroll.Name = "LogScroll"
    LogScroll.Size = UDim2.new(1, -10, 1, -55)
    LogScroll.Position = UDim2.new(0, 5, 0, 50)
    LogScroll.BackgroundTransparency = 1
    LogScroll.BorderSizePixel = 0
    LogScroll.ScrollBarThickness = 4
    LogScroll.Parent = Panel

    local LogList = Instance.new("UIListLayout")
    LogList.SortOrder = Enum.SortOrder.LayoutOrder
    LogList.Padding = UDim.new(0, 4)
    LogList.Parent = LogScroll

    return Panel, BackBtn, LogScroll, LogList
end

local function AddLog(scrollFrame, listLayout, text, color)
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, 0, 0, 0)
    msg.AutomaticSize = Enum.AutomaticSize.Y
    msg.BackgroundTransparency = 1
    msg.Text = text
    msg.Font = Enum.Font.RobotoMono
    msg.TextSize = 13
    msg.TextColor3 = color or Color3.fromRGB(228, 228, 231)
    msg.TextWrapped = true
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.LayoutOrder = #scrollFrame:GetChildren()
    msg.Parent = scrollFrame

    task.defer(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
        scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.CanvasSize.Y.Offset)
    end)
end

--------------------------------------------------------------------------------
-- 2. Logic Implementation
--------------------------------------------------------------------------------

-- A. Net Spy Setup
local NetSpyPanel, NetSpyBack, NetSpyScroll, NetSpyList = CreateMobilePanel("Network Spy")
local netSpyEnabled = false
local oldNamecall

local NetSpyToggle = Instance.new("TextButton")
NetSpyToggle.Size = UDim2.new(0, 80, 0, 26)
NetSpyToggle.Position = UDim2.new(1, -90, 0.5, -13)
NetSpyToggle.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
NetSpyToggle.TextColor3 = Color3.fromRGB(9, 9, 11)
NetSpyToggle.Font = Enum.Font.RobotoMono
NetSpyToggle.TextSize = 13
NetSpyToggle.Text = "START"
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 4)
uiCorner.Parent = NetSpyToggle
NetSpyToggle.Parent = NetSpyPanel.TopBar

NetSpyToggle.MouseButton1Click:Connect(function()
    netSpyEnabled = not netSpyEnabled
    NetSpyToggle.Text = netSpyEnabled and "STOP" or "START"
    NetSpyToggle.BackgroundColor3 = netSpyEnabled and Color3.fromRGB(248, 113, 113) or Color3.fromRGB(16, 185, 129)
    AddLog(NetSpyScroll, NetSpyList, netSpyEnabled and "[INFO] Net Spy Started. Listening..." or "[INFO] Net Spy Stopped.", Color3.fromRGB(16, 185, 129))
end)

oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    -- Anti-Bait: Confirm the self argument is actually an Instance
    if typeof(self) ~= "Instance" then
        return oldNamecall(self, ...)
    end

    local method = getnamecallmethod()
    
    if netSpyEnabled and not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
        -- Safe Property Check: Avoid Indexing errors on trapped/tampered instances
        local success, instName = pcall(function() return self.Name end)
        if not success then instName = "ProtectedInstance" end

        local args = {...}
        local typeStr = {}
        for _, v in ipairs(args) do table.insert(typeStr, typeof(v)) end
        
        local trace = string.format("[SPY] %s -> %s | Args: [%s]", method, tostring(instName), table.concat(typeStr, ", "))
        
        task.spawn(AddLog, NetSpyScroll, NetSpyList, trace, Color3.fromRGB(56, 189, 248))
    end
    
    return oldNamecall(self, ...)
end))

-- B. Audit Scanner Setup
local AuditPanel, AuditBack, AuditScroll, AuditList = CreateMobilePanel("Audit Scanner")
local AuditAction = NetSpyToggle:Clone()
AuditAction.Text = "SCAN NOW"
AuditAction.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
AuditAction.Parent = AuditPanel.TopBar

local function ScanHierarchy(target)
    AddLog(AuditScroll, AuditList, "[INFO] Starting deep recursive scan on Workspace...", Color3.fromRGB(250, 204, 21))
    local count = 0
    local issues = 0
    
    for i, child in ipairs(target:GetDescendants()) do
        if i % 150 == 0 then task.wait() end
        count = count + 1
        
        -- Hidden LocalScript detection
        if child:IsA("LocalScript") then
            local plrMatch = game.Players.LocalPlayer and child:IsDescendantOf(game.Players.LocalPlayer)
            local starterMatch = child:IsDescendantOf(game:GetService("StarterPlayer")) or child:IsDescendantOf(game:GetService("StarterGui")) or child:IsDescendantOf(game:GetService("StarterPack"))
            if not (plrMatch or starterMatch) then
                AddLog(AuditScroll, AuditList, "[!] Hidden LocalScript found: " .. child:GetFullName(), Color3.fromRGB(248, 113, 113))
                issues = issues + 1
            end
        end
        
        -- Suspicious Remote detection
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            if not child:IsDescendantOf(ReplicatedStorage) then
                AddLog(AuditScroll, AuditList, "[!] Suspicious Remote found: " .. child:GetFullName(), Color3.fromRGB(251, 146, 60))
                issues = issues + 1
            end
        end
        
        -- Invalid Asset detection
        pcall(function()
            local tex = (child:IsA("Decal") and child.Texture) or (child:IsA("Texture") and child.Texture) or (child:IsA("ImageLabel") and child.Image) or (child:IsA("ImageButton") and child.Image) or ""
            if tex:match("rbxassetid://0") then
                AddLog(AuditScroll, AuditList, "[!] Invalid Image ID: " .. child:GetFullName(), Color3.fromRGB(167, 139, 250))
                issues = issues + 1
            elseif child:IsA("Sound") and (child.SoundId or ""):match("rbxassetid://0") then
                AddLog(AuditScroll, AuditList, "[!] Invalid Sound ID: " .. child:GetFullName(), Color3.fromRGB(167, 139, 250))
                issues = issues + 1
            end
        end)
    end
    AddLog(AuditScroll, AuditList, string.format("[OK] Scan complete. %d instances checked, %d issues found.", count, issues), Color3.fromRGB(16, 185, 129))
end

local auditRunning = false
AuditAction.MouseButton1Click:Connect(function()
    if auditRunning then return end
    auditRunning = true
    task.spawn(function()
        ScanHierarchy(workspace)
        auditRunning = false
    end)
end)

--------------------------------------------------------------------------------
-- 3. Core Injection Logic (Mobile Grid Menu Hijack & Context Menu)
--------------------------------------------------------------------------------
local function InjectQuickSave(contextMenu, mainGui)
    if contextMenu:FindFirstChild("DexterQuickSaveBtn") then return end
    
    -- Find template to clone for context menu buttons
    local templateFn = nil
    for _, v in ipairs(contextMenu:GetChildren()) do
        if v:IsA("TextButton") then templateFn = v; break end
    end
    
    local btn = templateFn and templateFn:Clone() or Instance.new("TextButton")
    btn.Name = "DexterQuickSaveBtn"
    btn.Text = "  Save .rbxm (Isolate)"
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = Color3.fromRGB(16, 185, 129)
    btn.Font = Enum.Font.RobotoMono
    
    -- Stripping specific icons if cloned
    if btn:FindFirstChild("Icon") then btn.Icon:Destroy() end
    
    btn.MouseButton1Click:Connect(function()
        local targetInstance = nil
        
        -- Try Dex selection mechanism
        local listContainers = {mainGui:FindFirstChild("List", true), mainGui:FindFirstChild("ExplorerList", true)}
        for _, list in ipairs(listContainers) do
            if list then
                for _, row in ipairs(list:GetChildren()) do
                    -- Check for hover/highlighted backgrounds common in Dex Mobile
                    if row:IsA("Frame") and (row.BackgroundTransparency == 0 or row.BackgroundColor3 == Color3.fromRGB(11, 90, 175) or row.BackgroundColor3.B > 0.5) then
                        local obj = row:FindFirstChild("Obj")
                        if obj and obj:IsA("ObjectValue") then targetInstance = obj.Value; break end
                    end
                end
            end
            if targetInstance then break end
        end
        
        -- Fallback
        if not targetInstance then 
            local sel = Selection:Get()
            targetInstance = sel and sel[1]
        end
        
        if targetInstance then
            local s, e = pcall(function()
                saveinstance({Object = targetInstance, FileName = targetInstance.Name, mode = "rbxm", Isolate = true})
            end)
            if s then print("[Dexter QuickSave] Success: " .. targetInstance.Name .. ".rbxm") else warn("[Dexter QuickSave] Error: ", e) end
        else
            warn("[Dexter QuickSave] Target instance not found.")
        end
        contextMenu.Visible = false
    end)
    
    btn.Parent = contextMenu
    
    -- Rescale
    local uiList = contextMenu:FindFirstChildOfClass("UIListLayout")
    if uiList then
        task.defer(function() contextMenu.Size = UDim2.new(contextMenu.Size.X.Scale, contextMenu.Size.X.Offset, 0, uiList.AbsoluteContentSize.Y) end)
    end
end

local function ProcessDexterUI(gui)
    if gui:GetAttribute("DexterMobileInjected") then return end
    gui:SetAttribute("DexterMobileInjected", true)
    
    -- Find Grid Container based on UIGridLayout
    local gridLayout = gui:FindFirstChildOfClass("UIGridLayout", true)
    if not gridLayout then return end
    
    local gridMenu = gridLayout.Parent
    local mainAppFrame = gridMenu.Parent
    local templateBtn = nil
    
    -- Identify a standard button in the Grid to clone
    for _, child in ipairs(gridMenu:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("ImageButton") then
            if child.Name:match("Console") or child.Name:match("Explorer") or child.Name:match("Settings") then
                templateBtn = child
                break
            end
        end
    end
    
    if not templateBtn then templateBtn = gridMenu:FindFirstChildWhichIsA("TextButton") or gridMenu:FindFirstChildWhichIsA("ImageButton") end
    if not templateBtn then return end

    -- 1. Mount custom panels natively to main frame
    NetSpyPanel.Parent = mainAppFrame
    AuditPanel.Parent = mainAppFrame

    -- 2. Link Back Buttons to show Grid
    NetSpyBack.MouseButton1Click:Connect(function()
        NetSpyPanel.Visible = false
        gridMenu.Visible = true
    end)
    AuditBack.MouseButton1Click:Connect(function()
        AuditPanel.Visible = false
        gridMenu.Visible = true
    end)

    -- 3. Grid Toggles Maker
    local function AddGridApp(name, targetPanel)
        local icon = templateBtn:Clone()
        icon.Name = "DexterApp_" .. string.gsub(name, " ", "")
        
        -- Patch labeling
        local textLabel = icon:IsA("TextLabel") and icon or icon:FindFirstChildOfClass("TextLabel", true)
        if textLabel then textLabel.Text = name end
        if icon:IsA("TextButton") then icon.Text = (textLabel == nil) and name or "" end
        
        -- Clear cloned redundant icon image
        local img = icon:FindFirstChildOfClass("ImageLabel", true)
        if img then img.Image = "" end
        
        -- Dynamic hooking for TextButton/ImageButton
        local clickEvent = icon:IsA("TextButton") and icon.MouseButton1Click or icon:IsA("ImageButton") and icon.MouseButton1Click
        if clickEvent then
            clickEvent:Connect(function()
                -- Hide menu and any other potentially open windows inside the main frame
                gridMenu.Visible = false
                for _, v in ipairs(mainAppFrame:GetChildren()) do
                    if v:IsA("Frame") and v ~= targetPanel and v ~= NetSpyPanel and v ~= AuditPanel then
                        pcall(function() v.Visible = false end)
                    end
                end
                
                targetPanel.Visible = true
            end)
        end
        icon.Parent = gridMenu
    end

    -- Insert into grid
    AddGridApp("Net Spy", NetSpyPanel)
    AddGridApp("Audit", AuditPanel)
    
    -- 4. Hook Context Menus dynamically for Quick Save .rbxm
    gui.DescendantAdded:Connect(function(desc)
        if desc:IsA("Frame") and (desc.Name:lower():match("rightclick") or desc.Name:lower():match("context")) then
            task.wait(0.1)
            InjectQuickSave(desc, gui)
        end
    end)
    for _, desc in ipairs(gui:GetDescendants()) do
        if desc:IsA("Frame") and (desc.Name:lower():match("rightclick") or desc.Name:lower():match("context")) then
            InjectQuickSave(desc, gui)
        end
    end
end

-- Persistent Watcher specifically for Mobile Grid
task.spawn(function()
    while task.wait(1) do
        for _, gui in ipairs(guiParent:GetChildren()) do
            -- Target UI with UIGridLayout implying Dexter Mobile Dashboard
            if gui:IsA("ScreenGui") and (gui.Name:lower():match("dex") or gui.Name:lower():match("dexter")) then
                if gui:FindFirstChildOfClass("UIGridLayout", true) then
                    ProcessDexterUI(gui)
                end
            end
        end
    end
end)
