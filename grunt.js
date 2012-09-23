/*global module:false*/
module.exports = function(grunt) { 
  // Project configuration.
  grunt.initConfig({
    pkg : '<json:package.json>',

    meta : {
      banner : '/*! <%= pkg.title || pkg.name %> - v<%= pkg.version %> - ' +
        '<%= grunt.template.today("yyyy-mm-dd") %>\n' +
        '<%= pkg.homepage ? "* " + pkg.homepage + "\n" : "" %>' +
        '* Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %>;' +
        ' Licensed <%= _.pluck(pkg.licenses, "type").join(", ") %> */'
    },

    coffee : {
      plugin : {
        src  : 'src/*.coffee',
        dest : 'src'
      }
    },

    watch : {
      coffee : {
        files: ['<config:coffee.plugin.src>'],
        tasks: 'coffee growl:coffee'
      }
    },

    growl : {
      coffee : {
        title   : 'CoffeeScript',
        message : 'Compiled successfully'
      }
    },

    min : {
      dist : {
        src  : ['<banner:meta.banner>', 'src/<%= pkg.name %>.js'],
        dest : 'src/<%= pkg.name %>.min.js'
      }
    }
  });

  // Lib tasks.
  grunt.loadNpmTasks('grunt-growl');
  grunt.loadNpmTasks('grunt-coffee');

  // Default task.
  grunt.registerTask('default', 'growl coffee');  
};