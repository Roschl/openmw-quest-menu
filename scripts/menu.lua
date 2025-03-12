local ui = require("openmw.ui")
local util = require("openmw.util")
local I = require('openmw.interfaces')
local async = require('openmw.async')

local questMenu = nil

local function createButton(text, callback)
    return ui.create {
        type = ui.TYPE.Container,
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textNormal,
                        props = { text = text }
                    }
                }
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
                    createButton('Button', function()
                        ui.showMessage('You have pressed "Button"')
                    end)
                }
            }
        }
    }
end

return {
    engineHandlers = {
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
