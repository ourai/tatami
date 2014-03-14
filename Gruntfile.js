module.exports = function( grunt ) {
  var pkg = grunt.file.readJSON("package.json");
  var info = {
      name: pkg.name.charAt(0).toUpperCase() + pkg.name.substring(1),
      version: pkg.version
    };
  var npmTasks = [
      "grunt-contrib-concat",
      "grunt-contrib-coffee",
      "grunt-contrib-uglify",
      "grunt-contrib-copy"
    ];
  var index = 0;
  var length = npmTasks.length;

  grunt.initConfig({
    pkg: pkg,
    dirs: {
      src: "src",
      dest: "dest/<%= pkg.version %>"
    },
    concat: {
      options: {
        process: function( src, filepath ) {
          return src.replace(/@(NAME|VERSION)/g, function( text, key ) {
            return info[key.toLowerCase()];
          });
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
    },
    copy: {
      build: {
        cwd: "<%= dirs.dest %>",
        src: ["**"],
        dest: "dest",
        expand: true
      }
    }
  });

  for (; index < length; index++) {
    grunt.loadNpmTasks(npmTasks[index]);
  }

  grunt.registerTask("default", ["concat", "coffee", "uglify", "copy"]);
};
