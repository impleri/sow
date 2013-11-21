# File Helper
'use strict'

fs = require "fs"
logger = require "loggy"

# Define files
exports.files = files = {config: "config", aliases: "alias", history: "history"}

# Define main paths
configRoot = process.env.HOME or process.env.USERPROFILE or process.env.HOMEPATH
configParent = "{ configRoot }/.config"
configPath = "{ configParent }/sow"

###
 * Get File Path
 *
 * Builds full path for a config file.
 * @param string The file's basename for which to build.
 * @return string Complete path to the file.
###
getFilePath = (file) ->
    configPath + "/{ file }.json"


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
    toFile = getFilePath file
    saveData = JSON.stringify data

    fs.writeFile toFile, saveData, (err) ->
        if err
            logger.error "There has been an error writing { getFilePath file }"
            if config.debug
                logger.log err.message
        else
            if config.debug
                logger.success "Data saved to { getFilePath file }"

    (fs.existsSync file)

###
 * Read File
 *
 * Wrapper to Node's require to read a JSON file, parsing it.
 * @param  string file Name of file to save. Formatted to $HOME/.sow.$FILE.json.
 * @param  object|array data Data to save
 * @return boolean      True on success, false otherwise.
###
exports.read = readFile = (file) ->
    tryFile = getFilePath file

    try
        data = require tryFile
    catch err
        # Don't need to see this message under normal conditions
        if config.debug
            logger.warn err.message
        data = {}

    return data

exports.config = ->
    readFile files.config

exports.aliases = ->
    readFile files.aliases

# Check to see if we have a config
config = readFile files.config

# Run and export things
createConfigPath()
