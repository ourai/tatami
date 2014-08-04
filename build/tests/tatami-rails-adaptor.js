(function() {
  var addHandlers, handlerExists, handlerName, pageHandlers, runHandlers, turbolinksEnabled;

  turbolinksEnabled = this.Turbolinks && this.Turbolinks.supported === true;

  pageHandlers = new Tatami.__class__.Storage("pageHandlers");

  handlerName = function(func) {
    return func.toString().length.toString(16) + "";
  };

  handlerExists = function(page, func) {
    return this.equal(func, pageHandlers.get("" + page + "." + (handlerName(func))));
  };

  addHandlers = function(page, func, isPlain) {
    var handlers;
    handlers = {};
    this.each(page, (function(_this) {
      return function(flag, idx) {
        var name;
        if (isPlain) {
          func = flag;
          flag = idx;
        }
        if (!handlerExists.apply(_this, [flag, func])) {
          name = handlerName(func);
          _this.namespace(handlers, "" + flag + "." + name);
          return handlers[flag][name] = func;
        }
      };
    })(this));
    return pageHandlers.set(handlers);
  };

  runHandlers = function(page, func, isPlain) {
    return this.each(page, function(flag, idx) {
      if (isPlain) {
        func = flag;
        flag = idx;
      }
      if ($("body").is("[data-page='" + flag + "']")) {
        func();
        return false;
      }
    });
  };

  Tatami.extend({
    handlers: [
      {
        name: "inPage",
        handler: function(page, func) {
          var args, isObj, result;
          isObj = this.isPlainObject(page);
          if (arguments.length === 1 && !isObj) {
            if (!this.isArray(page)) {
              page = [page];
            }
            return result = this.inArray($("body").data("page"), page) > -1;
          } else {
            if (this.isString(page)) {
              page = [page];
            }
            args = [page, func, isObj];
            if (turbolinksEnabled) {
              return addHandlers.apply(this, args);
            } else {
              return runHandlers.apply(this, args);
            }
          }
        },
        validator: function(page, handler) {
          return this.isString(page) || this.isArray(page) || this.isPlainObject(page);
        },
        value: false
      }
    ]
  });

  if (turbolinksEnabled) {
    Tatami.init({
      runSandbox: function(prepareHandlers, readyHandlers) {
        return $(document).on({
          "page:change": (function(_this) {
            return function() {
              _this.each(pageHandlers.storage[$("body").data("page")], function(handler) {
                return handler();
              });
              return _this.run(prepareHandlers);
            };
          })(this),
          "page:load": (function(_this) {
            return function() {
              return _this.run(readyHandlers);
            };
          })(this),
          "page:restore": (function(_this) {
            return function() {
              console.log("restore");
              return _this.run(readyHandlers);
            };
          })(this)
        });
      }
    });
  }

}).call(this);
