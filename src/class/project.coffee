# Secondary: Project resource class
'use strict'

# Internal modules
Resource = require "./class/resource"

class Project extends Resource
    # The resource type
    name: "project"

# Our export
modules.export = Project

