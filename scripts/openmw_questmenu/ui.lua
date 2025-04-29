local ui = require('openmw.ui')
local util = require('openmw.util')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local vfs = require('openmw.vfs')

local UIComponents = require('scripts.openmw_questmenu.uiComponents')

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

local function createQuest(quest)
    local icon = I.SSQN.getQIcon(quest.id)

    if not vfs.fileExists(icon) then icon = "Icons\\SSQN\\DEFAULT.dds" end

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
            text = quest.name,
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

local function createQuestMenu(page, quests)
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

    local buttonBack = UIComponents.createButton("Back", 80, topButtonHeight, v2(0, .5), v2(0, .5), function()
        if questMenu and page > 0 then
            questMenu:destroy()
            questMenu = nil
            createQuestMenu(page - 1, quests)
        end
    end)

    local buttonForward = UIComponents.createButton("Next", 80, topButtonHeight, v2(1, .5), v2(1, .5), function()
        if questMenu then
            questMenu:destroy()
            questMenu = nil
            createQuestMenu(page + 1, quests)
        end
    end)

    local pageText = {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            text = tostring(page),
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

    local buttonHidden = UIComponents.createButton("Hidden", 100, topButtonHeight, nil, v2(0, .5), function()
    end)

    local buttonFinished = UIComponents.createButton("Finished", 100, topButtonHeight, nil, v2(0, .5), function()
        if questMenu then
            questMenu:destroy()
            questMenu = nil
            questMode = "FINISHED"
            createQuestMenu(page, I.OpenMWQuestList.getQuestList())
        end
    end, questMode == "FINISHED")

    local buttonActive = UIComponents.createButton("Active", 100, topButtonHeight, nil, v2(0, .5), function()
        if questMenu then
            questMenu:destroy()
            questMenu = nil
            questMode = "ACTIVE"
            createQuestMenu(0, I.OpenMWQuestList.getQuestList())
        end
    end, questMode == "ACTIVE")

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
            createQuestMenu(0, I.OpenMWQuestList.getQuestList())
        else
            I.UI.removeMode('Interface')
            questMenu:destroy()
            questMenu = nil;
        end
    end

    if key.code == input.KEY.M then
        print('amount of quests:' .. #I.OpenMWQuestList.getQuestList())
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
