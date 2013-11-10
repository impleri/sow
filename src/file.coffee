
String::ucfirst = ->
    this.charAt(0).toUpperCase() + this.slice(1)


###
 * Config Path
 *
 * Gets the (hopefully correct) path to the current user's $HOME directory.
 * @return string The absolute path to $HOME.
###
configPath = ->
    process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE

###
 * Save File
 *
 * Wrapper to Node's FS module to save a file, emitting a message on failure.
 * @param  string file Name of file to save. Formatted to $HOME/.sow.$FILE.json.
 * @param  object|array data Data to save
 * @return boolean      True on success, false otherwise.
###
saveFile = (file, data) ->
    saveFile = this.configPath + "/.sow." + file + ".json"
    saveData = JSON.stringify data

    fs.writeFile file, saveData, (err) ->
        if err
            console.log "There has been an error saving the " + file + " data."
            console.log err.message
            false
        else
            console.log file.ucfirst + " saved successfully."

    true

exports.save = saveFile
