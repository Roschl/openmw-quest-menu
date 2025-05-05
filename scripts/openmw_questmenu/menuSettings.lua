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
    name = 'Customization',
    description = 'You may need to refollow the quest to see changes.',
    permanentStorage = true,
    settings = {
        {
            key = 'MaxWidth',
            renderer = 'number',
            name = 'Widget Max Width',
            description = 'Sets the maximum width of the quest menu. Only updates on loading save game or restart.',
            default = 850,
        },
        {
            key = 'MaxHeight',
            renderer = 'number',
            name = 'Widget Max Height',
            description = 'Sets the maximum height of the quest menu. Only updates on loading save game or restart.',
            default = 1000,
        },
        {
            key = 'MaxIconSize',
            renderer = 'number',
            name = 'Widget Max Icon Size',
            description = 'Sets the maximum size of icons in the quest list.',
            default = 100,
        },
        {
            key = 'TextSize',
            renderer = 'number',
            name = 'Text Size',
            description = 'Sets the size of the Quest description.',
            default = 15,
        },
        {
            key = 'FIconSize',
            renderer = 'number',
            name = 'Followed Quest Icon Size',
            description = 'Sets the size of the Quest icon.',
            default = 30,
        },
        {
            key = 'FHeadlineSize',
            renderer = 'number',
            name = 'Followed Quest Name Size',
            description = 'Sets the size of the Quest name.',
            default = 14,
        },
        {
            key = 'FTextSize',
            renderer = 'number',
            name = 'Followed Text Size',
            description = 'Sets the size of the Quest description.',
            default = 12,
        },
    },
}

return
