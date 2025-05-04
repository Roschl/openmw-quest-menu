local self = require("openmw.self")
local core = require("openmw.core")
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local types = require("openmw.types")
local ui = require('openmw.ui')
local util = require('openmw.util')
local vfs = require('openmw.vfs')

local questList = {}
local followedQuest = nil

local playerCustomizationSettings = storage.playerSection('SettingsPlayerOpenMWQuestMenuCustomization')

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
                    size = util.vector2(playerCustomizationSettings:get('IconSize'),
                        playerCustomizationSettings:get('IconSize')),
                    resource = ui.texture { path = icon },
                }
            }
        end

        return {}
    end

    local note = #quest.notes > 0 and quest.notes[1] or "No Information Found"

    local uiWindow = {
        type = ui.TYPE.Container,
        layer = 'Windows',
        template = I.MWUI.templates.boxSolid,
        props = {
            position = util.vector2(10, 10),
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
                                                    textSize = playerCustomizationSettings:get('HeadlineSize'),
                                                    textAlignH = ui.ALIGNMENT.Start
                                                },
                                            }
                                        }
                                    },
                                    {
                                        template = I.MWUI.templates.textParagraph,
                                        props = {
                                            size = util.vector2(600, 10),
                                            text = note,
                                            textSize = playerCustomizationSettings:get('TextSize'),
                                        },
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    followedQuest = ui.create(uiWindow)
end

local function findDialogueWithStage(dialogueTable, targetStage)
    local filteredDialogue = nil

    for _, dialogue in pairs(dialogueTable) do
        if dialogue.questStage == targetStage then
            filteredDialogue = dialogue
        end
    end

    return filteredDialogue
end

local function followQuest(qid)
    local newFollowedQuest = nil
    local newQuestList = {}

    for _, quest in ipairs(questList) do
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

    questList = newQuestList
    return newQuestList
end

local function toggleQuest(qid)
    local newQuestList = {};
    for _, quest in ipairs(questList) do
        if quest.id == qid then
            quest.hidden = not quest.hidden
        end

        table.insert(newQuestList, quest)
    end
    questList = newQuestList
end

local function onLoadMidGame()
    local newQuestList = {};

    for _, quest in pairs(types.Player.quests(self)) do
        local dialogueRecord = core.dialogue.journal.records[quest.id]
        local dialogueRecordInfo = findDialogueWithStage(dialogueRecord.infos, quest.stage)

        if dialogueRecordInfo == nil then
            dialogueRecordInfo = {
                text = "No Information Found"
            }
        end

        local newQuest = {
            id = quest.id,
            name = dialogueRecord.questName,
            stage = quest.stage,
            hidden = false,
            finished = quest.finished,
            followed = false,
            notes = {}
        }
        table.insert(newQuest.notes, 1, dialogueRecordInfo.text)
        table.insert(newQuestList, newQuest)
    end

    questList = newQuestList
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
    local dialogueRecordInfo = findDialogueWithStage(dialogueRecord.infos, stage)

    if dialogueRecordInfo == nil then
        dialogueRecordInfo = {
            text = "No Information Found"
        }
    end

    local questExists = false;
    local newQuestList = {};
    for _, quest in ipairs(questList) do
        -- If Quest already exists just update it:
        if quest.id == qid then
            questExists = true
            quest.stage = stage
            quest.finished = isFinished
            table.insert(quest.notes, 1, dialogueRecordInfo.text)
        end

        table.insert(newQuestList, quest)
    end

    -- If Quest doesnt exist yet, add new list entry:
    if (questExists == false) then
        local newQuest = {
            id = qid,
            name = dialogueRecord.questName,
            stage = stage,
            hidden = false,
            finished = isFinished,
            followed = false,
            notes = {}
        }

        table.insert(newQuest.notes, dialogueRecordInfo.text)
        table.insert(newQuestList, 1, newQuest)
    end

    questList = newQuestList
    showFollowedQuest(getFollowedQuest(newQuestList))
end

local function onSave()
    return {
        questList = questList,
    }
end

local function onLoad(data)
    if not data or not data.questList or #data.questList == 0 then
        onLoadMidGame()
        return
    end

    questList = data.questList
    showFollowedQuest(getFollowedQuest(data.questList))
end

local function getQuestList()
    return questList
end

return {
    interfaceName = 'OpenMWQuestList',
    interface = {
        getQuestList = getQuestList,
        followQuest = followQuest,
        toggleQuest = toggleQuest
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onQuestUpdate = onQuestUpdate
    }
}
