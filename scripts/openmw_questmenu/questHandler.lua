local self = require("openmw.self")
local core = require("openmw.core")
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local types = require("openmw.types")
local ui = require('openmw.ui')
local util = require('openmw.util')
local vfs = require('openmw.vfs')
local async = require('openmw.async')

local modVersion = "1.1.0"

local questList = {
    quests = {},
    version = modVersion
}
local followedQuest = nil

local playerCustomizationSettings = storage.playerSection('SettingsPlayerOpenMWQuestMenuCustomization')

local function getQuestText(questId, stage)
    local dialogueRecord = core.dialogue.journal.records[questId]

    local filteredDialogue = nil
    for _, dialogue in pairs(dialogueRecord.infos) do
        if dialogue.questStage == stage then
            filteredDialogue = dialogue
        end
    end

    if filteredDialogue == nil then
        return "Error: No information found."
    end

    return filteredDialogue.text
end

local function getFollowedQuest(quests)
    for _, quest in pairs(quests) do
        if quest.followed == true then
            return quest
        end
    end

    return nil
end

local function showFollowedQuest(quest)
    if quest == nil then
        return
    end

    if (followedQuest ~= nil) then
        followedQuest:destroy()
        followedQuest = nil
    end

    local function createIcon()
        if I.SSQN then
            local icon = I.SSQN.getQIcon(quest.id)

            if not vfs.fileExists(icon) then icon = "Icons\\SSQN\\DEFAULT.dds" end

            return {
                type = ui.TYPE.Image,
                props = {
                    size = util.vector2(playerCustomizationSettings:get('FIconSize'),
                        playerCustomizationSettings:get('FIconSize')),
                    resource = ui.texture { path = icon },
                }
            }
        end

        return {}
    end

    local stage = #quest.stages > 0 and quest.stages[1] or "No Information Found"
    local text = getQuestText(quest.id, stage)

    followedQuest = ui.create({
        type = ui.TYPE.Container,
        layer = 'Windows',
        template = I.MWUI.templates.boxTransparent,
        props = {
            position = util.vector2(
                playerCustomizationSettings:get('FPosX'),
                playerCustomizationSettings:get('FPosY')
            ),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true
                        },
                        content = ui.content {
                            createIcon(),
                            {
                                type = ui.TYPE.Widget,
                                props = {
                                    size = util.vector2(10, 6)
                                }
                            },
                            {
                                type = ui.TYPE.Flex,
                                content = ui.content {
                                    {
                                        type = ui.TYPE.Flex,
                                        props = {
                                            horizontal = true
                                        },
                                        content = ui.content {
                                            {
                                                type = ui.TYPE.Text,
                                                props = {
                                                    text = quest.name,
                                                    textColor = util.color.rgb(1, 1, 1),
                                                    textSize = playerCustomizationSettings:get('FHeadlineSize'),
                                                    textAlignH = ui.ALIGNMENT.Start
                                                },
                                            }
                                        }
                                    },
                                    {
                                        template = I.MWUI.templates.textParagraph,
                                        props = {
                                            size = util.vector2(600, 10),
                                            text = text,
                                            textSize = playerCustomizationSettings:get('FTextSize'),
                                        },
                                    }
                                }
                            }
                        }
                    }
                }
            }
        },
        events = {
            mousePress = async:callback(function(coord, layout)
                layout.userData.doDrag = true
                layout.userData.lastMousePos = coord.position
            end),
            mouseRelease = async:callback(function(_, layout)
                layout.userData.doDrag = false
            end),
            mouseMove = async:callback(function(coord, layout)
                if followedQuest == nil or not layout.userData.doDrag then return end
                local props = layout.props
                props.position = props.position - (layout.userData.lastMousePos - coord.position)
                followedQuest:update()
                layout.userData.lastMousePos = coord.position
            end),
        },
        userData = {
            doDrag = false,
            lastMousePos = nil,
        }
    })
end

local function followQuest(qid)
    local newFollowedQuest = nil
    local newQuestList = {}

    for _, quest in ipairs(questList.quests) do
        if quest.id == qid then
            newFollowedQuest = quest
            newFollowedQuest.followed = not quest.followed
            table.insert(newQuestList, newFollowedQuest)
        else
            quest.followed = false
            table.insert(newQuestList, quest)
        end
    end

    if (newFollowedQuest ~= nil and newFollowedQuest.followed) then
        showFollowedQuest(newFollowedQuest)
    end

    if (followedQuest and (newFollowedQuest == nil or not newFollowedQuest.followed)) then
        followedQuest:destroy()
        followedQuest = nil
    end

    questList.quests = newQuestList
    return newQuestList
end

local function toggleQuest(qid)
    local newQuestList = {};
    for _, quest in ipairs(questList.quests) do
        if quest.id == qid then
            quest.hidden = not quest.hidden
        end

        table.insert(newQuestList, quest)
    end
    questList.quests = newQuestList
end

local function onUpdateToNewVersion(oldListOrObject)
    local newQuestListStructure = {
        quests = {},
        version = modVersion
    };

    local questsArrayToMigrate
    -- Heuristic to determine if oldListOrObject is the flat array or a versioned object
    if (oldListOrObject.version == nil and type(oldListOrObject) == "table" and (#oldListOrObject > 0 or next(oldListOrObject) == nil) and oldListOrObject.quests == nil) then
        -- It's likely the old flat array of quests if it has no .version and no .quests property,
        -- and is either empty or its first numeric key is 1 (typical for ipairs).
        questsArrayToMigrate = oldListOrObject
    elseif oldListOrObject.quests then -- It's an older versioned object with a .quests array
        questsArrayToMigrate = oldListOrObject.quests
    else
        core.sendGlobalEvent("OpenMWQuestList_MigrationWarning", "Unknown old data format during migration.")
        questsArrayToMigrate = {} -- Safety: unknown format
    end

    for _, quest in ipairs(questsArrayToMigrate) do
        -- Basic validation: ensure essential fields exist before trying to access them
        if quest and quest.id and quest.name and quest.name ~= "" then
            local migratedQuest = {
                id = quest.id:lower(), -- Standardize ID to lowercase
                name = quest.name,
                hidden = quest.hidden or false,
                finished = quest.finished or false,
                followed = quest.followed or false,
                stages = {}
            }
            if quest.stage then -- Old format might have a single 'stage'
                table.insert(migratedQuest.stages, quest.stage)
            elseif quest.stages and type(quest.stages) == "table" then -- Or it might already have a stages array
                for _, s in ipairs(quest.stages) do table.insert(migratedQuest.stages, s) end
            end
            table.insert(newQuestListStructure.quests, migratedQuest)
        else
            core.sendGlobalEvent("OpenMWQuestList_MigrationWarning", "Skipping invalid quest entry during migration: " .. (quest and quest.id or "unknown"))
        end
    end

    return newQuestListStructure
end

local function onQuestUpdate(questId, stage)
    local isFinished = false;
    for _, quest in pairs(types.Player.quests(self)) do
        if (quest.id == questId) then
            isFinished = quest.finished
        end
    end

    local qid = questId:lower()
    local dialogueRecord = core.dialogue.journal.records[qid]

    local questExists = false;
    local newQuestList = {};
    for _, quest in ipairs(questList.quests) do
        -- If Quest already exists just update it:
        if quest.id == qid then
            questExists = true
            quest.finished = isFinished
            table.insert(quest.stages, 1, stage)
        end

        -- Unfollow quest when it is finished
        if quest.followed and isFinished then
            followQuest(qid)
        end

        table.insert(newQuestList, quest)
    end

    -- If Quest doesnt exist yet, add new list entry:
    if (questExists == false and dialogueRecord.questName and dialogueRecord.questName ~= "") then
        local newQuest = {
            id = qid,
            name = dialogueRecord.questName,
            hidden = false,
            finished = isFinished,
            followed = false,
            stages = {}
        }

        table.insert(newQuest.stages, stage)
        table.insert(newQuestList, 1, newQuest)
    end

    questList.quests = newQuestList
    showFollowedQuest(getFollowedQuest(newQuestList))
end

local function onSave()
    return {
        questList = questList,
    }
end

local function onLoad(data)
    -- This will be the definitive list of quests for the current session,
    -- ensuring all game quests are present and mod-specific data is merged.
    local newSessionQuestList = {}

    -- Step 1: Populate with current quests from the game (this is the baseline)
    -- All quest IDs will be stored in lowercase internally for consistency.
    for _, gameQuest in pairs(types.Player.quests(self)) do
        local dialogueRecord = core.dialogue.journal.records[gameQuest.id:lower()] -- Use lowercase for lookup
        if dialogueRecord and dialogueRecord.questName and dialogueRecord.questName ~= "" then
            table.insert(newSessionQuestList, {
                id = gameQuest.id:lower(), -- Store ID in lowercase
                name = dialogueRecord.questName,
                hidden = false, -- Default
                finished = gameQuest.finished,
                followed = false, -- Default
                stages = {gameQuest.stage} -- Latest stage from game is initially the only one
            })
        end
    end

    local modDataFromSave = nil -- This will hold {quests={}, version=""} from save file after potential migration

    if data and data.questList then
        -- We have existing save data for this mod.
        if not data.questList.version or data.questList.version ~= modVersion then
            -- Perform version migration
            core.log("OpenMWQuestList: Migrating data from old version " .. (data.questList.version or "unknown") .. " to " .. modVersion)
            modDataFromSave = onUpdateToNewVersion(data.questList) -- Returns the migrated structure
        else
            -- Version matches, use the saved data directly
            modDataFromSave = data.questList
        end

        -- Step 2: Merge modDataFromSave into newSessionQuestList
        if modDataFromSave and modDataFromSave.quests then
            local followedQuestIdFromSave = nil -- To track which quest was followed

            -- Create a map of newSessionQuestList for efficient updating
            local activeQuestsMap = {}
            for _, activeQuest in ipairs(newSessionQuestList) do
                activeQuestsMap[activeQuest.id] = activeQuest -- ID is already lowercase
            end

            for _, savedQuest in ipairs(modDataFromSave.quests) do
                if savedQuest.id then -- Ensure savedQuest has an ID
                    local liveQuestToUpdate = activeQuestsMap[savedQuest.id:lower()] -- Ensure lookup is lowercase
                    if liveQuestToUpdate then
                        -- Quest from save exists in current game. Merge mod-specific properties.
                        liveQuestToUpdate.hidden = savedQuest.hidden
                        liveQuestToUpdate.followed = savedQuest.followed -- Tentatively set

                        if liveQuestToUpdate.followed then
                            if followedQuestIdFromSave then
                                core.log("OpenMWQuestList Warning: Multiple followed quests found in save data. Using last one: " .. liveQuestToUpdate.id)
                            end
                            followedQuestIdFromSave = liveQuestToUpdate.id
                        end

                        -- Merge stages: Game's current stage (already in liveQuestToUpdate.stages[1])
                        -- should be primary. Add other distinct stages from savedQuest.
                        local currentStageFromGame = liveQuestToUpdate.stages[1]
                        local combinedStages = { currentStageFromGame }
                        local stagesSet = { [currentStageFromGame] = true }

                        if savedQuest.stages and type(savedQuest.stages) == "table" then
                            for _, oldStage in ipairs(savedQuest.stages) do
                                if not stagesSet[oldStage] then
                                    table.insert(combinedStages, oldStage)
                                    stagesSet[oldStage] = true
                                end
                            end
                        end
                        liveQuestToUpdate.stages = combinedStages
                    else
                        -- Quest was in mod's save data but is NOT in the current game's active quests.
                        -- It's an "orphaned" quest (e.g., removed by console, mod conflict).
                        -- It's implicitly dropped because newSessionQuestList was built from current game state.
                        -- If it was marked 'followed', that state will be lost, which is correct.
                        core.log("OpenMWQuestList: Orphaned quest from save data dropped: " .. savedQuest.id)
                    end
                end
            end

            -- Ensure only one quest is actually marked as followed in the final list
            local oneQuestIsMarkedFollowed = false
            if followedQuestIdFromSave then
                for _, q in ipairs(newSessionQuestList) do
                    if q.id == followedQuestIdFromSave and q.followed then
                        if oneQuestIsMarkedFollowed then
                            q.followed = false -- Unfollow if another was already confirmed
                        else
                            oneQuestIsMarkedFollowed = true -- This is the one true followed quest
                        end
                    else
                        q.followed = false -- Unfollow any others
                    end
                end
            end
            -- If the followedQuestIdFromSave pointed to an orphaned quest, or none was followed:
            if not oneQuestIsMarkedFollowed then
                for _, q in ipairs(newSessionQuestList) do q.followed = false end
            end
        end
    end

    -- Update the global questList object
    questList.quests = newSessionQuestList
    questList.version = modVersion -- Always set to current mod version after load/merge process

    showFollowedQuest(getFollowedQuest(questList.quests))
end

local function getQuestList()
    return questList.quests
end

return {
    interfaceName = 'OpenMWQuestList',
    interface = {
        getQuestList = getQuestList,
        getQuestText = getQuestText,
        followQuest = followQuest,
        toggleQuest = toggleQuest
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onQuestUpdate = onQuestUpdate
    }
}
