local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local v2 = util.vector2

local textSize = 13.5

local function createButton(text, width, height, relativePosition, anchor, callback, highlight)
    local defaultWidth = 100
    local defaultHeight = 25

    return {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.bordersThick,
        props = {
            size = v2(width or defaultWidth, height or defaultHeight),
            anchor = anchor,
            relativePosition = relativePosition,
            visible = true,
            propagateEvents = false
        },
        content = ui.content {
            {
                template = I.MWUI.templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    anchor = v2(.5, .5),
                    relativePosition = v2(.5, .5),
                    text = text,
                    textSize = textSize + 1,
                    textColor = highlight and util.color.rgb(255, 255, 255) or nil
                }
            }
        },
        events = {
            mousePress = async:callback(callback)
        }
    }
end

return {
    createButton = createButton,
}
