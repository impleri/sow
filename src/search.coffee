# Small module to search Harvest resources for something
'use strict'

file = require "./file"
harvest = require "./harvest"
cache = require "./cache"
logger = require "loggy"
colors = require "colors"
prompt = require "prompt"
fuzzy = require "fuzzy.js"
config = file.config()
limit = config.limit or 9
searchQuery = ""
fileType = ""
callback = ->

prompt.message = "Select".cyan
prompt.delimiter = " "

processSelected = (chosen) ->
    if config.debug
        logger.log "Chosen result", chosen
    callback chosen.id


performSearch = (err, data) ->
    query = searchQuery
    type = fileType
    resourceName = file.resource type

    # Search resources if we don't have a direct ID
    chosen = {id: 0}
    if typeof query != "int"
        matches = []

        # Do some fuzzy matching
        for resource in data[resourceName]
            match = fuzzy resource[type].name, query
            match.id = resource[type].id
            matches.push match

        # Sort matches in descending order
        matches.sort fuzzy.matchComparator
        topX = matches[0...limit]

        # Ask for input if multiple matches
        if topX.length > 1
            counter = 1
            for match in topX
                logger.info "#{ counter }. #{ match.term }"
                counter++
            logger.info 'C. Cancel'
            prompt.start()
            prompt.get type, (err, result) ->
                if err
                    logger.error "Prompt error:", err
                else
                    if result[type] == "c" or result[type] == "C"
                        logger.warn "Cancelling action"
                        process.exit 0
                    # else if result[type]
                    #   logger.error "Invalid selection detected"
                    #   process.exit 1
                    number = parseInt result[type]
                    if config.debug
                        logger.log "Detected selection of #{ number }"
                    if 0 < number <= limit
                            number
                        selection = topX[number-1...number]
                        chosen = selection.pop()
                        processSelected chosen

        # Only one match, so assume it's right
        else if topX.lentgh == 1
            chosen = topX.shift
            processSelected chosen
    else
        chosen.id = search
        processSelected chosen

# Show the logged time for a day, defaulting to today
module.exports = search = (query, type, cb) ->
    callback = cb
    searchQuery = query
    fileType = type

    # Get current resources
    cache type, performSearch


