# Utility: Resource actions
'use strict'

file = require "./file"
harvest = require "./harvest"
alias = require "./alias"
logger = require "loggy"
colors = require "colors"
prompt = require "prompt"
fuzzy = require "fuzzy.js"

# Sow config
config = file.config()
limit = config.matchLimit or 9

# Variables within this scope
processed = activeOnly = defaultOnly = false
searchQuery = fileType = ""
topX = []
limiters = []
chosen =
    id: 0
callback = (match) ->

# Configure prompt
prompt.delimiter = " "
prompt.message = "Select".cyan


# Callback to prompt
promptResponse = (err, result) ->
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


# Perform the search
search = (data) ->
    resourceName = file.resource fileType

    # Search resources if we don't have a direct ID
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
            prompt.get fileType, promptResponse

        # Only one match, so assume it's right
        else if topX.lentgh is 1
            chosen = topX.shift()
    else
        chosen.id = search

    callback chosen.id if chosen.id > 0


# Search all resources of a type by a query
exports.search = (query, type, cb) ->
    # Make the passed parameters accessible for this scope
    searchQuery = query
    fileType = type
    callback = cb

    file.cache type, search


# List all resources of a type
list = (data) ->
    resourceName = file.resource fileType

    if fileType and data[resourceName]
        for resource in data[resourceName]
            if not resource[fileType]?
                if config.debug
                    logger.warn "Resource is missing #{fileType}", resource
                continue

            item = resource[fileType]
            passes = true
            if limiters.length > 0
                for limiter in limiters
                    value = alias.get limiter.value, limiter.type
                    if not item[limiter.field]? or item[limiter.field] isnt value
                        if config.debug
                            logger.warn "#{limiter.field} value of #{item[limiter.field]} does not match #{value}"
                        passes = false

            if not passes
                continue

            string = "#{item.id}: #{item.name}"
            if item.active?
                active = item.active
            else
                active = not item.deactivated

            if item.is_default?
                is_default = item.is_default
            else
                is_default = true

            if active and is_default
                console.log string.green
            else if active and not defaultOnly
                console.log string.yellow
            else if not activeOnly
                console.log string.grey.italic

            else # not default and not activeOnly


# List all resources of a given type
exports.list = (type = "project", limits = [], getAll = false, defaults = false) ->
    fileType = type
    activeOnly = not getAll
    defaultOnly = defaults
    limiters = limits

    file.cache type, list
