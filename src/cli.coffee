# Primary: command-line interface
'use strict'

cmd = require "commander"
commands = require './'
cmd.version require("../package.json").version


# Helper to parse shorthand resource names for aliasing
parseAlias = (input) ->
    switch input
        when 'c' then 'client'
        when 't' then 'task'
        when 'p' then 'project'
        when 'u' then 'user'
        when 'clients' then 'client'
        when 'tasks' then 'task'
        when 'projects' then 'project'
        when 'users' then 'user'
        else input


# Alias creation
cmd.command('alias <alias> <resource>')
    .description('Create an alias for a Harvest resource. Shortcut: a')
    .option('-t, --type <type>', 'specify the resource type for which to create an alias. Default: project')
    .action (target, query, program) ->
        commands.alias target, query, parseAlias program.type


# Alias listing
cmd.command('aliases')
    .description('Show all aliases for a Harvest resource. Shortcut: la')
    .option('-t, --type <type>', 'specify the resource type for limiting the listing. Default: project')
    .action (program) ->
        commands.aliases parseAlias program.type


# Resource listing
cmd.command('list [resource]')
    .description('Show all of a given resource in Harvest (default = project). Shortcut: ls')
    .option('-c, --client <client>', 'specify a client alias to limit the listing of tasks.')
    .action (resource, program) ->
        commands.list parseAlias(resource), program.client


# Summary reporting (range)
cmd.command('range <fromDate> <toDate>')
    .description('Show logged time for a date range.')
    .action (from, to) ->
        commands.range from, to


# Summary reporting (single day)
cmd.command('day [date]')
    .description('Show logged time for a date (default = today). Shortcut: d')
    .action (day) ->
        commands.day day


# Summary reporting (week)
cmd.command('week [date]')
    .description('Show logged time for the week of a date (default = today). Shortcut: w')
    .action (day) ->
        commands.week day


# Log time but stop the timer
cmd.command('log <project> <task> [time] [note]')
    .description('Create a stopped timer for a given task. Shortcut: l')
    .action (project, task, time, note) ->
        taskString = project
        if taskString.match /\./
            note = time
            time = task
        else
            taskString += "." + task

        commands.log taskString, time, note


# Start time tracking
cmd.command('start <project> [task] [time] [note]')
    .description('Start a new timer for a given task. Shortcut: s')
    .action (project, task, time, note) ->
        taskString = project
        if taskString.match /\./
            note = time
            time = task
        else
            taskString += "." + task

        commands.start taskString, time, note


# Pause/stop time tracking
cmd.command('pause')
    .description('Stops the currently running timer. Shortcut: p')
    .action ->
        commands.pause()


# Resume time tracking
cmd.command('resume [entry]')
    .description('Restarts the last running timer. Shortcut: r')
    .option('-n, --negative', 'Indicate that the number is negative')
    .action (entry, program) ->
        index = parseInt(entry)
        index *= -1 if program.negative?
        commands.resume index


# Edit notes for timer
cmd.command('note [note]')
    .description('Update the notes for the running timer. Shortcut: n')
    .action (note) ->
        commands.note note


# The function is executed every time user runs `bin/sow`
exports.run = ->
    args = process.argv.slice()
    command = args[2]

    # Replace shortcuts
    fullCommand = switch command
        when 'a' then 'alias'
        when 'd' then 'day'
        when 'w' then 'week'
        when 'l' then 'log'
        when 's' then 'start'
        when 'p' then 'pause'
        when 'r' then 'resume'
        when 'n' then 'note'
        when 'la' then 'aliases'
        when 'ls' then 'list'
        when 'stop' then 'pause'
        else command

    args[2] = fullCommand if fullCommand?
    cmd.parse args
    cmd.help() unless fullCommand?
