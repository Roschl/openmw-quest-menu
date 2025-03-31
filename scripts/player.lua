local self = require("openmw.self")
local ui = require("openmw.ui")
local util = require("openmw.util")
local I = require('openmw.interfaces')
local async = require('openmw.async')
local types = require("openmw.types")
local core = require("openmw.core")
local storage = require('openmw.storage')
local vfs = require('openmw.vfs')

local quests = {}
local questMenu = nil

local currentView = "list" -- Can be "list" or "detail"
local selectedQuest = nil

local renderMenu
local setView = function(view, quest)
    currentView = view
    selectedQuest = quest or nil
    renderMenu()
end

I.Settings.registerPage {
    key = 'OpenMWQuestStatusMenuPage',
    l10n = 'OpenMWQuestStatusMenu',
    name = 'OpenMW Quest Status Menu',
    description = 'Settings for the quest status menu.',
}

I.Settings.registerGroup {
    key = 'SettingsPlayerOpenMWQuestStatusMenu',
    page = 'OpenMWQuestStatusMenuPage',
    l10n = 'OpenMWQuestStatusMenu',
    name = 'Controls',
    permanentStorage = true,
    settings = {
        {
            key = 'OpenMenu',
            renderer = 'textLine',
            name = 'Open Menu',
            description = 'Key to open menu.',
            default = 'x',
        },
    },
}

local playerSettings = storage.playerSection('SettingsPlayerOpenMWQuestStatusMenu')


local function findDialogueWithStage(dialogueTable, targetStage)
    local filteredDialogue = nil

    for _, dialogue in pairs(dialogueTable) do
        if dialogue.questStage == targetStage then
            filteredDialogue = dialogue
        end
    end

    return filteredDialogue
end

local function loadQuests()
    quests = types.Player.quests(self)
end

local function showQuestDetail(quest)
    local qid = quest.id:lower()
    local dialogueRecord = core.dialogue.journal.records[qid]
    local dialogueRecordInfo = findDialogueWithStage(dialogueRecord.infos, quest.stage)
    local icon = I.SSQN.getQIcon(qid)

    if not vfs.fileExists(icon) then icon = "Icons\\SSQN\\DEFAULT.dds" end

    if dialogueRecordInfo == nil then
        dialogueRecordInfo = {
            text = "No Information Found"
        }
    end

    if (questMenu) then
        return {
            template = I.MWUI.templates.boxTransparent,
            props = {
                position = util.vector2(10, 10),
                relativeSize = util.vector2(.5, .5),
            },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true
                    },
                    content = ui.content {
                        {
                            type = ui.TYPE.Image,
                            props = {
                                size = util.vector2(30, 30),
                                resource = ui.texture { path = icon },
                                color = util.color.rgb(1, 1, 1),
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
                                                text = dialogueRecord.questName,
                                                textColor = util.color.rgb(1, 1, 1),
                                                textSize = 14,
                                                textAlignH = ui.ALIGNMENT.Start
                                            },
                                        }
                                    }
                                },
                                {
                                    template = I.MWUI.templates.textParagraph,
                                    props = {
                                        size = util.vector2(600, 10),
                                        text = dialogueRecordInfo.text,
                                        textSize = 12,
                                    },
                                }
                            }
                        }
                    }
                }
            }
        }
    end
end

local function questListItem(quest)
    local qid = quest.id:lower()
    local icon = I.SSQN.getQIcon(qid)

    if not vfs.fileExists(icon) then icon = "Icons\\SSQN\\DEFAULT.dds" end

    return {
        type = ui.TYPE.Image,
        props = {
            size = util.vector2(20, 20),
            resource = ui.texture { path = icon },
            color = util.color.rgb(1, 1, 1),
        },
        events = {
            mouseClick = async:callback(function()
                setView("detail", quest)
            end)
        },
    }
end

local function questList()
    local questlist = {}

    for _, quest in pairs(quests) do
        if quest.finished == false then
            table.insert(questlist, questListItem(quest))
        end
    end

    return ui.create {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true
        },
        content = ui.content(questlist),
    }
end

local function header()
    return ui.create {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.textHeader,
                type = ui.TYPE.Text,
                props = {
                    text = "Quests",
                    textSize = 12,
                },
            },
        }
    }
end

renderMenu = function()
    local content = {}

    if currentView == "list" then
        table.insert(content, header())
        table.insert(content, questList())
    elseif currentView == "detail" and selectedQuest then
        table.insert(content, showQuestDetail(selectedQuest))
        table.insert(content, {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text = "Back",
                textSize = 12,
            },
            events = {
                mouseClick = async:callback(function()
                    setView("list")
                end)
            }
        })
    else
        table.insert(content, {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text = "THERE IS NO INFORMATION",
                textSize = 12,
            }
        })
    end

    if questMenu then
        questMenu:destroy()
    end

    questMenu = ui.create {
        layer = 'Windows',
        template = I.MWUI.templates.boxSolid,
        props = {
            position = util.vector2(10, 10),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content)
            }
        }
    }
end

local function onQuestUpdate()
    loadQuests();

    if (currentView == "detail" and selectedQuest) then
        setView("detail", selectedQuest)
    else
        setView("list");
        return;
    end
end

return {
    engineHandlers = {
        onInit = loadQuests,
        onLoad = loadQuests,
        onQuestUpdate = onQuestUpdate,
        onKeyPress = function(key)
            if key.symbol == playerSettings:get('OpenMenu') and questMenu == nil then
                renderMenu()
            elseif key.symbol == playerSettings:get('OpenMenu') and questMenu then
                questMenu:destroy()
                questMenu = nil
                selectedQuest = nil
                currentView = "list"
            end
        end
    }
}
