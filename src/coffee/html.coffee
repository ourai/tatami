_H.mixin
  encodeEntities: ( string ) ->
    return if @isString(string) then string.replace /([<>&\'\"])/, ( match, chr ) ->
      switch chr
        when "<"
          et = lt
        when ">"
          et = gt
        when "\""
          et = quot
        when "'"
          et = apos
        when "&"
          et = amp

      return "&#{et};"
    else string

  decodeEntities: ( string ) ->
