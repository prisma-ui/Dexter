-- Ultimate Debugging Suite Injector for Dex
-- Theme: Zinc-950, Emerald Accent
-- Features: Net Spy, Audit Scanner, Quick Save .rbxm

-- [1] INITIALIZATION & PROTECTION
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")

-- Fallback for UI Parent securely
local guiParent = nil
if gethui then
    guiParent = gethui()
elseif syn and syn.protect_gui then
    guiParent = CoreGui
else
    guiParent = CoreGui
end

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DexUltimateInjector"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
end
ScreenGui.Parent = guiParent

-- [2] UI CREATION (Zinc-950 & Emerald)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainPanel"
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(9, 9, 11) -- Zinc-950
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = " ULTIMATE DEBUGGING SUITE"
TitleLabel.TextColor3 = Color3.fromRGB(16, 185, 129) -- Emerald-500
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.Code
TitleLabel.TextSize = 14
TitleLabel.Parent = MainFrame

-- Draggable Logic
local dragging, dragInput, dragStart, startPos
TitleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
TitleLabel.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local ButtonContainer = Instance.new("Frame")
ButtonContainer.Size = UDim2.new(1, 0, 0, 40)
ButtonContainer.Position = UDim2.new(0, 0, 0, 30)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Parent = MainFrame

local function createButton(name, pos, text)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0.45, 0, 1, -10)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(24, 24, 27) -- Zinc-900
    btn.TextColor3 = Color3.fromRGB(16, 185, 129)
    btn.Font = Enum.Font.Code
    btn.TextSize = 14
    btn.Text = text
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(16, 185, 129)
    stroke.Thickness = 1
    stroke.Parent = btn
    
    btn.Parent = ButtonContainer
    return btn
end

local NetSpyBtn = createButton("NetSpyBtn", UDim2.new(0.033, 0, 0, 5), "Net Spy: OFF")
local AuditBtn = createButton("AuditBtn", UDim2.new(0.516, 0, 0, 5), "Run Audit")

local LogScroll = Instance.new("ScrollingFrame")
LogScroll.Size = UDim2.new(1, -20, 1, -80)
LogScroll.Position = UDim2.new(0, 10, 0, 70)
LogScroll.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
LogScroll.BorderSizePixel = 0
LogScroll.ScrollBarThickness = 4
LogScroll.Parent = MainFrame

local LogList = Instance.new("UIListLayout")
LogList.SortOrder = Enum.SortOrder.LayoutOrder
LogList.Padding = UDim.new(0, 2)
LogList.Parent = LogScroll

local UICornerScroll = Instance.new("UICorner")
UICornerScroll.CornerRadius = UDim.new(0, 4)
UICornerScroll.Parent = LogScroll

local LogPadding = Instance.new("UIPadding")
LogPadding.PaddingLeft = UDim.new(0, 5)
LogPadding.PaddingTop = UDim.new(0, 5)
LogPadding.Parent = LogScroll

-- [3] LOG SYSTEM
local logCount = 0
local function addLog(text, color)
    logCount = logCount + 1
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, 0, 0, 16)
    msg.BackgroundTransparency = 1
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.Font = Enum.Font.Code
    msg.TextSize = 12
    msg.Text = "[LOG] " .. text
    msg.TextColor3 = color or Color3.fromRGB(228, 228, 231) -- Zinc-200
    msg.TextWrapped = true
    msg.LayoutOrder = logCount
    msg.Parent = LogScroll
    
    LogScroll.CanvasSize = UDim2.new(0, 0, 0, LogList.AbsoluteContentSize.Y + 10)
    LogScroll.CanvasPosition = Vector2.new(0, LogScroll.CanvasSize.Y.Offset)
end

-- [4] NET SPY MODULE
local netSpyEnabled = false
local oldNamecall

NetSpyBtn.MouseButton1Click:Connect(function()
    netSpyEnabled = not netSpyEnabled
    NetSpyBtn.Text = netSpyEnabled and "Net Spy: ON" or "Net Spy: OFF"
    NetSpyBtn.BackgroundColor3 = netSpyEnabled and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(24, 24, 27)
    NetSpyBtn.TextColor3 = netSpyEnabled and Color3.fromRGB(9, 9, 11) or Color3.fromRGB(16, 185, 129)
    if netSpyEnabled then addLog("Net Spy Activated", Color3.fromRGB(16, 185, 129)) end
end)

oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    if netSpyEnabled and not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
        local args = {...}
        local argTypes = {}
        for _, v in ipairs(args) do
            table.insert(argTypes, typeof(v))
        end
        
        local typeStr = #argTypes > 0 and table.concat(argTypes, ", ") or "None"
        local debugMsg = string.format("%s called on %s | Args: %s", method, tostring(self.Name), typeStr)
        
        -- Use task.spawn to avoid yielding or crashing the __namecall thread
        task.spawn(function()
            addLog(debugMsg, Color3.fromRGB(56, 189, 248)) -- Light Blue
        end)
    end
    
    return oldNamecall(self, ...)
end)

-- [5] DEPENDENCY SCANNER (AUDIT)
local auditRunning = false

AuditBtn.MouseButton1Click:Connect(function()
    if auditRunning then return end
    auditRunning = true
    addLog("Starting Audit...", Color3.fromRGB(250, 204, 21)) -- Yellow
    
    task.spawn(function()
        local descendants = workspace:GetDescendants()
        local totalSearched = 0
        local issuesFound = 0
        
        for i, child in ipairs(descendants) do
            -- Stabilizer: Yield every 100 iterations
            if i % 100 == 0 then
                task.wait()
            end
            
            totalSearched = totalSearched + 1
            
            -- Detect Hidden Scripts
            if child:IsA("LuaSourceContainer") then
                addLog("Hidden Script: " .. child:GetFullName(), Color3.fromRGB(248, 113, 113)) -- Red
                issuesFound = issuesFound + 1
            end
            
            -- Detect Suspicious Remotes outside ReplicatedStorage
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                if not child:IsDescendantOf(ReplicatedStorage) then
                    addLog("Suspicious Remote: " .. child:GetFullName(), Color3.fromRGB(251, 146, 60)) -- Orange
                    issuesFound = issuesFound + 1
                end
            end
            
            -- Detect Invalid Asset IDs safely using pcall to avoid property errors
            pcall(function()
                if child:IsA("Decal") or child:IsA("Texture") or child:IsA("ImageLabel") or child:IsA("ImageButton") then
                    local tex = (child:IsA("Decal") and child.Texture) or (child:IsA("Texture") and child.Texture) or (child.Image) or ""
                    if string.match(tex, "rbxassetid://0") then
                        addLog("Invalid Asset ID: " .. child:GetFullName(), Color3.fromRGB(167, 139, 250)) -- Purple
                        issuesFound = issuesFound + 1
                    end
                elseif child:IsA("Sound") then
                    if string.match(child.SoundId or "", "rbxassetid://0") then
                        addLog("Invalid Sound ID: " .. child:GetFullName(), Color3.fromRGB(167, 139, 250))
                        issuesFound = issuesFound + 1
                    end
                end
            end)
        end
        
        addLog(string.format("Audit Complete. Searched %d objects. Found %d issues.", totalSearched, issuesFound), Color3.fromRGB(16, 185, 129))
        auditRunning = false
    end)
end)

-- [6] QUICK SAVE .RBXM (CONTEXT MENU INJECTOR)
local function QuickSaveInstance(target)
    if typeof(target) ~= "Instance" then return false, "Not an Instance" end
    
    local success, err = pcall(function()
        if saveinstance then
            saveinstance({
                Object = target,
                FileName = target.Name,
                mode = "rbxm",
                Isolate = true
            })
        else
            error("'saveinstance' function is not supported on this executor.")
        end
    end)
    
    return success, err
end

-- Helper: Try to extract the currently selected instance from Dex UI
local function GetSelectedInstanceFromDex(dexGui)
    -- Heuristic 1: Scan Dex UI for the highlighted row to grab the ObjectValue
    local lists = {dexGui:FindFirstChild("List", true), dexGui:FindFirstChild("ExplorerList", true)}
    for _, list in ipairs(lists) do
        if list then
            for _, row in ipairs(list:GetChildren()) do
                -- Dex rows usually have a BackgroundColor that changes when selected, or BackgroundTransparency
                if row:IsA("Frame") and (row.BackgroundColor3 == Color3.fromRGB(11, 90, 175) or row.BackgroundTransparency == 0) then
                    local objValue = row:FindFirstChild("Obj")
                    if objValue and objValue:IsA("ObjectValue") then
                        return objValue.Value
                    end
                end
            end
        end
    end
    
    -- Heuristic 2: Fallback to regular Studio Selection (If Dex syncs it)
    local sel = Selection:Get()
    if sel and #sel > 0 then
        return sel[1]
    end
    
    return nil
end

local function InjectContextMenu(frame)
    if frame:FindFirstChild("QuickSaveBtn") then return end -- Prevent double-inject
    
    local btn = Instance.new("TextButton")
    btn.Name = "QuickSaveBtn"
    btn.Size = UDim2.new(1, 0, 0, 22) -- Match standard Dex list element size
    btn.BackgroundColor3 = Color3.fromRGB(9, 9, 11)   -- Zinc-950
    btn.TextColor3 = Color3.fromRGB(228, 228, 231)    -- Zinc-200
    btn.Text = "  Quick Save .rbxm"
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = frame.ZIndex + 1
    
    -- Hover effects
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(16, 185, 129) -- Emerald hover
        btn.TextColor3 = Color3.fromRGB(9, 9, 11)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(9, 9, 11)
        btn.TextColor3 = Color3.fromRGB(228, 228, 231)
    end)
    
    btn.MouseButton1Click:Connect(function()
        local dexGui = frame:FindFirstAncestorOfClass("ScreenGui")
        local target = GetSelectedInstanceFromDex(dexGui)
        
        if target then
            local success, err = QuickSaveInstance(target)
            if success then
                addLog(string.format("Saved '%s.rbxm' successfully.", target.Name), Color3.fromRGB(16, 185, 129))
            else
                addLog(string.format("Save failed for '%s': %s", target.Name, tostring(err)), Color3.fromRGB(248, 113, 113))
            end
        else
            addLog("Quick Save Failed: Could not identify selected instance in Dex.", Color3.fromRGB(251, 146, 60))
        end
        
        frame.Visible = false -- Dismiss context menu after clicking
    end)
    
    btn.Parent = frame
    
    -- Adjust container size if UIListLayout is used by the Context Menu
    local uiList = frame:FindFirstChildOfClass("UIListLayout")
    if uiList then
        task.defer(function()
            -- Add arbitrary 24 pixels to accommodate the new button height + padding
            frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, uiList.AbsoluteContentSize.Y)
        end)
    end
end

-- Hook loops to find Dex and its dynamically spawned Right Click Menus
task.spawn(function()
    while task.wait(1) do
        for _, gui in ipairs(guiParent:GetChildren()) do
            -- Identify Dex (Usually named "Dex" or contains ExplorerPanel/PropertiesFrame)
            if gui:IsA("ScreenGui") and (string.find(string.lower(gui.Name), "dex") or gui:FindFirstChild("PropertiesFrame", true)) then
                
                -- Catch already open/existing ContextMenus
                for _, desc in ipairs(gui:GetDescendants()) do
                    if desc:IsA("Frame") and (desc.Name == "RightClick" or desc.Name == "ContextMenu" or desc.Name == "RightClickMenu") then
                        InjectContextMenu(desc)
                    end
                end
                
                -- Hook into Dex so we immediately inject when right click menu is spawned/made visible
                if not gui:GetAttribute("UltimateInjectorHooked") then
                    gui:SetAttribute("UltimateInjectorHooked", true)
                    gui.DescendantAdded:Connect(function(desc)
                        if desc:IsA("Frame") and (desc.Name == "RightClick" or desc.Name == "ContextMenu" or desc.Name == "RightClickMenu") then
                            -- Wait slightly for Dex to populate native buttons before we append ours
                            task.wait(0.1)
                            InjectContextMenu(desc)
                        end
                    end)
                end
            end
        end
    end
end)

addLog("Initialized Injector with Quick Save Context Option. Ready.", Color3.fromRGB(16, 185, 129))
