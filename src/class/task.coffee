# Primary: Task resource class
'use strict'

# Internal modules
Resource = require "./class/resource"

class Task extends Resource
    # The resource type
    name: "task"

# Our export
modules.export = Task

