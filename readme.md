# Sow

You can only reap what you sow in any Harvest. For the CLI junkies, waiting for
a web page to load and react can be frustrating. Sow helps relieve that
frustration by making it possible to interact with Harvest without needing to
wait on the web UI. Hopefully, this will help you sow faster and reap more in
Harvest!

Early inspiration came from the original CLI utility for Harvest written in Ruby
by Zach Hobson, [hcl](https://github.com/zenhob/hcl). The CLI is kept lean thanks
to the NodeJS-based API for Harvest, [harvest](https://github.com/log0ymxm/node-harvest)
by Paul English.



## Installation

    $ npm install -g sow



## Usage

Sow focuses on time entry and history. Its aim is to make it easy to do CRUD-
like actions on time tracking, and produce some very simple reports all from the
CLI. Most commands have a shortcut as well to make usage as fast as possible.



### Utility Commands

* init

 Guided prompts to create an initial configuration. For the optimist, the base
 config items can be passed as options. Unless --force is used, this will test
 the settings and prompt in the case of a failure. Can also be called using the
 `setup` command.

 Parameters: [--subdomain <subdomain>] [--email <email_address>] [--password <password>] [--force]



### Resource Commands

Harvest provides multiple resources, with the primary ones being clients,
projects, tasks, and users. All resource commands have an option to select the
resource type: --type. These can be either singular or plural or even a single
letter. Valid Resource types are:
 1. Project (project, projects, p) [default]
 2. Client (client, clients, c)
 3. Task (task, tasks, t)
 4. User (user, users, u)


* alias [a]

 Create an alias for a resource. The alias must be unique for its type and
 cannot contain dots (.). The second parameter can be either the resource's ID
 (if known) or a string for fuzzy searching. If multiple matches are found by
 the search, the first 9 medium or strong matches will be provided as options
 from which you can choose the correct client.

 Parameters: [--type <resource_type>] <alias> <target_resource>

        $ sow alias cool "Cool Project" // Set a project alias for Cool Project
        $ sow a -t c joeco Joe // Set a client alias for Joe, Corp
        $ sow alias --type tasks design "Print Design" // Set a task alias for Print Design


* aliases [la]

 Shows all aliases. Optionally, this can be restricted to a single resource type.

 Parameters: [--type <resource_type>]

        $ sow aliases
        $ sow la -t c // Lists all saved client aliases


* list [ls]

 Shows all resource of a given type. This defaults to showing all active (and in
 the case of tasks, default) resources. The --all option will show inactive
 (and, for tasks, non-default) resources as well. In the case of projects, the
 --client option can restrict the listing to a given client alias.

 Parameters: [--type <resource_type>] [--client <client>] [--all]

        $ sow list // Lists all active projects
        $ sow ls -a -c joeco // List all projects for the Joe, Corp client
        $ sow ls -t t // Lists all active and default tasks



### Time Entry Commands

Entering time is a heavily opiniated thing. Sow tries to be as flexible as
possible so that you can continue doing work without worrying about entering the
right format. Most time entry commands take a few common parameters.

 - task_string identifies the project and task for the command. It can take one
 of three forms:
  1. project.task
  2. project task
  3. task@project
 In all cases, the project or task can be an alias or an ID.
 - time identifies time spent. It can be given in two different ways:
  1. Time-based:   HH:MM (e.g. 1:45)
  2. Decimal-baed: HH.mm (e.g. +1.75)
 In either case, an optional plus sign [+] can be prepended for readability.
 - comment provides a task commend. It must be in quotation marks if there is a
 space (e.g. example is fine without quotations marks, but "example thought
 here" requires them).


* log [l]

 Create a new inactive timer.

 Parameters: <task_string> <time> [comment]

        $ sow log cool design 0:45
        $ sow l cool.design +0.75
        $ sow l design@cool +0:45 "Some kind of comment"
    All examples a timer for the design task under "Cool Project" with 45 minutes


* start [s]

 Create a new running timer, optionally adding time to it.

 Parameters: <task_string> [time] [comment]

        $ sow start cool design
        $ sow s cool.design +0.75 // Add 45 minutes to the timer
        $ sow s design@cool "Some kind of comment" // Add a comment


* pause [p]

 Pause the active timer. Can also use `stop` as an alternative command.

        $ sow pause
        $ sow stop


* resume [r]

 Continue an existing timer. This has three different forms:
  1. No parameters will use the last timer created from sow.
  2. An integer, optionally using --negative to indicate a negative number, will
  indicate an index position (e.g. -n 1 will start the second to last timer).
  3. A task_string (with optional comment) will start the last timer matching
  the task_string (and comment).

 Parameters: [index] [--negative] or [task_string] [comment]

        $ sow resume
        $ sow r design@cool
        $ sow resume -n 2


* note [n]

 Updates the comment/note for the currently running timer.

 Parameters: <note>

        $ sow note "Some other comment"



### Time Reporting Commands

 Sow can provide a simple, tree-structured output for summarising time, well,
 spent. Each of the time reporting commands takes an optional parameter of a
 specific date. Sow uses the excellent [chrono](https://github.com/wanasit/chrono)
 package to parse the date string. Some examples of valid date strings include:

  - 2012-12-01
  - 11/11/2011
  - 7.11.2013
  - Yesterday
  - "Last Tuesday"


*  day [d]

 Day provides, as may be expected, a summary of a day's entries. If a date is
 not provided, today will be used.

 Parameters: [date]

        $ sow day            // Today's entries
        $ sow d 2012-12-01   // 01 Dec 2012
        $ sow day yesterday
        $ sow d "last Tuesday"


* week [w]

 Provides a summary of all entries within a week (Mon - Sun). The result will be
 for the week in which the provided date exists.

 Parameters: [date]

        $ sow week            // This week's entries
        $ sow w 2012-12-01    // Week of 01 Dec 2012


* range

 Provides a summary of all entries within a range of dates.

 Parameters: from_date to_date




## Configuration

Configuration settings are stored in a single JSON file. The init command


### Required settings

Sow requires only three settings to operate:

 1. subdomain: Harvest subdomain to use
 2. email: Your Harvest login email address
 3. password: Your Harvest login password


### Advanced settings

Sow assumes some things, but makes it possible for you to override those
assumptions without needing to alter the core files.

 1. startOfWeek: Day on which the week starts. Default is Monday.
 2. cacheLife: Number of days cached data is valid. Default is 7.
 3. matchLimit: Number of matches to display when searching resources. Default is 9.
 4. debug: Show additional debug messages. Default is false.
 5. debugHarvest: Enable debugging for the Harvest API module. Default is false.
