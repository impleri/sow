# Helper module to search resources by a query
'use strict'

file = require "./file"
harvest = require "./harvest"
logger = require "loggy"
colors = require "colors"
prompt = require "prompt"
fuzzy = require "fuzzy.js"

callback = ->
processed = false
config = file.config()
limit = config.limit or 9
searchQuery = fileType = ""
prompt.delimiter = " "
prompt.message = "Select".cyan


# Main function that performs the search as well as handle prompts for selection
performSearch = (data) ->
    resourceName = file.resource fileType

    # Search resources if we don't have a direct ID
    chosen = {id: 0}
    if typeof searchQuery != "int"
        matches = []

        # Do some fuzzy matching
        for resource in data[resourceName]
            match = fuzzy resource[fileType].name, searchQuery
            match.id = resource[fileType].id
            matches.push match if match.score > 3

        # Sort matches in descending order
        matches.sort fuzzy.matchComparator
        topX = matches[0...limit]

        # Ask for input if multiple matches
        if topX.length > 1
            counter = 0
            for match in topX
                counter++
                console.log "#{counter}. #{match.term}"
            console.log 'C. Cancel'

            prompt.start()
            prompt.get fileType, (err, result) ->
                if err
                    logger.error err
                else
                    if config.debug
                        logger.log "Detected selection of #{result[fileType]}"

                    if result[fileType] is "c" or result[fileType] is "C"
                        logger.warn "Cancelling action"
                        process.exit 0
                    else if not result[fileType].match /[0-9]+/
                        logger.error "Invalid selection detected"
                        process.exit 1

                    number = parseInt result[fileType]
                    if 0 < number <= limit
                        chosen = topX[number-1...number].pop()
                        callback chosen.id


        # Only one match, so assume it's right
        else if topX.lentgh is 1
            chosen = topX.shift
    else
        chosen.id = search

    callback chosen.id if chosen.id > 0


# Callback from Harvest API to cache resource list
searchCallback = (err, data) ->
    logger.error err if err

    if data
        now = new Date
        fileName = file.resource fileType

        cache =
            generated: now.toDateString()
        cache[fileName] = data

        file.save fileName, cache
        performSearch cache


# Show the logged time for a day, defaulting to today
module.exports = search = (query, type, cb) ->
    callback = cb
    searchQuery = query
    fileType = type

    cache = file.read file.resource type
    lastGenerated = cache.generated or 0
    generated = new Date lastGenerated

    if config.debug and generated
            logger.log "Cache for #{type} last updated on #{generated}"

    now = new Date
    cacheLife = config.cacheLife or 7
    generated.setDate generated.getDate() + cacheLife

    # Refresh cache if needed
    if now.getTime() < generated.getTime()
        performSearch cache
    else
        resource = harvest.getResourceName type
        if config.debug
            logger.log "Regenerating cache"
        harvest[resource].list {}, searchCallback

