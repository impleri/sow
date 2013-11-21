# Main logic for Harvest
'use strict'

time = require("./harvest").TimeTracking
file = require "./file"
search = require "./search"
logger = require "loggy"
colors = require "colors"
prompt = require "prompt"

config = file.config()
# aliases = file.aliases()
debug = config.debug or false

# Show the logged time for a day, defaulting to today
module.exports = alias = (alias, query, type = "project") ->
    options = {}

    # Set the resource to search
    aliases = "{ file.read type }.aliases"

    # Check existing aliases
    if aliases[alias]
        logger.err "Alias already exists"
        false

    # Search for a match
    match = search query, type

    if debug
        logger.log match

    # Set new alias
    if match > 0
        aliases[alias] = match
