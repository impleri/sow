# Main logic for summarising entries

harvest = require "./harvest"
file = require "./file"
logger = require "loggy"
colors = require "colors"
chrono = require "chrono-node"
archy = require "archy"

time = harvest.TimeTracking
config = file.read file.files.config
totalHours = 0.00
counter = maxCount = 0
debug = false
callsComplete = false
calledMethod = ""
dates = {}
entries = {}
structure = {
    label: ""
    nodes: []
}

# Sorts tasks by client and project
sortTasks = (entry) ->
    client = entry.client
    project = entry.project
    task = entry.task
    time = entry.hours
    note = entry.notes || "Unnoted"

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


# Constructs an object for archy
orderNodes = (client) ->
    clientNodes = []
    for index, project of client.projects
        projectNodes = []
        for index, task of project.tasks
            taskNodes = []
            for index, note of task.notes
                taskNodes.push note.total.toFixed(2) + " hours: " + note.name.italic
            projectNodes.push
                label: task.name.yellow + " (" + task.total.toFixed(2).yellow + " hours)"
                nodes: taskNodes
        clientNodes.push
            label: project.name.cyan + " (" + project.total.toFixed(2).cyan + " hours)"
            nodes: projectNodes
    structure.nodes.push
        label: client.name.green.bold + " (" + client.total.toFixed(2).green.bold + " hours)"
        nodes: clientNodes


# Small helper to parse a given date
getDate = (date = false) ->
    if (!date)
        date = "today"
    d = chrono.parseDate(date)

    if debug
        logger.log "Date:", d

    d

# Render the output
showCompleteLog = ->
    if debug
        logger.log "Showing text"

    for index, client of entries
        orderNodes client

    console.log archy structure


# Set the root label for archy
setRootLabel = (text) ->
    structure.label = text.red.bold + ": " + totalHours.toFixed(2).red.bold + " hours"


# Yet another callback to wait for parsing to finish
waitCallback = ->
    counter++
    if debug
        logger.log "Calls complete", callsComplete
        logger.log "Waiting", counter, maxCount
    if callsComplete and counter >= maxCount
        if debug
            logger.log "Ready to show"

        if calledMethod == "day"
            setRootLabel dates.end.toDateString()
        else if calledMethod == "week"
            setRootLabel "Week ending " + dates.end.toDateString()
        else
            setRootLabel dates.start.toDateString() + " -- " + dates.end.toDateString()
        showCompleteLog()


# Initial callback to parse callback
parseHarvestLog = (err, tasks) ->
    if (err)
        logger.error err
    else
        if tasks.day_entries
            tasks.day_entries.forEach (task, index, array) ->
                sortTasks task
        waitCallback()


# Dummy callback to prevent duplicating parsing
dummyHarvestCb = (err, tasks) ->


# Simple wrapper to the Harvest API that serves to create the restler callback
getHarvestLog = (options) ->
    callback = if maxCount == 1 then parseHarvestLog else dummyHarvestCb
    if debug
        logger.log "Callback:", callback
    time.daily options, callback


# Show the logged time entries for a range of dates
exports.range = dayRange = (from, to) ->
    options = {}
    d = getDate from
    end = getDate to

    if debug
        logger.log "Start:", d
        logger.log "End:", end

    start = new Date d.setDate d.getDate() - 1
    dates = {
        start: start
        end: end
    }

    while (start < end)
        options.date = start = new Date start.setDate start.getDate() + 1
        maxCount++
        callsComplete = true if start >= end
        getHarvestLog options


# Show the logged time for a day, defaulting to today
exports.day = dayDate = (date = false) ->
    calledMethod = "day"
    d = getDate date
    dayRange d.toDateString(), d.toDateString()


# Show the logged time for an entire week, defaulting to this week
exports.week = dayWeek = (date = false) ->
    calledMethod = "week"
    startOfWeek = config.startOfWeek || "Monday"
    first = getDate "last " + startOfWeek
    last = new Date first.getTime()
    last = new Date last.setDate last.getDate() + 6

    if debug
        logger.log "Start:", first
        logger.log "End:", last

    dayRange first.toDateString(), last.toDateString()
