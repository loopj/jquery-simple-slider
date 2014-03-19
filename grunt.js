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
          'js/<%= pkg.name %>.js': 'js/*.coffee'
        },

        options: {
          bare: true
        }
      }
    },

    watch: {
      coffee: {
        files: ['js/*.coffee']
      }
    },

    min: {
      dist: {
        src: ['<banner:meta.banner>', 'js/<%= pkg.name %>.js'],
        dest: 'js/<%= pkg.name %>.min.js'
      }
    },

    compress: {
      zip: {
        files: {
          "<%= pkg.name %>-<%= pkg.version %>.zip": ["js/**", "demo.html", "README.md"]
        }
      }
    }
  });

  // Lib tasks.
  grunt.loadNpmTasks('grunt-contrib');

  // Default task.
  grunt.registerTask('build', 'coffee min');
  grunt.registerTask('serve', 'server watch:coffee');
  grunt.registerTask('default', 'build');
};
