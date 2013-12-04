# Primary: time tracking actions
'use strict'

timer = require("./harvest").TimeTracking
file = require "./file"
alias = require "./alias"
crypto = require "crypto"
logger = require "loggy"
colors = require "colors"

config = file.config()
action = updateNote = messageType = oldTaskString = oldTaskNote = ""
rebuilt = false


# Add timer to the cache history for resume
trackHistory = (data) ->
    history = file.history()

    # Ensure history structure exists
    history.entries[data.project_id] = {} unless history.entries[data.project_id]
    history.entries[data.project_id][data.task_id] = {items: []} unless history.entries[data.project_id][data.task_id]

    # Add a new entry to the named history
    hashString = if data.notes then data.notes.toLowerCase() else "unnoted"
    if not history.entries[data.project_id][data.task_id][hashString]?
        history.entries[data.project_id][data.task_id][hashString] = data
        history.entries[data.project_id][data.task_id].items.push data

    # Add a new entry to the queue history
    last = history.chrono.pop()
    history.chrono.push last
    if last isnt data.id
        history.chrono.push data.id

    # Remove first entry if null
    first = history.chrono.shift()
    history.chrono.unshift first if first?

    # Save the file
    if config.debug
        logger.log "Writing history", history
    file.save file.files.history, history


# Build parameters to post to Harvest
parseOptions = (taskString, time = "", note = "") ->
    arr = taskString.split "."
    project = alias.get arr[0], "project"
    task = alias.get arr[1], "task"
    hours = ""

    if time.match /^\+?\d+(\.|:)\d+$/
        time = time.replace "+", ""

        # convert HH:MM to HH.MM
        if time.match /:/
            time_parts = time.split ":"
            hours = time_parts[0...1].pop()
            minutes = time_parts[1...2].pop()
            time = parseInt(hours) + parseInt(minutes)/60

        hours = parseFloat time
    else if time
        # Time doesn't look like a time entry and note is empty, so assume time is a note
        if not note
            note = time
        else
            note = time + " " + note

    {
        project_id: project
        task_id: task
        spent_at: generateTimeStamp()
        hours: hours
        notes: note
    }


# Endpoint callbacks from Harvest API

# Output stop message
sendNotice = (err, data) ->
    if err
        logger.error err
    else
        trackHistory data
        message = switch messageType
            when "log" then "Logged #{data.hours} hours for #{data.task} in #{data.project} (#{data.client})."
            when "start" then "Started timer for #{data.task} in #{data.project} (#{data.client})."
            when "stop" then "Stopped timer for #{data.task} in #{data.project} (#{data.client}). #{data.hours} hours logged."
            when "update" then "Updated notes for #{data.task} in #{data.project} (#{data.client}) to #{data.notes}."
            else "Complete"

        if messageType = "start" and data.hours > 0
            message += " #{data.hours} hours already logged."

        logger.success message
        process.exit 0


# Stop the timer if it is running
stopTimer = (err, data) ->
    logger.error err if err
    messageType = "stop"
    if not data.timer_started_at?
        rebuildHistory() unless rebuilt
    else
        timer.toggleTimer data, sendNotice


# Start the timer if it isn't running
startTimer = (err, data) ->
    logger.error err if err
    messageType = "start"

    # Expected timer is already running or doesn't exist
    if data.timer_started_at? or not data.id?
        rebuildHistory() unless rebuilt
    else if data.id
        timer.toggleTimer data, sendNotice


# Update the timer if it is running
updateTimer = (err, data) ->
    logger.error err if err
    messageType = "update"
    data.notes = updateNote
    if not data.timer_started_at?
        rebuildHistory() unless rebuilt
    else
        timer.update data, sendNotice


# Helper Functions

# Gets the time entry before triggering an actual action
checkTimer = (entry, cb) ->
    if config.debug
        logger.log "Getting entry #{ entry }"
    if entry
        data =
            id: entry
        timer.get data, cb
    else
        rebuildHistory() unless rebuilt

# Create the timestamp Harvest expects for spent_at
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


# Find the entry in cached history
getHistoryItem = (entry, note) ->
    history = file.history()
    details = parseOptions entry, note
    item = {}

    if history.entries[details.project_id] and history.entries[details.project_id][details.task_id]
        hash = details.notes.toLowerCase()
        if config.debug
            logger.log "Looking in entries for #{hash}"
            logger.log history.entries[details.project_id][details.task_id][hash]
        item = if history.entries[details.project_id][details.task_id][hash]? then history.entries[details.project_id][details.task_id][hash] else history.entries[details.project_id][details.task_id].items.pop()
        item


getHistoryEntry = (entry, note) ->
    history = file.history()
    end = history.chrono.length
    match = false

    if typeof entry is "number"
        if config.debug
            "Number entry is #{entry}"
        if entry < 0 <= end - entry
            index = end + entry
            match = history.chrono[index-1...index].pop()
        else if entry < end
            match = history.chrono[entry-1...entry].pop()
    else if typeof entry is "string" and entry.length > 0
        item = getHistoryItem entry, note
        match = item.id if item?

    # Default to the last logged timer
    if not match
        match = file.history().chrono.pop()

    if config.debug
        logger.log "Historical entry detected as #{match}"
    match


# Polls Harvest for full history and rewrites existing
rebuildHistory = ->
    if config.debug
        logger.info "Rebuilding today's history because I could not find the correct timer."

    timer.daily {}, (err, data) ->
        if not rebuilt
            rebuilt = true
            logger.error err if err?
            currentTimer = {}

            if data.day_entries
                for task in data.day_entries
                    trackHistory task
                    lastTimer = task
                    if task.timer_started_at
                        currentTimer = task

            # Else, just follow through the callback
            # If we have a running timer, assume it's the one
            if currentTimer.id?
                if config.debug
                    logger.info "Found a running timer"
                trackHistory currentTimer

            switch action
                when "resume" then resume oldTaskString, oldTaskNote
                when "pause" then pause()
                when "note" then setNote updateNote


# Exported functions

# Show the logged time for a day, defaulting to today
exports.log = (task, time = "", note = "") ->
    options = parseOptions task, time, note
    messageType = "log"
    timer.create options, sendNotice


# Start a new timer
exports.start = (task, time = "", note = "") ->
    options = parseOptions task, time, note
    messageType = "start"
    timer.create options, sendNotice


# Pause the running timer
exports.pause = pause = ->
    action = "pause"
    checkTimer file.history().chrono.pop(), stopTimer


# Resume a stopped timer
exports.resume = resume = (entry, note = "") ->
    action = "resume"
    oldTaskString = entry
    oldTaskNote = note
    # logger.log timer.api.service.run.addListener
    task = getHistoryEntry entry, note
    checkTimer task, startTimer


# Update the running timer with a new note
exports.note = setNote = (note = "") ->
    action = "note"
    updateNote = note
    checkTimer file.history().chrono.pop(), updateTimer
