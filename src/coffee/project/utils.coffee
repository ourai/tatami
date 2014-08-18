  storage.modules.utils =
    handlers: [
      {
        ###
        # 自定义警告提示框
        #
        # @method  alert
        # @param   message {String}
        # @param   [callback] {Function}
        # @return  {Boolean}
        ###
        name: "alert"

        handler: ( message, callback ) ->
          return systemDialog "alert", message, callback
      },
      {
        ###
        # 自定义确认提示框（两个按钮）
        #
        # @method  confirm
        # @param   message {String}
        # @param   [ok] {Function}       Callback for 'OK' button
        # @param   [cancel] {Function}   Callback for 'CANCEL' button
        # @return  {Boolean}
        ###
        name: "confirm"

        handler: ( message, ok, cancel ) ->
          return systemDialog "confirm", message, ok, cancel
      },
      {
        ###
        # 自定义确认提示框（两个按钮）
        #
        # @method  confirm
        # @param   message {String}
        # @param   [ok] {Function}       Callback for 'OK' button
        # @param   [cancel] {Function}   Callback for 'CANCEL' button
        # @return  {Boolean}
        ###
        name: "confirmEX"

        handler: ( message, ok, cancel ) ->
          return systemDialog "confirmEX", message, ok, cancel
      },
      {
        ###
        # 将外部处理函数引入到沙盒中
        # 
        # @method  queue
        # @return
        ###
        name: "queue"

        handler: ->
          return bindHandler.apply window, @slice arguments
      },
      {
        ###
        # 执行指定函数
        # 
        # @method  run
        # @return  {Variant}
        ###
        name: "run"

        handler: ->
          return runHandler.apply window, @slice arguments
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
      },
      {
        ###
        # Determines whether a function has been defined
        #
        # @method  functionExists
        # @param   funcName {String}
        # @param   isWindow {Boolean}
        # @return  {Boolean}
        ###
        name: "functionExists"

        handler: ( funcName, isWindow ) ->
          return isExisted (if isWindow is true then window else storage.fn.handler), funcName, "function"
      },
      {
        ###
        # 销毁系统对话框
        #
        # @method   destroySystemDialogs
        # @return   {Boolean}
        ###
        name: "destroySystemDialogs"

        handler: ->
          dlgs = storage.pool.systemDialog

          if @isFunction($.fn.dialog) and @isPlainObject(dlgs)
            @each dlgs, ( dlg ) ->
              dlg
                .dialog "destroy"
                .remove()

            dlgs = storage.pool.systemDialog = {}

          return @isEmpty dlgs
      }
    ]
