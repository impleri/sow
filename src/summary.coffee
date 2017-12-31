# Primary: show logged tasks
'use strict'

time = require("./harvest").TimeTracking
config = require("./file").config()
logger = require "loggy"
colors = require "colors"
chrono = require "chrono-node"
archy = require "archy"

# Variables within this scope
totalHours = 0.00
counter = maxCount = 0
callsComplete = false
calledMethod = ""
dates = entries = {}
structure =
    label: ""
    nodes: []

# Constructs an object to render in archy
insertClient = (client) ->
    clientNodes = []
    for index, project of client.projects
        projectNodes = []
        for index, task of project.tasks
            taskNodes = []
            for index, note of task.notes
                taskNodes.push "#{note.total.toFixed(2)} hours: #{note.name.italic}"
            projectNodes.push
                label: "#{task.name.yellow} (#{task.total.toFixed(2).yellow} hours)"
                nodes: taskNodes
        clientNodes.push
            label: "#{project.name.cyan} (#{project.total.toFixed(2).cyan} hours)"
            nodes: projectNodes
    structure.nodes.push
        label: "#{client.name.green.bold} (#{client.total.toFixed(2).green.bold} hours)"
        nodes: clientNodes


# Render the output
showCompleteLog = ->
    for index, client of entries
        insertClient client

    console.log ""
    console.log archy structure


# Set the root label of the archy structure
setRootLabel = ->
    end = dates.end.toDateString()
    label = switch calledMethod
        when "day" then end
        when "week" then "Week ending #{end}"
        else "#{dates.start.toDateString()} -- #{end}"
    structure.label = "#{label.red.bold}: #{totalHours.toFixed(2).red.bold} hours"


# Delay rendering until retrieval and parsing are complete
syncParsing = ->
    counter++

    if config.debug
        logger.log "Waiting (#{counter} of #{maxCount})" if maxCount > 1

    if callsComplete and counter >= maxCount
        setRootLabel()
        showCompleteLog()


# Sorts tasks by client and project
insertEntry = (entry) ->
    return if entry.hours == 0 && config.skipEmpty

    client = entry.client
    project = entry.project
    task = entry.task
    time = entry.hours
    note = entry.notes or "Unnoted"
    note += " (running)".red.bold if entry.timer_started_at

    # Ensure the structure exists
    entries[client] = {name: client, total: 0.00, projects: {}} unless entries[client]
    entries[client].projects[project] = {name: project, total: 0.00, tasks: {}} unless entries[client].projects[project]
    entries[client].projects[project].tasks[task] = {name: task, total: 0.00, notes: {}} unless entries[client].projects[project].tasks[task]
    entries[client].projects[project].tasks[task].notes[note] = {name: note, total: 0.00} unless entries[client].projects[project].tasks[task].notes[note]

    totalHours += time
    entries[client].total += time
    entries[client].projects[project].total += time
    entries[client].projects[project].tasks[task].total += time
    entries[client].projects[project].tasks[task].notes[note].total += time

# Filters out all entries that has 0 hours if the skipEmpty config is set
filterEntries = (entries) ->
    entries.filter (entry) -> !(config.skipEmpty && entry.hours == 0)

# Callback to parse data from Harvest and synchronise multiple callouts
parseData = (err, tasks) ->
    logger.error err if err?
    
    if !config.outputJson
        if tasks.day_entries
            for task in tasks.day_entries
                insertEntry task
        syncParsing()
    else if tasks.day_entries
        console.log(JSON.stringify filterEntries tasks.day_entries)


# Dummy callback to prevent duplicating parsing
dummyCallback = (err, tasks) ->


# Main function to retrieve and output tasks for a range of dates
dayRange = (from, to) ->
    options = {}
    d = chrono.parseDate from
    end = chrono.parseDate to
    start = new Date d.setDate d.getDate() - 1

    if config.debug
        logger.log "Start: #{d.toDateString()}"
        logger.log "End: #{end.toDateString()}"

    # Make the dates accessible throughout the scope
    dates =
        start: start
        end: end

    while start < end
        maxCount++
        options.date = start = new Date start.setDate start.getDate() + 1
        callback = if maxCount is 1 then parseData else dummyCallback
        callsComplete = true if start >= end
        if config.debug
            logger.log "Callouts are complete" if callsComplete

        time.daily options, callback


# Show the logged time for a day, defaulting to today
exports.day = (date = "today") ->
    # Set the called method for printing the main label
    calledMethod = "day"

    d = chrono.parseDate date
    dayRange d.toDateString(), d.toDateString()


# Show the logged time for an entire week, defaulting to this week
exports.week = (date = "today") ->
    startOfWeek = config.startOfWeek or "Monday"

    # Set the called method for printing the main label
    calledMethod = "week"

    given = chrono.parseDate date

    date = "#{startOfWeek} before #{given.toDateString()}"

    first = chrono.parseDate date
    last = new Date first.getTime()
    last = new Date last.setDate last.getDate() + 6
    dayRange first.toDateString(), last.toDateString()

exports.range = dayRange
