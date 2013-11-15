# Common logic for Harvest

harvestClass = require "harvest"
file = require "./file"
logger = require "loggy"

config = file.read file.files.config

if (!config)
    logger.err "Configuration is needed"

module.exports = new harvestClass
    subdomain: config.subdomain
    email: config.email
    password: config.password
