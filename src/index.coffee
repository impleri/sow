'use strict'

fs = require "fs"
logger = require "loggy"
harvest = require "./harvest"
sow = require "./sow"

module.exports = {
  alias: sow.alias
  build: watch.bind(null, false)
  watch: watch.bind(null, true)
}
