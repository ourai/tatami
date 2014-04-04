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
      "grunt-contrib-copy",
      "grunt-contrib-clean"
    ];
  var index = 0;
  var length = npmTasks.length;

  grunt.initConfig({
    repo: info,
    pkg: pkg,
    meta: {
      src: "src",
      coffee: "<%= meta.src %>/coffee",
      vendor: "<%= meta.src %>/vendors",
      matcha: "<%= meta.vendor %>/matcha",
      dest: "dest",
      dest_style: "<%= meta.dest %>/stylesheets",
      dest_script: "<%= meta.dest %>/javascripts",
      dest_image: "<%= meta.dest %>/images"
    },
    concat: {
      coffee: {
        src: ["<%= meta.coffee %>/intro.coffee",
              "<%= meta.coffee %>/variables.coffee",
              "<%= meta.coffee %>/functions.coffee",
              "<%= meta.coffee %>/util.coffee",
              "<%= meta.coffee %>/flow.coffee",
              "<%= meta.coffee %>/project.coffee",
              "<%= meta.coffee %>/storage.coffee",
              "<%= meta.coffee %>/request.coffee",
              "<%= meta.coffee %>/html.coffee",
              "<%= meta.coffee %>/outro.coffee"],
        dest: "<%= meta.dest_script %>/<%= pkg.name %>.coffee"
      },
      js: {
        options: {
          process: function( src, filepath ) {
            return src.replace(/@(NAME|VERSION)/g, function( text, key ) {
              return info[key.toLowerCase()];
            });
          }
        },
        src: ["<%= meta.vendor %>/ronin/ronin.js",
              "<%= meta.matcha %>/javascripts/matcha.js",
              "<%= meta.src %>/intro.js",
              "<%= meta.src %>/<%= pkg.name %>.js",
              "<%= meta.src %>/outro.js"],
        dest: "<%= meta.dest_script %>/<%= pkg.name %>.js"
      },
      css: {
        files: {
          "<%= meta.dest_style %>/<%= pkg.name %>.css": "<%= meta.matcha %>/stylesheets/matcha.css",
          "<%= meta.dest_style %>/<%= pkg.name %>.min.css": "<%= meta.matcha %>/stylesheets/matcha.min.css"
        }
      }
    },
    coffee: {
      options: {
        bare: true,
        separator: "\x20"
      },
      build: {
        src: "<%= meta.dest_script %>/<%= pkg.name %>.coffee",
        dest: "<%= meta.src %>/<%= pkg.name %>.js"
      }
    },
    uglify: {
      options: {
        banner: "/*!\n" +
                " * <%= repo.name %> v<%= repo.version %>\n" +
                " * <%= pkg.homepage %>\n" +
                " *\n" +
                " * Copyright 2013, <%= grunt.template.today('yyyy') %> Ourairyu, http://ourai.ws/\n" +
                " *\n" +
                " * Date: <%= grunt.template.today('yyyy-mm-dd') %>\n" +
                " */\n",
        sourceMap: true
      },
      build: {
        src: "<%= meta.dest_script %>/<%= pkg.name %>.js",
        dest: "<%= meta.dest_script %>/<%= pkg.name %>.min.js"
      }
    },
    copy: {
      build: {
        expand: true,
        cwd: "<%= meta.dest %>",
        src: ["**.js", "**.css", "**/*.scss"],
        dest: "dest"
      },
      matcha: {
        expand: true,
        cwd: "<%= meta.matcha %>",
        src: ["**/*.scss", "**/*.gif", "**/*.jpg", "**/*.png"],
        dest: "<%= meta.dest %>"
      }
    },
    clean: {
      compiled: {
        src: ["<%= meta.dest_script %>/*.coffee"]
      }
    }
  });

  for (; index < length; index++) {
    grunt.loadNpmTasks(npmTasks[index]);
  }

  grunt.registerTask("script", ["concat:coffee", "coffee", "concat:js", "uglify"]);
  grunt.registerTask("style", ["concat:css", "copy:matcha"]);
  grunt.registerTask("default", ["script", "style", "clean"]);
};
