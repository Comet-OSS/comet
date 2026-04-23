--// Imports
local keybinds = require("@config/keybinds")

--// Variables
local keybindsMeta = keybinds._META

--// Publish
return function(cascade, app, window, root)
    if not keybindsMeta then
        return
    end

    for sectionName, sectionMeta in pairs(keybindsMeta) do
        local page = root:PageSection({
            Title = sectionName,
            Subtitle = sectionMeta._Subtitle,
        })

        local formCount = 0
        for k, v in pairs(sectionMeta) do
            if type(k) == "number" then
                formCount = math.max(formCount, k)
            end
        end

        for i = 1, formCount do
            local form = page:Form()
            local entries = sectionMeta[i]
            if entries then
                for title, subtitle in pairs(entries) do
                    local row = form:TitledRow({
                        Title = title,
                        Subtitle = subtitle,
                    })

                    local bindTable = keybinds[sectionName]
                    local bindValue = bindTable and bindTable[title]
                    if bindValue then
                        row:Right():KeystrokeField({
                            Keys = bindValue,
                            ValueChanged = function(self, newKeys)
                                bindValue.Value = newKeys
                            end,
                        })
                    end
                end
            end
        end
    end
end
