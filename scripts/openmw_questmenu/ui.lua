local ui = require('openmw.ui')
local util = require('openmw.util')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local vfs = require('openmw.vfs')
local async = require('openmw.async')

local UIComponents = require('scripts.openmw_questmenu.uiComponents')

local v2 = util.vector2

local playerSettings = storage.playerSection('SettingsPlayerOpenMWQuestStatusMenuControls')

local questMenu = nil
local questMode = 'ACTIVE' -- ACTIVE, FINISHED, HIDDEN
local showable = nil;
local text_size = 13.5

local screenSize = ui.screenSize()
local width_ratio = 0.25
local height_ratio = 0.65
local widget_width = screenSize.x * width_ratio
local widget_height = screenSize.y * height_ratio

local icon_size = screenSize.y * 0.03
local menu_block_width = widget_width * 0.30

local createQuestMenu
local selectedQuest = nil

local questsPerPage = 3
local detailPage = 1

local function selectQuest(quest, page)
    selectedQuest = quest
    if questMenu then
        questMenu:destroy()
        questMenu = nil
        detailPage = 1
        createQuestMenu(page, I.OpenMWQuestList.getQuestList())
    end
end

local function createQuest(quest, page)
    local icon = nil
    local questLogo = nil
    if (I.SSQN) then
        icon = I.SSQN.getQIcon(quest.id)

        if not vfs.fileExists(icon) then icon = "Icons\\SSQN\\DEFAULT.dds" end

        questLogo = {
            type = ui.TYPE.Image,
            props = {
                relativePosition = v2(.5, .5),
                anchor = v2(.5, .5),
                size = v2(icon_size, icon_size),
                resource = ui.texture { path = icon },
                color = util.color.rgb(1, 1, 1)
            }
        }
    end

    local function getColor()
        if selectedQuest and selectedQuest.id == quest.id then
            return util.color.rgb(255, 255, 255)
        end

        return nil
    end

    local questNameText = {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            text = quest.name,
            textSize = screenSize.x * 0.0094,
            textColor = getColor()
        }
    }

    local emptyVBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(7, 50)
        }
    }

    local function createContent()
        if (icon ~= nil) then
            return {
                questLogo,
                emptyVBox,
                questNameText
            }
        end

        return { emptyVBox, questNameText }
    end

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
        content = ui.content(createContent()),
        events = {
            mouseClick = async:callback(function()
                selectQuest(quest, page)
            end)
        },
    }
end

local function createQuestList(quests, page)
    local questlist = {}

    if (questMode == "ACTIVE") then
        for _, quest in pairs(quests) do
            if (quest.hidden ~= true and quest.finished ~= true) then
                table.insert(questlist, quest)
            end
        end
    elseif (questMode == "HIDDEN") then
        for _, quest in pairs(quests) do
            if (quest.hidden == true) then
                table.insert(questlist, quest)
            end
        end
    elseif (questMode == "FINISHED") then
        for _, quest in pairs(quests) do
            if (quest.finished == true) then
                table.insert(questlist, quest)
            end
        end
    end

    local paginatedList = {}
    for index, quest in pairs(questlist) do
        if ((index - 1) >= ((page - 1) * questsPerPage) and (index - 1) < ((page - 1) * questsPerPage + questsPerPage)) then
            table.insert(paginatedList, createQuest(quest, page))
        end
    end

    return ui.content {
        {
            type = ui.TYPE.Flex,
            content = ui.content(paginatedList),
        }
    }
end

local function createQuestDetail()
    if selectedQuest == nil then
        return ui.content {
            {
                template = I.MWUI.templates.textNormal,
                props = {
                    anchor = v2(.5, .5),
                    relativePosition = v2(.5, .5),
                    text = "No Quest selected!",
                    textColor = util.color.rgb(255, 255, 255),
                    textSize = text_size,
                }
            }
        }
    end

    local note = selectedQuest.notes[detailPage]

    return ui.content {
        {
            template = I.MWUI.templates.textNormal,
            props = {
                text = note,
                size = v2((widget_width * 0.85), icon_size * 16),
                multiline = true,
                wordWrap = true,
                autoSize = false,
            }
        }
    }
end

createQuestMenu = function(page, quests)
    local menu_block_path = "Textures\\menu_head_block_middle.dds"
    local topButtonHeight = 23

    local filteredQuests = {}

    if (questMode == "ACTIVE") then
        for _, quest in pairs(quests) do
            if (quest.hidden ~= true and quest.finished ~= true) then
                table.insert(filteredQuests, quest)
            end
        end
    elseif (questMode == "HIDDEN") then
        for _, quest in pairs(quests) do
            if (quest.hidden == true) then
                table.insert(filteredQuests, quest)
            end
        end
    elseif (questMode == "FINISHED") then
        for _, quest in pairs(quests) do
            if (quest.finished == true) then
                table.insert(filteredQuests, quest)
            end
        end
    end

    local header = {
        type = ui.TYPE.Flex,
        props = {
            size = v2(widget_width * 2, 20),
            horizontal = true
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    anchor = v2(.5, .5),
                    size = v2(menu_block_width * 2, 20),
                    resource = ui.texture {
                        path = menu_block_path,
                        size = v2(menu_block_width * 2, 15)
                    }
                }
            },
            {
                type = ui.TYPE.Widget,
                props = {
                    size = v2(widget_width * 2 * 0.4, 20),
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
                    size = v2(menu_block_width * 2, 20),
                    resource = ui.texture {
                        path = menu_block_path,
                        size = v2(menu_block_width * 2, 15) }
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

    local questList = {
        type = ui.TYPE.Flex,
        props = {
            size = v2(widget_width * 0.85, icon_size * 16),
            horizontal = false,
            anchor = v2(0, 0),
            relativePosition = v2(0, 0)
        },
        content = createQuestList(filteredQuests, page)
    }

    local questBox = {
        type = ui.TYPE.Widget,
        props = {
            anchor = v2(.25, .5),
            relativePosition = v2(.25, .5),
            size = v2(widget_width * 0.85, icon_size * 16)
        },
        content = ui.content({ questList })
    }

    local questDetailBox = {
        type = ui.TYPE.Widget,
        props = {
            anchor = v2(1, .5),
            relativePosition = v2(1, .5),
            size = v2(widget_width * 0.85, icon_size * 16)
        },
        content = createQuestDetail()
    }

    local function createListNavigation(direction, relativePosition, anchor)
        local text = direction == "+" and "Next" or "Back"
        local nextPage = direction == "+" and (page + 1) or (page - 1)

        if ((direction == "-" and nextPage < 1) or (direction == "+" and nextPage > math.ceil(#filteredQuests / questsPerPage))) then
            return {}
        end

        return UIComponents.createButton(text, 80, topButtonHeight, relativePosition, anchor,
            function()
                if questMenu then
                    questMenu:destroy()
                    questMenu = nil
                    createQuestMenu(nextPage, filteredQuests)
                end
            end)
    end

    local function createDetailNavigation(direction, relativePosition, anchor)
        if (selectedQuest == nil) then
            return {}
        end

        local text = direction == "+" and "Next" or "Back"
        local nextPage = direction == "+" and (detailPage + 1) or (detailPage - 1)

        if ((direction == "-" and nextPage < 1) or (direction == "+" and nextPage > #selectedQuest.notes)) then
            return {}
        end

        return UIComponents.createButton(text, 80, topButtonHeight, relativePosition, anchor,
            function()
                if questMenu then
                    questMenu:destroy()
                    questMenu = nil
                    detailPage = nextPage
                    createQuestMenu(page, filteredQuests)
                end
            end)
    end

    local function createPageText()
        return tostring(page) .. " / " .. tostring(math.ceil(#filteredQuests / questsPerPage))
    end

    local pageText = {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            text = createPageText(),
            textSize = text_size + 4
        }
    }

    local function createDetailPageText()
        if (selectedQuest == nil) then
            return tostring(detailPage);
        end

        return tostring(detailPage) .. " / " .. tostring(#selectedQuest.notes)
    end

    local detailPageText = {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            text = createDetailPageText(),
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
        content = ui.content({
            createListNavigation("-", v2(0, .5), v2(0, .5)),
            pageText,
            createListNavigation("+", v2(1, .5), v2(1, .5))
        })
    }

    local buttonsBoxDetails = {
        type = ui.TYPE.Widget,
        props = {
            name = "buttonsBox",
            anchor = v2(.5, .5),
            relativePosition = v2(.5, .5),
            size = v2(widget_width * 0.65, 30)
        },
        content = ui.content({
            createDetailNavigation("-", v2(0, .5), v2(0, .5)),
            detailPageText,
            createDetailNavigation("+", v2(1, .5), v2(1, .5))
        })
    }

    local buttonHidden = UIComponents.createButton("Hidden", 100, topButtonHeight, nil, v2(0, .5), function()
        if questMenu then
            questMenu:destroy()
            questMenu = nil
            selectedQuest = nil
            questMode = "HIDDEN"
            createQuestMenu(1, I.OpenMWQuestList.getQuestList())
        end
    end, questMode == "HIDDEN")

    local buttonFinished = UIComponents.createButton("Finished", 100, topButtonHeight, nil, v2(0, .5), function()
        if questMenu then
            questMenu:destroy()
            questMenu = nil
            selectedQuest = nil
            questMode = "FINISHED"
            createQuestMenu(1, I.OpenMWQuestList.getQuestList())
        end
    end, questMode == "FINISHED")

    local buttonActive = UIComponents.createButton("Active", 100, topButtonHeight, nil, v2(0, .5), function()
        if questMenu then
            questMenu:destroy()
            questMenu = nil
            selectedQuest = nil
            questMode = "ACTIVE"
            createQuestMenu(1, I.OpenMWQuestList.getQuestList())
        end
    end, questMode == "ACTIVE")

    local function createButtonHide()
        if (not selectedQuest or questMode == "FINISHED") then
            return {}
        end

        local text = selectedQuest.hidden and "Show" or "Hide"

        return UIComponents.createButton(text, 100, topButtonHeight, nil, v2(0, .5), function()
            if questMenu and selectedQuest then
                questMenu:destroy()
                questMenu = nil
                I.OpenMWQuestList.toggleQuest(selectedQuest.id)
                selectedQuest = nil
                createQuestMenu(page, I.OpenMWQuestList.getQuestList())
            end
        end)
    end

    local buttonTopGap = {
        type = ui.TYPE.Widget,
        props = {
            anchor = v2(0, .5),
            size = v2(10, 30)
        }
    }

    local mainWindow = {
        type = ui.TYPE.Container,
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            name = "mainWindow",
            relativePosition = v2(.25, .5),
            anchor = v2(.25, .5),
            propagateEvents = false
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    name = "mainWindowFlex",
                    size = v2(widget_width * 2, widget_height),
                    autoSize = false,
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center
                },
                content = ui.content {
                    header,
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            align = ui.ALIGNMENT.Start,
                            arrange = ui.ALIGNMENT.Center
                        },
                        content = ui.content {
                            UIComponents.createBox(widget_width, widget_height - 20, ui.content {
                                emptyHBox,
                                UIComponents.createButtonGroup(widget_width * 0.85, ui.content({
                                    buttonActive,
                                    buttonTopGap,
                                    buttonFinished,
                                    buttonTopGap,
                                    buttonHidden
                                })),
                                UIComponents.createHorizontalLine(widget_width * 0.85),
                                emptyHBox,
                                questBox,
                                UIComponents.createHorizontalLine(widget_width * 0.85),
                                emptyHBox,
                                buttonsBox
                            }),
                            UIComponents.createBox(widget_width, widget_height - 20, ui.content {
                                emptyHBox,
                                UIComponents.createButtonGroup(widget_width * 0.85, ui.content({
                                    createButtonHide()
                                })),
                                UIComponents.createHorizontalLine(widget_width * 0.85),
                                emptyHBox,
                                questDetailBox,
                                UIComponents.createHorizontalLine(widget_width * 0.85),
                                emptyHBox,
                                buttonsBoxDetails
                            })
                        }
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
            createQuestMenu(1, I.OpenMWQuestList.getQuestList())
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
