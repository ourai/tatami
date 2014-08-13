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

})(window, Tatami);
