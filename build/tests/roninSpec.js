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

})(window, Tatami);
