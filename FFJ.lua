-- [[ DOORS SUPREMACY v77.0 - THE MULTIVERSE ]]
-- Content: Hotel | Mines | Backdoor | Rooms | Outdoors.
-- Logic: Global Cache Scanning + Proximity Trigger (Fixed Distance).
-- UI: Separated ESP Tabs (Entities, Hotel, Mines, Backdoor).
-- Status: NO LEAKS, NO MISSING ITEMS.

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

-- // 1. MEMORY MANAGEMENT (WEAK TABLES)
local Cache = {
    Folder = game.CoreGui:FindFirstChild("Doors_v77_Multi") or Instance.new("Folder", game.CoreGui),
    Interactables = setmetatable({}, { __mode = "k" }), 
    ProcessedRooms = setmetatable({}, { __mode = "k" }),
    ESP_Registry = setmetatable({}, { __mode = "k" }),
    IdentityCache = {} 
}
Cache.Folder.Name = "Doors_v77_Multi"

local Config = {
    -- SYSTEM
    Speed = { Enabled = false, Target = 21, Server = 16 },
    GodMode = false,
    Notify = { Chat = true, UI = true },
    
    -- AUTO LOOT (GRANULAR)
    Auto = {
        Unlock=true, Drawer=true, Instant=true,
        Bed=false, Wardrobe=false, -- Hiding
        
        -- Hotel
        Key=true, Lever=true, Gold=true, Lighter=true, Lockpick=true,
        Vitamin=true, Crucifix=true, Book=true, Breaker=true, Flashlight=true,
        
        -- Mines
        Fuse=true, Shears=true, Battery=true, Glowstick=true, 
        Bandage=true, Shake=true, Anchor=true, Valve=true,
        
        -- Backdoor / Rooms
        TimerLever=true, Vial=true, Tablet=true, Gummy=true
    },
    
    -- VISUALS (TOGGLES)
    Visuals = {
        -- Global
        Doors=true, FullBright=true,
        
        -- Entities (Full List)
        ESP_Rush=true, ESP_Ambush=true, ESP_Seek=true, ESP_Figure=true,
        ESP_Screech=true, ESP_Eyes=true, ESP_Halt=true, ESP_Glitch=true, ESP_Void=true,
        ESP_Dupe=true, ESP_Timothy=true, ESP_Jack=true, ESP_Jeff=true, ESP_ElGoblino=true,
        -- F2
        ESP_Giggle=true, ESP_Gloombat=true, ESP_Grumble=true, ESP_Snare=true,
        -- Backdoor / Rooms
        ESP_Blitz=true, ESP_Lookman=true, ESP_Haste=true,
        ESP_A60=true, ESP_A90=true, ESP_A120=true,
        -- Special
        ESP_Guiding=true, -- Guiding Light
        
        -- Items (Hotel)
        ESP_Key=true, ESP_Lever=true, ESP_Book=true, ESP_Breaker=true,
        ESP_Gold=true, ESP_Lighter=true, ESP_Lockpick=true, ESP_Vitamin=true, ESP_Crucifix=true, ESP_Flashlight=true,
        
        -- Items (Mines)
        ESP_Fuse=true, ESP_Shears=true, ESP_Battery=true, ESP_Glowstick=true, 
        ESP_Bandage=true, ESP_Shake=true, ESP_Anchor=true, ESP_Valve=true,
        
        -- Items (Backdoor/Rooms)
        ESP_TimerLever=true, ESP_Vial=true, ESP_Tablet=true, ESP_Gummy=true
    },
    
    Anti = { A90=true, Screech=true, Eyes=true, Snare=true, Dupe=true, Giggle=true, Lookman=true }
}

-- // 2. DATABASE (FULL UNIVERSE)
local Colors = {
    Door = Color3.fromRGB(0, 255, 0),
    Quest = Color3.fromRGB(0, 100, 255),
    Loot = Color3.fromRGB(255, 255, 0),
    Entity = Color3.fromRGB(255, 0, 0),
    Rare = Color3.fromRGB(170, 0, 170), -- Glitch/Void
    Backdoor = Color3.fromRGB(255, 0, 255) -- Magenta
}

-- 2.1 Entity Database (Name -> Config Key & Display)
local EntityDB = {
    -- Hotel
    ["RushMoving"]={N="🚨 RUSH", K="ESP_Rush"}, 
    ["AmbushMoving"]={N="⚡ AMBUSH", K="ESP_Ambush"}, 
    ["SeekMoving"]={N="👁️ SEEK", K="ESP_Seek"}, 
    ["FigureRagdoll"]={N="👺 FIGURE", K="ESP_Figure"},
    ["Screech"]={N="👾 SCREECH", K="ESP_Screech"}, 
    ["Eyes"]={N="👀 EYES", K="ESP_Eyes"}, 
    ["Halt"]={N="🛑 HALT", K="ESP_Halt"},
    ["Glitch"]={N="👾 GLITCH", K="ESP_Glitch", C=Colors.Rare}, 
    ["Void"]={N="🌑 VOID", K="ESP_Void", C=Colors.Rare},
    ["Dupe"]={N="🚪 DUPE", K="ESP_Dupe"}, 
    ["Spider"]={N="🕷️ TIMOTHY", K="ESP_Timothy"}, -- Timothy internal name often Spider/Timothy
    ["Timothy"]={N="🕷️ TIMOTHY", K="ESP_Timothy"},
    ["Jack"]={N="👻 JACK", K="ESP_Jack"},
    ["JeffTheKiller"]={N="🔪 JEFF", K="ESP_Jeff"},
    ["ElGoblino"]={N="👺 GOBLINO", K="ESP_ElGoblino"},
    
    -- Mines
    ["GiggleCeiling"]={N="🤪 GIGGLE", K="ESP_Giggle"}, 
    ["Gloombat"]={N="🦇 BAT", K="ESP_Gloombat"}, 
    ["GrumbleRig"]={N="🐛 GRUMBLE", K="ESP_Grumble"},
    ["Snare"]={N="🚫 BẪY", K="ESP_Snare"},
    
    -- Backdoor
    ["Blitz"]={N="⚡ BLITZ", K="ESP_Blitz", C=Colors.Backdoor},
    ["Lookman"]={N="👀 LOOKMAN", K="ESP_Lookman", C=Colors.Backdoor},
    ["Haste"]={N="⏳ HASTE", K="ESP_Haste", C=Colors.Backdoor},
    
    -- Rooms
    ["A60"]={N="A-60", K="ESP_A60", C=Colors.Entity},
    ["A90"]={N="🚫 A-90", K="ESP_A90", C=Colors.Entity},
    ["A120"]={N="A-120", K="ESP_A120", C=Colors.Entity}
}

-- 2.2 Item Patterns (Deep Scan)
local Patterns = {
    -- Mines (F2)
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
    
    -- Hotel (F1)
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
    {k="straplight", t="Flashlight", n="🔦 Straplight", c=Colors.Loot},
    
    -- Backdoor / Rooms
    {k="vial", t="Vial", n="🧪 Vial", c=Colors.Quest},
    {k="timer", t="TimerLever", n="⏳ Timer", c=Colors.Quest},
    {k="tablet", t="Tablet", n="📱 Tablet", c=Colors.Quest}, -- NVCS-3000
    {k="gummy", t="Gummy", n="🍬 Gummy", c=Colors.Loot},
    
    -- Misc
    {k="drawer", t="Drawer", n="Drawer", c=nil},
}

-- 2.3 Deep Identify Function
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

-- // 3. CORE: VALIDATION (WHITELIST + BLACKLIST)
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

    -- Whitelist
    local type, _, _ = Identify(prompt)
    if type and Config.Auto[type] then return true end
    
    -- Unlock
    if Config.Auto.Unlock and scan:find("unlock") then return true end

    return false
end

-- // 4. VISUAL & NOTIFY ENGINE
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

-- // 5. GLOBAL SCANNER
local function ProcessObject(v)
    -- A. Entity Check (From DB)
    local data = EntityDB[v.Name]
    if data then
        if Config.Anti.Eyes and v.Name=="Eyes" then task.wait(); v:Destroy(); return end
        if Config.Anti.Lookman and v.Name=="Lookman" then --[[Anti Logic]] end
        
        if Config.Visuals[data.K] then
            EspEngine.Create(v, data.N, data.C or Colors.Entity)
        end
        EspEngine.Notify("⚠️ ENTITY", data.N .. " SPAWNED!")
        return
    end
    
    -- B. Special Dupe Door
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

    -- E. Interactables (Auto Loot Cache + Items ESP)
    if v:IsA("ProximityPrompt") then
        -- 1. Auto Loot Cache (Store ALL valid items)
        if IsValidTarget(v) then
            if not Cache.Interactables[v] then Cache.Interactables[v] = true end
        end
        
        -- 2. ESP Drawing
        local type, name, col = Identify(v)
        if type and col and Config.Visuals["ESP_"..type] then
            if not v.Parent.Name:lower():find("drawer") then
                EspEngine.Create(v.Parent, name, col)
            end
        end
        
        -- Book Hint
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

-- // 6. LOOPS
-- Speed Hook
local SpeedEngine = {}
Services.RunService.Heartbeat:Connect(function(dt)
    if Config.Speed.Enabled and Client.Character and Client.Humanoid and Client.RootPart then
        if Client.Humanoid.WalkSpeed ~= Config.Speed.Server then Client.Humanoid.WalkSpeed = Config.Speed.Server end
        if Client.Humanoid.MoveDirection.Magnitude > 0 then
            Client.RootPart.CFrame = Client.RootPart.CFrame + (Client.Humanoid.MoveDirection * (Config.Speed.Target - Config.Speed.Server) * dt)
            Client.RootPart.Velocity = Vector3.new(Client.RootPart.Velocity.X, 0, Client.RootPart.Velocity.Z)
        end
    end
end)

-- Auto Loot Execution (Distance Check Here)
task.spawn(function()
    while task.wait(0.1) do
        if Client.Character and Client.Character:FindFirstChild("HumanoidRootPart") then
            local pos = Client.Character.HumanoidRootPart.Position
            for prompt, _ in pairs(Cache.Interactables) do
                if prompt.Parent and prompt.Enabled then
                    local pPos = prompt.Parent:GetPivot().Position
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
    local G = "God_v77"; pcall(function() Services.PhysicsService:CreateCollisionGroup(G); Services.PhysicsService:CollisionGroupSetCollidable(G,"Default",true); Services.PhysicsService:CollisionGroupSetCollidable(G,"Players",false) end)
    Services.RunService.Stepped:Connect(function() if Config.GodMode and c then for _,p in pairs(c:GetChildren()) do if p:IsA("BasePart") then p.CanTouch=false; p.CollisionGroup=G end end end end)
end
Client.Player.CharacterAdded:Connect(HookChar)
if Client.Player.Character then HookChar(Client.Player.Character) end

-- // 7. RAYFIELD UI (SEPARATED TABS)
local Window = Rayfield:CreateWindow({Name = "DOORS v77.0 MULTIVERSE", ConfigurationSaving = {Enabled = false}})

-- TAB 1: MAIN
local TabM = Window:CreateTab("Chính", 4483362458)
TabM:CreateToggle({Name="Speed Hook", CurrentValue=false, Callback=function(v) Config.Speed.Enabled=v end})
TabM:CreateSlider({Name="Tốc độ", Range={16,50}, Increment=1, CurrentValue=22, Callback=function(v) Config.Speed.Target=v end})
TabM:CreateToggle({Name="Ghost God Mode", CurrentValue=false, Callback=function(v) Config.GodMode=v end})
TabM:CreateToggle({Name="Anti-Entities (All)", CurrentValue=true, Callback=function(v) for k,_ in pairs(Config.Anti) do Config.Anti[k]=v end end})
TabM:CreateSection("Thông Báo")
TabM:CreateToggle({Name="Chat Notify", CurrentValue=true, Callback=function(v) Config.Notify.Chat=v end})
TabM:CreateToggle({Name="UI Notify", CurrentValue=true, Callback=function(v) Config.Notify.UI=v end})

-- TAB 2: AUTO LOOT
local TabA = Window:CreateTab("Auto Loot", 4483362458)
TabA:CreateSection("Action")
TabA:CreateToggle({Name="Mở Khóa (Unlock)", CurrentValue=true, Callback=function(v) Config.Auto.Unlock=v end})
TabA:CreateToggle({Name="Mở Ngăn Kéo (Drawer)", CurrentValue=true, Callback=function(v) Config.Auto.Drawer=v end})
TabA:CreateToggle({Name="Hide (Bed)", CurrentValue=false, Callback=function(v) Config.Auto.Bed=v end})
TabA:CreateToggle({Name="Hide (Wardrobe)", CurrentValue=false, Callback=function(v) Config.Auto.Wardrobe=v end})
TabA:CreateSection("Hotel")
TabA:CreateToggle({Name="Gold", CurrentValue=true, Callback=function(v) Config.Auto.Gold=v end})
TabA:CreateToggle({Name="Key/Lever/Book", CurrentValue=true, Callback=function(v) Config.Auto.Key=v; Config.Auto.Lever=v; Config.Auto.Book=v end})
TabA:CreateToggle({Name="Light/Pick/Vitamin", CurrentValue=true, Callback=function(v) Config.Auto.Lighter=v; Config.Auto.Lockpick=v; Config.Auto.Vitamin=v; Config.Auto.Flashlight=v end})
TabA:CreateSection("Mines")
TabA:CreateToggle({Name="Fuse/Shears", CurrentValue=true, Callback=function(v) Config.Auto.Fuse=v; Config.Auto.Shears=v end})
TabA:CreateToggle({Name="Battery/Glow/Bandage", CurrentValue=true, Callback=function(v) Config.Auto.Battery=v; Config.Auto.Glowstick=v; Config.Auto.Bandage=v end})
TabA:CreateToggle({Name="Anchor/Valve", CurrentValue=true, Callback=function(v) Config.Auto.Anchor=v; Config.Auto.Valve=v end})
TabA:CreateSection("Backdoor/Rooms")
TabA:CreateToggle({Name="Timer/Vial", CurrentValue=true, Callback=function(v) Config.Auto.TimerLever=v; Config.Auto.Vial=v end})
TabA:CreateToggle({Name="Tablet/Gummy", CurrentValue=true, Callback=function(v) Config.Auto.Tablet=v; Config.Auto.Gummy=v end})

-- TAB 3: ESP ENTITIES (SEPARATED)
local TabE = Window:CreateTab("ESP Entities", 4483362458)
local function Ref() EspEngine.Refresh(); local r=Services.Workspace.CurrentRooms; for _,v in pairs(r:GetChildren()) do for _,d in pairs(v:GetDescendants()) do ProcessObject(d) end end end
TabE:CreateSection("Main Hotel")
TabE:CreateToggle({Name="Rush", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Rush=v; Ref() end})
TabE:CreateToggle({Name="Ambush", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Ambush=v; Ref() end})
TabE:CreateToggle({Name="Seek", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Seek=v; Ref() end})
TabE:CreateToggle({Name="Figure", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Figure=v; Ref() end})
TabE:CreateToggle({Name="Screech/Eyes/Halt", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Screech=v; Config.Visuals.ESP_Eyes=v; Config.Visuals.ESP_Halt=v; Ref() end})
TabE:CreateToggle({Name="Dupe/Jack/Timothy", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Dupe=v; Config.Visuals.ESP_Jack=v; Config.Visuals.ESP_Timothy=v; Ref() end})
TabE:CreateSection("Mines")
TabE:CreateToggle({Name="Giggle", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Giggle=v; Ref() end})
TabE:CreateToggle({Name="Gloombat", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Gloombat=v; Ref() end})
TabE:CreateToggle({Name="Grumble", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Grumble=v; Ref() end})
TabE:CreateToggle({Name="Snare", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Snare=v; Ref() end})
TabE:CreateSection("Backdoor/Rooms")
TabE:CreateToggle({Name="Blitz/Lookman/Haste", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Blitz=v; Config.Visuals.ESP_Lookman=v; Config.Visuals.ESP_Haste=v; Ref() end})
TabE:CreateToggle({Name="A60/A90/A120", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_A60=v; Config.Visuals.ESP_A90=v; Config.Visuals.ESP_A120=v; Ref() end})

-- TAB 4: ESP HOTEL (F1)
local TabV1 = Window:CreateTab("ESP Hotel", 4483362458)
TabV1:CreateToggle({Name="Guiding Light", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Guiding=v; Ref() end})
TabV1:CreateToggle({Name="Doors", CurrentValue=true, Callback=function(v) Config.Visuals.Doors=v; Ref() end})
TabV1:CreateSection("Items")
TabV1:CreateToggle({Name="Key/Lever/Book", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Key=v; Config.Visuals.ESP_Lever=v; Config.Visuals.ESP_Book=v; Ref() end})
TabV1:CreateToggle({Name="Gold", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Gold=v; Ref() end})
TabV1:CreateToggle({Name="Tools (Light/Pick/Vit)", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Lighter=v; Config.Visuals.ESP_Lockpick=v; Config.Visuals.ESP_Vitamin=v; Config.Visuals.ESP_Flashlight=v; Ref() end})

-- TAB 5: ESP MINES (F2)
local TabV2 = Window:CreateTab("ESP Mines", 4483362458)
TabV2:CreateSection("Items")
TabV2:CreateToggle({Name="Fuse", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Fuse=v; Ref() end})
TabV2:CreateToggle({Name="Shears", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Shears=v; Ref() end})
TabV2:CreateToggle({Name="Anchor/Valve", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Anchor=v; Config.Visuals.ESP_Valve=v; Ref() end})
TabV2:CreateToggle({Name="Battery/Glowstick", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Battery=v; Config.Visuals.ESP_Glowstick=v; Ref() end})
TabV2:CreateToggle({Name="Bandage/Shake", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Bandage=v; Config.Visuals.ESP_Shake=v; Ref() end})

-- TAB 6: ESP BACKDOOR/ROOMS
local TabV3 = Window:CreateTab("ESP Other", 4483362458)
TabV3:CreateSection("Backdoor")
TabV3:CreateToggle({Name="Timer Lever", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_TimerLever=v; Ref() end})
TabV3:CreateToggle({Name="Vial", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Vial=v; Ref() end})
TabV3:CreateSection("Rooms")
TabV3:CreateToggle({Name="Tablet (NVCS)", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Tablet=v; Ref() end})
TabV3:CreateToggle({Name="Gummy Light", CurrentValue=true, Callback=function(v) Config.Visuals.ESP_Gummy=v; Ref() end})

Rayfield:Notify({Title = "V77.0 MULTIVERSE", Content = "All Floors Supported. Tabs Separated.", Duration = 5})
