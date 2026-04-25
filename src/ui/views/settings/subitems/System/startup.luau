--// Publish
return function(cascade, app, window, root)
    local storage = require("@modules/storage")

    local form = root:PageSection({ Title = "Startup" }):Form()

    do -- Show init greeting
        local row = form:TitledRow({
            Title = "Show init greeting",
            Subtitle = "Show the initial 'Palette loaded' notification when Comet starts.",
        })

        storage.uiFlag("ShowInitGreeting", row:Right():Toggle({
            Value = storage.getUiFlag("ShowInitGreeting", true),
        }))
    end
end
