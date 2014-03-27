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
      coffee: "src/coffee",
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
      coffee: {
        src: ["<%= dirs.coffee %>/intro.coffee",
              "<%= dirs.coffee %>/variable.coffee",
              "<%= dirs.coffee %>/function.coffee",
              "<%= dirs.coffee %>/util.coffee",
              "<%= dirs.coffee %>/flow.coffee",
              "<%= dirs.coffee %>/project.coffee",
              "<%= dirs.coffee %>/storage.coffee",
              "<%= dirs.coffee %>/request.coffee",
              "<%= dirs.coffee %>/html.coffee",
              "<%= dirs.coffee %>/outro.coffee"],
        dest: "<%= dirs.dest %>/<%= pkg.name %>.coffee"
      },
      js: {
        src: ["<%= dirs.src %>/intro.js",
              "<%= dirs.src %>/<%= pkg.name %>.js",
              "<%= dirs.src %>/outro.js"],
        dest: "<%= dirs.dest %>/<%= pkg.name %>.js"
      }
    },
    coffee: {
      options: {
        bare: true,
        separator: "\x20"
      },
      build: {
        src: "<%= dirs.dest %>/<%= pkg.name %>.coffee",
        dest: "<%= dirs.src %>/<%= pkg.name %>.js"
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

  grunt.registerTask("script", ["concat:coffee", "coffee", "concat:js", "uglify"]);
  grunt.registerTask("default", ["script", "copy"]);
};
