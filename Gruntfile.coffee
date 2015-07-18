module.exports = ( grunt ) ->
  pkg = grunt.file.readJSON "package.json"
  info =
    name: pkg.name.charAt(0).toUpperCase() + pkg.name.substring(1)
    version: pkg.version
  npmTasks = [
      "grunt-contrib-concat"
      "grunt-contrib-coffee"
      "grunt-contrib-uglify"
      "grunt-contrib-copy"
      "grunt-contrib-clean"
      "grunt-contrib-jasmine"
    ]

  grunt.initConfig
    repo: info
    pkg: pkg
    meta:
      proj: "src/project"
      classes: "src/classes"

      temp: ".<%= pkg.name %>-cache"

      ronin: "vendors/ronin"
      jquery: "vendors/jquery"
    concat:
      ronin:
        options:
          process: ( src, filepath ) ->
            return src.replace /^/gm, "\x20\x20"
        files: "<%= meta.temp %>/__ronin.coffee": [
            "<%= meta.ronin %>/ronin.coffee"
          ]
      coffee:
        options:
          process: ( src, filepath ) ->
            return src.replace /@(NAME|VERSION)/g, ( text, key ) ->
              return info[key.toLowerCase()]
        files:
          "<%= meta.temp %>/ronin.coffee": [
              "build/ronin_intro.coffee"
              "<%= meta.temp %>/__ronin.coffee"
              "build/ronin_outro.coffee"
            ]
          "<%= meta.temp %>/constructors.coffee": [
              "<%= meta.classes %>/Storage.coffee"
              "<%= meta.classes %>/Environment.coffee"
            ]
          "<%= meta.temp %>/<%= pkg.name %>.coffee": [
              "src/project/intro.coffee"
              "src/project/variables.coffee"
              "src/project/functions.coffee"
              "src/project/dialog.coffee"
              "src/project/handler.coffee"
              "src/project/execution.coffee"
              "src/project/configuration.coffee"
              "src/project/storage.coffee"
              "src/project/request.coffee"
              # "src/project/html.coffee"
              "src/project/url.coffee"
              "src/project/outro.coffee"
            ]
          "<%= pkg.name %>.coffee": [
              "src/intro.coffee"
              "<%= meta.temp %>/ronin.coffee"
              "<%= meta.temp %>/constructors.coffee"
              "<%= meta.temp %>/<%= pkg.name %>.coffee"
              "src/outro.coffee"
            ]
      js:
        src: [
            "build/intro.js"
            "<%= meta.temp %>/<%= pkg.name %>.js"
            "build/outro.js"
          ],
        dest: "<%= meta.temp %>/<%= pkg.name %>.full.js"
      vendors:
        files:
          "test/ronin.js": "<%= meta.ronin %>/ronin.js"
          "test/jquery.js": "<%= meta.jquery %>/jquery.js"
    coffee:
      options:
        bare: true
        separator: "\x20"
      build:
        src: "<%= pkg.name %>.coffee"
        dest: "<%= meta.temp %>/<%= pkg.name %>.js"
    uglify:
      options:
        banner: "/*!\n" +
                " * <%= repo.name %> v<%= repo.version %>\n" +
                " * <%= pkg.homepage %>\n" +
                " *\n" +
                " * Copyright 2013, <%= grunt.template.today('yyyy') %> Ourairyu, http://ourai.ws/\n" +
                " *\n" +
                " * Date: <%= grunt.template.today('yyyy-mm-dd') %>\n" +
                " */\n"
        sourceMap: false
      build:
        src: "<%= meta.temp %>/<%= pkg.name %>.full.js"
        dest: "<%= pkg.name %>.min.js"
    copy:
      test:
        expand: true
        cwd: "<%= meta.temp %>"
        src: ["**.js"]
        dest: "test"
    jasmine:
      test:
        src: "test/<%= pkg.name %>.js"
        options:
          specs: "test/*Spec.js"
          vendor: [
              "test/ronin.js"
              "test/jquery.js"
            ]

  grunt.loadNpmTasks task for task in npmTasks

  grunt.registerTask "script", [
      "concat:ronin"
      "concat:coffee"
      "coffee"
      "concat:js"
      "uglify"
    ]
  grunt.registerTask "default", [
      "script"
      "copy:test"
    ]
