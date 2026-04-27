--// Publish
return function(cascade, app, window, root)
    local storage = require("@modules/storage")

    local form = root:PageSection({ Title = "Startup" }):Form()

    do -- Show init greeting
        local row = form:TitledRow({
            Title = "Initialization notification",
            Subtitle = "Shows a notification when Comet has finished setting up",
        })

        storage.uiFlag("InitializationNotification", row:Right():Toggle({
            Value = true,
        }))
    end
end
