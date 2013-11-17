# Actual CLI interface (Commander)

'use strict'

cmd = require "commander"
commands = require './'

cmd.version(require("../package.json").version)

cmd.command('alias <alias> <resource>')
    .description('Create an alias for a Harvest resource. Shortcut: a')
    .option('-t, --type <type>', 'specify the resource type for which to create an alias. Default: project')
    .action ->
        commands.alias cmd.args[0], cmd.args[1], cmd.type

cmd.command('day [date]')
    .description('Show logged time for a date (default = today). Shortcut: d')
    .action ->
        commands.day cmd.args[0]

cmd.command('week [date]')
    .description('Show logged time for the week of a date (default = today). Shortcut: w')
    .action ->
        commands.week cmd.args[0]

cmd.command('range <fromDate> <toDate>')
    .description('Show logged time for a date range.')
    .action ->
        commands.range cmd.args[0], cmd.args[1]


# The function is executed every time user runs `bin/sow`
exports.run = ->
    args = process.argv.slice()
    command = args[2]

    # Replace shortcuts
    fullCommand = switch command
        when 'a' then 'alias'
        when 'd' then 'day'
        when 'w' then 'week'
        else command

    args[2] = fullCommand if fullCommand?
    cmd.parse args
    cmd.help() unless fullCommand?
