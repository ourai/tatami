  # storage.modules.HTML =
  #   handlers: [
  #     {
  #       name: "encodeEntities"

  #       handler: ( string ) ->
  #         return if @isString(string) then string.replace /([<>&\'\"])/g, ( match, chr ) ->
  #           switch chr
  #             when "<"
  #               et = "lt"
  #             when ">"
  #               et = "gt"
  #             when "\""
  #               et = "quot"
  #             when "'"
  #               et = "apos"
  #             when "&"
  #               et = "amp"

  #           return "&#{et};"
  #         else string

  #     }
  #     # ,
  #     # {
  #     #   name: "decodeEntities"

  #     #   handler: ( string ) ->
  #     # }
  #   ]
