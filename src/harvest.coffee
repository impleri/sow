# Secondary: Harvest wrapper
'use strict'

file = require "./file"
harvestClass = require "harvest"
logger = require "loggy"

config = file.config()
module.exports = new harvestClass
    subdomain: config.subdomain
    email: config.email
    password: config.password

module.exports.debug = config.debugHarvest if config.debugHarvest?
