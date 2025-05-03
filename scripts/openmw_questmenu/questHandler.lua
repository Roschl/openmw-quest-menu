local core = require("openmw.core")

local questList = {}

local function findDialogueWithStage(dialogueTable, targetStage)
    local filteredDialogue = nil

    for _, dialogue in pairs(dialogueTable) do
        if dialogue.questStage == targetStage then
            filteredDialogue = dialogue
        end
    end

    return filteredDialogue
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

local function onQuestUpdate(questId, stage)
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
            quest.finished = dialogueRecordInfo.questFinished
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
            finished = dialogueRecordInfo.questFinished,
            notes = {}
        }

        table.insert(newQuest.notes, dialogueRecordInfo.text)
        table.insert(newQuestList, newQuest)
    end

    questList = newQuestList
end

local function onSave()
    return {
        questList = questList,
    }
end

local function onLoad(data)
    if not data or not data.questList then
        questList = {}
        return
    end

    questList = data.questList
end

local function getQuestList()
    return questList
end

return {
    interfaceName = 'OpenMWQuestList',
    interface = {
        getQuestList = getQuestList,
        toggleQuest = toggleQuest
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onQuestUpdate = onQuestUpdate
    }
}
