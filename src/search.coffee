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
    aliases = file.read type + ".aliases"

    # Check existing aliases
    resources = file.read type

    # Perform a search
    if typeof search != "int"
        # Check existing cache


        # Poll Harvest for update if not found in cache
            # Save new cache

        # Ask for input if multiple matches
        selected = 0
        prompt.start()
        prompt.get type, (err, result) ->
            selected = result[type] unless err

        # Should have an integer now

    # Set new alias

    time.daily options, (err, tasks) ->
        if (err)
            logger.error err if err
        else
            tasks.day_entries.forEach (task, index, array) ->
                sortTasks task

            for index, client of entries
                orderNodes client

            s = archy(structure)
            console.log s

