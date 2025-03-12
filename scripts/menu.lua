local self = require("openmw.self")
local ui = require("openmw.ui")
local util = require("openmw.util")
local I = require('openmw.interfaces')
local async = require('openmw.async')
local types = require("openmw.types")
local core = require("openmw.core")

local quests = {}
local questMenu = nil

local function loadQuests()
    quests = types.Player.quests(self)
    ui.showMessage('Quests loaded!')
end

local function initQuestMenu()
    ui.showMessage('INIT QUEST MENU')
    loadQuests()
end

local function createQuestList()
    local questlist = {}

    for _, quest in pairs(quests) do
        local qid = quest.id:lower()
        table.insert(questlist, {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true
            },
            content = ui.content {
                {
                    type = ui.TYPE.Text,
                    props = {
                        text = core.dialogue.journal.records[qid].questName,
                        textColor = util.color.rgb(1, 1, 1),
                        textSize = 14,
                    },
                },
                {
                    type = ui.TYPE.Text,
                    props = {
                        text = qid,
                        textColor = util.color.rgb(0.5, 0.5, 0.5),
                        textSize = 12,
                    },
                },
                {
                    type = ui.TYPE.Text,
                    props = {
                        text = "Stage: " .. quest.stage,
                        textColor = util.color.rgb(0.5, 0.5, 0.5),
                        textSize = 12,
                    },
                },
            }
        })
    end

    return ui.create {
        type = ui.TYPE.Flex,
        content = ui.content(questlist),
    }
end

local function createButton(text, callback)
    local buttonText = {
        {
            template = I.MWUI.templates.textNormal,
            props = {
                text = text,
                textSize = 12
            }
        }
    }

    return ui.create {
        type = ui.TYPE.Container,
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content(buttonText)
            }
        },
        events = {
            mouseClick = async:callback(callback)
        }
    }
end

-- Function to create the menu
local function createMenu()
    questMenu = ui.create {
        layer = 'Windows',
        type = ui.TYPE.Container,
        template = I.MWUI.templates.boxTransparent,
        props = {
            position = util.vector2(10, 10),
            size = util.vector2(500, 800),
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
                    createQuestList(),
                    createButton('Refresh', function()
                        ui.showMessage('You have pressed "Button"')
                        loadQuests()
                    end)
                }
            }
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
        end
    }
}
