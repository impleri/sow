# Main logic for summarising entries
'use strict'

timer = require("./harvest").TimeTracking
file = require "./file"
alias = require "./alias"
logger = require "loggy"
colors = require "colors"
config = file.config()


# Initial callback to parse callback
trackCallback = (err, data) ->
    logger.success "Track!"
    if (err)
        logger.error err
    else
        logger.log data


toggleCallback = (err, data) ->
    logger.success "Toggle!"
    if (err)
        logger.error err
    else
        console.log data


# Helper method to ensure project and task IDs
parseAliasString = (args) ->
    arr = args.split "."
    project = alias.get arr[0], "project"
    task = alias.get arr[1], "task"
    {
        project_id: project
        task_id: task
    }


generateTimeStamp = (date = false) ->
    if date
        date = new Date date
    else
        date = new Date

    dayName = switch date.getDay()
        when 0 then "Sun"
        when 1 then "Mon"
        when 2 then "Tue"
        when 3 then "Wed"
        when 4 then "Thu"
        when 5 then "Fri"
        when 6 then "Sat"

    monthName = switch date.getMonth()
        when 0 then "Jan"
        when 1 then "Feb"
        when 2 then "Mar"
        when 3 then "Apr"
        when 4 then "May"
        when 5 then "Jun"
        when 6 then "Jul"
        when 7 then "Aug"
        when 8 then "Sep"
        when 9 then "Oct"
        when 10 then "Nov"
        when 11 then "Dec"

    # Tue, 17 Oct 2006
    "#{ dayName }, #{ date.getDate() } #{ monthName } #{ date.getFullYear() }"

# Show the logged time for a day, defaulting to today
exports.log = logTime = (date = false) ->
    # project(.| )task [comment]
    calledMethod = "day"
    d = getDate date
    dayRange d.toDateString(), d.toDateString()


# Start a new timer
exports.start = startTimer = (task, time = "", note = "") ->
    options = parseAliasString task
    options.spent_at = generateTimeStamp()
    options.notes = note
    options.hours = ""
    cb = trackCallback

    if time.match /[+]?[0-9]+[\.:][0-9]+/
        options.hours = time.replace "+", ""
        cb = toggleCallback

    if config.debug
        logger.log options

    timer.create options, cb


exports.pause = pauseTimer = (date = false) ->

exports.resume = startTimer = (date = false) ->
