# Small module to search Harvest resources for something
'use strict'

file = require "./file"
harvest = require "./harvest"
logger = require "loggy"
colors = require "colors"
step = require "step"
config = file.config()

# Show the logged time for a day, defaulting to today
module.exports = checkCache = (type = "project") ->
    if config.debug
        logger.log "Loading cache for " + type

    fileName = type + "s"
    cache = file.read fileName
    if config.debug
        logger.log "Cache", cache
    lastGenerated = cache.generated || 0
    cacheLife = config.cacheLife || 7
    generated = new Date lastGenerated
    now = new Date
    generated.setDate generated.getDate() + cacheLife
    generated.setHours 0, 0, 0, 0
    now.setHours 0, 0, 0, 0

    if config.debug
            logger.log "Cache dates", now, generated

    # Refresh cache if needed
    if now.getTime() > generated.getTime()
        if config.debug
            logger.log "Regenerating cache for " + type

            resource = fileName[0].toUpperCase() + fileName.slice 1
            harvest[resource].list {debug: true}, (err, data) ->
                if config.debug
                    logger.log "Response", err, data
                if not err and data
                    cache = {}
                    cache.generated = now.toDateString()
                    cache[type] = data
                    file.save fileName, cache

    # Return the cache
    cache
