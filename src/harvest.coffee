harvestClass = require "harvest"
harvest = new harvestClass
    subdomain: config.harvest.subdomain,
    email: config.harvest.email,
    password: config.harvest.password

TimeTracking = harvest.TimeTracking

TimeTracking.daily date: "", (err, tasks) ->
    if (err)
        throw new Error err
        false
    else
        true
