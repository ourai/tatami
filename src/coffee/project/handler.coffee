  storage.modules.handler =
    handlers: [
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
        # 将指定处理函数从沙盒中删除
        # 
        # @method  dequeue
        # @return
        ###
        name: "dequeue"

        handler: removeHandler

        validator: ( name ) ->
          return @isString(name) or @isArray(name)

        value: false
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
      }
    ]
