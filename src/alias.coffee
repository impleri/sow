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

aliasCallback = (match) ->
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
exports.set = setAlias = (alias, query, type = "project") ->
    aliasType = type
    activeAlias = alias

    # Read the resource to search
    aliases = file.aliases()

    # Check existing aliases
    if aliases and aliases[type] and aliases[type][alias]
        logger.error "Alias #{ alias } already exists"
        process.exit 1

    # Search for a match
    search query, type, aliasCallback

exports.get = getAlias = (alias, type = "project") ->
    # Already have an ID
    if alias.match /[0-9]+/
        +alias
    else
        # Set the resource to search
        aliases = file.aliases()

        # Check existing aliases
        if aliases and aliases[type] and aliases[type][alias]
            aliases[type][alias]
        else
            logger.error "No #{ type } alias found for #{ alias }"
            process.exit 1

exports.list = listAliases = (type = "project") ->
    aliases = file.aliases()

    # Check existing aliases
    if aliases and aliases[type]
        for alias, id of aliases[type]
            logger.info "#{ alias }: #{ id }"


