  storage.modules.dialog =
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
