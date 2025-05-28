local core = require("openmw.core")
local ui = require('openmw.ui')

local function isBlacklisted(questId)
    local dialogueRecord = core.dialogue.journal.records[questId]
    local canBeFinished = false

    for __, info in pairs(dialogueRecord.infos) do
        if info.isQuestFinished == true then
            canBeFinished = true
        end
    end

    return not canBeFinished
end

local function cleanList(quests)
    local newQuestList = {}

    for _, quest in pairs(quests) do
        if not isBlacklisted(quest.id) then
            table.insert(newQuestList, quest)
        end
    end

    ui.showMessage("Cleaned quest list. Removed " .. #quests - #newQuestList .. " fake quests.")
    return newQuestList
end

return {
    cleanList = cleanList,
    isBlacklisted = isBlacklisted
}
