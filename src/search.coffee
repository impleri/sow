# Small module to search Harvest resources for something
'use strict'

config = require("./file").config()
harvest = require "./harvest"
cache = require "./cache"
logger = require "loggy"
colors = require "colors"
cmd = require "commander"
fuzzy = require "fuzzy.js"
debug = config.debug or false
limit = config.limit or 9

# Show the logged time for a day, defaulting to today
module.exports = search = (query, type = "project") ->
    # Get current resources
    resources = cache type

    # Search resources if we don't have a direct ID
    if typeof query != "int"
        matches = []

        # Do some fuzzy matching
        for resource in resources[type]
            match = fuzzy resource[type].name, query
            match.id = resource[type].id

            if debug
                logger.log match.score

            matches.push match

        # Sort matches in descending order
        matches.sort fuzzy.matchComparator
        topX = matches[0...limit]

        # Ask for input if multiple matches
        chosen = {id: 0}
        if topX.length > 1
            counter = 1
            for match in matches
                logger.info "{ counter }. { match.term }"
            logger.info 'C. Cancel'
            cmd.prompt 'Select match: ', (input) ->
                number = parseInt(input)
                if 0 < number <= limit
                    chosen = topX[number-1...1]

        # Only one match, so assume it's right
        else if topX.lentgh == 1
            chosen = topX.shift

        selected = chosen.id
    # Given an integer, so assume it's the right ID
    else
        selected = search

    # Return
    selected
