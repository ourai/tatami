  __proj.extend storage.modules, __proj

  __proj.api.formatList = ( map ) ->
    API.config keys: map if __proj.isPlainObject map

  __proj.route.formatList = ( map ) ->
    route.config keys: map if __proj.isPlainObject map

  __proj.mixin new Environment

  exposeClasses()

  return __proj
  