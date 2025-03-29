local self = require("openmw.self")
local ui = require("openmw.ui")
local util = require("openmw.util")
local I = require('openmw.interfaces')
local async = require('openmw.async')
local types = require("openmw.types")
local core = require("openmw.core")
local vfs = require('openmw.vfs')

local quests = {}
local questMenu = nil
local questDetail = nil

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

local function initQuestMenu()
    ui.showMessage('INIT QUEST MENU')
    loadQuests()
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
        questMenu:destroy()
        questMenu = ui.create {
            layer = 'Windows',
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
                                size = util.vector2(48, 48),
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
                                        },
                                        {
                                            type = ui.TYPE.Text,
                                            props = {
                                                text = qid,
                                                textColor = util.color.rgb(0.5, 0.5, 0.5),
                                                textSize = 12,
                                                textAlignH = ui.ALIGNMENT.End
                                            },
                                        },
                                        {
                                            type = ui.TYPE.Text,
                                            props = {
                                                text = "Stage: " .. quest.stage,
                                                textColor = util.color.rgb(0.5, 0.5, 0.5),
                                                textSize = 12,
                                                textAlignH = ui.ALIGNMENT.End
                                            },
                                        }
                                    }
                                },
                                {
                                    template = I.MWUI.templates.textParagraph,
                                    props = {
                                        size = util.vector2(600, 48),
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
                showQuestDetail(quest)
            end)
        }
    }
end

local function questList()
    local questlist = {}

    if questDetail then
        return ui.create {
            type = ui.TYPE.Flex,
            content = ui.content(questDetail),
        }
    end

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

local function createMenu()
    questMenu = ui.create {
        layer = 'Windows',
        template = I.MWUI.templates.boxSolid,
        props = {
            position = util.vector2(10, 10),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content {
                    header(),
                    questList()
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
                if not layout.userData.doDrag then return end
                local props = layout.props
                props.position = props.position - (layout.userData.lastMousePos - coord.position)
                if questMenu then
                    questMenu:update()
                end
                layout.userData.lastMousePos = coord.position
            end),
        },
        userData = {
            doDrag = false,
            lastMousePos = nil,
        }
    }
end

local function reloadMenu()
    loadQuests();

    if (questMenu) then
        questMenu:destroy()
        questMenu = nil
    end

    createMenu();
end

return {
    engineHandlers = {
        onInit = initQuestMenu,
        onLoad = initQuestMenu,
        onQuestUpdate = reloadMenu,
        onKeyPress = function(key)
            if key.symbol == "x" and questMenu == nil then
                createMenu()
            elseif key.symbol == "x" and questMenu then
                questMenu:destroy()
                questMenu = nil
            end
        end
    }
}
