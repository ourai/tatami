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

# Main objects for internal usage
_H = {}

# JavaScript API's support
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
    storage: ["sandboxStarted", "config", "fn", "buffer", "pool", "i18n", "web_api"]
