# Small module to search Harvest resources for something
'use strict'

config = require("./file").config()
harvest = require "./harvest"
cache = require "./cache"
logger = require "loggy"
colors = require "colors"
prompt = require "prompt"

prompt.message = "Select".cyan;
prompt.delimiter = " ";

# Show the logged time for a day, defaulting to today
module.exports = search = (search, type = "project") ->
    # Get current resources
    resources = cache type

    # Search resources if we don't have a direct ID
    if typeof search != "int"
        matches = {}

        # Do some fuzzy matching
        for resource in resources[type]
            #


        # Ask for input if multiple matches
        selected = 0
        if matches.length > 1
            prompt.start()
            prompt.get type, (err, result) ->
                selected = result[type] unless err
        # Only one match, so assume it's right
        else if matches.lentgh == 1
            selected = 1
    # Given an integer, so assume it's the right ID
    else
        selected = search

    # Return
    selected
