  storage.modules.Core.Object =
    handlers: [
      {
        ###
        # Get a set of keys/indexes.
        # It will return a key or an index when pass the 'value' parameter.
        #
        # @method  keys
        # @param   object {Object/Function}    被操作的目标
        # @param   value {Mixed}               指定值
        # @return  {Array/String}
        #
        # refer: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/keys
        ###
        name: "keys"

        handler: ( object, value ) ->
          keys = []

          @each object, ( v, k ) ->
            if v is value
              keys = k

              return false
            else
              keys.push k

          return if @isArray(keys) then keys.sort() else keys

        validator: ( object ) ->
          return object isnt null and not (object instanceof Array) and typeof object in ["object", "function"]

        value: []
      }
    ]
