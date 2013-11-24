# Common logic for Harvest
'use strict'

harvestClass = require "harvest"
file = require "./file"
logger = require "loggy"

config = file.read file.files.config

if (!config)
    logger.err "Configuration is needed"

harvestClass.prototype.getResourceName = (stub) ->
    plural = file.resource stub
    plural[0].toUpperCase() + plural.slice 1

module.exports = new harvestClass
    subdomain: config.subdomain
    email: config.email
    password: config.password
