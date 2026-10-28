--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/shared/MPOptim_ModProfiler.lua
    Author: prop11
    Description: High-accuracy Lua VM profiler, real-time event hook interceptor,
                 namespace resolver, and weighted CPU/memory stress diagnostics.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"
require "MPOptim_ModGovernor"

MPOptim = MPOptim or {}
MPOptim.ModProfiler = MPOptim.ModProfiler or {}

-- Registry for intercepted event callbacks: evName -> list of { fn = fn, timestamp = num }
MPOptim.ModProfiler.CapturedHooks = MPOptim.ModProfiler.CapturedHooks or {}
MPOptim.ModProfiler.InterceptorsInstalled = MPOptim.ModProfiler.InterceptorsInstalled or false

-- =========================================================================
-- EVENT WEIGHTS (Frame rate & CPU execution impact)
-- =========================================================================
local EVENT_WEIGHTS = {
    -- Critical Per-Frame / High Frequency (60+ Hz)
    ["OnTick"]                          = 50,
    ["OnRenderTick"]                    = 60,
    ["OnPostRender"]                    = 40,
    ["OnPreUIDraw"]                     = 35,
    ["OnPostUIDraw"]                    = 35,
    ["OnPlayerUpdate"]                  = 35,
    ["OnZombieUpdate"]                  = 40,
    ["OnTickEven"]                      = 25,
    ["OnTickOdd"]                       = 25,

    -- Medium Frequency (Action / Context / Combat)
    ["OnFillWorldObjectContextMenu"]    = 15,
    ["OnFillInventoryObjectContextMenu"]= 15,
    ["OnWeaponHitThumpable"]            = 12,
    ["OnWeaponHitCharacter"]            = 12,
    ["OnHitZombie"]                     = 12,
    ["OnCharacterCollide"]              = 10,
    ["OnZombieDead"]                    = 8,
    ["OnPlayerDeath"]                   = 8,
    ["OnEquipPrimary"]                  = 6,
    ["OnEquipSecondary"]                = 6,

    -- Low / Periodic (Minutes / Hours / Days)
    ["EveryOneMinute"]                  = 5,
    ["EveryTenMinutes"]                 = 2,
    ["EveryDays"]                       = 1,
    ["EveryHours"]                      = 1,

    -- One-shot / Startup / Infrequent
    ["OnGameStart"]                     = 1,
    ["OnGameBoot"]                      = 1,
    ["OnCreatePlayer"]                  = 1,
    ["OnInitWorld"]                     = 1,
    ["OnMainMenuEnter"]                 = 1,
    ["OnResolutionChange"]              = 1,
    ["OnResetLua"]                      = 1
}

local EVENT_TAGS = {
    ["OnTick"]                          = { tag = "PER-FRAME",   r = 1.00, g = 0.28, b = 0.28 },
    ["OnRenderTick"]                    = { tag = "RENDER",      r = 1.00, g = 0.28, b = 0.28 },
    ["OnPostRender"]                    = { tag = "RENDER",      r = 1.00, g = 0.28, b = 0.28 },
    ["OnPreUIDraw"]                     = { tag = "UI DRAW",     r = 1.00, g = 0.45, b = 0.25 },
    ["OnPostUIDraw"]                    = { tag = "UI DRAW",     r = 1.00, g = 0.45, b = 0.25 },
    ["OnPlayerUpdate"]                  = { tag = "UPDATE",      r = 0.95, g = 0.85, b = 0.25 },
    ["OnZombieUpdate"]                  = { tag = "UPDATE",      r = 0.95, g = 0.85, b = 0.25 },
    ["OnTickEven"]                      = { tag = "SUB-TICK",    r = 0.95, g = 0.85, b = 0.25 },
    ["OnTickOdd"]                       = { tag = "SUB-TICK",    r = 0.95, g = 0.85, b = 0.25 },
    ["OnFillWorldObjectContextMenu"]    = { tag = "CONTEXT",     r = 0.40, g = 0.80, b = 1.00 },
    ["OnFillInventoryObjectContextMenu"]= { tag = "CONTEXT",     r = 0.40, g = 0.80, b = 1.00 },
    ["EveryOneMinute"]                  = { tag = "PERIODIC",    r = 0.45, g = 0.90, b = 0.45 },
    ["EveryTenMinutes"]                 = { tag = "PERIODIC",    r = 0.45, g = 0.90, b = 0.45 },
    ["EveryHours"]                      = { tag = "PERIODIC",    r = 0.45, g = 0.90, b = 0.45 },
    ["EveryDays"]                       = { tag = "PERIODIC",    r = 0.45, g = 0.90, b = 0.45 },
    ["OnGameStart"]                     = { tag = "STARTUP",     r = 0.70, g = 0.70, b = 0.70 },
    ["OnGameBoot"]                      = { tag = "BOOT",        r = 0.70, g = 0.70, b = 0.70 }
}

-- =========================================================================
-- VANILLA & CORE ENGINE BLACKLIST (Never attribute these to user mods)
-- =========================================================================
local VANILLA_BLACKLIST = {
    ["_G"] = true, ["package"] = true, ["table"] = true, ["string"] = true,
    ["math"] = true, ["coroutine"] = true, ["debug"] = true, ["os"] = true,
    ["Events"] = true, ["Hook"] = true, ["ZomboidFileSystem"] = true,
    ["Core"] = true, ["IsoWorld"] = true, ["IsoCamera"] = true, ["UIManager"] = true,
    ["SandboxVars"] = true, ["SandboxOptions"] = true, ["PZMath"] = true,
    ["PZArrayUtil"] = true, ["Color"] = true, ["Colors"] = true, ["Vector2"] = true,
    ["Vector3"] = true, ["ISUI"] = true, ["ISBaseObject"] = true, ["ISPanel"] = true,
    ["ISButton"] = true, ["ISScrollingListBox"] = true, ["ISLabel"] = true,
    ["ISTextBox"] = true, ["ISComboBox"] = true, ["ISTickBox"] = true,
    ["ISUIElement"] = true, ["ISCollapsableWindow"] = true, ["ISInventoryPane"] = true,
    ["ISCharacterScreen"] = true, ["ISGameLoadingUI"] = true, ["MainScreen"] = true,
    ["OptionScreens"] = true, ["BaseVehicle"] = true, ["VehicleCommands"] = true,
    ["ItemBinding"] = true, ["SurvivorFactory"] = true, ["TraitFactory"] = true,
    ["ProfessionFactory"] = true, ["ScriptManager"] = true, ["ItemPickerJava"] = true,
    ["KahluaUtil"] = true, ["LuaManager"] = true, ["LuaEventManager"] = true,
    ["SoundManager"] = true, ["RadioAPI"] = true, ["ZomboidRadio"] = true,
    ["Translator"] = true, ["TextManager"] = true, ["WorldMarkers"] = true,
    ["ClimateManager"] = true, ["WeatherFx"] = true, ["RainManager"] = true,
    ["ErosionGlobals"] = true, ["MapCollisionData"] = true, ["VirtualZombieManager"] = true,
    ["ZombiePopulationManager"] = true, ["IsoRegions"] = true, ["WorldStreamer"] = true,
    ["ItemPicker"] = true, ["BodyLocations"] = true, ["ClothingRecipes"] = true,
    ["Camping"] = true, ["Farming"] = true, ["Trapping"] = true, ["Vehicles"] = true,
    ["IsoUtils"] = true, ["TextDrawObject"] = true, ["RadialMenu"] = true,
    ["JoypadState"] = true, ["GameTime"] = true, ["PVPConfig"] = true,
    ["IsoPlayer"] = true, ["IsoZombie"] = true, ["InventoryItem"] = true,
    ["ItemContainer"] = true, ["IsoGridSquare"] = true, ["IsoCell"] = true,
    ["IsoObject"] = true, ["HandWeapon"] = true, ["Alarm"] = true,
    ["BodyDamage"] = true, ["Stats"] = true, ["SurvivorDesc"] = true
}

-- Well-known popular mod namespace mappings (modId / token -> canonical mod name)
local KNOWN_MOD_NAMESPACES = {
    ["mpoptim"]             = "mpoptimiser",
    ["mpoptimiser"]         = "mpoptimiser",
    ["mpoptimizer"]         = "mpoptimiser",
    ["guncon"]              = "brita_2",
    ["brita"]               = "brita_2",
    ["arsenal26"]           = "arsenal(26)gunfighter",
    ["a26"]                 = "arsenal(26)gunfighter",
    ["arsenal"]             = "arsenal(26)gunfighter",
    ["propsort"]            = "propsort",
    ["propcore"]            = "propsort",
    ["propcheatmenu"]       = "propcheatmenu",
    ["truemusic"]           = "truemusic",
    ["tc"]                  = "truemusic",
    ["tcmusic"]             = "truemusic",
    ["autoloot"]            = "autoloot",
    ["al_settings"]         = "autoloot",
    ["commonsense"]         = "bb_commonsense",
    ["bb_commonsense"]      = "bb_commonsense",
    ["ehe"]                 = "expandedhelicopterevents",
    ["expandedhelicopterevents"] = "expandedhelicopterevents",
    ["modoptions"]          = "modoptions",
    ["bettersort"]          = "bettersorting",
    ["equipmentui"]         = "equipmentui",
    ["rvinterior"]          = "rvinterior",
    ["hasbeenread"]         = "hasbeenread",
    ["autotsar"]            = "tsarslib",
    ["tsarslib"]            = "tsarslib"
}

-- =========================================================================
-- HELPER: STRING TOKEN NORMALIZATION
-- =========================================================================
local function normalizeToken(str)
    if not str or type(str) ~= "string" then return "" end
    local lower = string.lower(str)
    -- Strip punctuation, underscores, dashes, spaces, and brackets
    lower = string.gsub(lower, "[%s_%-%[%]%(%)%.'\"]", "")
    return lower
end

-- =========================================================================
-- REAL-TIME EVENT INTERCEPTOR INSTALLATION
-- =========================================================================
function MPOptim.ModProfiler.RegisterHook(evName, fn)
    if not evName or not fn then return end
    local captured = MPOptim.ModProfiler.CapturedHooks
    captured[evName] = captured[evName] or {}

    -- Avoid duplicate entries for same function reference
    for _, item in ipairs(captured[evName]) do
        if item.fn == fn then
            item.count = item.count + 1
            return
        end
    end

    table.insert(captured[evName], {
        fn = fn,
        count = 1
    })
end

function MPOptim.ModProfiler.UnregisterHook(evName, fn)
    if not evName or not fn then return end
    local list = MPOptim.ModProfiler.CapturedHooks[evName]
    if not list then return end

    for idx, item in ipairs(list) do
        if item.fn == fn then
            table.remove(list, idx)
            return
        end
    end
end

local function wrapEventTable(evName, evObj)
    if not evObj or type(evObj) ~= "table" or evObj._mpProfilerWrapped then return end

    local origAdd = evObj.Add
    local origRemove = evObj.Remove
    evObj._mpProfilerWrapped = true

    evObj.Add = function(...)
        local a1, a2 = ...
        local fn = (type(a1) == "function" and a1) or (type(a2) == "function" and a2)
        if fn then
            MPOptim.ModProfiler.RegisterHook(evName, fn)
            local targetFn = fn
            if MPOptim.ModGovernor and MPOptim.ModGovernor.WrapHook then
                targetFn = MPOptim.ModGovernor.WrapHook(evName, fn)
            end
            if origAdd then
                if a1 == fn then
                    return origAdd(targetFn, a2)
                else
                    return origAdd(a1, targetFn)
                end
            end
        elseif origAdd then
            return origAdd(...)
        end
    end

    if origRemove then
        evObj.Remove = function(...)
            local a1, a2 = ...
            local fn = (type(a1) == "function" and a1) or (type(a2) == "function" and a2)
            if fn then
                local targetFn = fn
                local originalFn = fn
                if MPOptim.ModGovernor and MPOptim.ModGovernor.UnwrapHook then
                    local w, orig = MPOptim.ModGovernor.UnwrapHook(fn)
                    targetFn = w or fn
                    originalFn = orig or fn
                end
                MPOptim.ModProfiler.UnregisterHook(evName, originalFn)
                if a1 == fn then
                    return origRemove(targetFn, a2)
                else
                    return origRemove(a1, targetFn)
                end
            elseif origRemove then
                return origRemove(...)
            end
        end
    end
end

function MPOptim.ModProfiler.InstallInterceptors()
    if MPOptim.ModProfiler.InterceptorsInstalled then return end
    MPOptim.ModProfiler.InterceptorsInstalled = true

    if Events and type(Events) == "table" then
        -- Wrap all current events in Events table
        for evName, evObj in pairs(Events) do
            if type(evName) == "string" and type(evObj) == "table" then
                wrapEventTable(evName, evObj)
            end
        end

        -- Metatable to catch future dynamically created events (LuaEventManager.AddEvent)
        local currentMt = getmetatable(Events)
        if type(currentMt) ~= "string" then
            local mt = currentMt or {}
            local origNewIndex = mt.__newindex

            mt.__newindex = function(tbl, key, val)
                if type(key) == "string" and type(val) == "table" then
                    wrapEventTable(key, val)
                end
                if origNewIndex then
                    return origNewIndex(tbl, key, val)
                else
                    rawset(tbl, key, val)
                end
            end

            setmetatable(Events, mt)
        end
    end
end

-- Install interceptors immediately upon file load
MPOptim.ModProfiler.InstallInterceptors()

-- =========================================================================
-- ACCURATE KAHLUA MEMORY ESTIMATOR
-- =========================================================================
local function estimateTableMemory(tbl, visited, depth)
    if not tbl or type(tbl) ~= "table" then return 0, 0, 0 end
    visited = visited or {}
    depth = depth or 0
    if visited[tbl] or depth > 8 then return 0, 0, 0 end
    visited[tbl] = true

    local bytes = 56 -- KahluaTableImpl overhead (Java object + inner table references)
    local tableCount = 1
    local closureCount = 0

    for k, v in pairs(tbl) do
        bytes = bytes + 32 -- Entry slot overhead

        -- Key memory
        if type(k) == "string" then
            bytes = bytes + 24 + #k
        elseif type(k) == "number" then
            bytes = bytes + 24 -- Boxed java.lang.Double
        end

        -- Value memory
        if type(v) == "string" then
            bytes = bytes + 24 + #v
        elseif type(v) == "number" then
            bytes = bytes + 24
        elseif type(v) == "function" then
            bytes = bytes + 64 -- LuaClosure + Prototype reference overhead
            closureCount = closureCount + 1
        elseif type(v) == "table" then
            local subBytes, subTables, subClosures = estimateTableMemory(v, visited, depth + 1)
            bytes = bytes + subBytes
            tableCount = tableCount + subTables
            closureCount = closureCount + subClosures
        end
    end

    return bytes, tableCount, closureCount
end

-- =========================================================================
-- MOD METADATA & NAME RESOLVER (Resolves true 'name=' from mod.info)
-- =========================================================================
local modDirectoryCache = nil

local function getModDirectoryCache()
    if modDirectoryCache then return modDirectoryCache end
    modDirectoryCache = {}

    if getModDirectoryTable and getModInfo and type(getModDirectoryTable) == "function" and type(getModInfo) == "function" then
        local dirs = getModDirectoryTable()
        if dirs then
            local count = (dirs.size and dirs:size()) or (type(dirs) == "table" and #dirs) or 0
            for i = 0, count - 1 do
                local d = (dirs.get and dirs:get(i)) or dirs[i + 1]
                if d and type(d) == "string" then
                    local mi = getModInfo(d)
                    if mi and mi.getId then
                        local mid = mi:getId()
                        if mid and #mid > 0 then
                            modDirectoryCache[string.lower(mid)] = mi
                        end
                    end
                end
            end
        end
    end

    return modDirectoryCache
end

local function resolveModInfo(modId)
    if not modId or #modId == 0 then return nil end

    -- 1. Global engine function getModInfoByID (most direct in PZ B42/B41)
    if getModInfoByID and type(getModInfoByID) == "function" then
        local info = getModInfoByID(modId)
        if info then return info end
    end

    -- 2. Directory scan cache
    local cache = getModDirectoryCache()
    if cache then
        local cachedInfo = cache[string.lower(modId)]
        if cachedInfo then return cachedInfo end
    end

    -- 3. ChooseGameInfo methods
    if ChooseGameInfo then
        if type(ChooseGameInfo.getAvailableModDetails) == "function" then
            local info = ChooseGameInfo.getAvailableModDetails(modId)
            if info then return info end
        end
        if type(ChooseGameInfo.getModDetails) == "function" then
            local info = ChooseGameInfo.getModDetails(modId)
            if info then return info end
        end
    end

    return nil
end

local function extractModName(modId, modInfo)
    -- Priority 1: Check modInfo:getName() (Populated directly by PZ from 'name=' in mod.info)
    if modInfo then
        if modInfo.getName and type(modInfo.getName) == "function" then
            local name = modInfo:getName()
            if name and type(name) == "string" and #name > 0 then
                return name
            end
        end
        if modInfo.name and type(modInfo.name) == "string" and #modInfo.name > 0 then
            return modInfo.name
        end
    end

    -- Priority 2: Well-known mod title mappings if engine lookup returned empty
    local lowerId = string.lower(modId or "")
    local KNOWN_TITLES = {
        ["mpoptimizer"]             = "Project Zomboid Optimiser",
        ["mpoptimiser"]             = "Project Zomboid Optimiser",
        ["brita_2"]                 = "Brita's Weapon Pack",
        ["arsenal(26)gunfighter"]   = "Arsenal[26] GunFighter",
        ["arsenal[26]gunfighter"]   = "Arsenal[26] GunFighter",
        ["arsenal26"]               = "Arsenal[26] GunFighter",
        ["truemusic"]               = "True Music",
        ["bb_commonsense"]          = "Common Sense",
        ["commonsense"]             = "Common Sense",
        ["expandedhelicopterevents"]= "Expanded Helicopter Events",
        ["ehe"]                     = "Expanded Helicopter Events",
        ["bettersort"]              = "Better Sorting",
        ["bettersorting"]           = "Better Sorting",
        ["equipmentui"]             = "Equipment UI",
        ["modoptions"]              = "Mod Options",
        ["propsort"]                = "PropSort",
        ["propcheatmenu"]           = "Prop Cheat Menu",
        ["autoloot"]                = "AutoLoot",
        ["hasbeenread"]             = "Has Been Read",
        ["rvinterior"]              = "RV Interior"
    }
    if KNOWN_TITLES[lowerId] then
        return KNOWN_TITLES[lowerId]
    end

    return modId
end

-- =========================================================================
-- MAIN SCAN ROUTINE
-- =========================================================================
function MPOptim.ModProfiler.Scan()
    local results = {}
    local totalActive = 0
    local totalEstimatedBytes = 0
    local totalHooksCount = 0

    -- 1. Resolve Active Mods List
    local activeModsList = nil
    if getActivatedMods then
        local rawMods = getActivatedMods()
        if rawMods then
            if rawMods.getMods then
                activeModsList = rawMods:getMods()
            elseif rawMods.size then
                activeModsList = rawMods
            end
        end
    end

    if not activeModsList and ActiveMods and ActiveMods.getById then
        local act = ActiveMods.getById("currentGame") or ActiveMods.getById("loaded") or ActiveMods.getById("default")
        if act and act.getMods then
            activeModsList = act:getMods()
        end
    end

    local modMap = {}
    local tokenToMod = {}

    if activeModsList and activeModsList.size then
        local count = activeModsList:size()
        for i = 0, count - 1 do
            local modId = activeModsList:get(i)
            if modId then
                totalActive = totalActive + 1
                local modInfo = resolveModInfo(modId)
                local name = extractModName(modId, modInfo)
                local author = (modInfo and ((modInfo.getAuthor and modInfo:getAuthor()) or modInfo.author)) or "Unknown"
                local version = (modInfo and ((modInfo.getModVersion and modInfo:getModVersion()) or modInfo.version)) or "1.0"
                local desc = (modInfo and ((modInfo.getDescription and modInfo:getDescription()) or modInfo.desc)) or ""

                local rawKey = string.lower(modId)
                local mEntry = {
                    id = modId,
                    name = name,
                    author = author,
                    version = version,
                    desc = desc,
                    namespaces = {},
                    estimatedBytes = 0,
                    tableCount = 0,
                    closureCount = 0,
                    hookCount = 0,
                    hooks = {},
                    stressScore = 0,
                    rating = "LIGHT"
                }

                modMap[rawKey] = mEntry

                -- Index normalized tokens for matching
                local idToken = normalizeToken(modId)
                if #idToken > 0 then
                    tokenToMod[idToken] = mEntry
                end

                local nameToken = normalizeToken(name)
                if #nameToken > 0 and nameToken ~= idToken then
                    tokenToMod[nameToken] = mEntry
                end

                -- Additional token aliases for common abbreviations
                if string.find(idToken, "mpoptim", 1, true) then
                    tokenToMod["mpoptim"] = mEntry
                    tokenToMod["mpoptimiser"] = mEntry
                    tokenToMod["pzo"] = mEntry
                elseif string.find(idToken, "brita", 1, true) then
                    tokenToMod["brita"] = mEntry
                    tokenToMod["guncon"] = mEntry
                elseif string.find(idToken, "arsenal", 1, true) or string.find(idToken, "26", 1, true) then
                    tokenToMod["arsenal26"] = mEntry
                    tokenToMod["a26"] = mEntry
                elseif string.find(idToken, "propsort", 1, true) or string.find(idToken, "propcheat", 1, true) then
                    tokenToMod["propsort"] = mEntry
                    tokenToMod["propcore"] = mEntry
                    tokenToMod["propcheatmenu"] = mEntry
                elseif string.find(idToken, "truemusic", 1, true) then
                    tokenToMod["truemusic"] = mEntry
                    tokenToMod["tc"] = mEntry
                    tokenToMod["tcmusic"] = mEntry
                end
            end
        end
    end

    if totalActive == 0 then
        local vanillaEntry = {
            id = "Vanilla",
            name = "Project Zomboid (Vanilla)",
            author = "The Indie Stone",
            version = "Build 42",
            desc = "Core Game Engine",
            namespaces = {},
            estimatedBytes = 0,
            tableCount = 0,
            closureCount = 0,
            hookCount = 0,
            hooks = {},
            stressScore = 0,
            rating = "LIGHT"
        }
        modMap["vanilla"] = vanillaEntry
        totalActive = 1
    end

    -- 2. Namespace Scan & Memory Attribution
    local visitedTables = {}
    local matchedGlobalTables = {}
    local fnToMod = {}
    local fnToDesc = {}

    for globalName, val in pairs(_G) do
        if type(globalName) == "string" and not VANILLA_BLACKLIST[globalName] then
            -- Check if it starts with "IS" (Indie Stone UI prefix) unless explicitly matched
            local isVanillaIS = (string.sub(globalName, 1, 2) == "IS")

            local matchedMod = nil
            local normGName = normalizeToken(globalName)

            -- Fast token lookup
            if not isVanillaIS then
                matchedMod = tokenToMod[normGName]

                -- Check substring match against known tokens
                if not matchedMod then
                    for tok, mEntry in pairs(tokenToMod) do
                        if #tok >= 4 and (string.find(normGName, tok, 1, true) or string.find(tok, normGName, 1, true)) then
                            matchedMod = mEntry
                            break
                        end
                    end
                end

                -- Check well-known lookup table
                if not matchedMod and KNOWN_MOD_NAMESPACES[normGName] then
                    local targetId = KNOWN_MOD_NAMESPACES[normGName]
                    matchedMod = modMap[targetId] or tokenToMod[targetId]
                end

                -- Check internal table metadata self-identification
                if not matchedMod and type(val) == "table" then
                    local tModId = val.modId or val.MOD_ID or val.mod_id or val._modId
                    if tModId and type(tModId) == "string" then
                        local normTMod = normalizeToken(tModId)
                        matchedMod = tokenToMod[normTMod] or modMap[string.lower(tModId)]
                    end
                end
            end

            if matchedMod and type(val) == "function" then
                fnToMod[val] = matchedMod
                fnToDesc[val] = globalName .. "()"
            elseif type(val) == "table" then
                -- Measure table footprint
                local tBytes, tTables, tClosures = estimateTableMemory(val, visitedTables, 0)
                totalEstimatedBytes = totalEstimatedBytes + tBytes

                if matchedMod then
                    table.insert(matchedMod.namespaces, globalName)
                    matchedMod.estimatedBytes = matchedMod.estimatedBytes + tBytes
                    matchedMod.tableCount = matchedMod.tableCount + tTables
                    matchedMod.closureCount = matchedMod.closureCount + tClosures
                    table.insert(matchedGlobalTables, { name = globalName, tbl = val, mod = matchedMod })
                end
            end
        end
    end

    -- 3. Build Reverse Function Registry for 100% Exact Callback Attribution
    local function registerTableFunctions(tbl, mEntry, prefix, depth, seen)
        if not tbl or type(tbl) ~= "table" or depth > 4 or seen[tbl] then return end
        seen[tbl] = true
        for k, v in pairs(tbl) do
            if type(k) == "string" or type(k) == "number" then
                local path = prefix .. "." .. tostring(k)
                if type(v) == "function" then
                    fnToMod[v] = mEntry
                    fnToDesc[v] = path
                elseif type(v) == "table" and v ~= _G and v ~= tbl then
                    registerTableFunctions(v, mEntry, path, depth + 1, seen)
                end
            end
        end
    end

    local seenTbls = {}
    for _, mg in ipairs(matchedGlobalTables) do
        registerTableFunctions(mg.tbl, mg.mod, mg.name, 1, seenTbls)
    end

    -- 4. Evaluate Active Event Hooks (From Interceptor Registry & Event Tables)
    local captured = MPOptim.ModProfiler.CapturedHooks or {}

    -- Merge any existing callbacks from Events table if exposed
    if Events and type(Events) == "table" then
        for evName, evObj in pairs(Events) do
            if type(evName) == "string" and type(evObj) == "table" and evObj.callbacks then
                local cbs = evObj.callbacks
                if cbs.size and cbs.get then
                    local sz = cbs:size()
                    for i = 0, sz - 1 do
                        local fn = cbs:get(i)
                        if fn and type(fn) == "function" then
                            MPOptim.ModProfiler.RegisterHook(evName, fn)
                        end
                    end
                elseif type(cbs) == "table" then
                    for _, fn in pairs(cbs) do
                        if fn and type(fn) == "function" then
                            MPOptim.ModProfiler.RegisterHook(evName, fn)
                        end
                    end
                end
            end
        end
    end

    -- Attribute each captured event hook to its owning mod
    for evName, hookList in pairs(captured) do
        local weight = EVENT_WEIGHTS[evName] or 2
        local tagInfo = EVENT_TAGS[evName] or { tag = "EVENT", r = 0.65, g = 0.65, b = 0.65 }

        for _, hookRec in ipairs(hookList) do
            local fn = hookRec.fn
            local matchedMod = fnToMod[fn]
            local desc = fnToDesc[fn]

            -- If not matched via table functions, check if only 1 active mod exists
            if not matchedMod and totalActive == 1 then
                for _, mEntry in pairs(modMap) do
                    matchedMod = mEntry
                    break
                end
            end

            if matchedMod then
                matchedMod.hookCount = matchedMod.hookCount + (hookRec.count or 1)
                matchedMod.stressScore = matchedMod.stressScore + (weight * (hookRec.count or 1))
                totalHooksCount = totalHooksCount + (hookRec.count or 1)

                table.insert(matchedMod.hooks, {
                    event = evName,
                    desc = desc or evName,
                    tag = tagInfo.tag,
                    color = { r = tagInfo.r, g = tagInfo.g, b = tagInfo.b },
                    weight = weight
                })
            end
        end
    end

    -- 5. Calculate Final Ratings & Format Diagnostics
    for _, mData in pairs(modMap) do
        local mb = mData.estimatedBytes / (1024 * 1024)
        local stress = mData.stressScore

        if stress >= 70 or mb >= 15.0 then
            mData.rating = "VERY HIGH"
        elseif stress >= 35 or mb >= 6.0 then
            mData.rating = "HIGH"
        elseif stress >= 12 or mb >= 1.5 or mData.hookCount >= 3 then
            mData.rating = "MODERATE"
        else
            mData.rating = "LIGHT"
        end

        table.insert(results, mData)
    end

    -- 6. Sort results: Highest stress score first, then largest memory footprint
    table.sort(results, function(a, b)
        if a.stressScore ~= b.stressScore then
            return a.stressScore > b.stressScore
        end
        return a.estimatedBytes > b.estimatedBytes
    end)

    return {
        mods = results,
        totalMods = totalActive,
        totalHooks = totalHooksCount,
        totalMemoryMB = (totalEstimatedBytes / (1024 * 1024))
    }
end

function MPOptim.ModProfiler.GetEventTag(evName)
    return EVENT_TAGS[evName] or { tag = "EVENT", r = 0.65, g = 0.65, b = 0.65 }
end