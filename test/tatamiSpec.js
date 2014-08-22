(function( window, $, undefined ) {

describe("Push functions into sandbox's internal queue.", function() {
  it("Push a function.", function() {
    var f_result = $.queue("foo", function() {
      return "foo";
    });

    var b_result = $.queue("bar", function() {
      return "bar";
    });

    expect($.queue("foo").toString()).toEqual(f_result.toString());
    expect($.queue("bar").toString()).toEqual(b_result.toString());
  });

  it("Push a function list.", function() {
    var l_result = $.queue({
      _foo: function() {
        return "_foo";
      },
      _bar: function() {
        return "_bar";
      },
      _foobar: function() {
        return "_foobar";
      }
    });

    expect($.queue("_foo").toString()).toEqual(l_result._foo.toString());
    expect($.queue("_bar").toString()).toEqual(l_result._bar.toString());
    expect($.queue("_foobar").toString()).toEqual(l_result._foobar.toString());

    var funcList = $.queue();

    expect(funcList._foo.toString()).toEqual(l_result._foo.toString());
    expect(funcList._bar.toString()).toEqual(l_result._bar.toString());
    expect(funcList._foobar.toString()).toEqual(l_result._foobar.toString());
  });
});

describe("Delete functions from sandbox's internal queue.", function() {
  $.queue({
    foo_dd: function() {
      return "foo";
    },
    bar_dd: function() {
      return "bar";
    },
    foobar_dd: function() {
      return "foobar";
    }
  });

  it("Delete a function.", function() {
    expect($.run("foo_dd")).toBe("foo");
    expect($.dequeue("foo_dd")).toBe(true);
    expect($.queue("foo_dd")).toBeUndefined();
  });

  it("Delete a function list.", function() {
    expect($.run("bar_dd")).toBe("bar");
    expect($.run("foobar_dd")).toBe("foobar");
    expect($.dequeue(["bar_dd", "foobar_dd"])).toBe(true);
    expect($.queue("bar_dd")).toBeUndefined();
    expect($.queue("foobar_dd")).toBeUndefined();
  });
});

describe("Run functions from sandbox's internal queue.", function() {
  it("Run a function.", function() {
    expect($.run("foo")).toBe("foo");
    expect($.run("bar")).toBe("bar");
  });

  it("Run a function list.", function() {
    var run_result = [];

    $.queue({
      run_1: function() {
        run_result.push("run_1");
      },
      run_2: function() {
        run_result.push("run_2");
      }
    });

    $.run(["run_2", "run_1"]);

    expect(run_result[0]).toBe("run_2");
    expect(run_result[1]).toBe("run_1");
  });
});

describe("Saving and accessing local data.", function() {
  it("Saving and accessing.", function() {
    var obj_1 = {bar: "bar"};
    var obj_2 = {foo: "foo"};
    var obj_3 = {foo: "foobar"};

    $.save("foo", obj_1);
    expect($.stringify($.access("foo"))).toBe($.stringify(obj_1));

    $.save("foo", obj_2);
    expect($.stringify($.access("foo"))).toBe($.stringify($.mixin(true, {}, obj_1, obj_2)));

    $.save("foo", obj_3);
    expect($.stringify($.access("foo"))).toBe($.stringify($.mixin(true, {}, obj_1, obj_2, obj_3)));

    $.save("bar", true);
    expect($.access("bar")).toBe(true);

    $.save("bar", "true");
    expect($.access("bar")).toBe("true");

    $.save("bar", false);
    expect($.access("bar")).toBe(false);

    $.save("bar", "false");
    expect($.access("bar")).toBe("false");

    $.save("bar", 1);
    expect($.access("bar")).toBe(1);

    $.save("bar", "1");
    expect($.access("bar")).toBe("1");

    $.save("bar", undefined);
    expect($.access("bar")).toBeUndefined();

    $.save("bar", "undefined");
    expect($.access("bar")).toBe("undefined");

    $.save("bar", null);
    expect($.access("bar")).toBeNull();

    $.save("bar", "null");
    expect($.access("bar")).toBe("null");

    $.save("doo");
    expect($.access("doo")).toBeUndefined();

    expect($.access("what")).toBeUndefined();

    expect($.access(11)).toBeUndefined();
  });
});

})(window, Tatami);
