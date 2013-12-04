# Secondary: join modules
'use strict'

file = require "./file"
logger = require "loggy"
colors = require "colors"
prompt = require "prompt"

config = file.config()
configDefaults = {}


# Try to test and save the config
saveConfig = (err, data = false) ->
    # Error in setup, so re-do screens
    if err?
        logger.warn err
        logger.info "Please check your settings and try again"
        configDefaults.force = false
        doSetup false
    # Success or forced
    else if data
        logger.success "Configuration successful!"
        file.save file.files.config, config
        process.exit 0
    else
        harvestClass = require "harvest"
        harvest = new harvestClass
            subdomain: config.subdomain
            email: config.email
            password: config.password
        harvest.Account.get {}, saveConfig


# Catch data from prompts
promptResponse = (err, result) ->
    if err
        logger.error err
    else
        if config.debug
            logger.log "Given values:", result

        config.subdomain = result.subdomain
        config.email = result.email
        config.password = result.password
        saveConfig err


# Start the setup process by prompting for config values
module.exports = doSetup = (defaults = false) ->
    configDefaults = defaults if defaults
    schema =
        properties:
            subdomain:
                pattern: /^[a-z0-9]+$/,
                message: 'Subdomain must be only letters or numbers.',
                required: true
                default: configDefaults.subdomain
            email:
                pattern: /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/i,
                message: 'Subdomain must be only letters or numbers.',
                required: true
                default: configDefaults.email
            password:
                hidden: true
                required: true
                default: configDefaults.password

    if defaults.force
        promptResponse null, defaults
    else
        prompt.start()
        prompt.delimiter = " "
        prompt.message = "Set".yellow.bold
        prompt.get schema, promptResponse
