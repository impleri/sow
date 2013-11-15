# Sow

You can only reap what you sow in any Harvest. For the CLI junkies, waiting for a
web page to load and react can be frustrating. Sow helps relieve that frustration
by making it possible to interact with Harvest without needing to wait on the web
UI. Hopefully, this will help you sow faster and reap more in Harvest!

## Installation

    $ npm install -g sow


## Usage

Sow focuses on time entry and history. Its aim is to make it easy to do CRUD-like
actions on time tracking, and produce some very simple reports all from the CLI.
Most commands have a shortcut as well to make usage as fast as possible.


### alias [a]

Create an alias for a resource. Aliases can be created for clients, projects, and
tasks
The alias must be unique for its type and cannot
contain dots (.).
The client parameter can be either the client ID (if known) or a string for
searching. If multiple matches are found, they will be provided as options from
which you can choose the correct client.

Parameters: [--type = project] alias resource

### start [s]

Start a new timer, optionally adding time to it.

Parameters: project(.| )task [time] [comment]


### pause [p]

Pause the active timer.


### resume [r]

Continue an existing timer.

Parameters: project(.| )task [comment]


### log [l]

Create a new stopped timer.

Parameters: project(.| )task time [comment]


### summary [sum]

Summary provides, as may be expected, a summary of a day's entries. A specific day
may be passed as a parameter in a format readable by Date.parse and without any
timezone handling. If a date is not provided, sow will default to today.

Parameters: [date]

    $ sow summary            // Today's entries
    $ sow s 2012-12-01 // 01 Dec 2012
    $ sow summary 11/11/2011 // 11 Nov 2011
    $ sow s 7.11.2013  // 11 July 2013


### week [w]

Provides a summary of all entries within a set week. A date may be passed as a
parameter in a format readable by Date.parse. If a date is provided, the result
will be for the week (Mon - Sun) in which that date exists.

Parameters: [date]

