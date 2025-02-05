-- Usual variables
local Players = game:GetService("Players")
local LocalPlyr = Players.LocalPlayer
local PlayerGui = LocalPlyr.PlayerGui
local Camera = Workspace.CurrentCamera

local Owns_Cap = PlayerGui.gamepassOwnershipReadOnly.ownsCaptain
local Crim_Amount = PlayerGui.crimControlsGui.Frame.criminalCount
local Neutral = Workspace.NPCs.Neutral
local streakEvent = Workspace.GameEvents.streakEvent

-- Placeholder variables
local WS, scan1, scan2, Downed, selected_WS, Cell, Remote, Weapon, originalCFrame, AutoSpawn, Max_Crims, AutoUnlock

-- Toggles
local Toggles = {
    Refill_Ammo = false,
    Spawning = false,
    AutoSpawn_AI = false,
    Collect_Streak = false,
    AutoUnlock_GP = false
}

----------- [[ SOME EXTRA STUFF ]] -----------

-- Handler for unintended changes to player walkspeed
function wsHandler(char)
    local Humanoid = char:WaitForChild("Humanoid")

    if WS then
        WS:Disconnect()
        WS = nil
    end

    WS = Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if Humanoid.WalkSpeed ~= selected_WS and selected_WS ~= nil then
            Humanoid.WalkSpeed = selected_WS
        end
    end)
end



-- Handler for when the player is down for too long (this is to save Notoriety)
function scanForWhenDownTypeSheee(char)
    if scan1 or scan2 then
        scan1:Disconnect()
        scan1 = nil

        scan2:Disconnect()
        scan2 = nil
    end

    scan1 = char.ChildAdded:Connect(function(highlight)
        if highlight:IsA("Highlight") then
            originalCFrame = char.HumanoidRootPart.CFrame

            Downed = true
            local start = tick()

            char.HumanoidRootPart.CFrame = CFrame.new(-1070, 211, -284)

            while Downed do
                if tick() - start >= 19 then
                    LocalPlyr:Kick("Kicked to prevent Notoriety from being reset")
                end
                task.wait(0.01)
            end
        end
    end)

    scan2 = char.ChildRemoved:Connect(function(highlight)
        if highlight:IsA("Highlight") then
            Downed = false

            char.HumanoidRootPart.CFrame = originalCFrame
        end
    end)
end



-- Initial sets
if LocalPlyr.Character then
    wsHandler(LocalPlyr.Character)
    scanForWhenDownTypeSheee(LocalPlyr.Character)
end

-- For respawns
function onCharAdded(character) 
    wsHandler(character)
    scanForWhenDownTypeSheee(character)
end

LocalPlyr.CharacterAdded:Connect(onCharAdded)


-- Function to get cellphone tool
function getCell()
    local Cellphone

    for _, v in pairs(LocalPlyr.Character:GetChildren()) do
        if v:IsA("Tool") and v.Name:find("Cell") then
            Cellphone = v 
        end
    end

    if not Cellphone then
        for _, v in pairs(LocalPlyr.Backpack:GetChildren()) do
            if v:IsA("Tool") and v.Name:find("Cell") then
                Cellphone = v
            end
        end
    end

    return Cellphone
end

----------- [[ MAIN FUNCTIONS ]] -----------

-- Ammo function
function getAmmo(Weapon)
    if Toggles["Refill_Ammo"] then
        originalCFrame = LocalPlyr.Character.HumanoidRootPart.CFrame

        for _, v in pairs(Workspace:WaitForChild("gsNew"):GetChildren()) do
            if v:IsA("Part") and v.Name:find("buy.*PromptContainer") then
                if v:FindFirstChild("ProximityPrompt2") then
                    if v.ProximityPrompt2.ActionText:find(Weapon) then

                        LocalPlyr.Character.HumanoidRootPart.CFrame = v.CFrame
                        v.ProximityPrompt2.HoldDuration = 0

                        task.spawn(function()
                            while Toggles["Refill_Ammo"] do
                                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, v.Position)
                                task.wait(0.01)
                            end
                        end)

                        while Toggles["Refill_Ammo"] do
                            fireproximityprompt(v.ProximityPrompt2)
                            task.wait(0.01)
                        end
                    end
                end
            end
        end
    else
        LocalPlyr.Character.HumanoidRootPart.CFrame = originalCFrame
    end
end



-- Spawning function
function spawnCrims()
    Toggles["Spawning"] = true

    repeat
        Remote:FireServer("MouseBtn1", Max_Crims)
        task.wait(0.01)
    until tonumber(Crim_Amount.Text) == Max_Crims or not Toggles["AutoSpawn_AI"]

    Toggles["Spawning"] = false
end

-- Checking function for spawning AI
function manageCrims()
    Cell = getCell()
    Remote = Cell.Remotes.npcAssistance

    local function handleAction()
        if not Toggles["Spawning"] then
            if LocalPlyr.Backpack:FindFirstChild(Cell.Name) then
                LocalPlyr.Character.Humanoid:EquipTool(Cell)
                spawnCrims()
                Cell.Parent = LocalPlyr.Backpack
            elseif LocalPlyr.Character:FindFirstChild(Cell.Name) then
                spawnCrims()
                Cell.Parent = LocalPlyr.Backpack
            end
        end
    end

    if Max_Crims == nil then
        if Owns_Cap.Value then
            Max_Crims = 12
        else
            Max_Crims = 8
        end
    end

    if Toggles["AutoSpawn_AI"] then
        handleAction()

        AutoSpawn = Crim_Amount:GetPropertyChangedSignal("Text"):Connect(function()
            if tonumber(Crim_Amount.Text) < Max_Crims then
                handleAction()
            end
        end)
    else
        if not AutoSpawn then
            repeat
                task.wait()
            until AutoSpawn
        end

        AutoSpawn:Disconnect()
        AutoSpawn = nil
    end
end



-- Function to collect streaks (this just gives you money, medkits, grenades, etc.)
function getStreaks()
    if Toggles["Collect_Streak"] then
        task.spawn(function()
            while Toggles["Collect_Streak"] do
                streakEvent:FireServer(1000) -- doesn't need to be randomized, 1k is max.
                task.wait(0.01)
            end
        end)
    end
end



----------- [[ GAMEPASS FUNCTIONS ]] -----------

-- Function holders for remotes
function unlockRemotes()
    Remote:FireServer("extraTurretSlotsPurchasedEvent", 82471)
    Remote:FireServer("grenadeTurretPurchasedEvent", 21556)
    Remote:FireServer("flamethrowerTurretPurchasedEvent", 57704)
    Remote:FireServer("turretPurchasedEvent", 58291)
    Remote:FireServer("jetpackPurchasedEvent", 72619)
end

function removeRemotes()
    Remote:FireServer("removeTurret")
    Remote:FireServer("removeGrenadeTurret")
    Remote:FireServer("removeFlamethrowerTurret")
end

-- For auto-unlocking GP upon death
function unlockGP()
    Cell = getCell()
    Remote = Cell.Remotes.npcAssistance

    if Toggles["AutoUnlock_GP"] then
        unlockRemotes()

        if not AutoUnlock then
            AutoUnlock = LocalPlyr.CharacterAdded:Connect(function()
                unlockGP()
            end)
        end
    else
        AutoUnlock:Disconnect()
        AutoUnlock = nil
    end  
end

-- Manages overall GP tab
function manageGP(turret, action)
    local function handleAction()
        if turret and action == "Place" then
            Remote:FireServer(turret)
        elseif not turret and action == "Remove" then
            removeRemotes()
        elseif not turret and action == "Jetpack" then
            Remote:FireServer("wearJetpack")
        end
    end

    if LocalPlyr.Backpack:FindFirstChild(Cell.Name) then
        LocalPlyr.Character.Humanoid:EquipTool(Cell)
        handleAction()
        Cell.Parent = LocalPlyr.Backpack
    elseif LocalPlyr.Character:FindFirstChild(Cell.Name) then
        handleAction()
        Cell.Parent = LocalPlyr.Backpack
    end
end


-------------------------------------------------- [[ UI LIBRARY ]] --------------------------------------------------

local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/Murvity/nautilus-lib/refs/heads/main/source.lua"))()


------------------------- [[ MAIN TAB ]] -------------------------

local main = ui:CreateTab({
    title = "Main"
})

----------------------

local gun_divider = main:CreateDivider({
    title = "Main"
})

local auto_streak = main:CreateToggle({
    title = "Autofarm",
    callback = function()
        Toggles["Collect_Streak"] = not Toggles["Collect_Streak"]
        getStreaks()
    end
})

local auto_spawn = main:CreateToggle({
    title = "Auto-Spawn AI",
    callback = function()
        Toggles["AutoSpawn_AI"] = not Toggles["AutoSpawn_AI"]
        manageCrims()
    end
})

----------------------

local gun_divider = main:CreateDivider({
    title = "Gun"
})

local wep_select = main:CreateSelection({
    title = "Selected Weapon",
    callback2 = function(v)
        Weapon = v 
    end
})

local ammo_toggle = main:CreateToggle({
    title = "Refill Ammo",
    callback = function()
        Toggles["Refill_Ammo"] = not Toggles["Refill_Ammo"]
        getAmmo(Weapon)
    end
})



------------------------- [[ GAMEPASSES TAB ]] -------------------------

local gp = ui:CreateTab({
    title = "Passes"
})

----------------------

local gp_divider = gp:CreateDivider({
    title = "Gamepasses"
})

local gp_toggle = gp:CreateToggle({
    title = "Auto-Unlock",
    callback = function()
        Toggles["AutoUnlock_GP"] = not Toggles["AutoUnlock_GP"]
        unlockGP()
    end
})

local jetpack_button = gp:CreateButton({
    title = "Jetpack",
    callback = function()
        manageGP(nil, "Jetpack")
    end
})

----------------------

local turret_divider = gp:CreateDivider({
    title = "Turrets"
})

local turret_dropdown = gp:CreateDropdown({
    title = "Placements",
    callback = function(v)
        if v == "placeTurret" then
            manageGP(v, "Place")
        elseif v == "placeGrenadeTurret" then
            manageGP(v, "Place")
        elseif v == "placeFlamethrowerTurret" then
            manageGP(v, "Place")
        end
    end
})

turret_dropdown:Add("Missile Turret", "placeTurret")
turret_dropdown:Add("Grenade Turret", "placeGrenadeTurret")
turret_dropdown:Add("Flamethrower Turret", "placeFlamethrowerTurret")

local remove_turret = gp:CreateButton({
    title = "Remove Turrets",
    callback = function()
        manageGP(nil, "Remove")
    end
})



------------------------- [[ TELEPORTS TAB ]] -------------------------

local tp = ui:CreateTab({
    title = "Teleports"
})

----------------------

local shops_divider = tp:CreateDivider({
    title = "Shops"
})

local shops_gun = tp:CreateButton({
    title = "Gun Store",
    callback = function()
        LocalPlyr.Character.HumanoidRootPart.CFrame = CFrame.new(-290, 3, 93.5)
    end
})

local shops_AI = tp:CreateButton({
    title = "Criminal AI Store",
    callback = function()
        LocalPlyr.Character.HumanoidRootPart.CFrame = CFrame.new(190, 3, 176)
    end
})

local shops_melee = tp:CreateButton({
    title = "Melee Store",
    callback = function()
        LocalPlyr.Character.HumanoidRootPart.CFrame = CFrame.new(-38.5, 3, -76)
    end
})

----------------------

local loc_divider = tp:CreateDivider({
    title = "Extras"
})

local loc_dropdown = tp:CreateDropdown({
    title = "Locations",
    callback = function(v)
        if v == "Downtown" then
            LocalPlyr.Character.HumanoidRootPart.CFrame = CFrame.new(86, 3, -33)
        elseif v == "Beach" then
            LocalPlyr.Character.HumanoidRootPart.CFrame = CFrame.new(-84, 3, 1057)
        elseif v == "Ohio" then -- hehe
            LocalPlyr.Character.HumanoidRootPart.CFrame = CFrame.new(-473, 3, -504)
        elseif v == "Slums" then
            LocalPlyr.Character.HumanoidRootPart.CFrame = CFrame.new(690, 3, -710)
        elseif v == "Paradise" then
            LocalPlyr.Character.HumanoidRootPart.CFrame = CFrame.new(285, 3, 827)
        end
    end
})

loc_dropdown:Add("Downtown Central", "Downtown")
loc_dropdown:Add("North Beach", "Beach")
loc_dropdown:Add("Ohio County Suburbs", "Ohio")
loc_dropdown:Add("Infamy City Slums", "Slums")
loc_dropdown:Add("Paradise Boulevard", "Paradise")



------------------------- [[ MISCELLANEOUS TAB ]] -------------------------

local misc = ui:CreateTab({
    title = "Misc"
})

----------------------

local misc_divider = misc:CreateDivider({
    title = "Miscellaneous"
})

local ws_slider = misc:CreateSlider({
    title = "Walkspeed",
    min = 0,
    max = 100,
    default = 50,
    callback = function(v)
        LocalPlyr.Character.Humanoid.WalkSpeed = v 
        selected_WS = v
    end
})

local jump_slider = misc:CreateSlider({
    title = "Jump Power",
    min = 0,
    max = 100,
    default = 50,
    callback = function(v)
        if LocalPlyr.Character.Humanoid.UseJumpPower then
            LocalPlyr.Character.Humanoid.JumpPower = v
        elseif not LocalPlyr.Character.Humanoid.UseJumpPower then
            LocalPlyr.Character.Humanoid.JumpHeight = v
        end
    end
})

local hipH_slider = misc:CreateSlider({
    title = "Hip Height",
    min = 0,
    max = 100,
    default = 50,
    callback = function(v)
        LocalPlyr.Character.Humanoid.HipHeight = v 
    end
})
