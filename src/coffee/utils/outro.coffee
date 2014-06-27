  __util = __proc storage.modules

  # Set the library' info as a meta data
  try
    Object.defineProperty __util, "__meta__",
      __proto__: null
      writable: true
      value:
        name: "__util"
        version: ""
  catch error
    __util.mixin
      __meta__:
        name: "__util"
        version: ""

  return __util
  