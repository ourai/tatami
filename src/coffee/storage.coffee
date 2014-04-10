###
# 通过 HTML 构建 dataset
# 
# @private
# @method  constructDatasetByHTML
# @param   html {HTML}   Node's outer html string
# @return  {JSON}
###
constructDatasetByHTML = ( html ) ->
  dataset = {}
  fragment = html.match /<[a-z]+[^>]*>/i

  if fragment isnt null
    $.each fragment[0].match(/(data(-[a-z]+)+=[^\s>]*)/ig) || [], ( idx, attr ) ->
      attr = attr.match /data-(.*)="([^\s"]*)"/i
      dataset[$.camelCase attr[1]] = attr[2]
      return true

  return dataset

###
# 通过属性列表构建 dataset
# 
# @private
# @method  constructDatasetByAttributes
# @param   attributes {NodeList}   Attribute node list
# @return  {JSON}
###
constructDatasetByAttributes = ( attributes ) ->
  dataset = {}

  $.each attributes, ( idx, attr ) ->
    dataset[$.camelCase match(1)] = attr.nodeValue if attr.nodeType is ATTRIBUTE_NODE and (match = attr.nodeName.match /^data-(.*)$/i)
    return true

  return dataset

_H.mixin
  ###
  # 获取 DOM 的「data-*」属性集或存储数据到内部/从内部获取数据
  # 
  # @method  data
  # @return  {Object}
  ###
  data: ->
    args = arguments
    length = args.length

    if length > 0
      target = args[0]

      try
        # 当 target 是包含有 "@" 的字符串时会抛出异常。
        # Error: Syntax error, unrecognized expression: @
        node = $(target).get(0)
      catch error
        node = target

      # 获取 DOM 的「data-*」属性集
      if node and node.nodeType is ELEMENT_NODE
        result = {}

        if node.dataset
          result = node.dataset
        else if node.outerHTML
          result = constructDatasetByHTML node.outerHTML
        else if node.attributes and $.isNumeric node.attributes.length
          result = constructDatasetByAttributes node.attributes
      # 存储数据到内部/从内部获取数据
      else
        if typeof target is "string" and REG_NAMESPACE.test(target)
          result = if length is 1 then getStorageData(target) else setStorageData target, args[1]

          # 将访问的 key 锁住，在第一次设置之后无法再读写到内部
          limit(target.split(".")[0]) if length > 1 and last(args) is true
        # 有可能覆盖被禁止存取的内部 key，暂时不允许批量添加
        # else {
        #   $.each(args, function( i, n ) {
        #     $.extend(storage, n);
        #   });
        # }

    return result ? null

  ###
  # Save data
  ###
  save: ->
    args = arguments
    key = args[0]
    val = args[1]

    # Use localStorage
    if support.storage
      if typeof key is "string"
        oldVal = this.access key

        localStorage.setItem key, escape if @isPlainObject(oldVal) then JSON.stringify($.extend oldVal, val) else val
    # Use cookie
    # else

  ###
  # Access data
  ###
  access: ->
    key = arguments[0]

    if typeof key is "string"
      # localStorage
      if support.storage
        result = localStorage.getItem key

        if result isnt null
          result = unescape result

          try
            result = JSON.parse result
          catch error
            result = result
      # Cookie
      # else

    return result || null

  # clear: ->
