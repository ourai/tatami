(function( window, $ ) {

function each( obj, callback ) {
  var idx = 0;
  var len = obj.length;
  var ele;
  var name;
  var value;

  if ( Array.isArray(obj) ) {
    while (idx < len) {
      ele = obj[idx];

      callback.apply(ele, [ele, idx++, obj]);
    }
  }
  else if ( typeof obj === "object" ) {
    for (name in obj) {
      value = obj[name];
      callback.apply(value, [value, name, obj]);
    }
  }
}

describe("determine variable types", function() {
  var vars = [
      window, document.links, [], {}, {a:1, b:2},
      undefined, null, true, false, "true",
      "false", "", "0", "0.0000", "0.0001",
      "00.0001", "0.0100", "00.0100", -1, 0,
      1, 1.00000, 0.00001, function() {}, function() {alert(1)},
      new Date(), /\^[a-z]/
    ];
  var data = {
    // base types
    isBoolean: [
        false, false, false, false, false,
        false, false, true, true, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false
      ],
    isNumber: [
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, true, true,
        true, true, true, false, false,
        false, false
      ],
    isString: [
        false, false, false, false, false,
        false, false, false, false, true,
        true, true, true, true, true,
        true, true, true, false, false,
        false, false, false, false, false,
        false, false
      ],
    isFunction: [
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, true, true,
        false, false
      ],
    isArray: [
        false, false, true, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false
      ],
    isDate: [
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        true, false
      ],
    isRegExp: [
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, true
      ],
    isObject: [
        true, true, false, true, true,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false
      ],
    // extension types
    isArrayLike: [
        false, true, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false
      ]
  };

  each(data, function( results, method ) {
    it("'." + method + "'", function() {
      each(vars, function( v, i ) {
        var r = results[i];
        // console.log(v, r);
        expect($[method](v)).toBe(r);
      });
    });
  });

  it("whether a window object", function() {
    expect($.isWindow(window)).toBe(true);
    expect($.isWindow(document)).toBe(false);
  });

  it("whether a fake window object", function() {
    expect($.isWindow({"setInterval": 1})).toBe(true);
  });

  it("whether a DOM object", function() {
    expect($.isElement(window)).toBe(false);
    expect($.isElement(document)).toBe(false);
    expect($.isElement(document.body)).toBe(true);
  });

  it("whether a fake DOM object", function() {
    expect($.isElement({"nodeType": 1})).toBe(true);
  });
});

describe("whether an empty object", function() {
  it("Null?", function() {
    expect($.isEmpty(null)).toBe(true);
    expect($.isEmpty("null")).toBe(false);
  });

  it("Undefined?", function() {
    expect($.isEmpty(undefined)).toBe(true);
    expect($.isEmpty("undefined")).toBe(false);
  });

  it("Empty Array-like object?", function() {
    expect($.isEmpty(document.getElementsByTagName("main"))).toBe(true);
    expect($.isEmpty(document.getElementsByTagName("body"))).toBe(false);
  });

  it("Empty Array?", function() {
    expect($.isEmpty([])).toBe(true);
    expect($.isEmpty([1, 2, 3])).toBe(false);
  });

  it("Empty object?", function() {
    expect($.isEmpty({})).toBe(true);
    expect($.isEmpty({a:123})).toBe(false);

    var F = function() {};
    var I = new F();
    expect($.isEmpty(I)).toBe(true);

    var G = function() {
      this.type = "test";
    };
    var J = new G();
    expect($.isEmpty(J)).toBe(false);
  });
});

describe("whether has properties", function() {
  it("Do a target object has specified property?", function() {
    expect($.hasProp("console")).toBe(true);
    expect($.hasProp("Function")).toBe(true);
    expect($.hasProp("Function", window)).toBe(true);
    expect($.hasProp("Functions", window)).toBe(false);

    var test = {
        what: "what",
        how: "how"
      };

    expect($.hasProp("what", test)).toBe(true);
    expect($.hasProp("how", test)).toBe(true);
    expect($.hasProp("why", test)).toBe(false);
    expect($.hasProp(test, "how")).toBe(false);
    expect($.hasProp("what", window)).toBe(false);
    expect($.hasProp("what")).toBe(false);
  });
});

})(window, Tatami);
