# Secondary: alias actions
'use strict'

harvest = require "./harvest"
file = require "./file"
search = require "./search"
logger = require "loggy"
colors = require "colors"
prompt = require "prompt"

timer = harvest.TimeTracking
config = file.config()

# Variables within this scope
aliasType = activeAlias = ""
aliases = {}

# Callback for search submodule to set an alias
setAlias = (match) ->
    if match > 0
        aliases[aliasType] = {} unless aliases[aliasType]
        aliases[aliasType][activeAlias] = match
        file.save file.files.aliases, aliases
        logger.success "Set #{aliasType} alias for ID #{match} as #{activeAlias}"


# Output all aliases in a uniform manner
printAliases = (data) ->
    for alias, id of data
        console.log "#{alias}: #{id}"
    console.log ""


# Set an alias by fuzzy search query or ID
exports.set = (alias, query, type = "project") ->
    # Make the passed parameters accessible for this scope
    aliasType = type
    activeAlias = alias
    aliases = file.aliases()

    # Check existing aliases
    if aliases[type] and aliases[type][alias]
        logger.error "Alias #{alias} already exists"
        process.exit 1

    # Search for a match
    search query, type, setAlias


# Get a resource ID from a given alias
exports.get = (alias, type = "project") ->
    # Make the passed parameters accessible for this scope
    aliases = file.aliases()

    # Already have an ID
    if alias.match /^[0-9]+$/
        +alias
    else
        alias = alias.slice 1 if alias.match /^@.*$/

        # Check existing aliases
        if aliases[type] and aliases[type][alias]
            aliases[type][alias]
        else
            logger.error "No #{type} alias found for #{alias}"
            process.exit 1


# List all aliases for a resource type
exports.list = (type = false) ->
    # Make the passed parameters accessible for this scope
    aliases = file.aliases()

    if type and aliases[type]
        printAliases aliases[type]
    else
        for type, details of aliases
            console.log "#{harvest.getResourceName type}".bold.blue
            printAliases details
