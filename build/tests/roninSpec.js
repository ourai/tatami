(function( window, $, undefined ) {

describe("determine variable types", function() {
  it("'.isArray'", function() {
    expect($.isArray([])).toBe(true);
    expect($.isArray(document.links)).toBe(false);
    expect($.isArray(window)).toBe(false);
    expect($.isArray("")).toBe(false);
    expect($.isArray({})).toBe(false);
    expect($.isArray(true)).toBe(false);
  });

  it("'.isArrayLike'", function() {
    expect($.isArrayLike(document.links)).toBe(true);
    expect($.isArrayLike([])).toBe(false);
  });
});

// describe("Date and time formatting", function() {
//   it("date", function() {
//     // var cases = [
//     //     ["March 28th, 1994 10:11:22am", "F jS, Y h:i:sa", "1994-03-28T10:11:22+0800"]
//     //   ];
//     expect($.date("F jS, Y h:i:sa", "1994-03-28T10:11:22+0800")).toEqual("March 28th, 1994 10:11:22am");

//     // $.each(cases, function( c, i ) {
//     //   expect($.date.apply($, c.slice(1))).toEqual(c[0]);
//     // });
//   });
// });

describe("Get elements from an indexed collection.", function() {
  var str = "123456";
  var arr = [5, 4, 3, 2, 1];
  var args = [true, 12, 13, 14];

  it("Get the first element.", function() {
    expect($.first(str)).toBe("1");
    expect($.first(arr)).toBe(5);

    (function() {
      expect($.first(arguments)).toBe(true);
    }).apply(window, args);
  });

  it("Get the last element.", function() {
    expect($.last(str)).toBe("6");
    expect($.last(arr)).toBe(1);

    (function() {
      expect($.last(arguments)).toBe(14);
    }).apply(window, args);
  });
});

})(window, Tatami);
