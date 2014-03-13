module.exports = function( grunt ) {
  grunt.initConfig({
    pkg: grunt.file.readJSON("package.json"),
    dirs: {
      src: "src",
      dest: "dest/<%= pkg.version %>"
    },
    concat: {
      options: {
        process: function( src, filepath ) {
          return src.replace(/@VERSION/g, "<%= pkg.version %>");
        }
      },
      build: {
        src: ["<%= dirs.src %>/intro.coffee",
              "<%= dirs.src %>/variable.coffee",
              "<%= dirs.src %>/function.coffee",
              "<%= dirs.src %>/core.coffee",
              "<%= dirs.src %>/outro.coffee"],
        dest: "<%= dirs.dest %>/<%= pkg.name %>.coffee"
      }
    },
    coffee: {
      options: {
        separator: "\x20"
      },
      build: {
        src: "<%= dirs.dest %>/<%= pkg.name %>.coffee",
        dest: "<%= dirs.dest %>/<%= pkg.name %>.js"
      }
    },
    uglify: {
      options: {
        banner: "/*! <%= pkg.name %> <%= grunt.template.today('yyyy-mm-dd') %> */\n"
      },
      build: {
        src: "<%= dirs.dest %>/<%= pkg.name %>.js",
        dest: "<%= dirs.dest %>/<%= pkg.name %>.min.js"
      }
    }
  });

  grunt.loadNpmTasks("grunt-contrib-concat");
  grunt.loadNpmTasks("grunt-contrib-coffee");
  grunt.loadNpmTasks("grunt-contrib-uglify");

  grunt.registerTask("combine", "Concatenate CoffeeScript files.", ["concat"]);
  grunt.registerTask("compile", "Compiles JavaScript files.", ["coffee"]);
  grunt.registerTask("compress", "Uglify JavaScript files.", ["uglify"]);

  grunt.registerTask("default", ["combine", "compile", "compress"]);
};
