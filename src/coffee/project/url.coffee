  # 补全 pathname 的开头斜杠
  # IE 中 pathname 开头没有斜杠（参考：http://msdn.microsoft.com/en-us/library/ms970635.aspx）
  resolvePathname = ( pathname ) ->
    return if pathname.charAt(0) is "\/" then pathname else "\/#{pathname}"

  storage.modules.URL =
    handlers: [
      {
        ###
        # 获取 URL 的 pathname
        #
        # @method   pathname
        # @param    url {String}
        # @return   {String}
        ###
        name: "pathname"

        handler: ( url ) ->
          return resolvePathname if @isString(url) then url else location.pathname
      },
      {
        name: "url"

        handler: ->
          loc = window.location
          url =
            search: loc.search.substring(1)
            hash: loc.hash.substring(1)
            query: {}

          @each url.search.split("&"), ( str ) ->
            str = str.split("=")
            url.query[str[0]] = str[1] if __proj.trim(str[0]) isnt ""

          return url
      },
      {
        ###
        # Save web resource to local disk
        #
        # @method  download
        # @param   fileURL {String}
        # @param   fileName {String}
        # @return
        ###
        name: "download"

        handler: ( fileURL, fileName ) ->
          # for non-IE
          if not window.ActiveXObject
            save = document.createElement "a"

            save.href = fileURL
            save.target = "_blank"
            save.download = fileName || "unknown"

            event = document.createEvent "Event"
            event.initEvent "click", true, true
            save.dispatchEvent event
            (window.URL || window.webkitURL).revokeObjectURL save.href
          # for IE
          else if !! window.ActiveXObject && document.execCommand
            _window = window.open fileURL, "_blank"
            
            _window.document.close()
            _window.document.execCommand "SaveAs", true, fileName || fileURL
            _window.close()
      }
    ]
