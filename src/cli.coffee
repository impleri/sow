# Actual CLI interface (Commander)

'use strict'

cmd = require "commander"
commands = require './'

cmd.version(require("../package.json").version)

cmd.command('client-alias [client] [alias]')
    .description('Create an alias for a Harvest client ID. Short-cut: ca')
    .action ->
        commands.alias "c", cmd.args[0], cmd.args[1]

cmd.command('project-alias [project] [alias]')
    .description('Create an alias for a Harvest project ID. Short-cut: pa')
    .action ->
        commands.alias "p", cmd.args[0], cmd.args[1]

cmd.command('summary [date]')
    .description('Show logged time for a date formatted as YYYY-MM-DD. Short-cut: s')
    .action ->
        commands.summary cmd.args[0]

###
program
  .command('build')
  .description('Build a brunch project. Short-cut: b')
  .option('-e, --env [setting]', 'specify a set of override settings to apply')
  .option('-P, --production', 'same as `--env production`')
  .option('-c, --config [path]', '[DEPRECATED] path to config files')
  .option('-o, --optimize', '[DEPRECATED] same as `--env production`')
  .action(commands.build)

program
  .command('watch')
  .description('Watch brunch directory and rebuild if something changed. Short-cut: w')
  .option('-e, --env [setting]', 'specify a set of override settings to apply')
  .option('-P, --production', 'same as `--env production`')
  .option('-s, --server', 'run a simple http server that would serve public dir')
  .option('-p, --port [port]', 'if a `server` option was specified, define on which port
 the server would run')
  .option('-c, --config [path]', '[DEPRECATED] path to config files')
  .option('-o, --optimize', '[DEPRECATED] same as `--env production`')
  .action(commands.watch)
###

# The function would be executed every time user run `bin/sow`.
exports.run = ->
    args = process.argv.slice()
    command = args[2]

    fullCommand = switch command
        when 'ca' then 'client-alias'
        when 'pa' then 'project-alias'
        when 's' then 'summary'
        else command

    args[2] = fullCommand if fullCommand?
    cmd.parse args
    cmd.help() unless fullCommand?
