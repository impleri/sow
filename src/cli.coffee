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


# Init/Setup
cmd.command('init')
    .description('Create the initial configuration.')
    .option('-s, --subdomain <subdomain>', 'specify the subdomain for your account.')
    .option('-e, --email <email>', 'specify your email address.')
    .option('-p, --password <password>', 'specify your account password.')
    .option('-f, --force', 'skip testing of configuration.')
    .action (program) ->
        commands.init
            subdomain: program.subdomain
            email: program.email
            password: program.password
            force: program.force


# Alias creation
cmd.command('alias <alias> <target_resource>')
    .description('Create an alias for a Harvest resource. Shortcut: a')
    .option('-t, --type <resource_type>', 'specify the resource type for which to create an alias. Default: project')
    .action (target, query, program) ->
        commands.alias target, query, parseAlias program.type


# Alias listing
cmd.command('aliases')
    .description('Show all aliases for a Harvest resource. Shortcut: la')
    .option('-t, --type <resource_type>', 'specify the resource type for limiting the listing. Default: project')
    .action (program) ->
        commands.aliases parseAlias program.type


# Resource listing
cmd.command('list [search]')
    .description('Show all active resources of a type (default = project). Shortcut: ls')
    .option('-t, --type <resource_type>', 'specify the resource type for limiting the listing. Default: project')
    .option('-a, --all', 'show all (include inactive resources).')
    .option('-c, --client <client>', 'specify a client alias to limit the listing of tasks.')
    .action (search, program) ->
        limits = []
        if program.client
            limits.push
                field: 'client_id'
                type: 'client'
                value: program.client
        if search
            limits.push
                field: 'name'
                type: 'fuzzy'
                value: search
        commands.list parseAlias(program.type), limits, program.all


# Summary reporting (range)
cmd.command('range <from_date> <to_date>')
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
        matches = taskString.match /^@?([^@])+@([^@])$/
        if matches
            taskString = matches[1] + "." + matches[0]
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
cmd.command('resume [entry] [task] [note]')
    .description('Restarts an existing timer. Shortcut: r')
    .option('-n, --negative', 'Indicate that the number is negative')
    .action (entry, task, note, program) ->
        index = parseInt(entry)
        if not isNaN index 
            index *= -1 if program.negative?
        else
            if entry.match /\./
                note = task
            else
                entry += "." + task
            index = entry

        commands.resume index, note


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
        when 'setup' then 'init'
        else command

    args[2] = fullCommand if fullCommand?
    cmd.parse args
    cmd.help() unless fullCommand?
