# Manage aliases
'use strict'

time = require("./harvest").TimeTracking
file = require "./file"
search = require "./search"
logger = require "loggy"
colors = require "colors"
prompt = require "prompt"

config = file.config()
aliasType = activeAlias = ""
aliases = {}

# Callback for search submodule to set an alias
aliasCallback = (match) ->
    if match > 0
        aliases[aliasType] = {} unless aliases[aliasType]
        aliases[aliasType][activeAlias] = match
        file.save file.files.aliases, aliases
        logger.success "Set #{aliasType} alias for ID #{match} as #{activeAlias}"


# Set an alias by fuzzy search query
exports.set = setAlias = (alias, query, type = "project") ->
    aliasType = type
    activeAlias = alias

    # Read the resource to search
    aliases = file.aliases()

    # Check existing aliases
    if aliases[type] and aliases[type][alias]
        logger.error "Alias #{alias} already exists"
        process.exit 1

    # Search for a match
    search query, type, aliasCallback


# Get a resource ID from a given alias
exports.get = getAlias = (alias, type = "project") ->
    # Already have an ID
    if alias.match /[0-9]+/
        +alias
    else
        aliases = file.aliases()

        # Check existing aliases
        if aliases[type] and aliases[type][alias]
            aliases[type][alias]
        else
            logger.error "No #{type} alias found for #{alias}"
            process.exit 1


# List all aliases for a resource type
exports.list = listAliases = (type = "project") ->
    aliases = file.aliases()

    if aliases[type]
        for alias, id of aliases[type]
            logger.info "#{alias}: #{id}"

