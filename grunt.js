module.exports = function(grunt) { 
  grunt.initConfig({
    pkg: '<json:package.json>',

    meta: {
      banner:
        '/*\n' + 
        ' * <%= pkg.title || pkg.name %>: <%= pkg.description %>\n' +
        ' * Version <%= pkg.version %>\n' + 
        ' *\n' +
        ' * Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %> (<%= pkg.author.url %>)\n' +
        ' *\n' +
        ' * Licensed under the <%= pkg.licenses[0].type %> license (<%= pkg.licenses[0].url %>)\n' +
        ' *\n' + 
        ' */\n'
    },

    coffee: {
      compile: {
        files: {
          'src/<%= pkg.name %>.js': 'src/*.coffee'
        },

        options: {
          bare: true
        }
      }
    },

    watch: {
      coffee: {
        files: ['src/*.coffee'],
        tasks: 'coffee growl:coffee'
      }
    },

    growl: {
      coffee: {
        title: 'CoffeeScript',
        message: 'Compiled successfully'
      }
    },

    min: {
      dist: {
        src: ['<banner:meta.banner>', 'src/<%= pkg.name %>.js'],
        dest: 'src/<%= pkg.name %>.min.js'
      }
    },
    
    compress: {
      zip: {
        files: {
          "<%= pkg.name %>-<%= pkg.version %>.zip": ["src/**", "demo.html", "README.md"]
        }
      }
    }
  });

  // Lib tasks.
  grunt.loadNpmTasks('grunt-contrib');
  grunt.loadNpmTasks('grunt-growl');

  // Default task.
  grunt.registerTask('default', 'coffee growl:coffee');
  grunt.registerTask('serve', 'server watch');
};