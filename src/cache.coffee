# Small module to search Harvest resources for something
'use strict'

file = require "./file"
harvest = require "./harvest"
logger = require "loggy"
colors = require "colors"
config = file.config()
fileType = ""
callback = ->
processed = false

# Callback from Harvest API
processList = (err, data) ->
    if err
        logger.error err
    else if data and not processed
        type = fileType
        fileName = file.resource type
        now = new Date
        if config.debug
            logger.log "Saving cache for #{ type }"
        cache = {}
        cache.generated = now.toDateString()
        cache[fileName] = data
        file.save fileName, cache
        processed = true
        callback err, cache

# Show the logged time for a day, defaulting to today
module.exports = checkCache = (type, cb) ->
    callback = cb
    fileType = type
    if config.debug
        logger.log "Loading cache for #{ type }"

    cache = file.read file.resource type
    lastGenerated = cache.generated or 0
    cacheLife = config.cacheLife or 7
    generated = new Date lastGenerated
    now = new Date
    generated.setDate generated.getDate() + cacheLife
    generated.setHours 0, 0, 0, 0
    now.setHours 0, 0, 0, 0

    if config.debug
            logger.log "Data cached on #{ generated.toDateString() }"

    # Refresh cache if needed
    if now.getTime() <= generated.getTime()
        callback {}, cache
    else
        resource = harvest.getResourceName type
        if config.debug
            logger.log "Regenerating cache for #{ type }"
        harvest[resource].list {}, processList
