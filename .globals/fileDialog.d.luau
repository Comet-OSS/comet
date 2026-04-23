--- @field extensions {string} -- File extensions without dots (e.g. {"json", "cfg"})
type filter = {
    extensions: {string},
}

--- @field title string? -- Dialog window title
--- @field defaultPath string? -- Directory the dialog opens in
type dialogOptions = {
    title: string?,
    defaultPath: string?,
}

--- @field filter filter? -- Restricts selectable file types
type fileDialogOptions = dialogOptions & {
    filter: filter?,
}

--- @field suggestedName string? -- Pre-filled filename in the dialog's name field
--- @field defaultExtension string? -- Appended automatically if no extension was given (e.g. "json")
type saveDialogOptions = fileDialogOptions & {
    suggestedName: string?,
    defaultExtension: string?,
}

--- Shared item functions
type item = {
    GetName: (self: item) -> string,
    IsFile: (self: item) -> boolean,
    IsFolder: (self: item) -> boolean,
    Delete: (self: item) -> (),
}

--- A file returned from a dialog.
type file = item & {
    Read: (self: file) -> string,
    Write: (self: file, content: string) -> (),
    Append: (self: file, content: string) -> (),
}

--- A folder returned from a dialog.
type folder = item & {
    List: (self: folder, recursive: boolean?) -> {dialogItem},
    MakeFolder: (self: folder, name: string) -> folder,
}

--- An item returned from a dialog.
type dialogItem = file | folder

--- Opens a dialog to select a file.
--- Blocks the calling thread until the dialog is dismissed.
--- @param options fileDialogOptions?
--- @return file? -- File object, or nil if the user cancelled
declare function openfiledialog(options: fileDialogOptions?): file?

--- Opens a dialog to select multiple files.
--- Blocks the calling thread until the dialog is dismissed.
--- @param options fileDialogOptions?
--- @return {file}? -- Array of file objects, or nil if the user cancelled
declare function openfilesdialog(options: fileDialogOptions?): {file}?

--- Opens a dialog to select a folder.
--- Blocks the calling thread until the dialog is dismissed.
--- @param options dialogOptions?
--- @return folder? -- Folder object, or nil if the user cancelled
declare function openfolderdialog(options: dialogOptions?): folder?

--- Opens a dialog to choose a path to save to, then writes content to that path.
--- Blocks the calling thread until the dialog is dismissed.
--- @param content string -- Content to write to the file
--- @param options saveDialogOptions?
--- @return file? -- File object of the saved file, or nil if the user cancelled
declare function savefiledialog(content: string, options: saveDialogOptions?): file?