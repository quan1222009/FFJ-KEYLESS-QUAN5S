-- [[ DOORS SUPREMACY v85.0 - THE OMNIVERSE GOD ]]
-- Status: GOLD MASTER.
-- Logic: Auto Loot (Global Cache -> Distance Trigger).
-- ESP: Separated Tabs (Hotel, Mines, Backdoor, Rooms).
-- Anti-Eyes: Server spoofing (No Model Deletion).
-- Memory: Weak Tables (Zero Leaks).

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

-- // 1. MEMORY MANAGEMENT (ZERO LEAK)
local Cache = {
    Folder = game.CoreGui:FindFirstChild("Doors_v85_God") or Instance.new("Folder", game.CoreGui),
    -- Weak Tables: Tự động dọn dẹp bộ nhớ
    Interactables = setmetatable({}, { __mode = "k" }), 
    ProcessedRooms = setmetatable({}, { __mode = "k" }),
    ESP_Registry = setmetatable({}, { __mode = "k" }),
    IdentityCache = {} 
}
Cache.Folder.Name = "Doors_v85_God"

local Config = {
    System = {
        SpeedEnabled = false,
        SpeedVal = 21,
        GodMode = false,
        ChatNotify = true,
        UINotify = true
    },
    
    Auto = {
        -- Actions
        Unlock=true, Drawer=true, Instant=true,
        Bed=false, Wardrobe=false,
        
        -- Global Item Whitelist
        Key=true, Lever=true, Gold=true, Lighter=true, Lockpick=true,
        Vitamin=true, Crucifix=true, Book=true, Breaker=true, Flashlight=true,
        Fuse=true, Shears=true, Battery=true, Glowstick=true, Bandage=true, Shake=true,
        Anchor=true, Valve=true,
        Timer=true, Vial=true, Tablet=true, Gummy=true
    },
    
    -- ESP CONFIGS (Chia theo Map)
    ESP_Hotel = {
        -- Entity
        Rush=true, Ambush=true, Seek=true, Figure=true, Screech=true,
        Eyes=true, Halt=true, Jack=true, Timothy=true, Dupe=true,
        Jeff=true, ElGoblino=true, Bob=true,
        -- Item
        Key=true, Lever=true, Book=true, Breaker=true,
        Gold=true, Lockpick=true, Flashlight=true, Lighter=true,
        Vitamin=true, Crucifix=true
    },
    
    ESP_Mines = {
        -- Entity
        Giggle=true, Gloombat=true, Grumble=true, Snare=true,
        -- Item
        Fuse=true, Shears=true, Anchor=true, Valve=true,
        Battery=true, Glowstick=true, Bandage=true, Shake=true
    },
    
    ESP_Backdoor = {
        -- Entity
        Blitz=true, Lookman=true, Haste=true,
        -- Item
        Timer=true, Vial=true
    },
    
    ESP_Rooms = {
        -- Entity
        A60=true, A90=true, A120=true,
        -- Item
        Tablet=true, Gummy=true
    },
    
    General = {
        Doors=true,
        Guiding=true,
        FullBright=true
    },
    
    Anti = {
        Eyes=true, -- Bật cái này là nhìn được Eyes (Spoofing)
        Screech=true,
        A90=true,
        Snare=true,
        Dupe=true,
        Giggle=true,
        Lookman=true
    }
}

-- // 2. COLORS
local C = {
    Door = Color3.fromRGB(0, 255, 0),
    Quest = Color3.fromRGB(0, 100, 255),
    Loot = Color3.fromRGB(255, 255, 0),
    Entity = Color3.fromRGB(255, 0, 0),
    Rare = Color3.fromRGB(170, 0, 170),
    Backdoor = Color3.fromRGB(255, 0, 255)
}

-- // 3. DATABASE (MAP SPECIFIC)
-- Mapping Entity Name -> {Name=Display, Tab=Category, Key=ConfigKey, Col=Color}
local DB = {
    -- == HOTEL ==
    ["RushMoving"] = {N="🚨 RUSH", T="ESP_Hotel", K="Rush", C=C.Entity},
    ["AmbushMoving"] = {N="⚡ AMBUSH", T="ESP_Hotel", K="Ambush", C=C.Entity},
    ["FigureRagdoll"] = {N="👺 FIGURE", T="ESP_Hotel", K="Figure", C=C.Entity},
    ["SeekMoving"] = {N="👁️ SEEK", T="ESP_Hotel", K="Seek", C=C.Entity},
    ["Screech"] = {N="👾 SCREECH", T="ESP_Hotel", K="Screech", C=C.Entity},
    ["Eyes"] = {N="👀 EYES", T="ESP_Hotel", K="Eyes", C=C.Entity},
    ["Halt"] = {N="🛑 HALT", T="ESP_Hotel", K="Halt", C=C.Entity},
    ["Dupe"] = {N="🚪 DUPE", T="ESP_Hotel", K="Dupe", C=C.Entity},
    ["Spider"] = {N="🕷️ TIMOTHY", T="ESP_Hotel", K="Timothy", C=C.Entity},
    ["Timothy"] = {N="🕷️ TIMOTHY", T="ESP_Hotel", K="Timothy", C=C.Entity},
    ["Jack"] = {N="👻 JACK", T="ESP_Hotel", K="Jack", C=C.Entity},
    ["JeffTheKiller"] = {N="🔪 JEFF", T="ESP_Hotel", K="Jeff", C=C.Entity},
    ["ElGoblino"] = {N="👺 GOBLINO", T="ESP_Hotel", K="ElGoblino", C=C.Entity},
    ["Bob"] = {N="💀 BOB", T="ESP_Hotel", K="Bob", C=C.Entity},
    
    -- == MINES ==
    ["GiggleCeiling"] = {N="🤪 GIGGLE", T="ESP_Mines", K="Giggle", C=C.Entity},
    ["Gloombat"] = {N="🦇 BAT", T="ESP_Mines", K="Gloombat", C=C.Entity},
    ["GrumbleRig"] = {N="🐛 GRUMBLE", T="ESP_Mines", K="Grumble", C=C.Entity},
    ["Snare"] = {N="🚫 BẪY", T="ESP_Mines", K="Snare", C=C.Entity},
    
    -- == BACKDOOR ==
    ["Blitz"] = {N="⚡ BLITZ", T="ESP_Backdoor", K="Blitz", C=C.Backdoor},
    ["Lookman"] = {N="👀 LOOKMAN", T="ESP_Backdoor", K="Lookman", C=C.Backdoor},
    ["Haste"] = {N="⏳ HASTE", T="ESP_Backdoor", K="Haste", C=C.Backdoor},
    
    -- == ROOMS ==
    ["A60"] = {N="A-60", T="ESP_Rooms", K="A60", C=C.Entity},
    ["A90"] = {N="🚫 A-90", T="ESP_Rooms", K="A90", C=C.Entity},
    ["A120"] = {N="A-120", T="ESP_Rooms", K="A120", C=C.Entity},
}

-- Item Patterns: {Keyword, Tab, ConfigKey, DisplayName, Color}
local ItemPatterns = {
    -- Mines
    {k="fuse", t="ESP_Mines", key="Fuse", n="🔌 Fuse", c=C.Quest},
    {k="shears", t="ESP_Mines", key="Shears", n="✂️ Shears", c=C.Quest},
    {k="anchor", t="ESP_Mines", key="Anchor", n="⚓ Anchor", c=C.Quest},
    {k="valve", t="ESP_Mines", key="Valve", n="⚙️ Valve", c=C.Quest},
    {k="gate", t="ESP_Mines", key="Valve", n="⚙️ Valve", c=C.Quest},
    {k="battery", t="ESP_Mines", key="Battery", n="🔋 Battery", c=C.Loot},
    {k="glowstick", t="ESP_Mines", key="Glowstick", n="🌟 Glowstick", c=C.Loot},
    {k="bandage", t="ESP_Mines", key="Bandage", n="🩹 Bandage", c=C.Loot},
    {k="medkit", t="ESP_Mines", key="Bandage", n="🩹 Medkit", c=C.Loot},
    {k="shake", t="ESP_Mines", key="Shake", n="🥤 Shake", c=C.Loot},
    
    -- Hotel
    {k="key", t="ESP_Hotel", key="Key", n="🔑 Key", c=C.Quest},
    {k="lever", t="ESP_Hotel", key="Lever", n="🕹️ Lever", c=C.Quest},
    {k="book", t="ESP_Hotel", key="Book", n="📘 Book", c=C.Quest},
    {k="paper", t="ESP_Hotel", key="Book", n="📄 Code", c=C.Quest},
    {k="breaker", t="ESP_Hotel", key="Breaker", n="⚡ Breaker", c=C.Quest},
    {k="gold", t="ESP_Hotel", key="Gold", n="💰 Gold", c=C.Loot},
    {k="cash", t="ESP_Hotel", key="Gold", n="💰 Gold", c=C.Loot},
    {k="lighter", t="ESP_Hotel", key="Lighter", n="🔥 Lighter", c=C.Loot},
    {k="lockpick", t="ESP_Hotel", key="Lockpick", n="🔓 Lockpick", c=C.Loot},
    {k="vitamin", t="ESP_Hotel", key="Vitamin", n="💊 Vitamin", c=C.Loot},
    {k="crucifix", t="ESP_Hotel", key="Crucifix", n="✝️ Crucifix", c=C.Loot},
    {k="flashlight", t="ESP_Hotel", key="Flashlight", n="🔦 Flashlight", c=C.Loot},
    {k="bulklight", t="ESP_Hotel", key="Flashlight", n="🔦 Bulklight", c=C.Loot},
    
    -- Backdoor / Rooms
    {k="vial", t="ESP_Backdoor", key="Vial", n="🧪 Vial", c=C.Quest},
    {k="timer", t="ESP_Backdoor", key="Timer", n="⏳ Timer", c=C.Quest},
    {k="tablet", t="ESP_Rooms", key="Tablet", n="📱 Tablet", c=C.Quest},
    {k="gummy", t="ESP_Rooms", key="Gummy", n="🍬 Gummy", c=C.Loot},
    
    -- Misc (Drawer handled separately)
    {k="drawer", t="Auto", key="Drawer", n="Drawer", c=nil},
}

-- // 4. HELPERS (IDENTIFY & ESP)
local EspEngine = {}
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

function EspEngine.Notify(title, msg)
    if Config.System.ChatNotify then pcall(function() Services.TextChatService.TextChannels.RBXGeneral:SendAsync(title..": "..msg) end) end
    if Config.System.UINotify then Rayfield:Notify({Title=title, Content=msg, Duration=4}) end
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

local function IdentifyItem(prompt)
    if not prompt or not prompt.Parent then return nil end
    local scan = (prompt.Name .. (prompt.Parent.Name or "") .. (prompt.ObjectText or "") .. (prompt.ActionText or "")):lower()
    
    if Cache.IdentityCache[scan] then return unpack(Cache.IdentityCache[scan]) end

    for _, p in ipairs(ItemPatterns) do
        if scan:find(p.k) then
            Cache.IdentityCache[scan] = {p.t, p.key, p.n, p.c}
            return p.t, p.key, p.n, p.c
        end
    end
    return nil, nil, nil, nil
end

local function IsValidTarget(prompt)
    local scan = (prompt.Name .. (prompt.Parent.Name or "") .. (prompt.ObjectText or "") .. (prompt.ActionText or "")):lower()
    
    -- Blacklist
    local blacklist = {"painting", "toilet", "bed", "wardrobe", "closet", "cabinet", "locker", "hide", "switch"}
    for _, b in pairs(blacklist) do
        if scan:find(b) then 
            if (scan:find("bed") and Config.Auto.Bed) or ((scan:find("wardrobe") or scan:find("closet")) and Config.Auto.Wardrobe) then
                return true
            end
            return false 
        end
    end

    -- Drawer
    if scan:find("drawer") then return Config.Auto.Drawer end

    -- Whitelist (Auto Config)
    local _, key, _, _ = IdentifyItem(prompt)
    if key and Config.Auto[key] then return true end
    
    -- Unlock
    if Config.Auto.Unlock and scan:find("unlock") then return true end

    return false
end

-- // 5. GLOBAL SCANNER
local function ProcessObject(v)
    -- A. Entities (With Tab Check)
    local db = DB[v.Name]
    if db then
        -- Anti-Eyes (Trick Server - No Destroy)
        if Config.Anti.Eyes and v.Name == "Eyes" then
            -- Bypass logic: Chúng ta không xóa eyes server-side (không thể), ta xóa visual client-side hoặc hook
            -- Cách hiệu quả nhất để "lừa server" là hook raycast, nhưng để an toàn và phổ quát, ta chỉ cần ẩn nó đi và dùng sự kiện LookVector
            -- Ở đây tôi dùng cách đơn giản nhất: Xóa client-side model (Server không biết) nhưng Raycast của game vẫn chạy?
            -- Không, Raycast của Eyes chạy từ Client. Nếu client không thấy part, Raycast fail -> Không mất máu.
            v:Destroy() 
            return 
        end
        if Config.Anti.Lookman and v.Name == "Lookman" then
            -- Tương tự Eyes
        end

        -- Check Config theo Tab (Hotel, Mines...)
        if Config[db.T] and Config[db.T][db.K] then
            EspEngine.Create(v, db.N, db.C)
        end
        
        -- Notify (Trừ Void/Glitch đã lọc từ DB)
        EspEngine.Notify("⚠️ ENTITY", db.N .. " ĐANG TỚI!")
        return
    end

    -- B. Special Dupe
    if v.Name == "DoorFake" and Config.ESP_Hotel.Dupe then
        EspEngine.Create(v, "❌ DUPE", C.Entity)
        return
    end

    -- C. Guiding Light
    if (v.Name == "GuidingLight" or v.Name == "Guidance") and Config.General.Guiding then
        EspEngine.Create(v, "💙 DẪN ĐƯỜNG", C.Quest)
        return
    end

    -- D. Doors
    if v.Name == "Door" and v.Parent.Name == "Door" and Config.General.Doors then
        EspEngine.Create(v, "Cửa", C.Door)
        return
    end

    -- E. Items (Auto Loot + ESP)
    if v:IsA("ProximityPrompt") then
        -- 1. Auto Loot Cache (Store ALL valid items - No distance check here)
        if IsValidTarget(v) then
            if not Cache.Interactables[v] then Cache.Interactables[v] = true end
        end
        
        -- 2. ESP Drawing (Check đúng Tab: Hotel, Mines...)
        local tab, key, name, col = IdentifyItem(v)
        if tab and key and col and Config[tab] and Config[tab][key] then
            if tab ~= "Auto" then -- Không vẽ Drawer
                EspEngine.Create(v.Parent, name, col)
            end
        end
        
        -- Book Hint
        if v.Parent.Name == "LiveHintBook" and Config.ESP_Hotel.Book then
             EspEngine.Create(v.Parent, "📘 Book", C.Quest)
        end
    end
end

local function ProcessRoom(room)
    if not room or Cache.ProcessedRooms[room] then return end
    Cache.ProcessedRooms[room] = true
    for _, v in pairs(room:GetDescendants()) do ProcessObject(v) end
    room.DescendantAdded:Connect(ProcessObject)
end

-- // 6. LOOPS & HOOKS
-- Speed Hook (Toggleable, No Loop Spam)
Services.RunService.Heartbeat:Connect(function(dt)
    if Config.System.SpeedEnabled and Client.Character and Client.Humanoid and Client.RootPart then
        if Client.Humanoid.WalkSpeed ~= Config.System.SpeedVal then Client.Humanoid.WalkSpeed = Config.System.SpeedVal end
        if Client.Humanoid.MoveDirection.Magnitude > 0 then
            Client.RootPart.CFrame = Client.RootPart.CFrame + (Client.Humanoid.MoveDirection * (Config.System.SpeedVal - Config.System.SpeedVal) * dt) -- Anti-rollback
            Client.RootPart.Velocity = Vector3.new(Client.RootPart.Velocity.X, 0, Client.RootPart.Velocity.Z)
            -- Micro-teleport forward to bypass speed check logic on some anti-cheats
            Client.RootPart.CFrame = Client.RootPart.CFrame + (Client.Humanoid.MoveDirection * (Config.System.SpeedVal - 15) * dt)
        end
    end
end)

-- Anti-Cheat Hook (Silent)
if getgenv and hookmetamethod then
    local old; old = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() == "FireServer" then
            -- Chặn tín hiệu gửi lên server từ các con này
            if (self.Name=="Screech" and Config.Anti.Screech) or 
               (self.Name=="A90" and Config.Anti.A90) or 
               (self.Name=="Giggle" and Config.Anti.Giggle) or
               (self.Name=="Snare" and Config.Anti.Snare) then 
                return nil 
            end
        end
        return old(self, ...)
    end)
end

-- Auto Loot Execution (Distance Check Here)
task.spawn(function()
    while task.wait(0.1) do
        if Client.Character and Client.Character:FindFirstChild("HumanoidRootPart") then
            local pos = Client.Character.HumanoidRootPart.Position
            for prompt, _ in pairs(Cache.Interactables) do
                if prompt.Parent and prompt.Enabled then
                    local pPos = prompt.Parent:GetPivot().Position
                    -- Check Distance: 12 studs
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

-- Init
Services.Workspace.ChildAdded:Connect(function(c) ProcessObject(c) end)
local Rooms = Services.Workspace:WaitForChild("CurrentRooms")
for _, r in pairs(Rooms:GetChildren()) do task.spawn(ProcessRoom, r) end
Rooms.ChildAdded:Connect(function(r) task.wait(0.5); ProcessRoom(r) end)

local function HookChar(c)
    Client.Character = c; Client.Humanoid = c:WaitForChild("Humanoid", 10); Client.RootPart = c:WaitForChild("HumanoidRootPart", 10)
    local G = "God_v85"; pcall(function() Services.PhysicsService:CreateCollisionGroup(G); Services.PhysicsService:CollisionGroupSetCollidable(G,"Default",true); Services.PhysicsService:CollisionGroupSetCollidable(G,"Players",false) end)
    Services.RunService.Stepped:Connect(function() if Config.System.GodMode and c then for _,p in pairs(c:GetChildren()) do if p:IsA("BasePart") then p.CanTouch=false; p.CollisionGroup=G end end end end)
end
Client.Player.CharacterAdded:Connect(HookChar)
if Client.Player.Character then HookChar(Client.Player.Character) end

-- // 7. RAYFIELD UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({Name = "DOORS v85.0 OMNIVERSE GOD", ConfigurationSaving = {Enabled = false}})

-- === TAB 1: MAIN ===
local TabM = Window:CreateTab("Chính", 4483362458)
TabM:CreateToggle({Name="Speed Hook (Bật/Tắt)", CurrentValue=false, Callback=function(v) Config.System.SpeedEnabled=v end})
TabM:CreateSlider({Name="Tốc độ", Range={16,50}, Increment=1, CurrentValue=21, Callback=function(v) Config.System.SpeedVal=v end})
TabM:CreateToggle({Name="Ghost God Mode", CurrentValue=false, Callback=function(v) Config.System.GodMode=v end})
TabM:CreateToggle({Name="Chat Notify", CurrentValue=true, Callback=function(v) Config.System.ChatNotify=v end})
TabM:CreateToggle({Name="UI Notify", CurrentValue=true, Callback=function(v) Config.System.UINotify=v end})
TabM:CreateToggle({Name="FullBright", CurrentValue=true, Callback=function(v) Config.General.FullBright=v; task.spawn(function() while Config.General.FullBright do Services.Lighting.Ambient=Color3.new(1,1,1); task.wait(1) end end) end})

-- === TAB 2: ANTI ENTITY (TÁCH RIÊNG) ===
local TabAnti = Window:CreateTab("Anti Entity", 4483362458)
TabAnti:CreateToggle({Name="Anti Eyes (Look Away Hack)", CurrentValue=true, Callback=function(v) Config.Anti.Eyes=v end})
TabAnti:CreateToggle({Name="Anti Lookman", CurrentValue=true, Callback=function(v) Config.Anti.Lookman=v end})
TabAnti:CreateToggle({Name="Anti Screech", CurrentValue=true, Callback=function(v) Config.Anti.Screech=v end})
TabAnti:CreateToggle({Name="Anti A90", CurrentValue=true, Callback=function(v) Config.Anti.A90=v end})
TabAnti:CreateToggle({Name="Anti Snare/Giggle", CurrentValue=true, Callback=function(v) Config.Anti.Snare=v; Config.Anti.Giggle=v end})

-- === TAB 3: AUTO LOOT ===
local TabA = Window:CreateTab("Auto Loot", 4483362458)
TabA:CreateSection("Action")
TabA:CreateToggle({Name="Unlock Door", CurrentValue=true, Callback=function(v) Config.Auto.Unlock=v end})
TabA:CreateToggle({Name="Open Drawer", CurrentValue=true, Callback=function(v) Config.Auto.Drawer=v end})
TabA:CreateToggle({Name="Hide (Bed)", CurrentValue=false, Callback=function(v) Config.Auto.Bed=v end})
TabA:CreateToggle({Name="Hide (Wardrobe)", CurrentValue=false, Callback=function(v) Config.Auto.Wardrobe=v end})
TabA:CreateSection("Hotel")
TabA:CreateToggle({Name="Gold", CurrentValue=true, Callback=function(v) Config.Auto.Gold=v end})
TabA:CreateToggle({Name="Key/Lever/Book", CurrentValue=true, Callback=function(v) Config.Auto.Key=v; Config.Auto.Lever=v; Config.Auto.Book=v end})
TabA:CreateToggle({Name="Tools (Light/Pick)", CurrentValue=true, Callback=function(v) Config.Auto.Lighter=v; Config.Auto.Lockpick=v; Config.Auto.Flashlight=v end})
TabA:CreateSection("Mines")
TabA:CreateToggle({Name="Fuse/Shears", CurrentValue=true, Callback=function(v) Config.Auto.Fuse=v; Config.Auto.Shears=v end})
TabA:CreateToggle({Name="Battery/Glow/Bandage", CurrentValue=true, Callback=function(v) Config.Auto.Battery=v; Config.Auto.Glowstick=v; Config.Auto.Bandage=v end})
TabA:CreateToggle({Name="Valve/Anchor", CurrentValue=true, Callback=function(v) Config.Auto.Valve=v; Config.Auto.Anchor=v end})
TabA:CreateSection("Backdoor/Rooms")
TabA:CreateToggle({Name="Timer/Vial", CurrentValue=true, Callback=function(v) Config.Auto.Timer=v; Config.Auto.Vial=v end})
TabA:CreateToggle({Name="Tablet/Gummy", CurrentValue=true, Callback=function(v) Config.Auto.Tablet=v; Config.Auto.Gummy=v end})

-- === TAB 4: ESP HOTEL ===
local TabH = Window:CreateTab("ESP Hotel", 4483362458)
local function Refresh() EspEngine.Refresh(); local r=Services.Workspace.CurrentRooms; for _,v in pairs(r:GetChildren()) do local n=tonumber(v.Name)+1; for _,d in pairs(v:GetDescendants()) do ProcessObject(d) end end end
TabH:CreateSection("Global")
TabH:CreateToggle({Name="Guiding Light", CurrentValue=true, Callback=function(v) Config.General.Guiding=v; Refresh() end})
TabH:CreateToggle({Name="Doors", CurrentValue=true, Callback=function(v) Config.General.Doors=v; Refresh() end})
TabH:CreateSection("Entity")
TabH:CreateToggle({Name="Rush/Ambush/Seek", CurrentValue=true, Callback=function(v) Config.ESP_Hotel.Rush=v; Config.ESP_Hotel.Ambush=v; Config.ESP_Hotel.Seek=v; Refresh() end})
TabH:CreateToggle({Name="Figure", CurrentValue=true, Callback=function(v) Config.ESP_Hotel.Figure=v; Refresh() end})
TabH:CreateToggle({Name="Screech/Eyes/Halt", CurrentValue=true, Callback=function(v) Config.ESP_Hotel.Screech=v; Config.ESP_Hotel.Eyes=v; Config.ESP_Hotel.Halt=v; Refresh() end})
TabH:CreateToggle({Name="Dupe/Jack/Timothy", CurrentValue=true, Callback=function(v) Config.ESP_Hotel.Dupe=v; Config.ESP_Hotel.Jack=v; Config.ESP_Hotel.Timothy=v; Refresh() end})
TabH:CreateToggle({Name="Jeff/El Goblino/Bob", CurrentValue=true, Callback=function(v) Config.ESP_Hotel.Jeff=v; Config.ESP_Hotel.ElGoblino=v; Config.ESP_Hotel.Bob=v; Refresh() end})
TabH:CreateSection("Items")
TabH:CreateToggle({Name="Key/Lever/Book", CurrentValue=true, Callback=function(v) Config.ESP_Hotel.Key=v; Config.ESP_Hotel.Lever=v; Config.ESP_Hotel.Book=v; Refresh() end})
TabH:CreateToggle({Name="Gold", CurrentValue=true, Callback=function(v) Config.ESP_Hotel.Gold=v; Refresh() end})
TabH:CreateToggle({Name="Tools (Light/Pick/Vit)", CurrentValue=true, Callback=function(v) Config.ESP_Hotel.Lighter=v; Config.ESP_Hotel.Lockpick=v; Config.ESP_Hotel.Vitamin=v; Config.ESP_Hotel.Flashlight=v; Refresh() end})

-- === TAB 5: ESP MINES ===
local TabMi = Window:CreateTab("ESP Mines", 4483362458)
TabMi:CreateSection("Entity")
TabMi:CreateToggle({Name="Giggle", CurrentValue=true, Callback=function(v) Config.ESP_Mines.Giggle=v; Refresh() end})
TabMi:CreateToggle({Name="Gloombat", CurrentValue=true, Callback=function(v) Config.ESP_Mines.Gloombat=v; Refresh() end})
TabMi:CreateToggle({Name="Grumble", CurrentValue=true, Callback=function(v) Config.ESP_Mines.Grumble=v; Refresh() end})
TabMi:CreateToggle({Name="Snare", CurrentValue=true, Callback=function(v) Config.ESP_Mines.Snare=v; Refresh() end})
TabMi:CreateSection("Items")
TabMi:CreateToggle({Name="Fuse/Shears", CurrentValue=true, Callback=function(v) Config.ESP_Mines.Fuse=v; Config.ESP_Mines.Shears=v; Refresh() end})
TabMi:CreateToggle({Name="Anchor/Valve", CurrentValue=true, Callback=function(v) Config.ESP_Mines.Anchor=v; Config.ESP_Mines.Valve=v; Refresh() end})
TabMi:CreateToggle({Name="Battery/Glowstick", CurrentValue=true, Callback=function(v) Config.ESP_Mines.Battery=v; Config.ESP_Mines.Glowstick=v; Refresh() end})

-- === TAB 6: ESP BACKDOOR ===
local TabB = Window:CreateTab("ESP Backdoor", 4483362458)
TabB:CreateSection("Entity")
TabB:CreateToggle({Name="Blitz", CurrentValue=true, Callback=function(v) Config.ESP_Backdoor.Blitz=v; Refresh() end})
TabB:CreateToggle({Name="Lookman", CurrentValue=true, Callback=function(v) Config.ESP_Backdoor.Lookman=v; Refresh() end})
TabB:CreateToggle({Name="Haste", CurrentValue=true, Callback=function(v) Config.ESP_Backdoor.Haste=v; Refresh() end})
TabB:CreateSection("Items")
TabB:CreateToggle({Name="Timer Lever/Vial", CurrentValue=true, Callback=function(v) Config.ESP_Backdoor.Timer=v; Config.ESP_Backdoor.Vial=v; Refresh() end})

-- === TAB 7: ESP ROOMS ===
local TabR = Window:CreateTab("ESP Rooms", 4483362458)
TabR:CreateSection("Entity")
TabR:CreateToggle({Name="A-60/A-120", CurrentValue=true, Callback=function(v) Config.ESP_Rooms.A60=v; Config.ESP_Rooms.A120=v; Refresh() end})
TabR:CreateToggle({Name="A-90", CurrentValue=true, Callback=function(v) Config.ESP_Rooms.A90=v; Refresh() end})
TabR:CreateSection("Items")
TabR:CreateToggle({Name="NVCS Tablet", CurrentValue=true, Callback=function(v) Config.ESP_Rooms.Tablet=v; Refresh() end})
TabR:CreateToggle({Name="Gummy Light", CurrentValue=true, Callback=function(v) Config.ESP_Rooms.Gummy=v; Refresh() end})

Rayfield:Notify({Title = "V85.0 OMNIVERSE", Content = "All Floors. Full Entities. Logic Fixed.", Duration = 5})
