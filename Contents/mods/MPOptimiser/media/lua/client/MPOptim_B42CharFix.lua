--[[
    Project Zomboid Optimiser - Build 42 Character Creation Preset Fix
    File: media/lua/client/MPOptim_B42CharFix.lua
    Author: prop11
    Description: Fixes vanilla Build 42 (42.20.3) crash when loading/saving character presets.
                 Safely ignores Build 41 to ensure 100% vanilla Build 41 character creation & 3D model rendering.
--]]

-- Strict Build 42 Guard: Exit immediately if running on Build 41
local ver = getCore and getCore().getVersionNumber and getCore():getVersionNumber() or ""
local isB42 = ver:find("^42") or (IsoAnimals ~= nil)
if not isB42 then
    return -- 100% untouched on Build 41
end

-- Guard against missing BCRC
if not BCRC or not BCRC.readSaveFile then
    return
end

require "OptionScreens/CharacterCreationProfession"

local function getObjectTypeName(obj)
    if not obj then return "" end
    local t = obj.getType and obj:getType()
    if type(t) == "string" then return t end
    if t and t.getName then return t:getName() end
    if type(obj) == "string" then return obj end
    if obj.getName then return obj:getName() end
    return tostring(obj)
end

if CharacterCreationProfession then
    -- Patch loadBuild for Build 42
    CharacterCreationProfession.loadBuild = function(self, box)
        local prof = box.options[box.selected]
        if prof == nil then return end

        if not BCRC or not BCRC.readSaveFile then return end
        local saved_builds = BCRC.readSaveFile()
        if not saved_builds then return end
        local build = saved_builds[prof]
        if build == nil then return end

        local traits = luautils.split(build, ";")
        if not traits or #traits == 0 then return end

        self:resetBuild()

        -- 1. Match Profession
        local targetProfName = traits[1]
        if self.listboxProf and self.listboxProf.items then
            for i = 1, #self.listboxProf.items do
                local profObj = self.listboxProf.items[i].item
                local profName = getObjectTypeName(profObj)
                if profName == targetProfName or (profObj.getName and profObj:getName() == targetProfName) then
                    self.listboxProf.selected = i
                    self:onSelectProf(self:getSelectedProf())
                    break
                end
            end
        end

        -- 2. Match Good Traits
        for j = 2, #traits do
            local targetTrait = traits[j]
            if targetTrait and targetTrait ~= "" and self.listboxTrait and self.listboxTrait.items then
                for i = 1, #self.listboxTrait.items do
                    if self.listboxTrait.items[i] ~= nil then
                        local trait = self.listboxTrait.items[i].item
                        local traitName = getObjectTypeName(trait)
                        if traitName == targetTrait or (trait.getName and trait:getName() == targetTrait) then
                            self.listboxTrait.selected = i
                            self:onOptionMouseDown(self.addTraitBtn)
                            break
                        end
                    end
                end
            end
        end

        -- 3. Match Bad Traits
        for j = 2, #traits do
            local targetTrait = traits[j]
            if targetTrait and targetTrait ~= "" and self.listboxBadTrait and self.listboxBadTrait.items then
                for i = 1, #self.listboxBadTrait.items do
                    if self.listboxBadTrait.items[i] ~= nil then
                        local trait = self.listboxBadTrait.items[i].item
                        local traitName = getObjectTypeName(trait)
                        if traitName == targetTrait or (trait.getName and trait:getName() == targetTrait) then
                            self.listboxBadTrait.selected = i
                            self:onOptionMouseDown(self.addBadTraitBtn)
                            break
                        end
                    end
                end
            end
        end
    end

    -- Patch saveBuildStep2 for Build 42
    CharacterCreationProfession.saveBuildStep2 = function(self, button, joypadData, param2)
        if joypadData then
            joypadData.focus = self.presetPanel
            updateJoypadFocus(joypadData)
        end

        if button.internal == "CANCEL" then
            return
        end

        if not BCRC or not BCRC.readSaveFile then return end
        local builds = BCRC.readSaveFile()
        if not builds then return end

        local profObj = self:getSelectedProf()
        local characterProfession = getObjectTypeName(profObj)
        local savestring = characterProfession .. ";"

        if self.listboxTraitSelected and self.listboxTraitSelected.items then
            for i = 1, #self.listboxTraitSelected.items do
                local trait = self.listboxTraitSelected.items[i].item
                if trait and not trait:isFree() then
                    local traitName = getObjectTypeName(trait)
                    savestring = savestring .. traitName .. ";"
                end
            end
        end

        local savename = button.parent.entry:getText()
        if savename == "" then return end
        builds[savename] = savestring

        local options = {}
        if BCRC.writeSaveFile then
            BCRC.writeSaveFile(builds)
        end
        for key, val in pairs(builds) do
            options[key] = 1
        end

        self.savedBuilds.options = {}
        local i = 1
        for key, val in pairs(options) do
            table.insert(self.savedBuilds.options, key)
            if key == savename then
                self.savedBuilds.selected = i
            end
            i = i + 1
        end
    end
end
