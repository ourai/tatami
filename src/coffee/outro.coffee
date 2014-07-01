_H.extend storage.modules, _H

_H.api.formatList = ( map ) ->
  API.config keys: map if _H.isPlainObject map

_H.route.formatList = ( map ) ->
  route.config keys: map if _H.isPlainObject map

window[LIB_CONFIG.name] = _H
