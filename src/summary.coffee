# Main logic for Harvest

harvest = require "./harvest_wrapper"
time = harvest.TimeTracking

logger = require "loggy"
colors = require "colors"
archy = require "archy"

totalHours = 0.00
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


getDate = (date = false) ->
    d = new Date

    if (date)
        d = new Date date

        # Hack to account for current timezone
        d.setTime d.getTime() + d.getTimezoneOffset()*60*1000

    d

getHarvestLog = (options) ->
    done = false
    success = false
    dead = 0

    time.daily options, (err, tasks) ->
        if (err)
            logger.error err
        else
            tasks.day_entries.forEach (task, index, array) ->
                sortTasks task
            if options.callback
                options.callback options.cbParam

showCompleteLog = (text) ->
    for index, client of entries
        orderNodes client

    structure.label = text.red.bold + ": " + totalHours.toFixed(2).red.bold + " hours"
    s = archy(structure)
    console.log s

# Show the logged time for a day, defaulting to today
exports.day = (date = false) ->
    options = {}
    options.date = d = getDate date
    options.callback = showCompleteLog
    options.cbParam = d.toDateString()

    getHarvestLog options

# Show the logged time for an entire week, defaulting to this week
exports.week = (date = false) ->
    options = {}
    d = getDate date

    first = d.getDate() - d.getDay() + 1
    last = first + 6

    d.setDate(first)
    start = new Date d
    logger.log "Start: " + start

    d.setDate(last)
    end = new Date d
    logger.log "End: " + end

    d = start

    while (start < end)
        d = start.setDate start.getDate() + 1
        options.date = start = new Date d
        logger.log "Polling for " + start

        if !(start < end)
            logger.success "Last Day!"
            options.callback = showCompleteLog
            options.cbParam = "Week ending " + end.toDateString()

        getHarvestLog options
