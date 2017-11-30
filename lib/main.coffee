{ CompositeDisposable } = require 'atom'

configSchema = require './config'

module.exports =
  config: configSchema
  provider: null
  subscriptions: null

  activate: ->
    @subscriptions = new CompositeDisposable()


  deactivate: ->
    @provider = null
    @subscriptions.dispose()

  provide: ->
    unless @provider?
      CiteProvider = require('./provider')
      @provider = new CiteProvider()

    @provider
