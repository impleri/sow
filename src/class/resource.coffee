# Secondary: alias actions
'use strict'

harvest = require "./harvest"
file = require "./file"
resource = require "./resource"
logger = require "loggy"
colors = require "colors"
prompt = require "prompt"
fuzzy = require "fuzzy.js"

# Sow config
config = file.config()

# Configure prompt
prompt.delimiter = " "
prompt.message = "Select".cyan

# helper function
ucfirst = (string) ->
    string[0].toUpperCase() + string.slice 1

class Resource
    name: ""

    plural: ""

    aliases: {}

    items: {}

    data:
        alias: ""

    # Simple constructor gets cached items and aliases for a resource
    constructor: (force = false) ->
        # Read the cached items from file (if one exists)
        now = new Date
        cache = file.read @plural
        cacheLife = config.cacheLife or 7
        generatedTime = cache.generated or 0
        generated = new Date generatedTime
        generated.setDate generated.getDate() + cacheLife

        if config.debug and generatedTime > 0
                logger.log "Cache for #{@name} last updated on #{generated}"

        # Refresh cache if needed
        if force or now.getTime() > generated.getTime()
            if config.debug
                logger.info "Regenerating cache"
            resource = ucfirst @plural
            harvest[resource].list {}, @loadItems
        else
            @items = cache

        # Load aliases for this resource type
        aliases = file.aliases()
        if aliases[@name]
            @aliases = aliases[@name]

        # Dummy return
        true

    # Constructor callback to save loaded resources
    loadItems: (err, data) ->
        logger.error err if err?

        if data
            now = new Date

            cache =
                generated: now.toDateString()
            cache[@plural] = data

            file.save @plural, cache
            @items = cache

        true

    formatName: (row) ->
        row.name

    # Create a resource in Harvest
    create: ->

    # Read a resource entry from cache or Harvest
    read: ->

    # Update a resource in Harvest
    update: ->

    # Remove a resource from Harvest
    delete: ->

    # list all resources
    list: (limits = [], getAll = false, defaults = false) ->
        if @items
        for resource in @items
            passes = true
            if limits.length > 0
                for limiter in limits
                    if limiter.type is "fuzzy"
                        match = fuzzy item[limiter.field], limiter.value
                        if match.score <= limiter.value.length * 1.5
                            passes = false
                        else if config.debug
                            logger.log "#{limiter.field} score is #{match.score}."
                    else
                        value = alias.get limiter.value, limiter.type
                        if not item[limiter.field]? or item[limiter.field] isnt value
                            if config.debug
                                logger.warn "#{limiter.field} value of #{item[limiter.field]} does not match #{value}."
                            passes = false

            if not passes
                continue

            string = "#{item.id}: "

            if fileType is "user"
                string += "#{item.first_name} #{item.last_name}"
            else
                string += item.name


            if item.active?
                active = item.active
            else if item.is_active?
                active = item.is_active
            else
                active = not item.deactivated

            if item.is_default?
                is_default = item.is_default
            else
                is_default = true

            if active and is_default
                console.log string.green
            else if active and not activeOnly
                console.log string.yellow
            else if not activeOnly
                console.log string.grey.italic

            else # not default and not activeOnly

    # Find a resource by fuzzy searching the name
    find: (query) ->
        result =
            id: 0

        # Search resources if we don't have a direct ID
        if typeof query != "int"
            matches = []

            # Do some fuzzy matching
            for resource in @items
                name = @formatName resource[@name]
                match = fuzzy name, query
                match.id = resource[@name].id
                matches.push match if match.score >= query.length

            # Sort matches in descending order
            matches.sort fuzzy.matchComparator
            limit = config.matchLimit or 9
            topX = matches[0...limit]

            # Ask for input if multiple matches
            if topX.length > 1
                counter = 0
                for match in topX
                    counter++
                    console.log "#{counter}. #{match.term}"
                console.log 'C. Cancel'

                prompt.start()
                prompt.get @name, promptResponse

            # Only one match, so assume it's right
            else if topX.length is 1
                result = topX.shift()
            else
                logger.warn "No matches found"
                process.exit 0
        else
            result.id = search

        result.id

    # Get a resource ID from a given alias
    readAlias: (alias, returnValue = false) ->
        # Already have an ID
        if alias.match /^[0-9]+$/
            +alias
        else if alias
            alias = alias.slice 1 if alias.match /^@.*$/

            # Check existing aliases
            if @aliases[alias]
                @aliases[alias]

        # Made it this far so either throw false or die
        if returnValue
            false
        else
            logger.error "No #{@name} alias found for #{alias}"
            process.exit 1

    # Append alias to save data
    saveAlias: (match) ->
        if match > 0
            # Get all aliases
            aliases = file.aliases()
            aliases[@name] = {} unless aliases[@name]
            aliases[@name][@data.alias] = match

            # Save all aliases
            file.save file.files.aliases, aliases
            logger.success "Set #{@name} alias for ID #{match} as #{@data.alias}"

            true
        false

    # Set an alias by fuzzy search query or ID
    setAlias: (alias, query) ->
        # Make the passed parameters accessible for this scope
        @data.alias = alias

        # Check existing aliases
        if @aliases[alias]
            logger.error "Alias #{alias} already exists for #{@name}"
            process.exit 1

        # Search for a match
        @find query, @saveAlias

    # List all aliases for the resource type
    listAlias: ->
        for alias, id of @aliases
            console.log "#{alias}: #{id}"
        console.log ""
        true
