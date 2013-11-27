# Simple reporting of logged tasks for date ranges
'use strict'

time = require("./harvest").TimeTracking
config = require("./file").config()
logger = require "loggy"
colors = require "colors"
chrono = require "chrono-node"
archy = require "archy"

totalHours = 0.00
counter = maxCount = 0
callsComplete = false
calledMethod = ""
dates = entries = {}
structure =
    label: ""
    nodes: []

# Constructs an object to render in archy
orderNodes = (client) ->
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
        orderNodes client

    console.log ""
    console.log archy structure


# Helper function to set the root label of the archy structure
setRootLabel = ->
    label = switch calledMethod
        when "day" then dates.end.toDateString()
        when "week" then "Week ending #{dates.end.toDateString()}"
        else "#{dates.start.toDateString()} -- #{dates.end.toDateString()}"
    structure.label = "#{label.red.bold}: #{totalHours.toFixed(2).red.bold} hours"


# Helper callback function to delay rendering until retrieval and parsing are complete
syncParsing = ->
    counter++

    if config.debug
        logger.log "Waiting (#{counter} of #{maxCount})" if maxCount > 1

    if callsComplete and counter >= maxCount
        setRootLabel()
        showCompleteLog()


# Sorts tasks by client and project
sortTasks = (entry) ->
    client = entry.client
    project = entry.project
    task = entry.task
    time = entry.hours
    note = entry.notes || "Unnoted"

    if entry.timer_started_at
        note += " (running)".red.bold

    if (!entries[client])
        entries[client] = {name: client, total: 0.00, projects: {}}

    if (!entries[client].projects[project])
        entries[client].projects[project] = {name: project, total: 0.00, tasks: {}}

    if (!entries[client].projects[project].tasks[task])
        entries[client].projects[project].tasks[task] = {name: task, total: 0.00, notes: {}}

    if (!entries[client].projects[project].tasks[task].notes[note])
        entries[client].projects[project].tasks[task].notes[note] = {name: note, total: 0.00}

    totalHours += time
    entries[client].total += time
    entries[client].projects[project].total += time
    entries[client].projects[project].tasks[task].total += time
    entries[client].projects[project].tasks[task].notes[note].total += time


# Callback to parse data from Harvest and synchronise multiple callouts
summaryCallback = (err, tasks) ->
    if err
        logger.error err
    else
        if tasks.day_entries
            for task in tasks.day_entries
                sortTasks task
        syncParsing()


# Dummy callback to prevent duplicating parsing
dummyCallback = (err, tasks) ->


# Small helper to parse a given date
getDate = (date = false) ->
    date = "today" unless date
    chrono.parseDate(date)


# Show the logged time entries for a range of dates
exports.range = dayRange = (from, to) ->
    options = {}
    d = getDate from
    end = getDate to

    if config.debug
        logger.log "Start: #{d.toDateString()}"
        logger.log "End: #{end.toDateString()}"

    start = new Date d.setDate d.getDate() - 1
    dates = {
        start: start
        end: end
    }

    while start < end
        maxCount++
        options.date = start = new Date start.setDate start.getDate() + 1
        callback = if maxCount is 1 then summaryCallback else dummyCallback
        callsComplete = true if start >= end
        if config.debug
            logger.log "Callouts are complete" if callsComplete

        time.daily options, callback


# Show the logged time for a day, defaulting to today
exports.day = dayDate = (date = false) ->
    calledMethod = "day"
    d = getDate date
    dayRange d.toDateString(), d.toDateString()


# Show the logged time for an entire week, defaulting to this week
exports.week = dayWeek = (date = false) ->
    calledMethod = "week"
    startOfWeek = config.startOfWeek or "Monday"

    if date
        date = "#{startOfWeek} before #{date}"
    else
        date = "last #{startOfWeek}"

    first = getDate date
    last = new Date first.getTime()
    last = new Date last.setDate last.getDate() + 6
    dayRange first.toDateString(), last.toDateString()

