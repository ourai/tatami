# Node-types
ELEMENT_NODE = 1
ATTRIBUTE_NODE = 2
TEXT_NODE = 3
CDATA_SECTION_NODE = 4
ENTITY_REFERENCE_NODE = 5
ENTITY_NODE = 6
PROCESSING_INSTRUCTION_NODE = 7
COMMENT_NODE = 8
DOCUMENT_NODE = 9
DOCUMENT_TYPE_NODE = 10
DOCUMENT_FRAGMENT_NODE = 11
NOTATION_NODE = 12

# Regular expressions
REG_NAMESPACE = /^[0-9A-Z_.]+[^_.]?$/i

# Main objects
$ = jQuery
_ENV =
  lang: document.documentElement.lang || document.documentElement.getAttribute("lang") || navigator.language || navigator.browserLanguage
_H = __util

_H.mask LIB_CONFIG.name
_H.__meta__ = LIB_CONFIG

# JavaScript APIs' support
support =
  storage: !!window.localStorage

# 限制器
limiter =
  ###
  # 键
  #
  # @property  key
  # @type      {Object}
  ###
  key:
    # 限制访问的 storage key 列表
    storage: ["sandboxStarted", "config", "fn", "buffer", "pool", "i18n"]

# 内部数据载体
storage =
  ###
  # 沙盒运行状态
  #
  # @property  sandboxStarted
  # @type      {Boolean}
  ###
  sandboxStarted: false

  ###
  # 配置
  #
  # @property  config
  # @type      {Object}
  ###
  config:
    debug: true
    platform: ""
    locale: _ENV.lang
    lang: _ENV.lang.split("-")[0]

  ###
  # 函数
  #
  # @property  fn
  # @type      {Object}
  ###
  fn:
    # DOM tree 构建未完成（sandbox 启动）时调用的处理函数
    prepare: []
    # DOM tree 构建已完成时调用的处理函数
    ready: []
    # 初始化函数
    init:
      # 系统对话框创建后
      systemDialog: $.noop
      # Ajax 请求
      ajaxHandler: ( succeed, fail ) ->
        return {
          # 状态码为 200
          success: ( data, textStatus, jqXHR ) ->
            args = _H.slice arguments
            ###
            # 服务端在返回请求结果时必须是个 JSON，如下：
            #    {
            #      "code": {Integer}       # 处理结果代码，code > 0 为成功，否则为失败
            #      "message": {String}     # 请求失败时的提示信息
            #    }
            ###
            if data.code > 0
              succeed.apply($, args) if _H.isFunction succeed
            else
              if _H.isFunction fail
                fail.apply $, args
              # 默认弹出警告对话框
              else
                systemDialog "alert", data.message
          # 状态码为非 200
          error: $.noop
        }
    handler: {}

  modules:
    utils: {}
    flow: {}
    project: {}
    storage: {}
    request: {}
    HTML: {}
    URL: {}

  ###
  # 缓冲区，存储临时数据
  #
  # @property  buffer
  # @type      {Object}
  ###
  buffer: {}

  ###
  # 对象池
  # 
  # @property  pool
  # @type      {Object}
  ###
  pool: {}

  ###
  # 国际化
  #
  # @property  i18n
  # @type      {Object}
  ###
  i18n:
    _SYS:
      dialog:
        zh:
          title: "系统提示"
          close: "关闭"
          ok: "确定"
          cancel: "取消"
          yes: "是"
          no: "否"
        en:
          title: "System"
          close: "Close"
          ok: "Ok"
          cancel: "Cancel"
          yes: "Yes"
          no: "No"
