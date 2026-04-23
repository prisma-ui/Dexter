--[[  STUDIO THEME FINAL — Delta Executor  ]]

local CoreGui = game:GetService("CoreGui")
local Players  = game:GetService("Players")

pcall(function()
    local o = CoreGui:FindFirstChild("SL_THEME")
    if o then o:Destroy() end
end)

local root = Instance.new("Folder")
root.Name   = "SL_THEME"
root.Parent = CoreGui

local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 15)
local StudioGui = PlayerGui and PlayerGui:WaitForChild("StudioGui", 15)
if not StudioGui then warn("[SL Theme] StudioGui tidak ditemukan!"); return end

-- ═══════════════════════════════════════════════════════════
--  KEEP STUDIO GUI ALIVE — paksa StudioGui + semua child
--  tetap Visible & Enabled saat Play mode, tidak hilang
-- ═══════════════════════════════════════════════════════════

-- Daftar nama panel penting yang harus selalu visible
local KEEP_VISIBLE_NAMES = {
    "StudioGui", "Explorer", "Properties", "ExplorerPanel",
    "PropertiesPanel", "OutputPanel", "Output", "Toolbar",
    "TopBar", "MenuBar", "DockBottom", "DockLeft", "DockRight",
}
local keepSet = {}
for _, n in ipairs(KEEP_VISIBLE_NAMES) do keepSet[n:lower()] = true end

local function keepGuiVisible()
    -- StudioGui sendiri
    pcall(function()
        StudioGui.Enabled = true
    end)

    -- Semua child langsung StudioGui
    for _, obj in ipairs(StudioGui:GetChildren()) do
        pcall(function()
            if obj:IsA("ScreenGui") or obj:IsA("Frame") or obj:IsA("GuiBase2d") then
                obj.Enabled = true
            end
            if obj:IsA("GuiObject") then
                obj.Visible = true
            end
        end)
    end

    -- Semua descendant yang namanya termasuk panel penting
    for _, obj in ipairs(StudioGui:GetDescendants()) do
        pcall(function()
            local n = obj.Name:lower()
            if keepSet[n] then
                if obj:IsA("ScreenGui") then obj.Enabled = true end
                if obj:IsA("GuiObject") then obj.Visible = true end
            end
        end)
    end
end

-- Monitor Enabled/Visible — langsung restore kalau ada yang mati
local function watchGuiVisibility(obj)
    pcall(function()
        if obj:IsA("ScreenGui") then
            obj:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not obj.Enabled then
                    task.defer(function() pcall(function() obj.Enabled = true end) end)
                end
            end)
        end
        if obj:IsA("GuiObject") then
            obj:GetPropertyChangedSignal("Visible"):Connect(function()
                if not obj.Visible then
                    task.defer(function() pcall(function() obj.Visible = true end) end)
                end
            end)
        end
    end)
end

local function startGuiWatcher()
    -- Watch semua existing children
    for _, obj in ipairs(StudioGui:GetChildren()) do
        pcall(function() watchGuiVisibility(obj) end)
    end
    -- Watch children baru
    StudioGui.ChildAdded:Connect(function(child)
        task.defer(function()
            pcall(function()
                watchGuiVisibility(child)
                -- Pastikan langsung visible
                if child:IsA("ScreenGui") then child.Enabled = true end
                if child:IsA("GuiObject") then child.Visible = true end
            end)
        end)
    end)
    -- Extra: monitor RunService untuk deteksi transisi Play mode
    pcall(function()
        local RS = game:GetService("RunService")
        RS.Heartbeat:Connect(function()
            -- Hanya cek sekali tiap 2 detik via throttle
        end)
    end)
    -- Loop ringan: cek setiap 3 detik (bukan per-frame, tidak lag)
    task.spawn(function()
        while true do
            task.wait(3)
            pcall(keepGuiVisible)
        end
    end)
end

local C = {
    c0      = Color3.fromRGB(28,28,28),
    c1      = Color3.fromRGB(37,37,38),
    c2      = Color3.fromRGB(45,45,45),
    c3      = Color3.fromRGB(58,58,58),
    border  = Color3.fromRGB(65,65,65),
    white   = Color3.fromRGB(245,245,245),
    expSel  = Color3.fromRGB(30,80,160),
    expSelB = Color3.fromRGB(55,105,185),
    playRed = Color3.fromRGB(220,55,55),
}

local function br(c) return (c.R+c.G+c.B)/3 end
local function isBlue(c) return c.B>0.30 and c.B>(c.R+0.10) and c.B>(c.G+0.10) end

local function isPlayObj(obj)
    local n = obj.Name:lower()
    return n=="play" or n=="playbtn" or n=="playbutton" or (n:sub(1,4)=="play" and #n<=10)
end

local function addRounded(obj)
    if not obj:FindFirstChildOfClass("UICorner") then
        local uc=Instance.new("UICorner"); uc.CornerRadius=UDim.new(0,5); uc.Parent=obj
    end
    local st=obj:FindFirstChildOfClass("UIStroke")
    if not st then st=Instance.new("UIStroke"); st.Parent=obj end
    st.Color=C.expSelB; st.Thickness=1
end

local SKIP = {
    SL_TerrainBtn=true, TerrainIconDraw=true,
    TerrainLabel=true, TerrainClickBtn=true, TerrainBar=true,
    SL_IconOverlay=true, SL_IconLabel=true,
}

-- ─────────────────────────────────────────────────────────────
--  SVG ICONS dari HTML — dikonversi ke ImageLabel via DrawingAPI
--  Karena Roblox tidak support SVG, kita inject icon sebagai
--  custom drawn Frame dengan lines (sama seperti Terrain icon)
-- ─────────────────────────────────────────────────────────────

-- Icon definitions: name_lowercase → function(parent, size, color)
local ICON_DRAW = {}

local function drawBar(parent, x1,y1,x2,y2, thick, col, zi)
    local dx=x2-x1; local dy=y2-y1
    local len=math.sqrt(dx*dx+dy*dy)
    if len<0.5 then return end
    local bar=Instance.new("Frame")
    bar.Name="SL_IconOverlay"
    bar.Size=UDim2.new(0,math.ceil(len),0,thick)
    bar.Position=UDim2.new(0,math.floor((x1+x2)/2-len/2),0,math.floor((y1+y2)/2-thick/2))
    bar.Rotation=math.deg(math.atan2(dy,dx))
    bar.BackgroundColor3=col
    bar.BorderSizePixel=0
    bar.ZIndex=zi or 50
    bar.Parent=parent
end

local function drawDot(parent, cx,cy, r, col, zi)
    local dot=Instance.new("Frame")
    dot.Name="SL_IconOverlay"
    dot.Size=UDim2.new(0,r*2,0,r*2)
    dot.Position=UDim2.new(0,cx-r,0,cy-r)
    dot.BackgroundColor3=col
    dot.BorderSizePixel=0
    dot.ZIndex=zi or 50
    dot.Parent=dot.Parent or parent
    dot.Parent=parent
    local uc=Instance.new("UICorner")
    uc.CornerRadius=UDim.new(1,0)
    uc.Parent=dot
end

-- SELECT — cursor arrow: M5 3l14 9-7 1-3 7L5 3z
ICON_DRAW["select"] = function(parent, S, col)
    local pts = {{5,3},{19,12},{12,13},{9,20},{5,3}}
    for i=1,#pts-1 do
        drawBar(parent, pts[i][1]/24*S,pts[i][2]/24*S, pts[i+1][1]/24*S,pts[i+1][2]/24*S, 2, col)
    end
end

-- MOVE — cross arrows: M12 2v20M2 12h20 + arrows
ICON_DRAW["move"] = function(parent, S, col)
    local T=2
    -- vertical line
    drawBar(parent, S/2,1, S/2,S-1, T,col)
    -- horizontal line
    drawBar(parent, 1,S/2, S-1,S/2, T,col)
    -- up arrow
    drawBar(parent, S/2,1, S/2-4,7, T,col)
    drawBar(parent, S/2,1, S/2+4,7, T,col)
    -- down arrow
    drawBar(parent, S/2,S-1, S/2-4,S-7, T,col)
    drawBar(parent, S/2,S-1, S/2+4,S-7, T,col)
    -- left arrow
    drawBar(parent, 1,S/2, 7,S/2-4, T,col)
    drawBar(parent, 1,S/2, 7,S/2+4, T,col)
    -- right arrow
    drawBar(parent, S-1,S/2, S-7,S/2-4, T,col)
    drawBar(parent, S-1,S/2, S-7,S/2+4, T,col)
end

-- SCALE — outer rect + inner rect
ICON_DRAW["scale"] = function(parent, S, col)
    local T=2; local m=3
    -- outer rect
    drawBar(parent, m,m, S-m,m, T,col)
    drawBar(parent, S-m,m, S-m,S-m, T,col)
    drawBar(parent, S-m,S-m, m,S-m, T,col)
    drawBar(parent, m,S-m, m,m, T,col)
    -- inner rect
    local i=S/2-4; local i2=S/2+4
    drawBar(parent, i,i, i2,i, T,col)
    drawBar(parent, i2,i, i2,i2, T,col)
    drawBar(parent, i2,i2, i,i2, T,col)
    drawBar(parent, i,i2, i,i, T,col)
end

-- ROTATE — dua panah melingkar berlawanan arah (mirip Roblox Studio PC)
ICON_DRAW["rotate"] = function(parent, S, col)
    local T = 2
    local cx = S/2; local cy = S/2
    local r  = S/2 - 5

    -- Arc KANAN (searah jarum jam, bagian kanan lingkaran): 300° → 90°
    local segs = 10
    for i = 0, segs-1 do
        local a  = math.rad(300 - 10) + (i/segs) * math.rad(160)
        local an = math.rad(300 - 10) + ((i+1)/segs) * math.rad(160)
        drawBar(parent,
            cx + math.cos(a)*r,  cy + math.sin(a)*r,
            cx + math.cos(an)*r, cy + math.sin(an)*r,
            T, col)
    end
    -- Kepala panah ujung arc kanan (di ~90° = atas)
    local xe = cx + math.cos(math.rad(90))*r
    local ye = cy + math.sin(math.rad(90))*r
    drawBar(parent, xe, ye, xe + 5, ye + 3, T, col)  -- kanan bawah
    drawBar(parent, xe, ye, xe - 5, ye + 3, T, col)  -- kiri bawah

    -- Arc KIRI (berlawanan jarum jam, bagian kiri lingkaran): 120° → 270°
    for i = 0, segs-1 do
        local a  = math.rad(120) + (i/segs) * math.rad(150)
        local an = math.rad(120) + ((i+1)/segs) * math.rad(150)
        drawBar(parent,
            cx + math.cos(a)*r,  cy + math.sin(a)*r,
            cx + math.cos(an)*r, cy + math.sin(an)*r,
            T, col)
    end
    -- Kepala panah ujung arc kiri (di ~270° = bawah)
    local xs = cx + math.cos(math.rad(270))*r
    local ys = cy + math.sin(math.rad(270))*r
    drawBar(parent, xs, ys, xs + 5, ys - 3, T, col)  -- kanan atas
    drawBar(parent, xs, ys, xs - 5, ys - 3, T, col)  -- kiri atas
end

-- PART — simple square (kotak)
ICON_DRAW["part"] = function(parent, S, col)
    local T=2; local m=4
    drawBar(parent, m,m, S-m,m, T,col)
    drawBar(parent, S-m,m, S-m,S-m, T,col)
    drawBar(parent, S-m,S-m, m,S-m, T,col)
    drawBar(parent, m,S-m, m,m, T,col)
end

-- SPHERE — circle + horizontal & vertical ellipse lines
ICON_DRAW["sphere"] = function(parent, S, col)
    local T=2; local cx=S/2; local cy=S/2; local r=S/2-4
    -- Circle
    local segs=14
    for i=0,segs-1 do
        local a1=(i/segs)*math.pi*2
        local a2=((i+1)/segs)*math.pi*2
        drawBar(parent,
            cx+math.cos(a1)*r, cy+math.sin(a1)*r,
            cx+math.cos(a2)*r, cy+math.sin(a2)*r,
            T, col)
    end
    -- Horizontal ellipse (equator)
    local segs2=10
    for i=0,segs2-1 do
        local a1=(i/segs2)*math.pi*2
        local a2=((i+1)/segs2)*math.pi*2
        drawBar(parent,
            cx+math.cos(a1)*r, cy+math.sin(a1)*(r*0.32),
            cx+math.cos(a2)*r, cy+math.sin(a2)*(r*0.32),
            T, col)
    end
end

-- WEDGE — segitiga
ICON_DRAW["wedge"] = function(parent, S, col)
    local T=2
    drawBar(parent, 3,S-3, S-3,S-3, T,col)   -- base
    drawBar(parent, 3,S-3, S/2,3, T,col)      -- left side
    drawBar(parent, S-3,S-3, S/2,3, T,col)    -- right side
end

-- CYLINDER — ellipse top + ellipse bottom + 2 vertical lines
ICON_DRAW["cylinder"] = function(parent, S, col)
    local T=2; local cx=S/2; local ry=S*0.12; local rx=S/2-4
    local ty=5; local by=S-5
    -- top ellipse
    local segs=12
    for i=0,segs-1 do
        local a1=(i/segs)*math.pi*2; local a2=((i+1)/segs)*math.pi*2
        drawBar(parent, cx+math.cos(a1)*rx,ty+math.sin(a1)*ry, cx+math.cos(a2)*rx,ty+math.sin(a2)*ry, T,col)
    end
    -- bottom ellipse
    for i=0,segs-1 do
        local a1=(i/segs)*math.pi*2; local a2=((i+1)/segs)*math.pi*2
        drawBar(parent, cx+math.cos(a1)*rx,by+math.sin(a1)*ry, cx+math.cos(a2)*rx,by+math.sin(a2)*ry, T,col)
    end
    -- side lines
    drawBar(parent, cx-rx,ty, cx-rx,by, T,col)
    drawBar(parent, cx+rx,ty, cx+rx,by, T,col)
end

-- MODEL — 3D box isometric
ICON_DRAW["model"] = function(parent, S, col)
    local T=2
    -- Top face (hexagon-ish top of 3D box)
    local cx=S/2; local top=4; local mid=S/2; local bot=S-4
    local lx=4; local rx=S-4; local mlx=cx-5; local mrx=cx+5
    drawBar(parent, cx,top, rx,mid-4, T,col)
    drawBar(parent, rx,mid-4, cx,mid+2, T,col)
    drawBar(parent, cx,mid+2, lx,mid-4, T,col)
    drawBar(parent, lx,mid-4, cx,top, T,col)
    -- left face
    drawBar(parent, lx,mid-4, lx,bot-4, T,col)
    drawBar(parent, lx,bot-4, cx,bot+2, T,col)
    drawBar(parent, cx,bot+2, cx,mid+2, T,col)
    -- right face
    drawBar(parent, rx,mid-4, rx,bot-4, T,col)
    drawBar(parent, rx,bot-4, cx,bot+2, T,col)
end

-- ─────────────────────────────────────────────────────────────
--  Inject custom icon ke toolbar button
--  Menghapus semua child visual lama, inject icon baru
-- ─────────────────────────────────────────────────────────────
local function injectIconIntoBtn(btn, iconKey, col)
    -- Hapus icon overlay lama kalau ada
    for _, ch in ipairs(btn:GetChildren()) do
        if ch.Name == "SL_IconOverlay" or ch.Name == "SL_IconFrame" then
            ch:Destroy()
        end
    end

    local drawFn = ICON_DRAW[iconKey]
    if not drawFn then return end

    -- Cari child ImageLabel — sembunyikan
    for _, ch in ipairs(btn:GetChildren()) do
        if ch:IsA("ImageLabel") or ch:IsA("ImageButton") then
            pcall(function() ch.ImageTransparency = 1 end)
        end
    end

    -- Buat container icon
    local iconF = Instance.new("Frame")
    iconF.Name = "SL_IconFrame"
    iconF.BackgroundTransparency = 1
    iconF.BorderSizePixel = 0
    iconF.ZIndex = 55
    iconF.ClipsDescendants = false

    -- Cari size dari button
    local btnH = btn.AbsoluteSize.Y
    if btnH < 10 then btnH = 32 end
    local iconSize = math.floor(btnH * 0.52)
    if iconSize < 16 then iconSize = 16 end
    if iconSize > 28 then iconSize = 28 end

    iconF.Size = UDim2.new(0, iconSize, 0, iconSize)
    -- Center di button
    iconF.Position = UDim2.new(0.5, -iconSize/2, 0, 4)
    iconF.Parent = btn

    pcall(function() drawFn(iconF, iconSize, col) end)
end

-- ─────────────────────────────────────────────────────────────
--  Map nama button → icon key
-- ─────────────────────────────────────────────────────────────
local ICON_MAP = {
    select   = "select",
    move     = "move",
    scale    = "scale",
    rotate   = "rotate",
    part     = "part",
    partinsert = "part",
    sphere   = "sphere",
    wedge    = "wedge",
    cylinder = "cylinder",
    model    = "model",
}

local function tryInjectIcons()
    for _, obj in ipairs(StudioGui:GetDescendants()) do
        if SKIP[obj.Name] then continue end
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local n = obj.Name:lower()
            local key = ICON_MAP[n]
            if key then
                local col = isPlayObj(obj) and C.playRed or C.white
                pcall(function() injectIconIntoBtn(obj, key, col) end)
            end
        end
    end
end

-- ─────────────────────────────────────────────────────────────
--  CLICK EFFECT — hanya untuk tombol kecil di toolbar, bukan frame besar
-- ─────────────────────────────────────────────────────────────
local function applyClickEffect(obj)
    -- Skip jika bukan TextButton/ImageButton (jangan apply ke frame biasa)
    if not (obj:IsA("TextButton") or obj:IsA("ImageButton")) then return end
    -- Skip jika objeknya besar (kemungkinan scroll area / panel besar)
    -- Cek AbsoluteSize saat runtime via Changed
    local function doApply()
        local sz = obj.AbsoluteSize
        if sz.X > 200 or sz.Y > 100 then return end  -- terlalu besar = bukan toolbar btn
        obj.MouseEnter:Connect(function()
            pcall(function()
                obj.BackgroundTransparency = 0.85
                obj.BackgroundColor3 = C.white
                local st = obj:FindFirstChildOfClass("UIStroke")
                if not st then st = Instance.new("UIStroke"); st.Parent = obj end
                st.Color = Color3.fromRGB(255,255,255)
                st.Transparency = 0.5
                st.Thickness = 1
            end)
        end)
        obj.MouseLeave:Connect(function()
            pcall(function()
                obj.BackgroundTransparency = 1
                local st = obj:FindFirstChildOfClass("UIStroke")
                if st then st:Destroy() end
            end)
        end)
    end
    -- Jalankan saat AbsoluteSize sudah tersedia
    if obj.AbsoluteSize.X > 0 then
        doApply()
    else
        local conn; conn = obj:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            conn:Disconnect()
            doApply()
        end)
    end
end

local function setIconColor(obj, col)
    pcall(function() obj.ImageColor3 = col end)
    for _, child in ipairs(obj:GetChildren()) do
        if child:IsA("ImageLabel") or child:IsA("ImageButton") then
            if not SKIP[child.Name] then
                pcall(function() child.ImageColor3 = col end)
            end
        end
    end
end

local function fixAll()
    for _, obj in ipairs(StudioGui:GetDescendants()) do
        if SKIP[obj.Name] then continue end
        pcall(function()

            if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
                if obj.BackgroundTransparency >= 0.95 then return end
                local c = obj.BackgroundColor3; local b = br(c)
                if isBlue(c) and b > 0.15 then
                    obj.BackgroundColor3 = C.expSel; addRounded(obj); return
                end
                if     b > 0.85 then obj.BackgroundColor3 = C.c0
                elseif b > 0.65 then obj.BackgroundColor3 = C.c1
                elseif b > 0.45 then obj.BackgroundColor3 = C.c2
                else                 obj.BackgroundColor3 = C.c3 end

            elseif obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                if obj.BackgroundTransparency < 0.95 then
                    local c = obj.BackgroundColor3; local b = br(c)
                    if isBlue(c) and b > 0.15 then
                        obj.BackgroundColor3 = C.expSel; addRounded(obj)
                    elseif b > 0.5 then obj.BackgroundColor3 = C.c2 end
                end
                -- Selalu putih
                if obj.TextTransparency < 0.99 then
                    obj.TextColor3 = isPlayObj(obj) and C.playRed or C.white
                end
                if obj:IsA("TextButton") then
                    local col = isPlayObj(obj) and C.playRed or C.white
                    setIconColor(obj, col)
                    if obj.BackgroundTransparency < 0.95 then
                        obj.BackgroundTransparency = 1
                        obj.BorderSizePixel = 0
                    end
                    applyClickEffect(obj)
                end

            elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                if obj.BackgroundTransparency < 0.95 then
                    local c = obj.BackgroundColor3; local b = br(c)
                    if isBlue(c) and b > 0.15 then obj.BackgroundColor3 = C.expSel
                    elseif b > 0.5 then obj.BackgroundColor3 = C.c2 end
                end
                local col = isPlayObj(obj) and C.playRed or C.white
                setIconColor(obj, col)
                if obj:IsA("ImageButton") then
                    applyClickEffect(obj)
                end

            elseif obj:IsA("UIStroke") then
                if not isBlue(obj.Color) then obj.Color = C.border end
            end
        end)
    end
end

StudioGui.DescendantAdded:Connect(function(desc)
    task.wait(0.05)
    if not desc or not desc.Parent or SKIP[desc.Name] then return end
    pcall(function()
        local col = isPlayObj(desc) and C.playRed or C.white

        if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
            setIconColor(desc, col)
            if desc:IsA("ImageButton") then applyClickEffect(desc) end

        elseif desc:IsA("TextButton") then
            desc.TextColor3 = col
            setIconColor(desc, col)
            if desc.BackgroundTransparency < 0.95 then
                desc.BackgroundTransparency = 1
                desc.BorderSizePixel = 0
            end
            applyClickEffect(desc)

        elseif desc:IsA("TextLabel") or desc:IsA("TextBox") then
            -- Lock putih permanen via event
            pcall(function() lockTextWhite(desc) end)

        elseif desc:IsA("Frame") or desc:IsA("ScrollingFrame") then
            if desc.BackgroundTransparency >= 0.95 then return end
            local c = desc.BackgroundColor3; local b = br(c)
            if isBlue(c) and b > 0.15 then
                desc.BackgroundColor3 = C.expSel; addRounded(desc); return
            end
            if     b > 0.85 then desc.BackgroundColor3 = C.c0
            elseif b > 0.65 then desc.BackgroundColor3 = C.c1
            elseif b > 0.45 then desc.BackgroundColor3 = C.c2
            else                  desc.BackgroundColor3 = C.c3 end
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════
--  HELPER — drawLine untuk icon terrain & part
-- ═══════════════════════════════════════════════════════════

local function drawLine(parent, x1,y1, x2,y2, thick, col, zi, name)
    local dx=x2-x1; local dy=y2-y1
    local len=math.sqrt(dx*dx+dy*dy)
    if len<1 then return end
    local bar=Instance.new("Frame")
    bar.Name = name or "TerrainBar"
    bar.Size=UDim2.new(0,math.ceil(len),0,thick)
    bar.Position=UDim2.new(0,math.floor((x1+x2)/2-len/2),0,math.floor((y1+y2)/2-thick/2))
    bar.Rotation=math.deg(math.atan2(dy,dx))
    bar.BackgroundColor3 = col or C.white
    bar.BorderSizePixel=0
    bar.ZIndex = zi or 50
    bar.Parent=parent
end

-- ═══════════════════════════════════════════════════════════
--  FIND TOOLBAR
-- ═══════════════════════════════════════════════════════════

local cachedToolbar = nil

local function findToolbar()
    if cachedToolbar and cachedToolbar.Parent then return cachedToolbar end
    for _,obj in ipairs(StudioGui:GetDescendants()) do
        if obj:IsA("ImageButton") or obj:IsA("TextButton") then
            local n=obj.Name:lower()
            if n:find("toolbox") or n:find("play") then
                local p=obj.Parent
                if p and (p:IsA("Frame") or p:IsA("ScrollingFrame")) then
                    cachedToolbar=p; return p
                end
            end
        end
    end
    return nil
end


local function getToolbarMaxX(toolbar)
    local maxX=0
    for _,ch in ipairs(toolbar:GetChildren()) do
        if ch:IsA("GuiObject") and not ch:IsA("UIListLayout") and not ch:IsA("UICorner") then
            pcall(function()
                local x=(ch.AbsolutePosition.X-toolbar.AbsolutePosition.X)+ch.AbsoluteSize.X
                if x>maxX then maxX=x end
            end)
        end
    end
    return maxX
end

-- ═══════════════════════════════════════════════════════════
--  MAKE TOOLBAR BTN — helper buat satu slot icon di toolbar
--  Mirip Terrain tapi bisa diklik untuk trigger fungsi
-- ═══════════════════════════════════════════════════════════

local function makeToolbarBtn(toolbar, offsetX, label, drawFn, onClickFn)
    local SIZE=26; local THICK=2
    local H=toolbar.AbsoluteSize.Y
    local padY=math.max(2,math.floor((H-SIZE-14)/2))
    local W=SIZE+14

    local cont=Instance.new("Frame")
    cont.Name="SL_CustomBtn_"..label
    cont.Size=UDim2.new(0,W,1,0)
    cont.Position=UDim2.new(0,offsetX,0,0)
    cont.BackgroundTransparency=1
    cont.ClipsDescendants=false
    cont.ZIndex=40
    cont.Parent=toolbar

    -- Icon frame
    local iconF=Instance.new("Frame")
    iconF.Name="SL_IconDraw_"..label
    iconF.Size=UDim2.new(0,SIZE,0,SIZE)
    iconF.Position=UDim2.new(0,W/2-SIZE/2,0,padY)
    iconF.BackgroundTransparency=1
    iconF.ClipsDescendants=false
    iconF.ZIndex=45
    iconF.Parent=cont

    -- Draw icon
    pcall(function() drawFn(iconF, SIZE, THICK) end)

    -- Label
    local lbl=Instance.new("TextLabel")
    lbl.Name="SL_LblDraw_"..label
    lbl.Size=UDim2.new(0,W,0,13)
    lbl.Position=UDim2.new(0,0,0,padY+SIZE+2)
    lbl.BackgroundTransparency=1
    lbl.Text=label
    lbl.TextColor3=C.white
    lbl.TextSize=9
    lbl.Font=Enum.Font.GothamBold
    lbl.TextXAlignment=Enum.TextXAlignment.Center
    lbl.ZIndex=40
    lbl.Parent=cont

    -- Click button (invisible overlay)
    local btn=Instance.new("TextButton")
    btn.Name="SL_ClickBtn_"..label
    btn.Size=UDim2.new(1,0,1,0)
    btn.BackgroundTransparency=1
    btn.Text=""
    btn.ZIndex=60
    btn.Parent=cont

    -- Hover effect
    btn.MouseEnter:Connect(function()
        pcall(function()
            btn.BackgroundTransparency=0.85
            btn.BackgroundColor3=C.white
            local st=btn:FindFirstChildOfClass("UIStroke")
            if not st then st=Instance.new("UIStroke"); st.Parent=btn end
            st.Color=Color3.fromRGB(255,255,255)
            st.Transparency=0.5
            st.Thickness=1
        end)
    end)
    btn.MouseLeave:Connect(function()
        pcall(function()
            btn.BackgroundTransparency=1
            local st=btn:FindFirstChildOfClass("UIStroke")
            if st then st:Destroy() end
        end)
    end)

    btn.MouseButton1Click:Connect(function()
        pcall(onClickFn)
    end)

    return cont, W
end

-- ═══════════════════════════════════════════════════════════
--  ICON DRAW FUNCTIONS untuk Part types
-- ═══════════════════════════════════════════════════════════

local function drawBlock(iconF, S, T)
    -- Kotak solid (3D isometric style)
    local cx=S/2
    -- Top face
    drawLine(iconF, cx,3,    S-3,S/2-3, T,C.white,46,"SL_IconOverlay")
    drawLine(iconF, S-3,S/2-3, cx,S/2+2, T,C.white,46,"SL_IconOverlay")
    drawLine(iconF, cx,S/2+2, 3,S/2-3,  T,C.white,46,"SL_IconOverlay")
    drawLine(iconF, 3,S/2-3,  cx,3,     T,C.white,46,"SL_IconOverlay")
    -- Left face
    drawLine(iconF, 3,S/2-3,  3,S-5,    T,C.white,46,"SL_IconOverlay")
    drawLine(iconF, 3,S-5,    cx,S-2,   T,C.white,46,"SL_IconOverlay")
    drawLine(iconF, cx,S-2,   cx,S/2+2, T,C.white,46,"SL_IconOverlay")
    -- Right face
    drawLine(iconF, S-3,S/2-3, S-3,S-5, T,C.white,46,"SL_IconOverlay")
    drawLine(iconF, S-3,S-5,   cx,S-2,  T,C.white,46,"SL_IconOverlay")
end

local function drawBall(iconF, S, T)
    -- Circle
    local cx=S/2; local cy=S/2; local r=S/2-3
    local segs=14
    for i=0,segs-1 do
        local a1=(i/segs)*math.pi*2
        local a2=((i+1)/segs)*math.pi*2
        drawLine(iconF,
            cx+math.cos(a1)*r, cy+math.sin(a1)*r,
            cx+math.cos(a2)*r, cy+math.sin(a2)*r,
            T,C.white,46,"SL_IconOverlay")
    end
    -- Equator ellipse
    for i=0,9 do
        local a1=(i/10)*math.pi*2; local a2=((i+1)/10)*math.pi*2
        drawLine(iconF,
            cx+math.cos(a1)*r, cy+math.sin(a1)*(r*0.3),
            cx+math.cos(a2)*r, cy+math.sin(a2)*(r*0.3),
            T,C.white,46,"SL_IconOverlay")
    end
end

local function drawCylinder(iconF, S, T)
    local cx=S/2; local ry=S*0.14; local rx=S/2-3
    local ty=4; local by=S-4
    local segs=12
    -- Top ellipse
    for i=0,segs-1 do
        local a1=(i/segs)*math.pi*2; local a2=((i+1)/segs)*math.pi*2
        drawLine(iconF, cx+math.cos(a1)*rx,ty+math.sin(a1)*ry,
                        cx+math.cos(a2)*rx,ty+math.sin(a2)*ry, T,C.white,46,"SL_IconOverlay")
    end
    -- Bottom ellipse
    for i=0,segs-1 do
        local a1=(i/segs)*math.pi*2; local a2=((i+1)/segs)*math.pi*2
        drawLine(iconF, cx+math.cos(a1)*rx,by+math.sin(a1)*ry,
                        cx+math.cos(a2)*rx,by+math.sin(a2)*ry, T,C.white,46,"SL_IconOverlay")
    end
    -- Side lines
    drawLine(iconF, cx-rx,ty, cx-rx,by, T,C.white,46,"SL_IconOverlay")
    drawLine(iconF, cx+rx,ty, cx+rx,by, T,C.white,46,"SL_IconOverlay")
end

local function drawWedge(iconF, S, T)
    -- Segitiga
    drawLine(iconF, 3,S-3,   S-3,S-3, T,C.white,46,"SL_IconOverlay") -- base
    drawLine(iconF, 3,S-3,   S/2,3,   T,C.white,46,"SL_IconOverlay") -- left
    drawLine(iconF, S-3,S-3, S/2,3,   T,C.white,46,"SL_IconOverlay") -- right
end

local function drawCornerWedge(iconF, S, T)
    -- Corner wedge — segitiga siku dari sudut
    drawLine(iconF, 3,S-3,   S-3,S-3, T,C.white,46,"SL_IconOverlay") -- bottom
    drawLine(iconF, 3,S-3,   3,3,     T,C.white,46,"SL_IconOverlay") -- left side
    drawLine(iconF, 3,3,     S-3,S-3, T,C.white,46,"SL_IconOverlay") -- diagonal
    -- small top detail
    drawLine(iconF, 3,3,     S-3,3,   T,C.white,46,"SL_IconOverlay") -- top
    drawLine(iconF, S-3,3,   S-3,S-3, T,C.white,46,"SL_IconOverlay") -- right
end

local function drawTerrainIcon(iconF, S, T)
    local sc=S/24
    local pts={{3,20},{9,8},{13,16},{16,11},{21,20},{3,20}}
    for i=1,#pts-1 do
        drawLine(iconF,pts[i][1]*sc,pts[i][2]*sc,pts[i+1][1]*sc,pts[i+1][2]*sc,T,C.white,46,"TerrainBar")
    end
end

-- ═══════════════════════════════════════════════════════════
--  INJECT PART BUTTONS — cari original PartInsert button,
--  sembunyikan, taruh icon baru di posisinya
-- ═══════════════════════════════════════════════════════════

local partsDone = false

-- Insert part langsung ke Workspace tanpa popup apapun
local function triggerPartInsert(partName)
    pcall(function()
        local workspace = game:GetService("Workspace")
        local camera = workspace.CurrentCamera
        -- Posisi spawn: tepat di depan kamera, orientation tegak lurus (tidak ikut rotasi kamera)
        local spawnCFrame = CFrame.new(0, 5, 0)
        if camera then
            local cf      = camera.CFrame
            local forward = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit
            if forward.Magnitude < 0.01 then forward = Vector3.new(0,0,-1) end
            local pos = cf.Position + forward * 18
            -- Paksa Y minimal 3 agar tidak masuk tanah
            spawnCFrame = CFrame.new(pos.X, math.max(pos.Y, 3), pos.Z)
        end

        local newPart
        if partName == "Block" then
            newPart = Instance.new("Part")
            newPart.Shape = Enum.PartType.Block
        elseif partName == "Ball" then
            newPart = Instance.new("Part")
            newPart.Shape = Enum.PartType.Ball
        elseif partName == "Cylinder" then
            newPart = Instance.new("Part")
            newPart.Shape = Enum.PartType.Cylinder
        elseif partName == "Wedge" then
            newPart = Instance.new("WedgePart")
        elseif partName == "CornerWedge" then
            newPart = Instance.new("CornerWedgePart")
        else
            newPart = Instance.new("Part")
        end

        newPart.Size     = Vector3.new(4, 1.2, 2)
        newPart.CFrame   = spawnCFrame
        newPart.Anchored = true
        newPart.Material = Enum.Material.SmoothPlastic
        newPart.Color    = Color3.fromRGB(255, 255, 255)
        newPart.Parent   = workspace

        pcall(function()
            local sel = game:GetService("Selection")
            if sel then sel:Set({newPart}) end
        end)
        print("[SL Theme] Inserted: " .. partName)
    end)
end

local function injectPartButtons()
    if partsDone then return end
    local toolbar = findToolbar()
    if not toolbar then return end
    if toolbar:FindFirstChild("SL_CustomBtn_Block") then partsDone=true; return end

    -- Cari dan sembunyikan tombol PartInsert bawaan supaya tidak dobel
    for _, obj in ipairs(toolbar:GetChildren()) do
        local n = obj.Name:lower()
        if n:find("part") or n:find("insert") then
            pcall(function()
                obj.Visible = false
                obj.BackgroundTransparency = 1
                for _, ch in ipairs(obj:GetDescendants()) do
                    pcall(function()
                        if ch:IsA("GuiObject") then ch.Visible = false end
                    end)
                end
            end)
        end
    end

    -- Posisi: ambil maxX dari toolbar (setelah terrain kalau ada)
    local maxX = getToolbarMaxX(toolbar)

    local SIZE=26; local THICK=2
    local H=toolbar.AbsoluteSize.Y
    local padY=math.max(2,math.floor((H-SIZE-14)/2))

    -- Daftar: {label, drawFn, partTypeName}
    local parts = {
        {"Block",       drawBlock,       "Block"},
        {"Ball",        drawBall,        "Ball"},
        {"Cylinder",    drawCylinder,    "Cylinder"},
        {"Wedge",       drawWedge,       "Wedge"},
        {"Corner",      drawCornerWedge, "CornerWedge"},
    }

    local GAP = 3
    local curX = maxX + GAP

    -- ── Separator garis tipis antara tool icons & part buttons ──
    local sep = Instance.new("Frame")
    sep.Name = "SL_Separator_Parts"
    sep.Size = UDim2.new(0, 1, 0, math.floor(H * 0.55))
    sep.Position = UDim2.new(0, curX + 2, 0, math.floor(H * 0.225))
    sep.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
    sep.BorderSizePixel = 0
    sep.ZIndex = 200
    sep.Parent = toolbar
    curX = curX + 8  -- extra gap setelah separator

    for _, def in ipairs(parts) do
        local label, drawFn, partType = def[1], def[2], def[3]
        local W = SIZE + 14

        local cont = Instance.new("Frame")
        cont.Name = "SL_CustomBtn_"..label
        cont.Size = UDim2.new(0, W, 1, 0)
        cont.Position = UDim2.new(0, curX, 0, 0)
        cont.BackgroundTransparency = 1
        cont.ClipsDescendants = false
        cont.ZIndex = 200
        cont.Parent = toolbar

        -- Icon frame
        local iconF = Instance.new("Frame")
        iconF.Name = "SL_IconDraw_"..label
        iconF.Size = UDim2.new(0, SIZE, 0, SIZE)
        iconF.Position = UDim2.new(0, W/2-SIZE/2, 0, padY)
        iconF.BackgroundTransparency = 1
        iconF.ClipsDescendants = false
        iconF.ZIndex = 210
        iconF.Parent = cont
        pcall(function() drawFn(iconF, SIZE, THICK) end)

        -- Label
        local lbl = Instance.new("TextLabel")
        lbl.Name = "SL_LblDraw_"..label
        lbl.Size = UDim2.new(0, W, 0, 13)
        lbl.Position = UDim2.new(0, 0, 0, padY+SIZE+2)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = C.white
        lbl.TextSize = 9
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.ZIndex = 205
        lbl.Parent = cont

        -- Click overlay
        local btn = Instance.new("TextButton")
        btn.Name = "SL_ClickBtn_"..label
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.ZIndex = 220
        btn.Parent = cont

        -- Hover
        btn.MouseEnter:Connect(function()
            pcall(function()
                btn.BackgroundTransparency = 0.85
                btn.BackgroundColor3 = C.white
                local st = btn:FindFirstChildOfClass("UIStroke")
                if not st then st = Instance.new("UIStroke"); st.Parent = btn end
                st.Color = Color3.fromRGB(255,255,255)
                st.Transparency = 0.5
                st.Thickness = 1
            end)
        end)
        btn.MouseLeave:Connect(function()
            pcall(function()
                btn.BackgroundTransparency = 1
                local st = btn:FindFirstChildOfClass("UIStroke")
                if st then st:Destroy() end
            end)
        end)

        -- Click — trigger bawaan SL
        local capturedType = partType
        btn.MouseButton1Click:Connect(function()
            pcall(function() triggerPartInsert(capturedType) end)
        end)

        curX = curX + W + GAP
    end

    partsDone = true
    print("[SL Theme] Part buttons injected!")
end


-- ═══════════════════════════════════════════════════════════
--  WHITE TEXT PERMANENT — pakai Changed event, bukan loop
--  Sehingga tidak ada kedip/flicker sama sekali
-- ═══════════════════════════════════════════════════════════
local lockedWhite = {}  -- track objek yang sudah di-lock

local function lockTextWhite(obj)
    if lockedWhite[obj] then return end
    if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
    lockedWhite[obj] = true
    local targetCol = isPlayObj(obj) and C.playRed or C.white
    pcall(function() obj.TextColor3 = targetCol end)
    -- Setiap kali warna berubah (misal saat diklik Explorer), langsung kembalikan
    obj:GetPropertyChangedSignal("TextColor3"):Connect(function()
        pcall(function()
            if obj.TextColor3 ~= targetCol then
                obj.TextColor3 = targetCol
            end
        end)
    end)
end

local function forceExplorerOutputWhite()
    for _, obj in ipairs(StudioGui:GetDescendants()) do
        pcall(function() lockTextWhite(obj) end)
    end
end

-- startPersistentWhiteText — tidak pakai loop lagi, cukup lock sekali
local function startPersistentWhiteText()
    -- Sudah ditangani oleh lockTextWhite + DescendantAdded
end

-- Disable multi-select: setiap klik di StudioGui, clear selection ke satu item
local function disableMultiSelect()
    pcall(function()
        local sel = game:GetService("Selection")
        if not sel then return end
        sel.SelectionChanged:Connect(function()
            pcall(function()
                local items = sel:Get()
                if #items > 1 then
                    -- Simpan item terakhir (yang baru dipilih), deselect sisanya
                    sel:Set({items[#items]})
                end
            end)
        end)
    end)
end


local terrainDone = false

local function injectTerrain()
    if terrainDone then return end
    local toolbar = findToolbar()
    if not toolbar then warn("[SL Theme] Toolbar tidak ketemu"); return end
    if toolbar:FindFirstChild("SL_TerrainBtn") then terrainDone=true; return end

    local maxX = getToolbarMaxX(toolbar)
    local SIZE=26; local THICK=2
    local H=toolbar.AbsoluteSize.Y
    local padY=math.max(2,math.floor((H-SIZE-14)/2))
    local W=SIZE+14

    -- ── Separator sebelum Terrain ──
    local sepT = Instance.new("Frame")
    sepT.Name = "SL_Separator_Terrain"
    sepT.Size = UDim2.new(0, 1, 0, math.floor(H * 0.55))
    sepT.Position = UDim2.new(0, maxX + 6, 0, math.floor(H * 0.225))
    sepT.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
    sepT.BorderSizePixel = 0
    sepT.ZIndex = 200
    sepT.Parent = toolbar

    local cont=Instance.new("Frame")
    cont.Name="SL_TerrainBtn"
    cont.Size=UDim2.new(0,W,1,0)
    cont.Position=UDim2.new(0,maxX+14,0,0)
    cont.BackgroundTransparency=1
    cont.ClipsDescendants=false
    cont.ZIndex=200
    cont.Parent=toolbar

    local iconF=Instance.new("Frame")
    iconF.Name="TerrainIconDraw"
    iconF.Size=UDim2.new(0,SIZE,0,SIZE)
    iconF.Position=UDim2.new(0,W/2-SIZE/2,0,padY)
    iconF.BackgroundTransparency=1
    iconF.ClipsDescendants=false
    iconF.ZIndex=210
    iconF.Parent=cont

    drawTerrainIcon(iconF, SIZE, THICK)

    local lbl=Instance.new("TextLabel")
    lbl.Name="TerrainLabel"
    lbl.Size=UDim2.new(0,W,0,13)
    lbl.Position=UDim2.new(0,0,0,padY+SIZE+2)
    lbl.BackgroundTransparency=1
    lbl.Text="Terrain"
    lbl.TextColor3=C.white
    lbl.TextSize=9
    lbl.Font=Enum.Font.GothamBold
    lbl.TextXAlignment=Enum.TextXAlignment.Center
    lbl.ZIndex=205
    lbl.Parent=cont

    local btn=Instance.new("TextButton")
    btn.Name="TerrainClickBtn"
    btn.Size=UDim2.new(1,0,1,0)
    btn.BackgroundTransparency=1
    btn.Text=""
    btn.ZIndex=220
    btn.Parent=cont

    btn.MouseEnter:Connect(function()
        pcall(function()
            btn.BackgroundTransparency=0.85; btn.BackgroundColor3=C.white
            local st=btn:FindFirstChildOfClass("UIStroke")
            if not st then st=Instance.new("UIStroke"); st.Parent=btn end
            st.Color=Color3.fromRGB(255,255,255); st.Transparency=0.5; st.Thickness=1
        end)
    end)
    btn.MouseLeave:Connect(function()
        pcall(function()
            btn.BackgroundTransparency=1
            local st=btn:FindFirstChildOfClass("UIStroke"); if st then st:Destroy() end
        end)
    end)

    btn.MouseButton1Click:Connect(function()
        pcall(function()
            for _,obj in ipairs(StudioGui:GetDescendants()) do
                local n=obj.Name:lower()
                if (n=="terraineditor" or n=="terrain_editor") and obj:IsA("Frame") then
                    obj.Visible=not obj.Visible; return
                end
            end
        end)
    end)

    terrainDone=true
    print("[SL Theme] Terrain icon injected!")
end

-- ── MAIN ─────────────────────────────────────────────────────────────────────
print("[SL Theme FINAL] Menerapkan...")
task.spawn(function()
    fixAll()
    task.wait(0.3)
    fixAll()
    forceExplorerOutputWhite()
    -- Inject part buttons DULU (posisinya sebelum terrain)
    injectPartButtons()
    -- Inject terrain SETELAH part (terrain di ujung kanan)
    injectTerrain()
    task.wait(0.5)
    fixAll()
    forceExplorerOutputWhite()
    task.wait(0.3)
    tryInjectIcons()
    if not partsDone  then task.wait(2); injectPartButtons() end
    if not terrainDone then task.wait(2); injectTerrain() end
    -- Final pass text putih
    task.wait(0.5)
    forceExplorerOutputWhite()
    -- Disable multi-select
    disableMultiSelect()
    -- Persistent white text via event (no loop/flicker)
    startPersistentWhiteText()
    -- Jaga semua GUI Studio tetap visible saat Play mode
    keepGuiVisible()
    startGuiWatcher()
    print("[SL Theme FINAL] ✅ Done!")
end)
