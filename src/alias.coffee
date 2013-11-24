# Main logic for Harvest
'use strict'

time = require("./harvest").TimeTracking
file = require "./file"
search = require "./search"
logger = require "loggy"
colors = require "colors"
prompt = require "prompt"
config = file.config()
aliases = ""
aliasType = ""
activeAlias = ""

setAlias = (match) ->
    if config.debug
        logger.log "Match: #{ match }"

    # Set new alias
    if match > 0
        if not aliases[aliasType]
            aliases[aliasType] = {}
        aliases[aliasType][activeAlias] = match
        file.save file.files.aliases, aliases
        logger.success "Set #{ aliasType } alias for ID #{ match } as #{ activeAlias }"


# Show the logged time for a day, defaulting to today
exports.set = alias = (alias, query, type = "project") ->
    aliasType = type
    activeAlias = alias

    # Set the resource to search
    aliases = file.aliases()

    # Check existing aliases
    if aliases and aliases[type] and aliases[type][alias]
        logger.err "Alias already exists"
        false

    # Search for a match
    search query, type, setAlias
