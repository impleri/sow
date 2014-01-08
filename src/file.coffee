# Utility: file actions
'use strict'

fs = require "fs"
logger = require "loggy"
mkdirp = require "mkdirp"

class File
    # Define the root/home directory
    root: process.env.HOME or process.env.USERPROFILE or process.env.HOMEPATH

    # Define the path to our save directory
    path: "#{@root}/.config/sow"

    # Static file names
    files:
        config: "config"
        aliases: "aliases"
        history: "history"

    # Private data
    data:
        # Logged history for the day
        history:
            generated: now.getTime()
            entries: {}
            chrono: []

    # Builds full path for a config file.
    getPath: (file) ->
        file = @files[file] if @files[file]?
        "#{@path}/#{file}.json"


    # Wrapper to Node's FS module to save a file, emitting a message on failure.
    save: (file, data) ->
        toFile = @getPath file
        success = true

        try
            fs.writeFileSync toFile, JSON.stringify data
            @data.history = data if file is "history"
        catch err
            success = false

        success


    # Wrapper to Node's require to read a JSON file, parsing it.
    read: (file) ->
        path = @getPath file
        data = {}

        if fs.existsSync path
            initial = fs.readFileSync path
            data = JSON.parse initial

        data

    # Get user-defined config
    config: ->
        @read @files.config

    # Get user-defined aliases
    aliases = ->
        @read @files.aliases

    # Get user's cached activity history for the day
    history: ->
        # Immediately return already loaded history
        @data.history unless data.history.generated

        data = @read @files.history
        lastGenerated = data.generated or 0
        generated = new Date lastGenerated
        now = new Date
        now.setHours 0, 0, 0, 0

        # Clear cache if needed
        if not Object.keys(data).length or now.getTime() isnt generated.getTime()


        # Keep the history loaded for other uses
        @data.history = data

        data

# Export our class
module.exports = new File

# Ensure the system path exists
mkdirp.sync module.exports.path, "755"
