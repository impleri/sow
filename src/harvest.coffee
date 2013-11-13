# Main logic for Harvest

logger = require "loggy"
archy = require "archy"
file = require "./file"
harvestClass = require "harvest"

config = file.read file.files.config
totalHours = 0.00
entries = {}
structure = {
    label: ""
    nodes: []
}

if (!config)
    logger.err "Configuration is needed"

harvest = new harvestClass
    subdomain: config.subdomain
    email: config.email
    password: config.password

time = harvest.TimeTracking

# Sorts tasks by client and project
sortTasks = (task) ->
    client = task.client
    project = task.project

    if (!entries[client])
        entries[client] = {name: client, total: 0.00, projects: {}}

    if (!entries[client].projects[project])
        entries[client].projects[project] = {name: project, total: 0.00, entries: []}

    entries[client].total += task.hours
    entries[client].projects[project].total += task.hours
    totalHours += task.hours

    note = task.notes || "Entry"
    entries[client].projects[project].entries.push note: note, time: task.hours

orderNodeEntries = (entry) ->
    {
        label: entry.time + " hours: " + entry.note
        nodes: []
    }


orderNodes = (client) ->
    clientNodes = []
    for index, project of client.projects
        projectNodes = []
        projectNodes.push orderNodeEntries entry for entry in project.entries
        clientNodes.push
            label: project.name + " (" + project.total + " hours)"
            nodes: projectNodes
    structure.nodes.push
        label: client.name + " (" + client.total + " hours)"
        nodes: clientNodes


# Show the logged time for a day, defaulting to today
exports.summary = (date = false) ->
    options = {}

    if (date)
        options.date = new Date date

        first = new Date options.date.getFullYear(), 0, 1
        day_of_year = Math.round ((options.date - first) / 1000 / 60 / 60 / 24) + .5, 0

        logger.log first, day_of_year

    time.daily options, (err, tasks) ->
        if (err)
            logger.error err
        else
            tasks.day_entries.forEach (task, index, array) ->
                sortTasks task

            for index, client of entries
                orderNodes client

            structure.label =  totalHours + " hours"
            s = archy(structure)
            console.log s

