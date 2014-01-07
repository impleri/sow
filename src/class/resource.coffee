# Secondary: alias actions
'use strict'

# External modules
logger = require "loggy"
colors = require "colors"
prompt = require "prompt"
fuzzy = require "fuzzy.js"

# Internal modules
file = require "./file"
harvest = require "./harvest"

# Sow config
config = file.config()

# Configure prompt
prompt.delimiter = " "
prompt.message = "Select".cyan

class Resource
    # The resource type
    name: ""

    # Plural of @name for easier reference
    plural: ""

    # The class from the Harvest API to use
    api: {}

    # Internal data
    data:
        # Local aliases
        aliases: {}

        # Resources in Harvest (or cached)
        items: {}

        # Alias argument passed to @setAlias for use in @saveAlias
        alias: ""

        # Chosen response from find
        chosen:
            id: 0

    # Simple constructor gets cached items and aliases for a resource
    constructor: (force = false) ->
        # Automate setting this.plural of to the simple plural of name
        @plural = "#{@name}s" if @plural is ""

        # Set the upstream Harvest class
        resource = @plural[0].toUpperCase() + @plural.slice 1
        @api = harvest[resource]

        # Read the cached items from file (if one exists)
        now = new Date
        cache = file.read @plural
        cacheLife = config.cacheLife or 7
        generatedTime = cache.generated or 0
        generated = new Date generatedTime
        generated.setDate generated.getDate() + cacheLife

        logger.log "Cache for #{@name} last updated on #{generated}" if config.debug and generatedTime > 0

        # Set cache and refresh if needed
        @data.items = cache
        @api.list {}, @loadItems if force or now.getTime() > generated.getTime()
            
        # Load aliases for this resource type
        aliases = file.aliases()
        @data.aliases = aliases[@name] if aliases[@name]

        # Dummy return
        true

    # Constructor callback to save loaded resources
    loadItems: (err, data) ->
        logger.info "Regenerating cache" if config.debug
        logger.error err if err?
        false unless data

        now = new Date

        cache =
            generated: now.toDateString()
        cache[@plural] = data

        file.save @plural, cache
        @data.items = cache
        true

    # Helper for formatting compound names if need be
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
        for item in @data.items
            passes = true
            if limits.length > 0
                for limit in limits
                    if limit.type is "fuzzy"
                        match = fuzzy item[limit.field], limit.value
                        passes = false if match.score <= limit.value.length * 1.5
                        logger.log "#{limit.field} score is #{match.score}." if config.debug
                    else
                        value = @readAlias limit.value, true
                        if not item[limit.field]? or item[limit.field] isnt value
                            logger.warn "#{limit.field} value of #{item[limit.field]} does not match #{value}." if config.debug
                            passes = false

            continue unless passes

            string = "#{item.id}: " + @formatName item.name
            active = not item.deactivated
            active = item.is_active if item.is_active?
            active = item.active if item.active?
            is_default = item.is_default if item.is_default? else true

            if active and is_default
                console.log string.green
            else if active and not activeOnly
                console.log string.yellow
            else if not activeOnly
                console.log string.grey.italic


    # Find a resource by fuzzy searching the name
    find: (query, callback = null) ->
        @data.callback = callback if typeof callback is "function"

        # We already have an integer, so assume it's an ID
        if typeof query is "int"
            @data.chosen.id = query
        # Search resources if we don't have a direct ID
        else
            matches = []

            # Do some fuzzy matching
            for resource in @data.items
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
                prompt.get @name, @prompt

            # Only one match, so assume it's right
            else if topX.length is 1
                @data.chosen = topX.shift()
            else
                logger.warn "No matches found"
                process.exit 0
        else
            @data.chosen.id = search

        # We're doing async stuff, so act like we know what we're doing
        @data.callback @data.chosen.id if typeof @data.callback is "function"

        # Normal sync stuff wants a real result
        result.id

    # Prompt user to select from the search results
    prompt = (err, result) ->
        logger.error err if err

        logger.log "Detected selection of #{result[@name]}" if config.debug

        if result[@name] is "c" or result[@name] is "C"
            logger.warn "Cancelling action"
            process.exit 0
        else if result[@name]? and not result[@name].match /[0-9]+/
            logger.error "Invalid selection detected"
            process.exit 1

        number = parseInt result[@name]
        if 0 < number <= limit
            @data.chosen = topX[number-1...number].pop()
                
        @data.callback @data.chosen.id

    # Set an alias by fuzzy search query or ID (alias create)
    link: (alias, query) ->
        # Make the passed parameters accessible for this scope
        @data.alias = alias

        # Check existing aliases
        if @data.aliases[alias]
            logger.error "Alias #{alias} already exists for #{@name}"
            process.exit 1

        # Search for a match
        @find query, @set

    # Callback to append alias to local data
    set: (match) ->
        # Immediately end if nothing to set
        false if match < 1

        # Get all aliases
        aliases = file.aliases()
        aliases[@name] = {} unless aliases[@name]
        aliases[@name][@data.alias] = match

        # Save all aliases
        file.save file.files.aliases, aliases
        logger.success "Set #{@name} alias for ID #{match} as #{@data.alias}"

        true

    # Get a resource ID from a given alias (alias read)
    alias: (alias, returnValue = false) ->
        false if returnValue and not alias

        # Clean up alias
        alias = alias.slice 1 if alias.match /^@.*$/
        
        # Alias is an ID
        +alias if alias.match /^[0-9]+$/
            
        # Alias exists
        @data.aliases[alias] if @data.aliases[alias]

        # Made it this far so return throw false or die
        false if returnValue

        logger.error "No #{@name} alias found for #{alias}"
        process.exit 1

    # Set an alias by fuzzy search query or ID (alias delete)
    unlink: (alias) ->
        # Check existing aliases
        false unless @data.aliases[alias]
            
        aliases = file.aliases()
        delete aliases[@name][alias]

        # Save all aliases
        file.save file.files.aliases, aliases
        logger.success "Unset #{@name} alias"
        true

    # List all aliases for the resource type (alias list)
    aliases: ->
        console.log "#{alias}: #{id}" for alias, id of @data.aliases
        console.log ""
        true
