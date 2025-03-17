local self = require("openmw.self")
local ui = require("openmw.ui")
local util = require("openmw.util")
local I = require('openmw.interfaces')
local async = require('openmw.async')
local types = require("openmw.types")
local core = require("openmw.core")
local vfs = require('openmw.vfs')

-- Copied some stuff from
-- OpenMW Skyrim Style Quest Notifications (version 1.24)
-- by taitechnic

local iconlist = {}

local function parseList(list, isMain)
    local name = ""
    for k, v in pairs(list) do
        if not iconlist[k:lower()] or isMain then
            name = string.sub(v, 2, -1)
            iconlist[k:lower()] = name
        end
    end
    return list
end

local M = require("scripts.SSQN.iconlist")
parseList(M, true)

for i in vfs.pathsWithPrefix("scripts\\SSQN\\iconlists") do
    if not string.find(i, ".lua$") then
        print("Error non .lua file present in iconlists.")
        break
    end
    i = string.gsub(i, ".lua", "")
    i = string.gsub(i, "/", ".")
    M = require(i)
    parseList(M, false)
end

local function iconpicker(qIDString)
    --checks for full name of index first as requested, then falls back on finding prefix
    if (iconlist[qIDString] ~= nil) then
        return iconlist[qIDString:lower()]
    else
        local j = 0 --Just to prevent a possible infinite loop
        repeat
            j = j + 1
            local loc = nil
            local i = 0
            repeat
                i = i - 1
                loc = string.find(qIDString, "_", i)
            until (loc ~= nil) or (i == -string.len(qIDString))
            if (loc ~= nil) then
                qIDString = string.sub(qIDString, 1, loc)
                if (iconlist[qIDString:lower()] ~= nil) then
                    break
                else
                    qIDString = string.sub(qIDString, 1, loc - 1)
                end
            else
                qIDString = ""
                break
            end
        until (iconlist[qIDString:lower()] ~= nil) or (qIDString == "") or (j == 10)

        if (iconlist[qIDString:lower()] ~= nil) then
            return iconlist[qIDString:lower()]
        else
            return "Icons\\SSQN\\DEFAULT.dds" --Default in case no icon is found
        end
    end
end

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
    ui.showMessage('Quests loaded!')
end

local function initQuestMenu()
    ui.showMessage('INIT QUEST MENU')
    loadQuests()
end

local function showQuestDetail(quest)
    local qid = quest.id:lower()
    local dialogueRecord = core.dialogue.journal.records[qid]
    local dialogueRecordInfo = findDialogueWithStage(dialogueRecord.infos, quest.stage)
    local icon = iconpicker(qid)

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
                            },
                            events = {
                                mouseClick = async:callback(function()
                                    showQuestDetail(quest)
                                end)
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

local function generateQuestLayout(quest)
    local qid = quest.id:lower()
    local dialogueRecord = core.dialogue.journal.records[qid]
    local dialogueRecordInfo = findDialogueWithStage(dialogueRecord.infos, quest.stage)
    local icon = iconpicker(qid)

    if not vfs.fileExists(icon) then icon = "Icons\\SSQN\\DEFAULT.dds" end

    if dialogueRecordInfo == nil then
        dialogueRecordInfo = {
            text = "No Information Found"
        }
    end

    return {
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
                },
                events = {
                    mouseClick = async:callback(function()
                        showQuestDetail(quest)
                    end)
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
end

local function createQuestList()
    local questlist = {}

    if questDetail then
        return ui.create {
            type = ui.TYPE.Flex,
            content = ui.content(questDetail),
        }
    end

    for _, quest in pairs(quests) do
        table.insert(questlist, generateQuestLayout(quest))
    end

    return ui.create {
        type = ui.TYPE.Container,
        content = ui.content(questlist),
    }
end

-- Function to create the menu
local function createMenu()
    questMenu = ui.create {
        layer = 'Windows',
        template = I.MWUI.templates.boxTransparent,
        props = {
            position = util.vector2(10, 10),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textHeader,
                        type = ui.TYPE.Text,
                        props = {
                            text = "Quests",
                            textSize = 16,
                        },
                    },
                    createQuestList()
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

local function onQuestUpdate()
    ui.showMessage('Quest UPDATE')
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
        onQuestUpdate = onQuestUpdate,
        onKeyPress = function(key)
            if key.symbol == "x" and questMenu == nil then
                createMenu()
            elseif key.symbol == "x" and questMenu then
                questMenu:destroy()
                questMenu = nil
            end
        end,
        onMouseWheel = function(vertical, horizontal)
            ui.showMessage('MOPUSE WHEEL')
        end
    }
}
