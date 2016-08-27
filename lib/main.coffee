fs = require "fs"
path = require 'path'

referencesProvider = require "./provider"
pathWatcher = require 'pathwatcher'

module.exports =

  config:
    references:
      type: 'array'
      default: []
      items:
        type: 'string'
    scope:
      type: 'string'
      default: '.gfm,.md'
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
      @stateTime = state.saveTime
      if not Array.isArray(referencesFiles)
        # TODO remove this bloc after testing
        referencesFiles = [referencesFiles]
      # reload everything if any files changed
      for file in referencesFiles
        try
          stats = fs.statSync(file)
          if stats.isFile()
            watcher = pathWatcher.watch file, (type, path) ->
              if type == "change"
                console.log "Reference file changed -- currently unimplemented"
            if state.saveTime <= stats.mtime.getTime()
              reload = true
              @stateTime = new Date().getTime()
        catch error
          console.log "No references file is present"

    # Need to distinguish between the Autocomplete provider and the
    # containing class (which holds the serialize fn)
    if state and reload is false
      @referencesProvider = atom.deserializers.deserialize(state.provider)
      # deserializer produces "undefined" if it fails, so double check
      if not @referencesProvider
        @referencesProvider = new referencesProvider()
    else
      @referencesProvider = new referencesProvider()

    @provider = @referencesProvider.provider

  deactivate: ->
    pathWatcher.closeAllWatchers()
    @provider.registration.dispose()

  serialize: ->
    state = {
      provider: @referencesProvider.serialize()
      saveTime: @stateTime ? new Date().getTime()
    }
    return state


  provide: ->
    @provider
