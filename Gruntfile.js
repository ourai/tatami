module.exports = function( grunt ) {
  grunt.initConfig({
    pkg: grunt.file.readJSON("package.json"),
    coffee: {
      options: {
        separator: "\n"
      },
      build: {
        expand: true,
        cwd: "src/",
        src: ["**/*.coffee"],
        dest: "dest/",
        ext: ".js"
      }
    },
    uglify: {
      options: {
        banner: "/*! <%= pkg.name %> <%= grunt.template.today('yyyy-mm-dd') %> */\n"
      },
      build: {
        src: "dest/<%= pkg.name %>.js",
        dest: "dest/<%= pkg.name %>.min.js"
      }
    }
  });

  grunt.loadNpmTasks("grunt-contrib-coffee");
  grunt.loadNpmTasks("grunt-contrib-uglify");

  grunt.registerTask("js2cs", "Compiles JavaScript files.", ["coffee"]);

  grunt.registerTask("default", ["js2cs", "uglify"]);
};
