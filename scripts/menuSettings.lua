local I = require("openmw.interfaces")

I.Settings.registerPage {
    key = 'OpenMWQuestStatusMenuPage',
    l10n = 'OpenMWQuestStatusMenu',
    name = 'OpenMW Quest Status Menu',
    description = 'Settings for the quest status menu.',
}

I.Settings.registerGroup {
    key = 'SettingsPlayerOpenMWQuestStatusMenuControls',
    page = 'OpenMWQuestStatusMenuPage',
    l10n = 'OpenMWQuestStatusMenu',
    name = 'Controls',
    permanentStorage = true,
    settings = {
        {
            key = 'OpenMenu',
            renderer = 'textLine',
            name = 'Open Menu',
            description = 'Key to open menu.',
            default = 'x',
        },
    },
}

I.Settings.registerGroup {
    key = 'SettingsPlayerOpenMWQuestStatusMenuCustomization',
    page = 'OpenMWQuestStatusMenuPage',
    l10n = 'OpenMWQuestStatusMenu',
    name = 'Customization',
    permanentStorage = true,
    settings = {
        {
            key = 'HeadlineSize',
            renderer = 'number',
            name = 'Quest Name Size',
            description = 'Sets the size of the Quest names.',
            default = 14,
        },
        {
            key = 'TextSize',
            renderer = 'number',
            name = 'Text Size',
            description = 'Sets the size of the Quest description and "back" button.',
            default = 12,
        },
    },
}

return
