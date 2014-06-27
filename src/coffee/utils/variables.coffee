  # Save a reference to some core methods.
  toString = {}.toString

  # Regular expressions
  NAMESPACE_EXP = /^[0-9A-Z_.]+[^_.]?$/i

  # storage for internal usage
  storage =
    regexps:
      date:
        iso8601: /// ^
            (\d{4})\-(\d{2})\-(\d{2})                         # date
            (?:
              T(\d{2})\:(\d{2})\:(\d{2})(?:(?:\.)(\d{3}))?    # time
              (Z|[+-]\d{2}\:\d{2})?                           # timezone
            )?
          $ ///
      object:
        array: /\[(.*)\]/
        number: /(-?[0-9]+)/
    modules:
      Core: {}
