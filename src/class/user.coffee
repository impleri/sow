# Primary: User resource class
'use strict'

# Internal modules
Resource = require "./class/resource"

class Task extends Resource
    # The resource type
    name: "upser"

    # Plural of @name for easier reference
    plural: "people"

# Our export
modules.export = Task

