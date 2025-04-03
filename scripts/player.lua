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
local disabledQuests = {}
local questMenu = nil

local currentView = "list" -- Can be "list" or "detail"
local selectedQuest = nil

local mode = "Enabled" -- Can be "Disabled" or "Enabled"
local showFinished = false

local renderMenu
local setView = function(view, quest)
    currentView = view
    selectedQuest = quest or nil
    renderMenu()
end

local playerControlSettings = storage.playerSection('SettingsPlayerOpenMWQuestStatusMenuControls')
local playerCustomizationSettings = storage.playerSection('SettingsPlayerOpenMWQuestStatusMenuCustomization')

local function hasValue(tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function removeValue(tab, val)
    local newList = {};
    for _, value in ipairs(tab) do
        if value ~= val then
            table.insert(newList, value)
        end
    end

    disabledQuests = newList
end

local function renderButton(text, onClick)
    return {
        template = I.MWUI.templates.boxTransparent,
        content = ui.content {
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text = text,
                    textColor = util.color.hex("cccccc"),
                    textSize = playerCustomizationSettings:get('ButtonSize')
                },
                events = {
                    mouseClick = onClick
                }
            } }
    }
end

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
    local isDisabled = hasValue(disabledQuests, qid)

    if not vfs.fileExists(icon) then icon = "Icons\\SSQN\\DEFAULT.dds" end

    if dialogueRecordInfo == nil then
        dialogueRecordInfo = {
            text = "No Information Found"
        }
    end

    if (questMenu) then
        return {
            type = ui.TYPE.Flex,
            content = ui.content {
                {
                    template = I.MWUI.templates.boxTransparent,
                    props = {
                        position = util.vector2(10, 10),
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
                                        size = util.vector2(playerCustomizationSettings:get('IconSize'), playerCustomizationSettings:get('IconSize')),
                                        resource = ui.texture { path = icon },
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
                                                        textSize = playerCustomizationSettings:get('HeadlineSize'),
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
                                                textSize = playerCustomizationSettings:get('TextSize'),
                                            },
                                        }
                                    }
                                }
                            }
                        }
                    }
                },
                {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true
                    },
                    content = ui.content {
                        renderButton("Back", async:callback(function()
                            setView("list")
                        end)),
                        renderButton(isDisabled == true and "Enable" or "Disable", async:callback(function()
                            if (isDisabled) then
                                removeValue(disabledQuests, qid)
                                setView("detail", quest)
                            else
                                table.insert(disabledQuests, qid)
                                setView("detail", quest)
                            end
                        end))
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
            size = util.vector2(playerCustomizationSettings:get('IconSizeList'),
                playerCustomizationSettings:get('IconSizeList')),
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
        if mode == "Disabled" then
            if quest.finished == showFinished and hasValue(disabledQuests, quest.id) then
                table.insert(questlist, questListItem(quest))
            end
        else
            if quest.finished == showFinished and not hasValue(disabledQuests, quest.id) then
                table.insert(questlist, questListItem(quest))
            end
        end
    end

    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true
        },
        content = ui.content(questlist),
    }
end

local function header()
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.textHeader,
                type = ui.TYPE.Text,
                props = {
                    text = "Quests",
                    textSize = playerCustomizationSettings:get('TextSize')
                },
            },
        }
    }
end

renderMenu = function()
    local content = {}

    if currentView == "list" then
        table.insert(content, {
            template = I.MWUI.templates.boxTransparent,
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    content = ui.content {
                        header(),
                        questList()
                    }
                }
            }
        })
        table.insert(content, {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true
            },
            content = ui.content {
                renderButton(showFinished and "Finished" or "Active", async:callback(function()
                    showFinished = not showFinished
                    setView("list")
                end)),
                renderButton(mode, async:callback(function()
                    if (mode == "Enabled") then
                        mode = "Disabled"
                    else
                        mode = "Enabled"
                    end
                    setView("list")
                end)),
            }
        })
    elseif currentView == "detail" and selectedQuest then
        table.insert(content, showQuestDetail(selectedQuest))
    else
        table.insert(content, {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text = "THERE IS NO INFORMATION",
                textSize = playerCustomizationSettings:get('TextSize')
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
                props = {
                    relativeSize = util.vector2(.5, .5)
                },
                content = ui.content(content)
            }
        }
    }
end

local function onQuestUpdate()
    loadQuests();

    if (questMenu and currentView == "detail" and selectedQuest) then
        setView("detail", selectedQuest)
    elseif (questMenu and currentView == "list") then
        setView("list");
        return;
    end
end

local function onSave()
    return {
        disabledQuests = disabledQuests,
    }
end

local function onLoad(data)
    loadQuests()

    if not data or not data.disabledQuests then
        disabledQuests = {}
        return
    end

    disabledQuests = data.disabledQuests
end

return {
    engineHandlers = {
        onInit = loadQuests,
        onSave = onSave,
        onLoad = onLoad,
        onQuestUpdate = onQuestUpdate,
        onKeyPress = function(key)
            if key.symbol == playerControlSettings:get('OpenMenu') and questMenu == nil then
                renderMenu()
            elseif key.symbol == playerControlSettings:get('OpenMenu') and questMenu then
                questMenu:destroy()
                questMenu = nil
                selectedQuest = nil
                currentView = "list"
            end
        end
    }
}
