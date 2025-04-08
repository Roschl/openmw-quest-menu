local self = require("openmw.self")
local ui = require('openmw.ui')
local util = require('openmw.util')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local types = require("openmw.types")
local async = require('openmw.async')
local vfs = require('openmw.vfs')
local core = require("openmw.core")

local v2 = util.vector2

local playerSettings = storage.playerSection('SettingsPlayerOpenMWQuestStatusMenuControls')

local questMenu = nil
local questMode = 'ACTIVE' -- ACTIVE, FINISHED
local showable = nil;
local hiddenQuests = {}
local text_size = 13.5

local screenSize = ui.screenSize()
local width_ratio = 0.25
local height_ratio = 0.65
local widget_width = screenSize.x * width_ratio
local widget_height = screenSize.y * height_ratio

local icon_size = screenSize.y * 0.03
local menu_block_width = widget_width * 0.30

local function hasValue(tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function getQuests()
    return types.Player.quests(self)
end

local function createQuest(quest)
    local qid = quest.id:lower()
    local icon = I.SSQN.getQIcon(qid)
    local dialogueRecord = core.dialogue.journal.records[qid];

    if not vfs.fileExists(icon) then icon = "Icons\\SSQN\\DEFAULT.dds" end

    if dialogueRecord == nil then
        dialogueRecord = {
            questName = "Unknown"
        }
    end

    local questLogo = {
        type = ui.TYPE.Image,
        props = {
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5),
            size = v2(icon_size, icon_size),
            resource = ui.texture { path = icon },
            color = util.color.rgb(1, 1, 1)
        }
    }

    local questNameText = {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            text = dialogueRecord.questName,
            textSize = screenSize.x * 0.0094
        }
    }

    local emptyVBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(7, 50)
        }
    }

    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            relativePosition = v2(0, 0),
            align = ui.ALIGNMENT.Start,
            arrange = ui.ALIGNMENT.Center
        },
        external = {
            stretch = 1,
            grow = 1
        },
        content = ui.content {
            questLogo,
            emptyVBox,
            questNameText
        }
    }
end

local function createQuestList(quests)
    local questlist = {}

    for _, quest in pairs(quests) do
        if (questMode == "ACTIVE" and not hasValue(hiddenQuests, quest.id) and quest.finished ~= true)
            or (questMode == "FINISHED" and quest.finished == true) then
            table.insert(questlist, createQuest(quest))
        end
    end

    return ui.content {
        {
            type = ui.TYPE.Flex,
            content = ui.content(questlist),
        }
    }
end

local function createQuestMenu(quests)
    local menu_block_path = "Textures\\menu_head_block_middle.dds"
    local topButtonHeight = 23

    local header = {
        type = ui.TYPE.Flex,
        props = {
            size = v2(widget_width, 20),
            horizontal = true
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    anchor = v2(.5, .5),
                    size = v2(menu_block_width, 20),
                    resource = ui.texture {
                        path = menu_block_path,
                        size = v2(menu_block_width, 15)
                    }
                }
            },
            {
                type = ui.TYPE.Widget,
                props = {
                    size = v2(widget_width * 0.4, 20),
                    anchor = v2(.5, .5)
                },
                content = ui.content { {
                    template = I.MWUI.templates.textNormal,
                    type = ui.TYPE.Text,
                    props = {
                        anchor = v2(.5, .5),
                        relativePosition = v2(.5, .5),
                        text = "Quest Menu",
                        textColor = util.color.rgb(255, 255, 255),
                        textSize = text_size,
                    }
                } }
            },
            {
                type = ui.TYPE.Image,
                props = {
                    anchor = v2(.5, .5),
                    size = v2(menu_block_width, 20),
                    resource = ui.texture {
                        path = menu_block_path,
                        size = v2(menu_block_width, 15) }
                }
            }
        }
    }

    local emptyHBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(300, 6)
        }
    }

    local emptyVBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(7, 80)
        }
    }

    local questList = {
        type = ui.TYPE.Flex,
        props = {
            size = v2(widget_width * 0.85, icon_size * 16),
            horizontal = false,
            anchor = v2(0, 0),
            relativePosition = v2(0, 0)
        },
        content = createQuestList(quests)
    }

    local questBox = {
        type = ui.TYPE.Widget,
        props = {
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            size = v2(widget_width * 0.85, icon_size * 16)
        },
        content = ui.content({ questList })
    }

    local buttonBack = {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.bordersThick,
        props = {
            name = "buttonBack",
            anchor = v2(0, .5),
            relativePosition = v2(0, .5),
            size = v2(80, topButtonHeight),
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
                    text = "Back",
                    textSize = text_size + 1,
                }
            }
        },
        events = {
            mousePress = async:callback(function(button)
            end)
        }
    }

    local buttonForward = {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.bordersThick,
        props = {
            anchor = v2(1, .5),
            relativePosition = v2(1, .5),
            size = v2(80, topButtonHeight),
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
                    text = "Next",
                    textSize = text_size + 1,
                }
            }
        },
        events = {
            mousePress = async:callback(function(button)

            end)
        }
    }

    local pageText = {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            text = "TEXT PAGE",
            textSize = text_size + 4
        }
    }

    local buttonsBox = {
        type = ui.TYPE.Widget,
        props = {
            name = "buttonsBox",
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            size = v2(widget_width * 0.65, 30)
        },
        content = ui.content(
            { buttonBack, pageText, buttonForward }
        )
    }

    local buttonHidden = {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.bordersThick,
        props = {
            name = "buttonAll",
            anchor = v2(0, .5),
            size = v2(100, topButtonHeight),
            visible = true
        },
        content = ui.content {
            {
                template = I.MWUI.templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    anchor = v2(.5, .5),
                    relativePosition = v2(.5, .5),
                    text = "Hidden",
                    textSize = text_size + 1
                }
            }
        },
        events = {
            mousePress = async:callback(function(button)
            end)
        }
    }

    local buttonFinished = {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.bordersThick,
        props = {
            anchor = v2(0, .5),
            size = v2(100, topButtonHeight),
            visible = true
        },
        content = ui.content {
            {
                template = I.MWUI.templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    anchor = v2(.5, .5),
                    relativePosition = v2(.5, .5),
                    text = "Finished",
                    textSize = text_size + 1,
                    textColor = questMode == "FINISHED" and util.color.rgb(255, 255, 255) or nil
                }
            }
        },
        events = {
            mousePress = async:callback(function()
                if questMenu then
                    questMenu:destroy()
                    questMenu = nil
                    questMode = "FINISHED"
                    createQuestMenu(getQuests())
                end
            end)
        }
    }

    local buttonActive = {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.bordersThick,
        props = {
            anchor = v2(0, .5),
            size = v2(100, topButtonHeight),
            visible = true
        },
        content = ui.content {
            {
                template = I.MWUI.templates.textNormal,
                type = ui.TYPE.Text,
                props = {
                    anchor = v2(.5, .5),
                    relativePosition = v2(.5, .5),
                    text = "Active",
                    textSize = text_size + 1,
                    textColor = questMode == "ACTIVE" and util.color.rgb(255, 255, 255) or nil
                }
            }
        },
        events = {
            mousePress = async:callback(function()
                if questMenu then
                    questMenu:destroy()
                    questMenu = nil
                    questMode = "ACTIVE"
                    createQuestMenu(getQuests())
                end
            end)
        }
    }

    local buttonTopGap = {
        type = ui.TYPE.Widget,
        props = {
            anchor = v2(0, .5),
            size = v2(10, 30)
        }
    }

    local topButtonsFlex = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
        },
        content = ui.content({
            buttonActive,
            buttonTopGap,
            buttonFinished,
            buttonTopGap,
            buttonHidden })
    }

    local topButtonsBox = {
        type = ui.TYPE.Widget,
        props = {
            name = "topButtonsBox",
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            size = v2(widget_width * 0.85, 30)
        },
        content = ui.content(
            { topButtonsFlex }
        )
    }

    local horizontalLine = {
        type = ui.TYPE.Image,
        template = I.MWUI.templates.horizontalLine,
        props = {
            size = v2(widget_width * 0.85, 2)
        }
    }

    local pluginBox = ui.content {
        {
            type = ui.TYPE.Widget,
            template = I.MWUI.templates.borders,
            props = {
                name = "pluginBox",
                anchor = v2(.5, .5),
                relativePosition = v2(.5, .5),
                size = v2(widget_width * 0.93, (widget_height) * 0.93)
            },
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    props = {
                        anchor = v2(.5, .5),
                        relativePosition = v2(.5, .5),
                        name = "pluginBoxFlex",
                        horizontal = false,
                        align = ui.ALIGNMENT.Start,
                        arrange = ui.ALIGNMENT.Center
                    },
                    external = {
                        stretch = 0.4
                    },
                    content = ui.content {
                        emptyHBox,
                        topButtonsBox,
                        horizontalLine,
                        emptyHBox,
                        questBox,
                        horizontalLine,
                        emptyHBox,
                        buttonsBox
                    }
                }
            }
        }
    }

    local pluginBoxPadding = ui.content {
        {
            type = ui.TYPE.Widget,
            props = {
                name = "pluginBoxPadding",
                anchor = v2(.5, .5),
                relativePosition = v2(.5, .5),
                size = v2(widget_width, (widget_height - 10))
            },
            content = pluginBox
        }
    }

    local mainWindow = {
        type = ui.TYPE.Container,
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            name = "mainWindow",
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5),
            propagateEvents = false
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    name = "mainWindowFlex",
                    size = v2(widget_width, widget_height),
                    autoSize = false,
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center
                },
                content = ui.content {
                    header,
                    {
                        name = "mainWindowWidget",
                        type = ui.TYPE.Widget,
                        template = I.MWUI.templates.bordersThick,
                        props = {
                            size = v2(widget_width, widget_height - 20)
                        },
                        content = pluginBoxPadding
                    }
                }
            }
        }
    }

    questMenu = ui.create(mainWindow)
end

local function onKeyPress(key)
    if key.symbol == playerSettings:get('OpenMenuNew') then
        if questMenu == nil then
            I.UI.setMode('Interface', { windows = {} })
            createQuestMenu(getQuests())
        else
            I.UI.removeMode('Interface')
            questMenu:destroy()
            questMenu = nil;
        end
    end

    if key.code == input.KEY.Escape and questMenu then
        I.UI.removeMode('Interface')
        questMenu:destroy()
        questMenu = nil;
    end
end

local function onInputAction(id)
    if showable == true then
        if questMenu and id == input.ACTION.Inventory then
            questMenu:destroy()
            questMenu = nil;
        end

        if questMenu and id == input.ACTION.Journal then
            questMenu:destroy()
            questMenu = nil;
            I.UI.removeMode('Interface')
        end
    end
end

return {
    engineHandlers = {
        onKeyPress = onKeyPress,
        onInputAction = onInputAction
    }
}
