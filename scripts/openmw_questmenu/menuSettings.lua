local I = require("openmw.interfaces")

I.Settings.registerPage {
    key = 'OpenMWQuestMenuPage',
    l10n = 'OpenMWQuestMenu',
    name = 'OpenMW Quest Menu',
    description = 'Settings for the quest menu.',
}

I.Settings.registerGroup {
    key = 'SettingsPlayerOpenMWQuestMenuControls',
    page = 'OpenMWQuestMenuPage',
    l10n = 'OpenMWQuestMenu',
    name = 'Controls',
    permanentStorage = true,
    settings = {
        {
            key = 'OpenMenu',
            renderer = 'textLine',
            name = 'Open Menu',
            description = 'Key to open menu.',
            default = 'x',
        }
    },
}

I.Settings.registerGroup {
    key = 'SettingsPlayerOpenMWQuestMenuCustomization',
    page = 'OpenMWQuestMenuPage',
    l10n = 'OpenMWQuestMenu',
    name = 'Followed Quest Customization',
    description = 'You may need to refollow the quest to see changes.',
    permanentStorage = true,
    settings = {
        {
            key = 'IconSize',
            renderer = 'number',
            name = 'Details Quest Icon Size',
            description = 'Sets the size of the Quest icon.',
            default = 30,
        },
        {
            key = 'HeadlineSize',
            renderer = 'number',
            name = 'Quest Name Size',
            description = 'Sets the size of the Quest name.',
            default = 14,
        },
        {
            key = 'TextSize',
            renderer = 'number',
            name = 'Text Size',
            description = 'Sets the size of the Quest description.',
            default = 12,
        },
    },
}

return
