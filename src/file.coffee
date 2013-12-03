# Utility: file actions
'use strict'

fs = require "fs"
logger = require "loggy"
mkdirp = require "mkdirp"

# Variables within this scope
cacheType = ""
callback = (data) ->


# System paths
configRoot = process.env.HOME or process.env.USERPROFILE or process.env.HOMEPATH
configPath = "#{configRoot}/.config/sow"

# Static file names
files =
    config: "config"
    aliases: "aliases"
    history: "history"


# Dynamic file names
getResource = (type) ->
    if type is "user" or type is "people"
        "people"
    else
        "#{type}s"


# Map resource type here to Harvest API
getHarvestName = (stub) ->
    plural = getResource stub
    plural[0].toUpperCase() + plural.slice 1


# Builds full path for a config file.
getFilePath = (file) ->
    file = files[file] if files[file]?
    "#{configPath}/#{file}.json"


# Wrapper to Node's FS module to save a file, emitting a message on failure.
saveFile = (file, data) ->
    toFile = getFilePath file
    success = true

    try
        fs.writeFileSync toFile, JSON.stringify data
    catch err
        success = false
        logger.error "There has been an error writing #{toFile}"
        if config and config.debug
            logger.log err.message

    success


# Wrapper to Node's require to read a JSON file, parsing it.
readFile = (file) ->
    try
        data = require getFilePath file
    catch err
        data = {}
        # Since the file may not exist, this message may be expected
        if config and config.debug
            logger.warn err.message

    return data


# Callback from Harvest API to cache resource list
saveCache = (err, data) ->
    logger.error err if err?

    if data
        now = new Date
        file = getResource cacheType

        cache =
            generated: now.toDateString()
        cache[file] = data

        saveFile file, cache
        callback cache


# Reads a file and polls Harvest for an update if it has expired
readCache = (type, cb) ->
    # Make the passed parameters accessible for this scope
    cacheType = type
    callback = cb

    # Load the cached file (if it exists)
    cache = readFile getResource type
    generatedTime = cache.generated or 0
    generated = new Date generatedTime

    if config.debug and generatedTime > 0
            logger.log "Cache for #{type} last updated on #{generated}"

    now = new Date
    cacheLife = config.cacheLife or 7
    generated.setDate generated.getDate() + cacheLife

    # Refresh cache if needed
    if now.getTime() < generated.getTime()
        cb cache
    else
        resource = getHarvestName type
        if config.debug
            logger.log "Regenerating cache"
        # require this late so that it can get the config before being loaded
        harvest = require "./harvest"
        harvest[resource].list {}, saveCache


# Ensure the system path exists
mkdirp.sync configPath, "755"

# Try to load the config file for use here if it exists
config = readFile files.config


# Define exports
exports.path = configPath
exports.files = files
exports.resource = getResource
exports.save = saveFile
exports.read = readFile
exports.cache = readCache
exports.getHarvestName = getHarvestName


# Get user-defined config
exports.config = ->
    readFile files.config


# Get user-defined aliases
exports.aliases = ->
    readFile files.aliases


# Get user's cached activity history for the day
exports.history = ->
    data = readFile files.history
    lastGenerated = data.generated or 0
    generated = new Date lastGenerated
    now = new Date
    now.setHours 0, 0, 0, 0

    # Clear cache if needed
    if not Object.keys(data).length or now.getTime() isnt generated.getTime()
        data =
            generated: now.getTime()
            entries: {}
            chrono: []

    data

