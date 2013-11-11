fs = require "fs"
logger = require "loggy"

configRoot = process.env.HOME or process.env.USERPROFILE or process.env.HOMEPATH
configParent = configRoot + "/.config"
configPath = configParent + "/sow"


###
 * Get File Path
 *
 * Builds full path for a config file.
 * @param string The file's basename for which to build.
 * @return string Complete path to the file.
###
getFilePath = (file) ->
    configPath + "/" + file + ".json"


###
 * Create Config Path
 *
 * Ensures the directories exist for the config path.
###
createConfigPath = ->
    fs.exists configParent, (exists) ->
        if !exists
            fs.mkdir configParent, "755"

        fs.exists configPath, (exists) ->
            if !exists
                fs.mkdir configPath, "755"


###
 * Save File
 *
 * Wrapper to Node's FS module to save a file, emitting a message on failure.
 * @param  string file Base name of file to save.
 * @param  mixed  data Data to save.
 * @return boolean     True on success, false otherwise.
###
exports.save = saveFile = (file, data) ->
    saveFile = getFilePath file
    saveData = JSON.stringify data

    fs.writeFile saveFile, saveData, (err) ->
        if err
            logger.warn "There has been an error saving the " + file + " data."
            logger.log err.message
            false
        else
            logger.success file + " saved successfully to " + getFilePath file
            true


###
 * Read File
 *
 * Wrapper to Node's require to read a JSON file, parsing it.
 * @param  string file Name of file to save. Formatted to $HOME/.sow.$FILE.json.
 * @param  object|array data Data to save
 * @return boolean      True on success, false otherwise.
###
exports.read = readFile = (file) ->
    readFile = getFilePath file

    try
        data = require readFile
    catch err
        console.log err.message
        data = {}

    return data

# Run and export things
createConfigPath()
