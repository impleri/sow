# File actions
'use strict'

fs = require "fs"
logger = require "loggy"
mkdirp = require "mkdirp"

# Define main paths
configRoot = process.env.HOME or process.env.USERPROFILE or process.env.HOMEPATH
configPath = "#{configRoot}/.config/sow"

# Define files
exports.files = files =
    config: "config"
    aliases: "aliases"
    history: "history"

# Builds full path for a config file.
getFilePath = (file) ->
    configPath + "/#{file}.json"


# Wrapper to Node's FS module to save a file, emitting a message on failure.
exports.save = saveFile = (file, data) ->
    toFile = getFilePath file

    fs.writeFile toFile, JSON.stringify(data), (err) ->
        if err
            logger.error "There has been an error writing #{getFilePath file}"
            if config.debug
                logger.log err.message
        else
            if config.debug
                logger.success "Data saved to #{getFilePath file}"

    (fs.existsSync file)


# Wrapper to Node's require to read a JSON file, parsing it.
exports.read = readFile = (file) ->
    tryFile = getFilePath file

    try
        data = require tryFile
    catch err
        # Don't need to see this message under normal conditions
        if config and config.debug
            logger.warn err.message
        data = {}

    return data


# Get user config
exports.config = ->
    readFile files.config


# Get user's aliases
exports.aliases = ->
    readFile files.aliases


# Get user's cached activity history
exports.history = ->
    data = readFile files.history
    lastGenerated = data.generated or 0
    generated = new Date lastGenerated
    now = new Date
    now.setHours 0, 0, 0, 0

    # Refresh cache if needed
    if not Object.keys(data).length or now.getTime() isnt generated.getTime()
        data =
            generated: now.getTime()
            entries: {}
            chrono: []
    data


# Helper function to build resource file name
exports.resource = (type) ->
    "#{ type }s"


# Check to see if we have a config
config = readFile files.config

# Run and export things
mkdirp.sync configPath, "755"
