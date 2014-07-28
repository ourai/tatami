  storage.fn.init.runSandbox = ( prFns, rdFns ) ->
    # 全局配置
    # setup();
    # DOM tree 构建前的函数队列
    runHandler prFns
    
    # DOM tree 构建后的函数队列
    $(document).ready ->
      runHandler rdFns

  ###
  # 重新配置系统参数
  # 
  # @private
  # @method  resetConfig
  # @param   setting {Object}      配置参数
  # @return  {Object}              （修改后的）系统配置信息
  ###
  resetConfig = ( setting ) ->
    return clone if __proj.isPlainObject(setting) then $.extend(storage.config, setting) else storage.config

  storage.modules.flow =
    handlers: [
      {
        ###
        # 沙盒
        #
        # 封闭运行环境的开关，每个页面只能运行一次
        # 
        # @method  sandbox
        # @param   setting {Object}      系统环境配置
        # @return  {Object/Boolean}      （修改后的）系统环境配置
        ###
        name: "sandbox"

        handler: ( setting ) ->
          # 返回值为修改后的系统环境配置
          result = resetConfig setting

          initializer("runSandbox") storage.fn.prepare, storage.fn.ready
          
          storage.sandboxStarted = true
          
          return result || false

        value: false

        validator: ->
          return storage.sandboxStarted isnt true
      },
      {
        ###
        # DOM 未加载完时调用的处理函数
        # 主要进行事件委派等与 DOM 加载进程无关的操作
        #
        # @method  prepare
        # @param   handler {Function}
        # @return
        ###
        name: "prepare"

        handler: ( handler ) ->
          return pushHandler handler, "prepare"
      },
      {
        ###
        # DOM 加载完成时调用的处理函数
        #
        # @method  ready
        # @param   handler {Function}
        # @return
        ###
        name: "ready"

        handler: ( handler ) ->
          return pushHandler handler, "ready"
      }
    ]
