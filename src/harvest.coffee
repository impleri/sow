# Secondary: Harvest wrapper
'use strict'

harvestClass = require "harvest"
file = require "./file"
logger = require "loggy"

config = file.config()

if not config.subdomain?
    logger.error "Configuration is needed"
    process.exit 1

harvestClass.prototype.getResourceName = (stub) ->
    plural = file.resource stub
    plural[0].toUpperCase() + plural.slice 1

module.exports = new harvestClass
    subdomain: config.subdomain
    email: config.email
    password: config.password

module.exports.debug = config.debugHarvest if config.debugHarvest?
