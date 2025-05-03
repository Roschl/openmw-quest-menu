local I = require("openmw.interfaces")

I.Settings.registerPage {
    key = 'OpenMWQuestMenuPage',
    l10n = 'OpenMWQuestMenu',
    name = 'OpenMW Quest Menu',
    description = 'Settings for the quest menu.',
}

I.Settings.registerGroup {
    key = 'SettingsPlayerOpenMWQuestMenuControls',
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
        }
    },
}

return
