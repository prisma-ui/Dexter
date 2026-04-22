-- Ultimate Debugging Suite NATIVE Injector for Dex
-- Theme: Seamless Dex Integration + Zinc-950/Emerald Content
-- Features: Net Spy, Audit Scanner, Quick Save .rbxm

local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")

-- Fallback securely
local guiParent = pcall(gethui) and gethui() or (syn and syn.protect_gui and CoreGui or CoreGui)

--------------------------------------------------------------------------------
-- 1. Helper: UI Builder for Content Panels
--------------------------------------------------------------------------------
local function CreateLogPanel(name)
    local CustomPanel = Instance.new("Frame")
    CustomPanel.Name = name
    CustomPanel.Size = UDim2.new(1, 0, 1, -22) -- Standard Dex content size (leaves space for Topbar)
    CustomPanel.Position = UDim2.new(0, 0, 0, 22)
    CustomPanel.BackgroundColor3 = Color3.fromRGB(9, 9, 11) -- Zinc-950
    CustomPanel.BorderSizePixel = 0
    CustomPanel.Visible = false
    CustomPanel.ZIndex = 5

    -- Top Control Bar inside Panel
    local ControlBar = Instance.new("Frame")
    ControlBar.Size = UDim2.new(1, 0, 0, 30)
    ControlBar.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
    ControlBar.BorderSizePixel = 0
    ControlBar.Parent = CustomPanel

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(0.5, 0, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Font = Enum.Font.Code
    TitleLabel.TextSize = 14
    TitleLabel.TextColor3 = Color3.fromRGB(16, 185, 129)
    TitleLabel.Text = name:upper() .. " OUTPUT"
    TitleLabel.Parent = ControlBar

    -- Log Scrolling Frame
    local LogScroll = Instance.new("ScrollingFrame")
    LogScroll.Name = "LogScroll"
    LogScroll.Size = UDim2.new(1, -10, 1, -40)
    LogScroll.Position = UDim2.new(0, 5, 0, 35)
    LogScroll.BackgroundTransparency = 1
    LogScroll.BorderSizePixel = 0
    LogScroll.ScrollBarThickness = 4
    LogScroll.Parent = CustomPanel

    local LogList = Instance.new("UIListLayout")
    LogList.SortOrder = Enum.SortOrder.LayoutOrder
    LogList.Padding = UDim.new(0, 2)
    LogList.Parent = LogScroll
    
    return CustomPanel, ControlBar, LogScroll, LogList
end

local function addLog(scrollFrame, listLayout, text, color)
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, 0, 0, 16)
    msg.BackgroundTransparency = 1
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.Font = Enum.Font.Code
    msg.TextSize = 12
    msg.Text = text
    msg.TextColor3 = color or Color3.fromRGB(228, 228, 231)
    msg.TextWrapped = true
    msg.LayoutOrder = #scrollFrame:GetChildren()
    msg.Parent = scrollFrame
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.CanvasSize.Y.Offset)
end

--------------------------------------------------------------------------------
-- 2. Core Injection Logic
--------------------------------------------------------------------------------
local function InjectIntoDex(dexGui)
    if dexGui:GetAttribute("UltimateInjectorHookedNative") then return end
    dexGui:SetAttribute("UltimateInjectorHookedNative", true)
    
    local topMenuBar = dexGui:FindFirstChild("TopBar", true) 
                        or dexGui:FindFirstChild("Header", true) 
                        or dexGui:FindFirstChild("Menu", true)

    local mainContainer = dexGui:FindFirstChild("MainFrame", true) 
                           or dexGui:FindFirstChild("Background", true) 
                           or (topMenuBar and topMenuBar.Parent)

    if not topMenuBar or not mainContainer then
        warn("[Ultimate Dex] Could not find Dex TopBar or MainContainer.")
        return
    end

    -- Attempt to find an existing button to clone for aesthetics
    local templateBtn = nil
    for _, child in ipairs(topMenuBar:GetDescendants()) do
        if child:IsA("TextButton") and (child.Name == "Explorer" or child.Name == "Console" or child.Name == "Properties") then
            templateBtn = child
            break
        end
    end

    if not templateBtn then
        warn("[Ultimate Dex] Could not find a template button to clone.")
        return
    end

    ----------------------------------------------------------------------------
    -- A. CREATE CUSTOM PANELS
    ----------------------------------------------------------------------------
    local NetSpyPanel, NetSpyControls, NetSpyScroll, NetSpyList = CreateLogPanel("Network Spy")
    NetSpyPanel.Parent = mainContainer

    local AuditPanel, AuditControls, AuditScroll, AuditList = CreateLogPanel("Audit Scanner")
    AuditPanel.Parent = mainContainer

    -- Net Spy Toggle Button inside Panel
    local SpyToggleBtn = Instance.new("TextButton")
    SpyToggleBtn.Size = UDim2.new(0, 120, 0, 20)
    SpyToggleBtn.Position = UDim2.new(1, -130, 0.5, -10)
    SpyToggleBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
    SpyToggleBtn.TextColor3 = Color3.fromRGB(228, 228, 231)
    SpyToggleBtn.Font = Enum.Font.Code
    SpyToggleBtn.TextSize = 12
    SpyToggleBtn.Text = "Toggle Logging"
    SpyToggleBtn.Parent = NetSpyControls
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(16, 185, 129)
    stroke.Thickness = 1
    stroke.Parent = SpyToggleBtn

    -- Audit Run Button inside Panel
    local AuditRunBtn = SpyToggleBtn:Clone()
    AuditRunBtn.Text = "Run Audit Now"
    AuditRunBtn.Parent = AuditControls

    ----------------------------------------------------------------------------
    -- B. CLONE & INJECT TOP BAR TABS
    ----------------------------------------------------------------------------
    -- A table to hold references to all "panels" mapped to their tab buttons
    -- We assume Dex native panels are things like "ExplorerPanel", "PropertiesFrame"
    local allPanels = {
        NetSpy = NetSpyPanel,
        Audit = AuditPanel
    }

    -- Gather native panels dynamically by looking at native tabs
    for _, btn in ipairs(topMenuBar:GetChildren()) do
        if btn:IsA("TextButton") then
            -- Dex usually toggles visibility of a frame named similar to the button
            btn.MouseButton1Click:Connect(function()
                -- If a native tab is clicked, hide OUR custom panels
                NetSpyPanel.Visible = false
                AuditPanel.Visible = false
                
                -- Attempt to visually 'deselect' our custom tabs (Dex native styling revert)
                local btnContainer = topMenuBar:FindFirstChild("InjectedTabsContainer") 
                if btnContainer then
                    for _, cBtn in ipairs(btnContainer:GetChildren()) do
                        if cBtn:IsA("TextButton") then
                            cBtn.BackgroundTransparency = templateBtn.BackgroundTransparency
                            cBtn.BackgroundColor3 = templateBtn.BackgroundColor3
                        end
                    end
                end
            end)
        end
    end

    -- Create a container snippet for our tabs to sit nicely in the Topbar Layout
    local InjectedTabsContainer = Instance.new("Frame")
    InjectedTabsContainer.Name = "InjectedTabsContainer"
    InjectedTabsContainer.BackgroundTransparency = 1
    InjectedTabsContainer.Size = UDim2.new(0, 200, 1, 0)
    
    local uiListTB = Instance.new("UIListLayout")
    uiListTB.FillDirection = Enum.FillDirection.Horizontal
    uiListTB.SortOrder = Enum.SortOrder.LayoutOrder
    uiListTB.Parent = InjectedTabsContainer
    InjectedTabsContainer.Parent = topMenuBar

    local function InjectNavTab(tabName, targetPanel)
        local newTab = templateBtn:Clone()
        newTab.Name = tabName .. "_Btn"
        newTab.Text = " " .. tabName .. " "
        
        -- Override resizing logic if template has constrains
        newTab.Size = UDim2.new(0, newTab.TextBounds.X + 20, 1, 0)
        
        newTab.MouseButton1Click:Connect(function()
            -- 1. Hide EVERYTHING in main container
            for _, child in ipairs(mainContainer:GetChildren()) do
                if child:IsA("Frame") or child:IsA("ScrollingFrame") then
                    -- Safely hide native panels if they are currently visible
                    -- Wait, hiding literal everything might break Dex topbar if TopBar is inside MainContainer. 
                    -- Let's only hide known panels or objects that take up the content area.
                    if child.Name:match("Panel") or child.Name:match("Viewer") or child.Name:match("Properties") then
                        child.Visible = false
                    end
                end
            end
            
            -- Explicitly hide our custom panels
            NetSpyPanel.Visible = false
            AuditPanel.Visible = false

            -- 2. Show TARGET panel
            targetPanel.Visible = true

            -- 3. Visual feedback for selection
            for _, tb in ipairs(InjectedTabsContainer:GetChildren()) do
                if tb:IsA("TextButton") then
                    tb.BackgroundTransparency = templateBtn.BackgroundTransparency
                    tb.BackgroundColor3 = templateBtn.BackgroundColor3
                end
            end
            newTab.BackgroundTransparency = 0
            newTab.BackgroundColor3 = Color3.fromRGB(16, 185, 129) -- Emerald Highlighting
        end)
        
        newTab.Parent = InjectedTabsContainer
        
        -- Re-adjust container size to fix alignment
        task.defer(function()
            InjectedTabsContainer.Size = UDim2.new(0, uiListTB.AbsoluteContentSize.X, 1, 0)
        end)
    end

    InjectNavTab("Net Spy", NetSpyPanel)
    InjectNavTab("Audit", AuditPanel)

    ----------------------------------------------------------------------------
    -- C. LOGIC: NETWORK SPY
    ----------------------------------------------------------------------------
    local netSpyEnabled = false
    local oldNamecall

    SpyToggleBtn.MouseButton1Click:Connect(function()
        netSpyEnabled = not netSpyEnabled
        SpyToggleBtn.BackgroundColor3 = netSpyEnabled and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(24, 24, 27)
        SpyToggleBtn.TextColor3 = netSpyEnabled and Color3.fromRGB(9, 9, 11) or Color3.fromRGB(228, 228, 231)
        if netSpyEnabled then addLog(NetSpyScroll, NetSpyList, "[INFO] Net Spy Activated.", Color3.fromRGB(16, 185, 129)) end
    end)

    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if netSpyEnabled and not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
            local args = {...}
            local argTypes = {}
            for _, v in ipairs(args) do table.insert(argTypes, typeof(v)) end
            local typeStr = #argTypes > 0 and table.concat(argTypes, ", ") or "None"
            local debugMsg = string.format("[SPY] %s -> %s | Args: [%s]", method, tostring(self.Name), typeStr)
            
            task.spawn(function()
                addLog(NetSpyScroll, NetSpyList, debugMsg, Color3.fromRGB(56, 189, 248))
            end)
        end
        return oldNamecall(self, ...)
    end)

    ----------------------------------------------------------------------------
    -- D. LOGIC: AUDIT SCANNER
    ----------------------------------------------------------------------------
    local auditRunning = false
    AuditRunBtn.MouseButton1Click:Connect(function()
        if auditRunning then return end
        auditRunning = true
        addLog(AuditScroll, AuditList, "[INFO] Starting Deep Workspace Audit...", Color3.fromRGB(250, 204, 21))
        
        task.spawn(function()
            local descendants = workspace:GetDescendants()
            local total, issues = 0, 0
            
            for i, child in ipairs(descendants) do
                if i % 250 == 0 then task.wait() end
                total = total + 1
                
                if child:IsA("LuaSourceContainer") then
                    addLog(AuditScroll, AuditList, "[!] Hidden Script: " .. child:GetFullName(), Color3.fromRGB(248, 113, 113))
                    issues = issues + 1
                end
                if (child:IsA("RemoteEvent") or child:IsA("RemoteFunction")) and not child:IsDescendantOf(ReplicatedStorage) then
                    addLog(AuditScroll, AuditList, "[!] Suspicious Remote: " .. child:GetFullName(), Color3.fromRGB(251, 146, 60))
                    issues = issues + 1
                end
                
                pcall(function()
                    if child:IsA("Decal") or child:IsA("Texture") or child:IsA("ImageLabel") or child:IsA("ImageButton") then
                        local tex = (child:IsA("Decal") and child.Texture) or (child:IsA("Texture") and child.Texture) or (child.Image) or ""
                        if string.match(tex, "rbxassetid://0") then
                            addLog(AuditScroll, AuditList, "[!] Invalid Texture ID: " .. child:GetFullName(), Color3.fromRGB(167, 139, 250))
                            issues = issues + 1
                        end
                    elseif child:IsA("Sound") and string.match(child.SoundId or "", "rbxassetid://0") then
                        addLog(AuditScroll, AuditList, "[!] Invalid Sound ID: " .. child:GetFullName(), Color3.fromRGB(167, 139, 250))
                        issues = issues + 1
                    end
                end)
            end
            
            addLog(AuditScroll, AuditList, string.format("[OK] Audit Complete. %d limits checked, %d issues found.", total, issues), Color3.fromRGB(16, 185, 129))
            auditRunning = false
        end)
    end)

    ----------------------------------------------------------------------------
    -- E. CONTEXT MENU QUICK SAVE INJECTION
    ----------------------------------------------------------------------------
    local function GetSelectedInstance()
        -- Attempt to read selection from Dex Selection logic / Native Selection
        local sel = Selection:Get()
        return sel and sel[1] or nil
    end

    local function InjectContextMenu(frame)
        if frame:FindFirstChild("QuickSaveNode") then return end
        
        -- Many Dex forks build the RightClick menu dynamically based on hovering.
        -- We'll try to find a template button in the context menu to clone to match styling
        local cmTemplate = nil
        for _, obj in ipairs(frame:GetChildren()) do
            if obj:IsA("TextButton") then cmTemplate = obj; break end
        end

        local btn = cmTemplate and cmTemplate:Clone() or Instance.new("TextButton")
        btn.Name = "QuickSaveNode"
        if not cmTemplate then
            -- Fallback styling
            btn.Size = UDim2.new(1, 0, 0, 22)
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.SourceSans
            btn.TextSize = 14
        end
        
        btn.Text = "  Quick Save .rbxm"
        if btn:FindFirstChild("Icon") then btn.Icon:Destroy() end -- Remove cloned icons
        
        btn.MouseButton1Click:Connect(function()
            local target = GetSelectedInstance()
            if not target then
                -- Try to find highlight in dex
                local list = mainContainer:FindFirstChild("List", true) or mainContainer:FindFirstChild("ExplorerList", true)
                if list then
                    for _, row in ipairs(list:GetChildren()) do
                        if row:IsA("Frame") and (row.BackgroundColor3 == Color3.fromRGB(11, 90, 175) or row.BackgroundTransparency == 0) then
                            local obj = row:FindFirstChild("Obj")
                            if obj and obj:IsA("ObjectValue") then target = obj.Value break end
                        end
                    end
                end
            end
            
            if target then
                pcall(function()
                    saveinstance({Object = target, FileName = target.Name, mode = "rbxm", Isolate = true})
                end)
                addLog(NetSpyScroll, NetSpyList, "[SAVE] Quick Saved: " .. target.Name .. ".rbxm", Color3.fromRGB(16, 185, 129))
            else
                addLog(NetSpyScroll, NetSpyList, "[ERR] Could not determine target for saving.", Color3.fromRGB(248, 113, 113))
            end
            
            frame.Visible = false
        end)
        
        btn.Parent = frame
        
        -- Adjust height of context menu container
        local uiList = frame:FindFirstChildOfClass("UIListLayout")
        if uiList then
            task.defer(function()
                frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, uiList.AbsoluteContentSize.Y)
            end)
        end
    end

    -- Hook Dex RightClick Menus
    dexGui.DescendantAdded:Connect(function(desc)
        if desc:IsA("Frame") and (desc.Name == "RightClick" or desc.Name == "ContextMenu" or desc.Name == "RightClickMenu") then
            task.wait(0.1)
            InjectContextMenu(desc)
        end
    end)
    -- Also check existing
    for _, desc in ipairs(dexGui:GetDescendants()) do
        if desc:IsA("Frame") and (desc.Name == "RightClick" or desc.Name == "ContextMenu" or desc.Name == "RightClickMenu") then
            InjectContextMenu(desc)
        end
    end

    print("[Ultimate Dex Injector] Native Integration Complete.")
end

--------------------------------------------------------------------------------
-- 3. Core Loop: Finding Dex 
--------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        for _, gui in ipairs(guiParent:GetChildren()) do
            if gui:IsA("ScreenGui") and (gui.Name:lower():match("dex") or gui:FindFirstChild("PropertiesFrame", true)) then
                InjectIntoDex(gui)
            end
        end
    end
end)
