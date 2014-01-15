# Secondary: Base resource class (for clients, users, projects, and tasks)
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

modules.export = class PrimaryResource
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

        # Alias argument from @link for @set
        alias: ""

        # Callback to @find
        callback: null

        # Chosen response from @find/@prompt
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

    # Helper for saving freshly loaded resources
    loadItems: (err, data) ->
        logger.error err if err?
        logger.info "Regenerating cache" if config.debug

        # Immediately return if we don't have anything
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

    # Helper for filtering a row according to criteria
    filterRow: (row, filters) ->
        passes = true
        if limits.length > 0
            for limit in limits
                method = "filterRow" + limit.type.toUpperCase() + limit.type.slice 1
                method = "filterRowValue" unless this[method]?
                passes = this[method] row, limit
        passes

    # Helper for testing a row's field matches a given value exactly
    filterRowValue: (item, limit) ->
        passes = true
        passes = false unless item[limit.field]? and item[limit.field] is value
        logger.warn "#{limit.field} value of #{item[limit.field]} does not match #{value}." if config.debug and not passes
        passes

    # Helper for testing a row's field (should be ID) matches an alias's ID exactly
    filterRowAlias: (item, limit) ->
        limit.value = @alias limit.value, true
        @filterRowValue item, value

    # Helper for testing a row's field matches a given value by a fuzzy search
    filterRowFuzzy: (item, limit, returnMatch = false) ->
        value = item[limit.field]
        value = @formatName item if limit.field is "name"
        match = fuzzy value, limit.value
        minScore = config.score or 1.5
        logger.log "#{limit.field} score is #{match.score}." if config.debug

        # Give the whole match object back if requested
        match if returnMatch

        # else return a simple boolean
        passes = true
        passes = false if match.score <= limit.value.length * minScore
        passes

    # Helper for testing a row is marked as active
    filterRowActive: (item, limit) ->
        item.active if limit.value else not item.active

    # Helper for testing a row is marked as a default
    filterRowDefault: (item, limit) ->
        item.is_default if limit.value else not item.is_default

    # Create a resource in Harvest
    create: ->

    # Read a resource entry from cache or Harvest
    read: ->

    # Update a resource in Harvest
    update: ->

    # Remove a resource from Harvest
    delete: ->

    # list all resources
    list: (limits = [], show = "all") ->
        for item in @data.items
            passes = filterRow item[@name], limits

            # if item passes the filters, show it
            @listRow item if passes

        # Dummy return
        true

    # Helper for formatting the printout of a listed row
    listRow: (item) ->
        string = "#{item.id}: " + @formatName item.name

        if item.active
            console.log string.green
        else
            console.log string.grey.italic
        true

    # Find a resource by fuzzy searching the name
    find: (query, callback = null) ->
        @data.callback = callback if typeof callback is "function"

        # We have an integer, so assume it's an ID
        if typeof query is "int"
            @data.chosen.id = query
        # Search resources if we don't have a direct ID
        else
            matches = []
            filter =
                type: "fuzzy"
                field: "name"
                value: query

            # Do some fuzzy matching
            for item in @data.items
                match = @filterRowFuzzy item[@name], filter, true

                if match
                    match.id = item[@name].id
                    matches.push match

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
                prompt.get @name, @promptSelect

            # Only one match, so assume it's right
            else if topX.length is 1
                @data.chosen = topX.shift()
            else
                logger.warn "No matches found"
                process.exit 0

        # We're doing async stuff, so act like we know what we're doing
        @data.callback @data.chosen.id if typeof @data.callback is "function"

        # Normal sync stuff wants a real result
        result.id

    # Helper for prompting user to select from the search results
    promptSelect = (err, result) ->
        # Logging
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
        # Check existing aliases
        if @data.aliases[alias]
            logger.error "Alias #{alias} already exists for #{@name}"
            process.exit 1

        # Make the passed parameters accessible to @set
        @data.alias = alias

        # Do our find and have it callback the @set alias
        @find query, @setAlias

    # Helper for appending alias to local data
    setAlias: (match) ->
        # Immediately end if nothing to set
        false if match < 1

        # Get all aliases
        aliases = file.aliases()

        # Append this alias
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

        # Made it this far so return throw false...
        false if returnValue

        # ...or die
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
