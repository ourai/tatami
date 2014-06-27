  # Save a reference to some core methods.
  toString = {}.toString

  # default settings
  settings =
    validator: ->
      return true

  # storage for internal usage
  storage =
    # map of object types
    types: {}
