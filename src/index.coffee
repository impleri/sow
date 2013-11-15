# Common file to map subfiles to commands
'use strict'


summary = require "./summary"
exports.summary = summary.day
exports.week = summary.week

exports.alias = require "./alias"

# timer = require "./timer"
# exports.start = timer.start
# exports.pause = timer.pause
# exports.resume = timer.resume
# exports.log = timer.log
