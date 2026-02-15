-- [[ DOORS SUPREMACY v76.0 - THE OMNIVERSE ]]
-- Content: Hotel + Mines + Backdoor + Rooms.
-- Logic: Deep Scan Cache + Proximity Trigger (Fixed Distance Check).
-- Visuals: Full Entity List (Blitz, Lookman, Dupe, Timothy...).

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

-- // 1. MEMORY MANAGEMENT (ZERO LEAK ARCHITECTURE)
local Cache = {
    Folder = game.CoreGui:FindFirstChild("Doors_v76_Omni") or Instance.new("Folder", game.CoreGui),
    -- Weak Tables: Tự động xóa dữ liệu khi object trong game bị hủy
    Interactables = setmetatable({}, { __mode = "k" }), 
    ProcessedRooms = setmetatable({}, { __mode = "k" }),
    ESP_Registry = setmetatable({}, { __mode = "k" }),
    IdentityCache = {} 
}
Cache.Folder.Name = "Doors_v76_Omni"

local Config = {
    -- AUTO INTERACT (FULL GRANULAR)
    Auto = {
        Unlock = true, Drawer = true, Instant = true,
        
        -- Hiding (Safety)
        Bed = false, Wardrobe = false,
        
        -- Hotel (F1) Items
        Key=true, Lever=true, Gold=true, Lighter=true, Lockpick=true,
        Vitamin=true, Crucifix=true, Book=true, Breaker=true, Flashlight=true,
        
        -- Mines (F2) Items
        Fuse=true, Shears=true, Battery=true, Glowstick=true, 
        Bandage=true, Shake=true, Anchor=true, Valve=true,
        
        -- Backdoor Items
        TimerLever=true, Vial=true
    },
    
    -- VISUALS (ESP FULL)
    Visuals = {
        Doors = true, -- Xanh Lá
        
        -- Quest
        ESP_Key=true, ESP_Lever=true, ESP_Book=true, ESP_Breaker=true, 
        ESP_Fuse=true, ESP_Valve=true, ESP_Anchor=true, ESP_Shears=true,
        ESP_Guiding=true, -- Guiding Light
        
        -- Loot
        ESP_Gold=true, ESP_Lighter=true, ESP_Lockpick=true, ESP_Vitamin=true, ESP_Crucifix=true,
        ESP_Flashlight=true, ESP_Battery=true, ESP_Glowstick=true, ESP_Bandage=true, ESP_Shake=true,
        
        -- Entities (Phân loại chi tiết)
        ESP_Main = true,      -- Rush, Ambush, Seek...
        ESP_Backdoor = true,  -- Blitz, Lookman
        ESP_Floor2 = true,    -- Giggle, Grumble, Gloombat
        ESP_Minor = true,     -- Timothy, Jack, Snare
        ESP_Dupe = true,      -- Cửa giả
        
        FullBright=true
    },
    
    Notify = { Chat = true, UI = true },
    Speed = { Enabled = false, Target = 21, Server = 16 },
    GodMode = false,
    Anti = { A90=true, Screech=true, Eyes=true, Snare=true, Dupe=true, Giggle=true, Lookman=true }
}

-- // 2. DATABASE (THE OMNIVERSE LIST)
local Colors = {
    Door = Color3.fromRGB(0, 255, 0),       -- Xanh Lá
    Quest = Color3.fromRGB(0, 100, 255),    -- Xanh Dương
    Loot = Color3.fromRGB(255, 255, 0),     -- Vàng
    Entity = Color3.fromRGB(255, 0, 0),     -- Đỏ
    Rare = Color3.fromRGB(170, 0, 170)      -- Tím (Glitch/Void)
}

-- Pattern Scan (Deep Search)
local Patterns = {
    -- == FLOOR 2 ==
    {k="fuse", t="Fuse", n="🔌 Fuse", c=Colors.Quest},
    {k="shears", t="Shears", n="✂️ Shears", c=Colors.Quest},
    {k="anchor", t="Anchor", n="⚓ Anchor", c=Colors.Quest},
    {k="valve", t="Valve", n="⚙️ Valve", c=Colors.Quest},
    {k="gate", t="Valve", n="⚙️ Valve", c=Colors.Quest},
    {k="battery", t="Battery", n="🔋 Battery", c=Colors.Loot},
    {k="glowstick", t="Glowstick", n="🌟 Glowstick", c=Colors.Loot},
    {k="bandage", t="Bandage", n="🩹 Bandage", c=Colors.Loot},
    {k="medkit", t="Bandage", n="🩹 Medkit", c=Colors.Loot},
    {k="shake", t="Shake", n="🥤 Shake", c=Colors.Loot},
    
    -- == FLOOR 1 ==
    {k="key", t="Key", n="🔑 Key", c=Colors.Quest},
    {k="lever", t="Lever", n="🕹️ Lever", c=Colors.Quest},
    {k="book", t="Book", n="📘 Book", c=Colors.Quest},
    {k="paper", t="Book", n="📄 Code", c=Colors.Quest},
    {k="breaker", t="Breaker", n="⚡ Breaker", c=Colors.Quest},
    {k="gold", t="Gold", n="💰 Gold", c=Colors.Loot},
    {k="cash", t="Gold", n="💰 Gold", c=Colors.Loot},
    {k="lighter", t="Lighter", n="🔥 Lighter", c=Colors.Loot},
    {k="lockpick", t="Lockpick", n="🔓 Lockpick", c=Colors.Loot},
    {k="vitamin", t="Vitamin", n="💊 Vitamin", c=Colors.Loot},
    {k="crucifix", t="Crucifix", n="✝️ Crucifix", c=Colors.Loot},
    {k="flashlight", t="Flashlight", n="🔦 Flashlight", c=Colors.Loot},
    {k="bulklight", t="Flashlight", n="🔦 Bulklight", c=Colors.Loot},
    
    -- == BACKDOOR ==
    {k="vial", t="Vial", n="🧪 Vial", c=Colors.Quest},
    {k="timer", t="TimerLever", n="⏳ Timer Lever", c=Colors.Quest},
    
    -- == SPECIALS ==
    {k="drawer", t="Drawer", n="Drawer", c=nil},
}

-- Entity Database (Tên trong Game -> Tên hiển thị)
local EntityDB = {
    -- Hotel
    ["RushMoving"]={N="🚨 RUSH", Type="ESP_Main"}, 
    ["AmbushMoving"]={N="⚡ AMBUSH", Type="ESP_Main"}, 
    ["Eyes"]={N="👀 EYES", Type="ESP_Main"}, 
    ["Screech"]={N="👾 SCREECH", Type="ESP_Main"}, 
    ["Halt"]={N="🛑 HALT", Type="ESP_Main"},
    ["SeekMoving"]={N="👁️ SEEK", Type="ESP_Main"}, 
    ["FigureRagdoll"]={N="👺 FIGURE", Type="ESP_Main"},
    ["Glitch"]={N="👾 GLITCH", Type="ESP_Main", C=Colors.Rare},
    ["Void"]={N="🌑 VOID", Type="ESP_Main", C=Colors.Rare},
    ["JeffTheKiller"]={N="🔪 JEFF", Type="ESP_Main"}, -- April Fools
    
    -- Mines
    ["GiggleCeiling"]={N="🤪 GIGGLE", Type="ESP_Floor2"}, 
    ["Gloombat"]={N="🦇 GLOOMBAT", Type="ESP_Floor2"}, 
    ["GrumbleRig"]={N="🐛 GRUMBLE", Type="ESP_Floor2"},
    ["Snare"]={N="🚫 BẪY", Type="ESP_Minor"},
    
    -- Backdoor
    ["Blitz"]={N="⚡ BLITZ", Type="ESP_Backdoor"},
    ["Lookman"]={N="👀 LOOKMAN", Type="ESP_Backdoor"},
    ["Haste"]={N="⏳ HASTE", Type="ESP_Backdoor"},
    
    -- Rooms
    ["A60"]={N="A-60", Type="ESP_Main"},
    ["A90"]={N="🚫 A-90", Type="ESP_Main"},
    ["A120"]={N="A-120", Type="ESP_Main"},
    
    -- Minor
    ["Timothy"]={N="🕷️ TIMOTHY", Type="ESP_Minor"},
    ["Jack"]={N="👻 JACK", Type="ESP_Minor"},
    ["Window"]={N="🪟 WINDOW", Type="ESP_Minor"}
}

local function Identify(prompt)
    if not prompt or not prompt.Parent then return nil end
    local scan = (prompt.Name .. (prompt.Parent.Name or "") .. (prompt.ObjectText or "") .. (prompt.ActionText or "")):lower()
    
    if Cache.IdentityCache[scan] then return unpack(Cache.IdentityCache[scan]) end

    for _, p in ipairs(Patterns) do
        if scan:find(p.k) then
            Cache.IdentityCache[scan] = {p.t, p.n, p.c}
            return p.t, p.n, p.c
        end
    end
    return nil, nil, nil
end

-- // 3. CORE LOGIC (FIXED)
local function IsValidTarget(prompt)
    local scan = (prompt.Name .. (prompt.Parent.Name or "") .. (prompt.ObjectText or "") .. (prompt.ActionText or "")):lower()
    
    -- 1. Blacklist (Chặn tuyệt đối)
    local blacklist = {"painting", "toilet", "bed", "wardrobe", "closet", "cabinet", "locker", "hide", "switch"}
    for _, b in pairs(blacklist) do
        if scan:find(b) then 
            if (scan:find("bed") and Config.Auto.Bed) or ((scan:find("wardrobe") or scan:find("closet")) and Config.Auto.Wardrobe) then
                return true
            end
            return false 
        end
    end

    -- 2. Drawer Priority
    if scan:find("drawer") then return Config.Auto.Drawer end

    -- 3. Whitelist Item (Check Config)
    local type, _, _ = Identify(prompt)
    if type and Config.Auto[type] then return true end
    
    -- 4. Door Unlock
    if Config.Auto.Unlock and scan:find("unlock") then return true end

    return false
end

-- // 4. VISUAL ENGINE
local EspEngine = {}
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

function EspEngine.Notify(title, msg)
    if Config.Notify.Chat then pcall(function() Services.TextChatService.TextChannels.RBXGeneral:SendAsync(title..": "..msg) end) end
    if Config.Notify.UI then Rayfield:Notify({Title=title, Content=msg, Duration=4}) end
end

function EspEngine.Create(obj, name, color)
    if not obj or not obj.Parent then return end
    if Cache.ESP_Registry[obj] then return end

    local container = Instance.new("Folder", Cache.Folder)
    container.Name = "ESP"
    Cache.ESP_Registry[obj] = container
    
    local hl = Instance.new("Highlight", container)
    hl.Adornee = obj; hl.FillColor = color; hl.OutlineColor = color
    hl.FillTransparency = 0.6; hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    local bgui = Instance.new("BillboardGui", container)
    bgui.AlwaysOnTop = true; bgui.Size = UDim2.new(0, 100, 0, 30); bgui.Adornee = obj; bgui.StudsOffset = Vector3.new(0, 2, 0)
    
    local label = Instance.new("TextLabel", bgui)
    label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1; label.Text = name
    label.TextColor3 = color; label.TextSize = 11; label.Font = Enum.Font.GothamBold; label.TextStrokeTransparency = 0.5
    
    obj.AncestryChanged:Connect(function(_, parent) if not parent then container:Destroy() end end)
end

function EspEngine.Refresh() Cache.Folder:ClearAllChildren(); table.clear(Cache.ESP_Registry) end

-- // 5. GLOBAL SCANNER (CACHE ALL, CHECK NONE)
local function ProcessObject(v)
    -- A. Entity Check (Database)
    local entData = EntityDB[v.Name]
    if entData then
        -- Anti Logic
        if Config.Anti.Eyes and v.Name == "Eyes" then task.wait(); v:Destroy(); return end
        if Config.Anti.Lookman and v.Name == "Lookman" then -- Backdoor anti
             -- Logic Anti Lookman (Cần quay đi, nhưng ở đây chỉ warn/esp)
        end

        if Config.Visuals[entData.Type] then
            EspEngine.Create(v, entData.N, entData.C or Colors.Entity)
        end
        EspEngine.Notify("⚠️ CẢNH BÁO", entData.N .. " ĐANG TỚI!")
        return
    end
    
    -- B. Special Dupe (Cửa Giả)
    if v.Name == "DoorFake" and Config.Visuals.ESP_Dupe then
        EspEngine.Create(v, "❌ DUPE", Colors.Entity)
        return
    end

    -- C. Guiding Light
    if (v.Name == "GuidingLight" or v.Name == "Guidance") and Config.Visuals.ESP_Guiding then
        EspEngine.Create(v, "💙 DẪN ĐƯỜNG", Colors.Quest)
        return
    end

    -- D. Door
    if v.Name == "Door" and v.Parent.Name == "Door" and Config.Visuals.Doors then
        EspEngine.Create(v, "Cửa", Colors.Door)
        return
    end

    -- E. Items / Prompts
    if v:IsA("ProximityPrompt") then
        local type, name, col = Identify(v)
        
        -- AUTO LOOT CACHE: Lưu TẤT CẢ prompt hợp lệ vào cache
        -- Khoảng cách KHÔNG được check ở đây để tránh lỗi item xa
        if IsValidTarget(v) then
            if not Cache.Interactables[v] then Cache.Interactables[v] = true end
        end
        
        -- ESP
        if type and col and Config.Visuals["ESP_"..type] then
            if not v.Parent.Name:lower():find("drawer") then
                EspEngine.Create(v.Parent, name, col)
            end
        end
        
        -- Hint Book
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

-- // 6. LOOPS (DISTANCE CHECK HERE)
-- Auto Loot Loop
task.spawn(function()
    while task.wait(0.1) do
        if Client.Character and Client.Character:FindFirstChild("HumanoidRootPart") then
            local pos = Client.Character.HumanoidRootPart.Position
            for prompt, _ in pairs(Cache.Interactables) do
                if prompt.Parent and prompt.Enabled then
                    local pPos = prompt.Parent:GetPivot().Position
                    -- Check khoảng cách 12 studs (Tối ưu)
                    if (pos - pPos).Magnitude <= 12 then
                        if IsValidTarget(prompt) then
                             if Config.Auto.Instant then prompt.HoldDuration = 0 end
                             fireproximityprompt(prompt)
                        end
                    end
                else
                    Cache.Interactables[prompt] = nil
                end
            end
        end
    end
end)

-- Speed Hook
Services.RunService.Heartbeat:Connect(function(dt)
    if Config.Speed.Enabled and Client.Character and Client.Humanoid and Client.RootPart then
        if Client.Humanoid.WalkSpeed ~= Config.Speed.Server then Client.Humanoid.WalkSpeed = Config.Speed.Server end
        if Client.Humanoid.MoveDirection.Magnitude > 0 then
            Client.RootPart.CFrame = Client.RootPart.CFrame + (Client.Humanoid.MoveDirection * (Config.Speed.Target - Config.Speed.Server) * dt)
            Client.RootPart.Velocity = Vector3.new(Client.RootPart.Velocity.X, 0, Client.RootPart.Velocity.Z)
        end
    end
end)

-- Entity Watcher & Room Init
Services.Workspace.ChildAdded:Connect(function(c) ProcessObject(c) end)
local Rooms = Services.Workspace:WaitForChild("CurrentRooms")
for _, r in pairs(Rooms:GetChildren()) do task.spawn(ProcessRoom, r) end
Rooms.ChildAdded:Connect(function(r) task.wait(0.5); ProcessRoom(r) end)

local function HookChar(c)
    Client.Character = c; Client.Humanoid = c:WaitForChild("Humanoid", 10); Client.RootPart = c:WaitForChild("HumanoidRootPart", 10)
    local G = "God_v76"; pcall(function() Services.PhysicsService:CreateCollisionGroup(G); Services.PhysicsService:CollisionGroupSetCollidable(G,"Default",true); Services.PhysicsService:CollisionGroupSetCollidable(G,"Players",false) end)
    Services.RunService.Stepped:Connect(function() if Config.GodMode and c then for _,p in pairs(c:GetChildren()) do if p:IsA("BasePart") then p.CanTouch=false; p.CollisionGroup=G end end end end)
end
Client.Player.CharacterAdded:Connect(HookChar)
if Client.Player.Character then HookChar(Client.Player.Character) end

-- // 7. RAYFIELD UI (MASSIVE)
local Window = Rayfield:CreateWindow({Name = "DOORS v76.0 OMNIVERSE", ConfigurationSaving = {Enabled = false}})

-- MAIN TAB
local TabM = Window:CreateTab("Chính", 4483362458)
TabM:CreateToggle({Name="Speed Hook", CurrentValue=false, Callback=function(v) Config.Speed.Enabled=v end})
TabM:CreateSlider({Name="Tốc độ", Range={16,50}, Increment=1, CurrentValue=22, Callback=function(v) Config.Speed.Target=v end})
TabM:CreateToggle({Name="Ghost God Mode", CurrentValue=false, Callback=function(v) Config.GodMode=v end})
TabM:CreateToggle({Name="Chat Notify", CurrentValue=true, Callback=function(v) Config.Notify.Chat=v end})
TabM:CreateToggle({Name="UI Notify", CurrentValue=true, Callback=function(v) Config.Notify.UI=v end})

-- AUTO LOOT TAB
local TabA = Window:CreateTab("Auto Loot", 4483362458)
TabA:CreateSection("Action")
TabA:CreateToggle({Name="Unlock Door", CurrentValue=true, Callback=function(v) Config.Auto.Unlock=v end})
TabA:CreateToggle({Name="Open Drawer", CurrentValue=true, Callback=function(v) Config.Auto.Drawer=v end})
TabA:CreateSection("Hotel (F1)")
TabA:CreateToggle({Name="Gold", CurrentValue=true, Callback=function(v) Config.Auto.Gold=v end})
TabA:CreateToggle({Name="Key & Lever", CurrentValue=true, Callback=function(v) Config.Auto.Key=v; Config.Auto.Lever=v end})
TabA:CreateToggle({Name="Lighter/Lockpick", CurrentValue=true, Callback=function(v) Config.Auto.Lighter=v; Config.Auto.Lockpick=v end})
TabA:CreateToggle({Name="Vitamin/Crucifix", CurrentValue=true, Callback=function(v) Config.Auto.Vitamin=v; Config.Auto.Crucifix=v end})
TabA:CreateToggle({Name="Book/Breaker", CurrentValue=true, Callback=function(v) Config.Auto.Book=v; Config.Auto.Breaker=v end})
TabA:CreateSection("Mines (F2)")
TabA:CreateToggle({Name="Fuse", CurrentValue=true, Callback=function(v) Config.Auto.Fuse=v end})
TabA:CreateToggle({Name="Shears", CurrentValue=true, Callback=function(v) Config.Auto.Shears=v end})
TabA:CreateToggle({Name="Battery/Glowstick", CurrentValue=true, Callback=function(v) Config.Auto.Battery=v; Config.Auto.Glowstick=v end})
TabA:CreateToggle({Name="Bandage/Shake", CurrentValue=true, Callback=function(v) Config.Auto.Bandage=v; Config.Auto.Shake=v end})
TabA:CreateSection("Backdoor")
TabA:CreateToggle({Name="Timer Lever/Vial", CurrentValue=true, Callback=function(v) Config.Auto.TimerLever=v; Config.Auto.Vial=v end})

-- VISUALS ITEMS
local TabVI = Window:CreateTab("ESP Items", 4483362458)
local function Ref() EspEngine.Refresh(); local r=Services.Workspace.CurrentRooms; for _,v in pairs(r:GetChildren()) do local n=tonumber(v.Name)+1; for _,d in pairs(v:GetDescendants()) do ProcessObject(d) end end end
TabVI:CreateToggle({Name="Guiding Light", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Guiding=v; Ref() end})
TabVI:CreateToggle({Name="Door", CurrentValue=true, Callback=function(v) Config.Visuals.Doors=v; Ref() end})
TabVI:CreateSection("Hotel Items")
TabVI:CreateToggle({Name="Key/Lever/Book", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Key=v; Config.Visuals.ESP_Lever=v; Config.Visuals.ESP_Book=v; Ref() end})
TabVI:CreateToggle({Name="Gold", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Gold=v; Ref() end})
TabVI:CreateToggle({Name="Tools (Light/Pick)", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Lighter=v; Config.Visuals.ESP_Flashlight=v; Config.Visuals.ESP_Lockpick=v; Ref() end})
TabVI:CreateSection("Mines Items")
TabVI:CreateToggle({Name="Fuse/Shears", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Fuse=v; Config.Visuals.ESP_Shears=v; Ref() end})
TabVI:CreateToggle({Name="Anchor/Valve", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Anchor=v; Config.Visuals.ESP_Valve=v; Ref() end})

-- VISUALS ENTITIES
local TabVE = Window:CreateTab("ESP Entities", 4483362458)
TabVE:CreateToggle({Name="Main (Rush/Ambush/Seek/Figure)", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Entities=v; Config.Visuals.ESP_Figure=v; Config.Visuals.ESP_Seek=v; Ref() end})
TabVE:CreateToggle({Name="Backdoor (Blitz/Lookman)", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Backdoor=v; Ref() end})
TabVE:CreateToggle({Name="Floor 2 (Giggle/Grumble/Bat)", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Giggle=v; Config.Visuals.ESP_Grumble=v; Config.Visuals.ESP_Gloombat=v; Ref() end})
TabVE:CreateToggle({Name="Minor (Timothy/Jack/Dupe)", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Minor=v; Config.Visuals.ESP_Dupe=v; Ref() end})
TabVE:CreateToggle({Name="FullBright", CurrentValue=true, Callback=function(v) Config.Visuals.FullBright=v; task.spawn(function() while Config.Visuals.FullBright do Services.Lighting.Ambient=Color3.new(1,1,1); task.wait(1) end end) end})

Rayfield:Notify({Title = "V76.0 OMNIVERSE", Content = "All Floors. Full ESP. Fixed Logic.", Duration = 5})
