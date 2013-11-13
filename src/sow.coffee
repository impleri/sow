# Executable file

path = require 'path'
fs = require 'fs'

dir = path.dirname fs.realpathSync __filename
src = path.join dir, '..', 'build', 'cli'
require(src).run()
