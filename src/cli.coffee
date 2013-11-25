# Actual CLI interface (Commander)
'use strict'

cmd = require "commander"
commands = require './'

cmd.version(require("../package.json").version)

parseAlias = (input) ->
    switch input
        when 'c' then 'client'
        when 't' then 'task'
        when 'p' then 'project'
        when 'u' then 'user'
        else input


# Alias handling
cmd.command('alias <alias> <resource>')
    .description('Create an alias for a Harvest resource. Shortcut: a')
    .option('-t, --type <type>', 'specify the resource type for which to create an alias. Default: project')
    .action (prog, args, program) ->
        commands.alias cmd.args[0], cmd.args[1], parseAlias program.type


cmd.command('list <resource>')
    .description('Show all aliases for a Harvest resource. Shortcut: la')
    .action (prog, args, program) ->
        commands.aliases parseAlias cmd.args[0]


# Summary reporting
cmd.command('range <fromDate> <toDate>')
    .description('Show logged time for a date range.')
    .action ->
        commands.range cmd.args[0], cmd.args[1]

cmd.command('day [date]')
    .description('Show logged time for a date (default = today). Shortcut: d')
    .action ->
        commands.day cmd.args[0]

cmd.command('week [date]')
    .description('Show logged time for the week of a date (default = today). Shortcut: w')
    .action ->
        commands.week cmd.args[0]

# Time tracking
cmd.command('start <project> [task] [time] [note]')
    .description('Start a new timer for a given task. Project and task can be passed as a single string in dot notation (i.e. project.task) or as two separate arguments. Optionally adding initial time spent to the timer and/or a note. Shortcut: s')
    .action ->
        taskString = cmd.args[0]
        if taskString.match /\./
            task = ""
            time = cmd.args[1]
            note = cmd.args[2]
        else
            taskString += "." + cmd.args[1]
            time = cmd.args[2]
            note = cmd.args[3]

        commands.start taskString, time, note

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
