# Executable file
'use strict'

console.log "Starting"

path = require "path"
fs = require "fs"

dir = path.dirname fs.realpathSync __filename
src = path.join dir, "..", "build", "cli"
console.log src
require(src).run()
