sysPath = require 'path'
fs = require 'fs'
jsdom = require 'jsdom'

module.exports = class EmblemCompiler
  brunchPlugin: yes
  type: 'template'
  extension: 'emblem'
  pattern: /\.(?:emblem)$/

  setup: (@config) ->
    @window = jsdom.jsdom().createWindow()
    paths = @config.files.templates.paths
    if paths.jquery
      @window.run fs.readFileSync paths.jquery, 'utf8'
    @window.run fs.readFileSync paths.handlebars, 'utf8'
    @window.run fs.readFileSync paths.emblem, 'utf8'
    if paths.ember
      @window.run fs.readFileSync paths.ember, 'utf8'
      @ember = true
    else
      @ember = false

  constructor: (@config) ->
    if @config.files.templates?.paths?
      @setup(@config)
    null

  compile: (data, path, callback) ->
    if not @window?
      return callback "files.templates.paths must be set in your config", {}
    try
      if @ember
        console.log 'compile'
        root = @config.files.templates?.root ? /^app\//
        templatesRoot = @config.files.templates?.templates ? root + /templates\//
        featuresRoot = @config.files.templates?.features ? root + /features\//
        componentsRoot = @config.files.templates?.components ? root + /components\//

        isTemplate = (path.search templatesRoot) != -1
        isComponent = (path.search componentsRoot) != -1
        isfeature = (path.search featuresRoot) != -1

        console.log '+'

        if isComponent
          filter = componentsRoot
        else if isfeature
          filter = featuresRoot
        else
          filter = templatesRoot

        if isTemplate
          path = path
            .replace(new RegExp('\\\\', 'g'), '/')
            .replace(filter, '')
            .replace(/\.\w+$/, '')
        else
          path = path
            .replace(new RegExp('\\\\', 'g'), '/')
            .replace(filter, '')
            .replace(/\/\w+.emblem$/, '')

        if isComponent
          path = 'components/' + path

        console.log 'final: ' + path

        content = @window.Emblem.precompile @window.Ember.Handlebars, data
        result = "Ember.TEMPLATES[#{JSON.stringify(path)}] = Ember.Handlebars.template(#{content});module.exports = module.id;"


      else
        content = @window.Emblem.precompile @window.Handlebars, data
        result = "module.exports = Handlebars.template(#{content});"
    catch err
      error = err
    finally
      callback error, result
