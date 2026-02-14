-- [[ DOORS SUPREMACY v71.0 - THE ETERNAL ]]
-- Status: GOLD MASTER.
-- Logic: Auto Loot (Global Cache -> Proximity Trigger).
-- Memory: Weak Tables (Zero Leaks).
-- Menu: Massive, No Master Switch, Full Granular Control.

local Services = {
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    Lighting = game:GetService("Lighting"),
    PhysicsService = game:GetService("PhysicsService"),
    TextChatService = game:GetService("TextChatService"),
    ProximityPromptService = game:GetService("ProximityPromptService")
}

local Client = {
    Player = Services.Players.LocalPlayer,
    Character = nil,
    RootPart = nil,
    Humanoid = nil
}

-- // 1. MEMORY MANAGEMENT (CRITICAL FIX)
local Cache = {
    Folder = game.CoreGui:FindFirstChild("Doors_v71_Eternal") or Instance.new("Folder", game.CoreGui),
    
    -- WEAK TABLES: Chìa khóa vàng để fix Memory Leak
    -- Khi Object bị Destroy, nó tự động bị xóa khỏi các bảng này
    Interactables = setmetatable({}, { __mode = "k" }), 
    ProcessedRooms = setmetatable({}, { __mode = "k" }),
    ESP_Registry = setmetatable({}, { __mode = "k" }),
    
    IdentityCache = {} -- Memoization giúp chạy nhanh hơn
}
Cache.Folder.Name = "Doors_v71_Eternal"

local Config = {
    -- CONFIG AUTO (Tách lẻ từng món - Không Master Switch)
    Auto = {
        -- Actions
        Unlock = true,      -- Tự mở khóa cửa
        Drawer = true,      -- Tự mở ngăn kéo
        Instant = true,     -- Nhặt không delay
        
        -- Hiding (Mặc định tắt để an toàn)
        Bed = false,
        Wardrobe = false,
        
        -- Floor 1 Items
        Key = true, Lever = true, Gold = true, Lighter = true, Lockpick = true,
        Vitamin = true, Crucifix = true, Book = true, Flashlight = true, Breaker = true,
        
        -- Floor 2 Items
        Fuse = true, Shears = true, Battery = true, Glowstick = true, 
        Bandage = true, Shake = true, Anchor = true, Valve = true
    },
    
    -- CONFIG VISUALS (ESP Chi tiết)
    Visuals = {
        Doors = true, -- Xanh Lá
        
        -- Quest (Xanh Dương)
        ESP_Key=true, ESP_Lever=true, ESP_Book=true, ESP_Breaker=true, 
        ESP_Fuse=true, ESP_Valve=true, ESP_Anchor=true, ESP_Shears=true,
        ESP_Guiding=true, -- Guiding Light
        
        -- Loot (Vàng)
        ESP_Gold=true, ESP_Lighter=true, ESP_Lockpick=true, ESP_Vitamin=true, ESP_Crucifix=true,
        ESP_Flashlight=true, ESP_Battery=true, ESP_Glowstick=true, ESP_Bandage=true, ESP_Shake=true,
        
        -- Entities (Đỏ)
        ESP_Entities=true, -- Tổng quát
        ESP_Figure=true, ESP_Giggle=true, ESP_Gloombat=true, ESP_Grumble=true,
        
        FullBright=true
    },
    
    -- SYSTEM
    Speed = { Enabled = false, Target = 21, Server = 16 },
    GodMode = false,
    ChatNotify = true,
    Anti = { A90=true, Screech=true, Eyes=true, Snare=true, Dupe=true, Giggle=true }
}

-- // 2. DATABASE & PATTERNS
local Colors = {
    Door = Color3.fromRGB(0, 255, 0),       -- Xanh Lá
    Quest = Color3.fromRGB(0, 100, 255),    -- Xanh Dương
    Loot = Color3.fromRGB(255, 255, 0),     -- Vàng
    Entity = Color3.fromRGB(255, 0, 0)      -- Đỏ
}

-- Danh sách mẫu nhận diện (Priority List)
local Patterns = {
    -- QUEST ITEMS
    {k="key", t="Key", n="🔑 Key", c=Colors.Quest},
    {k="lever", t="Lever", n="🕹️ Lever", c=Colors.Quest},
    {k="book", t="Book", n="📘 Book", c=Colors.Quest},
    {k="paper", t="Book", n="📄 Code", c=Colors.Quest},
    {k="breaker", t="Breaker", n="⚡ Breaker", c=Colors.Quest},
    {k="fuse", t="Fuse", n="🔌 Fuse", c=Colors.Quest},
    {k="shears", t="Shears", n="✂️ Shears", c=Colors.Quest},
    {k="valve", t="Valve", n="⚙️ Valve", c=Colors.Quest},
    {k="gate", t="Valve", n="⚙️ Valve", c=Colors.Quest},
    {k="anchor", t="Anchor", n="⚓ Anchor", c=Colors.Quest},
    
    -- LOOT ITEMS
    {k="gold", t="Gold", n="💰 Gold", c=Colors.Loot},
    {k="cash", t="Gold", n="💰 Gold", c=Colors.Loot},
    {k="lighter", t="Lighter", n="🔥 Lighter", c=Colors.Loot},
    {k="lockpick", t="Lockpick", n="🔓 Lockpick", c=Colors.Loot},
    {k="vitamin", t="Vitamin", n="💊 Vitamin", c=Colors.Loot},
    {k="crucifix", t="Crucifix", n="✝️ Crucifix", c=Colors.Loot},
    {k="flashlight", t="Flashlight", n="🔦 Flashlight", c=Colors.Loot},
    {k="bulklight", t="Flashlight", n="🔦 Bulklight", c=Colors.Loot},
    {k="straplight", t="Flashlight", n="🔦 Straplight", c=Colors.Loot},
    {k="battery", t="Battery", n="🔋 Battery", c=Colors.Loot},
    {k="glowstick", t="Glowstick", n="🌟 Glowstick", c=Colors.Loot},
    {k="bandage", t="Bandage", n="🩹 Bandage", c=Colors.Loot},
    {k="medkit", t="Bandage", n="🩹 Medkit", c=Colors.Loot},
    {k="shake", t="Shake", n="🥤 Shake", c=Colors.Loot},
    
    -- CONTAINERS (Auto Only)
    {k="drawer", t="Drawer", n="Drawer", c=nil},
    {k="bed", t="Bed", n="Bed", c=nil},
    {k="wardrobe", t="Wardrobe", n="Closet", c=nil},
    {k="closet", t="Wardrobe", n="Closet", c=nil},
    {k="cabinet", t="Wardrobe", n="Closet", c=nil}
}

-- Hàm nhận diện thông minh (Memoization)
local function Identify(prompt)
    if not prompt or not prompt.Parent then return nil end
    -- Check gộp tên cha, tên model, tên prompt
    local checkStr = (prompt.Name .. prompt.Parent.Name .. (prompt.ObjectText or "")):lower()
    
    if Cache.IdentityCache[checkStr] then return unpack(Cache.IdentityCache[checkStr]) end

    for _, p in ipairs(Patterns) do
        if checkStr:find(p.k) then
            Cache.IdentityCache[checkStr] = {p.t, p.n, p.c}
            return p.t, p.n, p.c
        end
    end
    return nil, nil, nil
end

-- // 3. CORE: VALIDATION (WHITELIST SYSTEM)
local function IsValidTarget(prompt)
    local objT = prompt.ObjectText:lower()
    local actT = prompt.ActionText:lower()
    local name = prompt.Parent.Name:lower()
    
    -- 1. Blacklist (Chặn tuyệt đối rác)
    local blacklist = {"painting", "toilet", "bed", "wardrobe", "closet", "cabinet", "locker", "hide", "switch"}
    for _, b in pairs(blacklist) do
        if name:find(b) then 
            -- Ngoại lệ: Nếu bật Auto Trốn
            if (name:find("bed") and Config.Auto.Bed) or ((name:find("wardrobe") or name:find("closet")) and Config.Auto.Wardrobe) then
                return true
            end
            return false 
        end
    end

    -- 2. Whitelist Item (Check Config)
    local type, _, _ = Identify(prompt)
    if type and Config.Auto[type] then return true end
    
    -- 3. Special Cases
    if name:find("drawer") and Config.Auto.Drawer then return true end
    if Config.Auto.Unlock and actT == "unlock" then return true end

    return false
end

-- // 4. VISUAL ENGINE
local EspEngine = {}

function EspEngine.Create(obj, name, color)
    if not obj or not obj.Parent then return end
    if Cache.ESP_Registry[obj] then return end

    local container = Instance.new("Folder", Cache.Folder)
    container.Name = "ESP"
    Cache.ESP_Registry[obj] = container
    
    local hl = Instance.new("Highlight", container)
    hl.Adornee = obj
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.6  -- Nền mờ
    hl.OutlineTransparency = 0 -- Viền rõ
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    local bgui = Instance.new("BillboardGui", container)
    bgui.AlwaysOnTop = true; bgui.Size = UDim2.new(0, 100, 0, 30); bgui.Adornee = obj; bgui.StudsOffset = Vector3.new(0, 2, 0)
    
    local label = Instance.new("TextLabel", bgui)
    label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1; label.Text = name
    label.TextColor3 = color; label.TextSize = 11; label.Font = Enum.Font.GothamBold; label.TextStrokeTransparency = 0.5
    
    obj.AncestryChanged:Connect(function(_, parent) if not parent then container:Destroy() end end)
end

function EspEngine.Refresh() Cache.Folder:ClearAllChildren(); table.clear(Cache.ESP_Registry) end

-- // 5. SCANNERS & LOGIC
local function ProcessObject(v)
    -- A. Snare & Entities
    if v.Name == "Snare" then
        if Config.Anti.Snare then v.CanTouch = false end
        if Config.Visuals.ESP_Entities then EspEngine.Create(v, "🚫 BẪY", Colors.Entity) end
        return
    end
    
    -- B. Doors
    if v.Name == "Door" and v.Parent.Name == "Door" and Config.Visuals.Doors then
        EspEngine.Create(v, "Cửa", Colors.Door)
        return
    end
    
    -- C. Guiding Light (Fix)
    if (v.Name == "GuidingLight" or v.Name == "Guidance") and Config.Visuals.ESP_Guiding then
        EspEngine.Create(v, "💙 DẪN ĐƯỜNG", Colors.Quest)
        return
    end
    
    -- D. Figure (Specific Fix)
    if v.Name == "FigureRagdoll" and Config.Visuals.ESP_Figure then
        EspEngine.Create(v, "👺 FIGURE", Colors.Entity)
        return
    end

    -- E. Interactables (Auto Loot Cache + ESP)
    if v:IsA("ProximityPrompt") then
        -- 1. Auto Loot Cache (Thêm vào list để Loop xử lý sau)
        -- Lưu ý: Thêm TẤT CẢ cái gì hợp lệ vào cache, không check khoảng cách ở đây
        if IsValidTarget(v) then
            if not Cache.Interactables[v] then Cache.Interactables[v] = true end
        end
        
        -- 2. ESP Logic
        local type, name, col = Identify(v)
        if type and col and Config.Visuals["ESP_"..type] then
            if not v.Parent.Name:lower():find("drawer") then
                EspEngine.Create(v.Parent, name, col)
            end
        end
        
        -- Special Asset: Book
        if v.Parent.Name == "LiveHintBook" and Config.Visuals.ESP_Book then
             EspEngine.Create(v.Parent, "📘 Book", Colors.Quest)
        end
    end
end

local function ProcessRoom(room)
    if not room or Cache.ProcessedRooms[room] then return end
    Cache.ProcessedRooms[room] = true
    for _, v in pairs(room:GetDescendants()) do ProcessObject(v) end
    room.DescendantAdded:Connect(ProcessObject)
end

-- // 6. MAIN LOOPS
-- Speed Hook
local SpeedEngine = {}
function SpeedEngine.Update(dt)
    if not Config.Speed.Enabled then return end
    if not Client.Character or not Client.Humanoid or not Client.RootPart then return end
    if Client.Humanoid.WalkSpeed ~= Config.Speed.Server then Client.Humanoid.WalkSpeed = Config.Speed.Server end
    local dir = Client.Humanoid.MoveDirection
    if dir.Magnitude > 0 then
        Client.RootPart.CFrame = Client.RootPart.CFrame + (dir * (Config.Speed.Target - Config.Speed.Server) * dt)
        local vel = Client.RootPart.Velocity; Client.RootPart.Velocity = Vector3.new(vel.X, 0, vel.Z)
    end
end
Services.RunService.Heartbeat:Connect(SpeedEngine.Update)

-- Centralized Auto Loot Loop (0.1s check distance)
task.spawn(function()
    while task.wait(0.1) do
        if Client.Character and Client.Character:FindFirstChild("HumanoidRootPart") then
            local pos = Client.Character.HumanoidRootPart.Position
            for prompt, _ in pairs(Cache.Interactables) do
                if prompt.Parent and prompt.Enabled then
                    local pPos = prompt.Parent:GetPivot().Position
                    -- Check Distance Here (12 Studs)
                    if (pos - pPos).Magnitude <= 12 then
                        -- Double Check Whitelist
                        if IsValidTarget(prompt) then
                             if Config.Auto.Instant then prompt.HoldDuration = 0 end
                             fireproximityprompt(prompt)
                        end
                    end
                else
                    Cache.Interactables[prompt] = nil -- Clean up
                end
            end
        end
    end
end)

-- Entity Watcher
Services.Workspace.ChildAdded:Connect(function(c)
    local Names = {
        ["RushMoving"]="🚨 RUSH", ["AmbushMoving"]="⚡ AMBUSH", ["Eyes"]="👀 EYES",
        ["Screech"]="👾 SCREECH", ["A90"]="🚫 A-90", ["FigureRagdoll"]="👺 FIGURE",
        ["GiggleCeiling"]="🤪 GIGGLE", ["Gloombat"]="🦇 BAT", ["GrumbleRig"]="🐛 GRUMBLE"
    }
    if Names[c.Name] then
        if Config.Anti.Eyes and c.Name=="Eyes" then task.wait(); c:Destroy(); return end
        if Config.Visuals.ESP_Entities then EspEngine.Create(c, Names[c.Name], Colors.Entity) end
    end
    if (c.Name == "GuidingLight" or c.Name == "Guidance") and Config.Visuals.ESP_Guiding then
        EspEngine.Create(c, "💙 DẪN ĐƯỜNG", Colors.Quest)
    end
end)

-- Init
local Rooms = Services.Workspace:WaitForChild("CurrentRooms")
for _, r in pairs(Rooms:GetChildren()) do task.spawn(ProcessRoom, r) end
Rooms.ChildAdded:Connect(function(r) task.wait(0.5); ProcessRoom(r) end)

local function HookChar(c)
    Client.Character = c; Client.Humanoid = c:WaitForChild("Humanoid", 10); Client.RootPart = c:WaitForChild("HumanoidRootPart", 10)
    local G = "God_v71"; pcall(function() Services.PhysicsService:CreateCollisionGroup(G); Services.PhysicsService:CollisionGroupSetCollidable(G,"Default",true); Services.PhysicsService:CollisionGroupSetCollidable(G,"Players",false) end)
    Services.RunService.Stepped:Connect(function() if Config.GodMode and c then for _,p in pairs(c:GetChildren()) do if p:IsA("BasePart") then p.CanTouch=false; p.CollisionGroup=G end end end end)
end
Client.Player.CharacterAdded:Connect(HookChar)
if Client.Player.Character then HookChar(Client.Player.Character) end

-- // 7. UI CONSTRUCTION (MASSIVE MENU)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({Name = "DOORS v71.0 ETERNAL", ConfigurationSaving = {Enabled = false}})

-- === TAB 1: MAIN ===
local TabM = Window:CreateTab("Chính", 4483362458)
TabM:CreateToggle({Name="Speed Bypass", CurrentValue=false, Callback=function(v) Config.Speed.Enabled=v end})
TabM:CreateSlider({Name="Tốc độ (Target)", Range={16,50}, Increment=1, CurrentValue=22, Callback=function(v) Config.Speed.Target=v end})
TabM:CreateToggle({Name="Ghost God Mode", CurrentValue=false, Callback=function(v) Config.GodMode=v end})
TabM:CreateToggle({Name="Anti-Entities (All)", CurrentValue=true, Callback=function(v) for k,_ in pairs(Config.Anti) do Config.Anti[k]=v end end})
TabM:CreateToggle({Name="Chat Notify", CurrentValue=true, Callback=function(v) Config.ChatNotify=v end})

-- === TAB 2: AUTO F1 ===
local TabA1 = Window:CreateTab("Auto F1", 4483362458)
TabA1:CreateSection("Hành động")
TabA1:CreateToggle({Name="Mở Khóa Cửa (Unlock)", CurrentValue=true, Callback=function(v) Config.Auto.Unlock=v end})
TabA1:CreateToggle({Name="Mở Ngăn Kéo (Drawer)", CurrentValue=true, Callback=function(v) Config.Auto.Drawer=v end})
TabA1:CreateToggle({Name="Tự Trốn Giường (Bed)", CurrentValue=false, Callback=function(v) Config.Auto.Bed=v end})
TabA1:CreateToggle({Name="Tự Trốn Tủ (Wardrobe)", CurrentValue=false, Callback=function(v) Config.Auto.Wardrobe=v end})
TabA1:CreateSection("Vật phẩm")
TabA1:CreateToggle({Name="Nhặt Vàng (Gold)", CurrentValue=true, Callback=function(v) Config.Auto.Gold=v end})
TabA1:CreateToggle({Name="Nhặt Key", CurrentValue=true, Callback=function(v) Config.Auto.Key=v end})
TabA1:CreateToggle({Name="Nhặt Lever", CurrentValue=true, Callback=function(v) Config.Auto.Lever=v end})
TabA1:CreateToggle({Name="Nhặt Book/Code", CurrentValue=true, Callback=function(v) Config.Auto.Book=v end})
TabA1:CreateToggle({Name="Nhặt Lighter", CurrentValue=true, Callback=function(v) Config.Auto.Lighter=v end})
TabA1:CreateToggle({Name="Nhặt Lockpick", CurrentValue=true, Callback=function(v) Config.Auto.Lockpick=v end})
TabA1:CreateToggle({Name="Nhặt Vitamin", CurrentValue=true, Callback=function(v) Config.Auto.Vitamin=v end})
TabA1:CreateToggle({Name="Nhặt Crucifix", CurrentValue=true, Callback=function(v) Config.Auto.Crucifix=v end})
TabA1:CreateToggle({Name="Nhặt Flashlight", CurrentValue=true, Callback=function(v) Config.Auto.Flashlight=v end})

-- === TAB 3: AUTO F2 ===
local TabA2 = Window:CreateTab("Auto F2", 4483362458)
TabA2:CreateSection("Vật phẩm")
TabA2:CreateToggle({Name="Nhặt Fuse (Cầu chì)", CurrentValue=true, Callback=function(v) Config.Auto.Fuse=v end})
TabA2:CreateToggle({Name="Nhặt Shears (Kéo)", CurrentValue=true, Callback=function(v) Config.Auto.Shears=v end})
TabA2:CreateToggle({Name="Nhặt Battery (Pin)", CurrentValue=true, Callback=function(v) Config.Auto.Battery=v end})
TabA2:CreateToggle({Name="Nhặt Glowstick", CurrentValue=true, Callback=function(v) Config.Auto.Glowstick=v end})
TabA2:CreateToggle({Name="Nhặt Bandage", CurrentValue=true, Callback=function(v) Config.Auto.Bandage=v end})
TabA2:CreateToggle({Name="Nhặt Shake", CurrentValue=true, Callback=function(v) Config.Auto.Shake=v end})
TabA2:CreateToggle({Name="Nhặt Anchor Code", CurrentValue=true, Callback=function(v) Config.Auto.Anchor=v end})
TabA2:CreateToggle({Name="Nhặt Breaker", CurrentValue=true, Callback=function(v) Config.Auto.Breaker=v end})
TabA2:CreateToggle({Name="Nhặt Valve", CurrentValue=true, Callback=function(v) Config.Auto.Valve=v end})

-- === TAB 4: VISUALS F1 ===
local TabV1 = Window:CreateTab("ESP F1", 4483362458)
local function Refresh() EspEngine.Refresh(); local r=Services.Workspace.CurrentRooms; for _,v in pairs(r:GetChildren()) do local n=tonumber(v.Name)+1; for _,d in pairs(v:GetDescendants()) do ProcessObject(d) end end end
TabV1:CreateToggle({Name="🔵 ESP Guiding Light", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Guiding=v; Refresh() end})
TabV1:CreateToggle({Name="🟢 ESP Cửa", CurrentValue=true, Callback=function(v) Config.Visuals.Doors=v; Refresh() end})
TabV1:CreateSection("Quest")
