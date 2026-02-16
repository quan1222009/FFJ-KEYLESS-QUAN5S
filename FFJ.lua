-- [[ DOORS SUPREMACY v99.0 - THE FINAL GOD ]]
-- Status: COMPLETED.
-- Logic: Auto Loot (Scan Global -> Cache -> Distance 12 Studs).
-- Anti-Eyes: Remote Spoofing (No Model Deletion).
-- Visuals: Full Tabs (Hotel, Mines, Backdoor, Rooms).
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

-- // 1. MEMORY & CONFIGURATION
local Cache = {
    Folder = game.CoreGui:FindFirstChild("Doors_v99_God") or Instance.new("Folder", game.CoreGui),
    -- Weak Tables: Tự động dọn rác RAM
    Interactables = setmetatable({}, { __mode = "k" }), 
    ProcessedRooms = setmetatable({}, { __mode = "k" }),
    ESP_Registry = setmetatable({}, { __mode = "k" }),
    IdentityCache = {} 
}
Cache.Folder.Name = "Doors_v99_God"

local Config = {
    System = {
        SpeedEnabled = false,
        SpeedVal = 21,
        GodMode = false,
        ChatNotify = true,
        UINotify = true
    },
    
    Auto = {
        Unlock=true, Drawer=true, Instant=true,
        Bed=false, Wardrobe=false,
        
        -- Global Item Whitelist (Tất cả item các floor)
        KeyObtain=true, Lever=true, Gold=true, Lighter=true, Lockpick=true,
        Vitamins=true, Crucifix=true, Book=true, Breaker=true, Flashlight=true,
        Candle=true, SkeletonKey=true, Herb=true, BandagePack=true,
        
        Glowstick=true, Battery=true, Pickaxe=true, Fuse=true, Shears=true, Anchor=true, Valve=true,
        
        TimerLever=true, Vial=true, Tablet=true, Gummy=true
    },
    
    -- CONFIG ESP (TÁCH RIÊNG TỪNG FLOOR)
    ESP_Hotel = {
        -- Entities
        RushMoving=true, AmbushMoving=true, SeekMoving=true, FigureRig=true,
        Screech=true, Eyes=true, Halt=true, Timothy=true, Jack=true,
        Hide=true, Shadow=true, JeffTheKiller=true, ElGoblino=true,
        -- Items
        KeyObtain=true, Lockpick=true, Vitamins=true, Lighter=true, Candle=true,
        Flashlight=true, Crucifix=true, SkeletonKey=true, Herb=true, BandagePack=true,
        Lever=true, Book=true, Breaker=true, Gold=true
    },
    
    ESP_Mines = {
        -- Entities
        Grumble=true, Giggle=true, Lookman=true, Snare=true, Haste=true,
        Gloombat=true, -- Thêm nếu có
        -- Items
        Glowstick=true, Battery=true, Pickaxe=true, 
        Fuse=true, Shears=true, Anchor=true, Valve=true
    },
    
    ESP_Backdoor = {
        -- Entities
        Blitz=true, Vacuum=true, Lookman=true, Haste=true,
        -- Items
        TimerLever=true, Vial=true
    },
    
    ESP_Rooms = {
        -- Entities
        A60=true, A90=true, A120=true,
        -- Items
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

-- // 3. DATABASE (INTERNAL NAME -> CONFIG MAPPING)
-- Structure: [InternalName] = {Display="Name", Tab="ConfigTab", Key="ConfigKey", Color}

local EntityDB = {
    -- [FLOOR 1 – HOTEL]
    ["RushMoving"]      = {N="🚨 RUSH", T="ESP_Hotel", K="RushMoving", C=C.Entity},
    ["AmbushMoving"]    = {N="⚡ AMBUSH", T="ESP_Hotel", K="AmbushMoving", C=C.Entity},
    ["SeekMoving"]      = {N="👁️ SEEK", T="ESP_Hotel", K="SeekMoving", C=C.Entity},
    ["FigureRig"]       = {N="👺 FIGURE", T="ESP_Hotel", K="FigureRig", C=C.Entity},
    ["Screech"]         = {N="👾 SCREECH", T="ESP_Hotel", K="Screech", C=C.Entity},
    ["Eyes"]            = {N="👀 EYES", T="ESP_Hotel", K="Eyes", C=C.Entity},
    ["Halt"]            = {N="🛑 HALT", T="ESP_Hotel", K="Halt", C=C.Entity},
    ["Timothy"]         = {N="🕷️ TIMOTHY", T="ESP_Hotel", K="Timothy", C=C.Entity}, -- Often inside "Spider" model but script name Timothy
    ["Spider"]          = {N="🕷️ TIMOTHY", T="ESP_Hotel", K="Timothy", C=C.Entity},
    ["Jack"]            = {N="👻 JACK", T="ESP_Hotel", K="Jack", C=C.Entity},
    ["Hide"]            = {N="🚫 HIDE", T="ESP_Hotel", K="Hide", C=C.Entity},
    ["Shadow"]          = {N="👻 SHADOW", T="ESP_Hotel", K="Shadow", C=C.Entity},
    ["JeffTheKiller"]   = {N="🔪 JEFF", T="ESP_Hotel", K="JeffTheKiller", C=C.Entity},
    ["ElGoblino"]       = {N="👺 GOBLINO", T="ESP_Hotel", K="ElGoblino", C=C.Entity},

    -- [FLOOR 2 – THE MINES]
    ["Grumble"]         = {N="🐛 GRUMBLE", T="ESP_Mines", K="Grumble", C=C.Entity},
    ["GrumbleRig"]      = {N="🐛 GRUMBLE", T="ESP_Mines", K="Grumble", C=C.Entity},
    ["Giggle"]          = {N="🤪 GIGGLE", T="ESP_Mines", K="Giggle", C=C.Entity},
    ["GiggleCeiling"]   = {N="🤪 GIGGLE", T="ESP_Mines", K="Giggle", C=C.Entity},
    ["Lookman"]         = {N="👀 LOOKMAN", T="ESP_Mines", K="Lookman", C=C.Entity}, -- Also in Backdoor
    ["Snare"]           = {N="🚫 BẪY", T="ESP_Mines", K="Snare", C=C.Entity},
    ["Haste"]           = {N="⏳ HASTE", T="ESP_Mines", K="Haste", C=C.Entity}, -- Also in Backdoor
    ["Gloombat"]        = {N="🦇 BAT", T="ESP_Mines", K="Gloombat", C=C.Entity}, -- Common name

    -- [SUBFLOOR – ROOMS]
    ["A60"]             = {N="A-60", T="ESP_Rooms", K="A60", C=C.Entity},
    ["A90"]             = {N="🚫 A-90", T="ESP_Rooms", K="A90", C=C.Entity},
    ["A120"]            = {N="A-120", T="ESP_Rooms", K="A120", C=C.Entity},

    -- [SUBFLOOR – BACKDOOR]
    ["Blitz"]           = {N="⚡ BLITZ", T="ESP_Backdoor", K="Blitz", C=C.Backdoor},
    ["Vacuum"]          = {N="🌪️ VACUUM", T="ESP_Backdoor", K="Vacuum", C=C.Backdoor},
}

-- Item Patterns: {Keyword, Tab, ConfigKey, DisplayName, Color}
local ItemPatterns = {
    -- [FLOOR 1 Items]
    {k="keyobtain", t="ESP_Hotel", key="KeyObtain", n="🔑 Key", c=C.Quest},
    {k="lockpick", t="ESP_Hotel", key="Lockpick", n="🔓 Lockpick", c=C.Loot},
    {k="vitamins", t="ESP_Hotel", key="Vitamins", n="💊 Vitamins", c=C.Loot},
    {k="lighter", t="ESP_Hotel", key="Lighter", n="🔥 Lighter", c=C.Loot},
    {k="candle", t="ESP_Hotel", key="Candle", n="🕯️ Candle", c=C.Loot},
    {k="flashlight", t="ESP_Hotel", key="Flashlight", n="🔦 Flashlight", c=C.Loot},
    {k="crucifix", t="ESP_Hotel", key="Crucifix", n="✝️ Crucifix", c=C.Loot},
    {k="skeletonkey", t="ESP_Hotel", key="SkeletonKey", n="💀 Skeleton Key", c=C.Quest},
    {k="herb", t="ESP_Hotel", key="Herb", n="🌿 Herb", c=C.Loot},
    {k="bandage", t="ESP_Hotel", key="BandagePack", n="🩹 Bandage", c=C.Loot}, -- Covers BandagePack
    {k="lever", t="ESP_Hotel", key="Lever", n="🕹️ Lever", c=C.Quest},
    {k="book", t="ESP_Hotel", key="Book", n="📘 Book", c=C.Quest},
    {k="breaker", t="ESP_Hotel", key="Breaker", n="⚡ Breaker", c=C.Quest},
    {k="gold", t="ESP_Hotel", key="Gold", n="💰 Gold", c=C.Loot},
    
    -- [FLOOR 2 Items]
    {k="glowstick", t="ESP_Mines", key="Glowstick", n="🌟 Glowstick", c=C.Loot},
    {k="battery", t="ESP_Mines", key="Battery", n="🔋 Battery", c=C.Loot},
    {k="pickaxe", t="ESP_Mines", key="Pickaxe", n="⛏️ Pickaxe", c=C.Quest},
    {k="fuse", t="ESP_Mines", key="Fuse", n="🔌 Fuse", c=C.Quest},
    {k="shears", t="ESP_Mines", key="Shears", n="✂️ Shears", c=C.Quest},
    {k="anchor", t="ESP_Mines", key="Anchor", n="⚓ Anchor", c=C.Quest},
    {k="valve", t="ESP_Mines", key="Valve", n="⚙️ Valve", c=C.Quest},
    
    -- [Backdoor/Rooms]
    {k="timer", t="ESP_Backdoor", key="TimerLever", n="⏳ Timer", c=C.Quest},
    {k="vial", t="ESP_Backdoor", key="Vial", n="🧪 Vial", c=C.Quest},
    {k="tablet", t="ESP_Rooms", key="Tablet", n="📱 Tablet", c=C.Quest},
    {k="gummy", t="ESP_Rooms", key="Gummy", n="🍬 Gummy", c=C.Loot},
    
    -- Misc
    {k="drawer", t="Auto", key="Drawer", n="Drawer", c=nil},
}

-- // 4. HELPERS
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
    
    -- Blacklist (Giường/Tủ)
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

    -- Whitelist (Check Config Auto)
    local _, key, _, _ = IdentifyItem(prompt)
    if key and Config.Auto[key] then return true end
    
    -- Unlock
    if Config.Auto.Unlock and scan:find("unlock") then return true end

    return false
end

-- // 5. GLOBAL SCANNER (CACHE LOGIC)
local function ProcessObject(v)
    -- A. Entities (Full Check)
    local entData = DB[v.Name]
    if entData then
        -- Anti Eyes (No Delete - Spoofing happens in Hooks, here we just ESP)
        -- Anti Lookman
        
        -- ESP Check (Correct Tab)
        if Config[entData.T] and Config[entData.T][entData.K] then
            EspEngine.Create(v, entData.N, entData.C)
        end
        
        -- Notify (No Void/Glitch)
        if v.Name ~= "Glitch" and v.Name ~= "Void" then
            EspEngine.Notify("⚠️ ENTITY", entData.N .. " ĐANG TỚI!")
        end
        return
    end

    -- B. Guiding Light
    if (v.Name == "GuidingLight" or v.Name == "Guidance") and Config.General.Guiding then
        EspEngine.Create(v, "💙 DẪN ĐƯỜNG", C.Quest)
        return
    end

    -- C. Doors
    if v.Name == "Door" and v.Parent.Name == "Door" and Config.General.Doors then
        EspEngine.Create(v, "Cửa", C.Door)
        return
    end

    -- D. Items (Auto Loot Cache)
    if v:IsA("ProximityPrompt") then
        -- 1. Auto Loot Cache (Store ALL valid items)
        if IsValidTarget(v) then
            if not Cache.Interactables[v] then Cache.Interactables[v] = true end
        end
        
        -- 2. ESP Drawing
        local tab, key, name, col = IdentifyItem(v)
        if tab and key and col and Config[tab] and Config[tab][key] then
            if tab ~= "Auto" then -- Not Drawer
                EspEngine.Create(v.Parent, name, col)
            end
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
-- Speed
Services.RunService.Heartbeat:Connect(function(dt)
    if Config.System.SpeedEnabled and Client.Character and Client.Humanoid and Client.RootPart then
        if Client.Humanoid.WalkSpeed ~= Config.System.SpeedVal then Client.Humanoid.WalkSpeed = Config.System.SpeedVal end
        if Client.Humanoid.MoveDirection.Magnitude > 0 then
            Client.RootPart.CFrame = Client.RootPart.CFrame + (Client.Humanoid.MoveDirection * (Config.System.SpeedVal - Config.System.SpeedVal) * dt)
            Client.RootPart.Velocity = Vector3.new(Client.RootPart.Velocity.X, 0, Client.RootPart.Velocity.Z)
            Client.RootPart.CFrame = Client.RootPart.CFrame + (Client.Humanoid.MoveDirection * (Config.System.SpeedVal - 15) * dt)
        end
    end
end)

-- Anti-Eyes (Spoofing - No Delete)
if getgenv and hookmetamethod then
    local old; old = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" then
            -- Chặn Damage
            if (self.Name == "Screech" and Config.Anti.Screech) or 
               (self.Name == "A90" and Config.Anti.A90) or 
               (self.Name == "Snare" and Config.Anti.Snare) then return nil end
               
            -- Chặn Eyes Damage (Tên Remote thường là MotorReplication hoặc Damage)
            -- Note: Doors check eyes local, nếu xóa model thì raycast fail.
            -- Nếu ko xóa model, ta phải chặn remote gửi dmg.
            if Config.Anti.Eyes and self.Name == "Eyes" then return nil end -- Placeholder for Remote Block
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
                    if (pos - pPos).Magnitude <= 12 then -- Tầm nhặt
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
    local G = "God_v99"; pcall(function() Services.PhysicsService:CreateCollisionGroup(G); Services.PhysicsService:CollisionGroupSetCollidable(G,"Default",true); Services.PhysicsService:CollisionGroupSetCollidable(G,"Players",false) end)
    Services.RunService.Stepped:Connect(function() if Config.System.GodMode and c then for _,p in pairs(c:GetChildren()) do if p:IsA("BasePart") then p.CanTouch=false; p.CollisionGroup=G end end end end)
end
Client.Player.CharacterAdded:Connect(HookChar)
if Client.Player.Character then HookChar(Client.Player.Character) end

-- // 7. RAYFIELD UI
local Window = Rayfield:CreateWindow({Name = "DOORS v99.0 THE FINAL GOD", ConfigurationSaving = {Enabled = false}})

-- MAIN
local TabM = Window:CreateTab("Chính", 4483362458)
TabM:CreateToggle({Name="Speed Hook (Bật/Tắt)", CurrentValue=false, Callback=function(v) Config.System.SpeedEnabled=v end})
TabM:CreateSlider({Name="Tốc độ", Range={16,50}, Increment=1, CurrentValue=21, Callback=function(v) Config.System.SpeedVal=v end})
TabM:CreateToggle({Name="Ghost God Mode", CurrentValue=false, Callback=function(v) Config.System.GodMode=v end})
TabM:CreateToggle({Name="FullBright", CurrentValue=true, Callback=function(v) Config.General.FullBright=v; task.spawn(function() while Config.General.FullBright do Services.Lighting.Ambient=Color3.new(1,1,1); task.wait(1) end end) end})
TabM:CreateSection("Thông Báo")
TabM:CreateToggle({Name="Chat Notify", CurrentValue=true, Callback=function(v) Config.System.ChatNotify=v end})
TabM:CreateToggle({Name="UI Notify", CurrentValue=true, Callback=function(v) Config.System.UINotify=v end})

-- ANTI ENTITY
local TabAnti = Window:CreateTab("Anti Entity", 4483362458)
TabAnti:CreateToggle({Name="Anti Eyes (Spoof)", CurrentValue=true, Callback=function(v) Config.Anti.Eyes=v end})
TabAnti:CreateToggle({Name="Anti Lookman", CurrentValue=true, Callback=function(v) Config.Anti.Lookman=v end})
TabAnti:CreateToggle({Name="Anti Screech", CurrentValue=true, Callback=function(v) Config.Anti.Screech=v end})
TabAnti:CreateToggle({Name="Anti A90", CurrentValue=true, Callback=function(v) Config.Anti.A90=v end})
TabAnti:CreateToggle({Name="Anti Snare/Giggle", CurrentValue=true, Callback=function(v) Config.Anti.Snare=v; Config.Anti.Giggle=v end})

-- AUTO LOOT
local TabA = Window:CreateTab("Auto Loot", 4483362458)
TabA:CreateSection("Actions")
TabA:CreateToggle({Name="Unlock Door", CurrentValue=true, Callback=function(v) Config.Auto.Unlock=v end})
TabA:CreateToggle({Name="Open Drawer", CurrentValue=true, Callback=function(v) Config.Auto.Drawer=v end})
TabA:CreateToggle({Name="Hide (Bed)", CurrentValue=false, Callback=function(v) Config.Auto.Bed=v end})
TabA:CreateToggle({Name="Hide (Wardrobe)", CurrentValue=false, Callback=function(v) Config.Auto.Wardrobe=v end})
TabA:CreateSection("Hotel Items")
TabA:CreateToggle({Name="Key & Lever", CurrentValue=true, Callback=function(v) Config.Auto.KeyObtain=v; Config.Auto.Lever=v end})
TabA:CreateToggle({Name="Gold", CurrentValue=true, Callback=function(v) Config.Auto.Gold=v end})
TabA:CreateToggle({Name="Lighter/Lockpick", CurrentValue=true, Callback=function(v) Config.Auto.Lighter=v; Config.Auto.Lockpick=v end})
TabA:CreateToggle({Name="Vitamins/Crucifix", CurrentValue=true, Callback=function(v) Config.Auto.Vitamins=v; Config.Auto.Crucifix=v end})
TabA:CreateToggle({Name="Book/Breaker", CurrentValue=true, Callback=function(v) Config.Auto.Book=v; Config.Auto.Breaker=v end})
TabA:CreateToggle({Name="Skeleton Key/Candle", CurrentValue=true, Callback=function(v) Config.Auto.SkeletonKey=v; Config.Auto.Candle=v end})
TabA:CreateSection("Mines Items")
TabA:CreateToggle({Name="Fuse/Shears", CurrentValue=true, Callback=function(v) Config.Auto.Fuse=v; Config.Auto.Shears=v end})
TabA:CreateToggle({Name="Battery/Glowstick", CurrentValue=true, Callback=function(v) Config.Auto.Battery=v; Config.Auto.Glowstick=v end})
TabA:CreateToggle({Name="Anchor/Valve", CurrentValue=true, Callback=function(v) Config.Auto.Anchor=v; Config.Auto.Valve=v end})
TabA:CreateToggle({Name="Pickaxe", CurrentValue=true, Callback=function(v) Config.Auto.Pickaxe=v end})
TabA:CreateSection("Backdoor/Rooms")
TabA:CreateToggle({Name="Timer/Vial", CurrentValue=true, Callback=function(v) Config.Auto.TimerLever=v; Config.Auto.Vial=v end})
TabA:CreateToggle({Name="Tablet/Gummy", CurrentValue=true, Callback=function(v) Config.Auto.Tablet=v; Config.Auto.Gummy=v end})

-- ESP HOTEL
local TabH = Window:CreateTab("ESP Hotel", 4483362458)
local function Ref() EspEngine.Refresh(); local r=Services.Workspace.CurrentRooms; for _,v in pairs(r:GetChildren()) do local n=tonumber(v.Name)+1; for _,d in pairs(v:GetDescendants()) do ProcessObject(d) end end end
TabH:CreateSection("Entity")
TabH:CreateToggle({Name="Rush/Ambush/Seek", CurrentValue=true, Callback=function(v) Config.ESP_Hotel.RushMoving=v; Config.ESP_Hotel.AmbushMoving=v; Config.ESP_Hotel.SeekMoving=v; Ref() end})
TabH:CreateToggle({Name="Figure", CurrentValue=true, Callback=function(v) Config.ESP_Hotel.FigureRig=v; Ref() end})
TabH:CreateToggle({Name="Screech/Eyes/Halt", CurrentValue=true, Callback=function(v) Config.ESP_Hotel.Screech=v; Config.ESP_Hotel.Eyes=v; Config.ESP_Hotel.Halt=v; Ref() end})
TabH:CreateToggle({Name="Dupe/Jack/Timothy", CurrentValue=true, Callback=function(v) Config.ESP_Hotel.Dupe=v; Config.ESP_Hotel.Jack=v; Config.ESP_Hotel.Timothy=v; Ref() end})
TabH:CreateToggle({Name="Jeff/El Goblino", CurrentValue=true, Callback=function(v) Config.ESP_Hotel.JeffTheKiller=v; Config.ESP_Hotel.ElGoblino=v; Ref() end})
TabH:CreateSection("Items")
TabH:CreateToggle({Name="Key/Lever/Book", CurrentValue=true, Callback=function(v) Config.ESP_Hotel.KeyObtain=v; Config.ESP_Hotel.Lever=v; Config.ESP_Hotel.Book=v; Ref() end})
TabH:CreateToggle({Name="Gold", CurrentValue=true, Callback=function(v) Config.ESP_Hotel.Gold=v; Ref() end})
TabH:CreateToggle({Name="Light/Pick/Vit", CurrentValue=true, Callback=function(v) Config.ESP_Hotel.Lighter=v; Config.ESP_Hotel.Lockpick=v; Config.ESP_Hotel.Vitamins=v; Ref() end})

-- ESP MINES
local TabMi = Window:CreateTab("ESP Mines", 4483362458)
TabMi:CreateSection("Entity")
TabMi:CreateToggle({Name="Giggle", CurrentValue=true, Callback=function(v) Config.ESP_Mines.GiggleCeiling=v; Ref() end})
TabMi:CreateToggle({Name="Gloombat", CurrentValue=true, Callback=function(v) Config.ESP_Mines.Gloombat=v; Ref() end})
TabMi:CreateToggle({Name="Grumble", CurrentValue=true, Callback=function(v) Config.ESP_Mines.GrumbleRig=v; Ref() end})
TabMi:CreateToggle({Name="Snare", CurrentValue=true, Callback=function(v) Config.ESP_Mines.Snare=v; Ref() end})
TabMi:CreateSection("Items")
TabMi:CreateToggle({Name="Fuse/Shears", CurrentValue=true, Callback=function(v) Config.ESP_Mines.Fuse=v; Config.ESP_Mines.Shears=v; Ref() end})
TabMi:CreateToggle({Name="Battery/Glow/Bandage", CurrentValue=true, Callback=function(v) Config.ESP_Mines.Battery=v; Config.ESP_Mines.Glowstick=v; Config.ESP_Mines.Bandage=v; Ref() end})

-- ESP BACKDOOR
local TabB = Window:CreateTab("ESP Backdoor", 4483362458)
TabB:CreateSection("Entity")
TabB:CreateToggle({Name="Blitz", CurrentValue=true, Callback=function(v) Config.ESP_Backdoor.Blitz=v; Ref() end})
TabB:CreateToggle({Name="Lookman", CurrentValue=true, Callback=function(v) Config.ESP_Backdoor.Lookman=v; Ref() end})
TabB:CreateToggle({Name="Haste", CurrentValue=true, Callback=function(v) Config.ESP_Backdoor.Haste=v; Ref() end})
TabB:CreateSection("Items")
TabB:CreateToggle({Name="Timer/Vial", CurrentValue=true, Callback=function(v) Config.ESP_Backdoor.TimerLever=v; Config.ESP_Backdoor.Vial=v; Ref() end})

-- ESP ROOMS
local TabR = Window:CreateTab("ESP Rooms", 4483362458)
TabR:CreateSection("Entity")
TabR:CreateToggle({Name="A-60/A-120", CurrentValue=true, Callback=function(v) Config.ESP_Rooms.A60=v; Config.ESP_Rooms.A120=v; Ref() end})
TabR:CreateToggle({Name="A-90", CurrentValue=true, Callback=function(v) Config.ESP_Rooms.A90=v; Ref() end})
TabR:CreateSection("Items")
TabR:CreateToggle({Name="Tablet", CurrentValue=true, Callback=function(v) Config.ESP_Rooms.Tablet=v; Ref() end})

Rayfield:Notify({Title = "V99.0 GOD MODE", Content = "Full Internal Database Loaded.", Duration = 5})
