fs = require "fs"

referencesProvider = require "./provider"

module.exports =
  config:
    references:
      type: 'array'
      default: []
      items:
        type: 'string'
    scope:
      type: 'string'
      default: '.text.md'
    ignoreScope:
      type: 'string'
      default: '.comment'
    resultTemplate:
      type: 'string'
      default: '@[key]'

  activate: (state) ->
    reload = false
    if state
      referencesFiles = atom.config.get "autocomplete-citeproc.references"
      if not Array.isArray(referencesFiles)
        referencesFiles = [referencesFiles]
      # reload everything if any files changed
      for file in referencesFiles
        stats = fs.statSync(file)
        if stats.isFile()
          if state.saveTime < stats.mtime.getTime()
            reload = true

    # Need to distinguish between the Autocomplete provider and the
    # containing class (which holds the serialize fn)
    if state and reload is false
      @referencesProvider = atom.deserializers.deserialize(state.provider)
      #deserializer produces "undefined" if it fails, so double check
      if not @referencesProvider
        @referencesProvider = new referencesProvider()
    else
      @referencesProvider = new referencesProvider()

    @provider = @referencesProvider.provider

  deactivate: ->
    @provider.registration.dispose()

  serialize: ->
    state = {
      provider: @referencesProvider.serialize()
      saveTime: new Date().getTime()
    }
    return state


  provide: ->
    @provider
