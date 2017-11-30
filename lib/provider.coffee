CiteManager = require('./manager')
path = require 'path'

module.exports =
class CiteProvider

  # This line lists the scopes in which autocompletion of references will work
  selector: '.md,.gfm'
  # We don't want it to work in comments
  disableForSelector: '.comment'
  # Priorities for autocomplete
  inclusionPriority: 2
  suggestionPriority: 3
  excludeLowerPriority: false
  # We want citations to be triggered by the @ symbol
  commandList: "@"

  constructor: ->
    @manager = new CiteManager()
    @manager.initialize()

  getSuggestions: ({editor, bufferPosition}) ->
    console.log "getSuggestions"
    prefix = @getPrefix(editor, bufferPosition)
    console.log prefix
    return unless prefix?.length
    new Promise (resolve) =>
      results = @manager.searchForPrefixInDatabase(prefix)
      suggestions = []
      for result in results
        suggestion = @suggestionForResult(result, prefix)
        suggestions.push suggestion
      resolve(suggestions)

  suggestionForResult: (result, prefix) ->
    console.log "suggestionForResult"
    iconClass = "icon-mortar-board"
    if (result.class == 'article' || result.class == 'inproceedings' || result.class == "incollection")
      iconClass = "icon-file-text"
    else if (result.class == 'book' ||  result.class == 'inbook')
      iconClass = "icon-repo"

    suggestion =
      text: result.id
      replacementPrefix: prefix
      type: result.class
      className: 'citeproc-cite'
      descriptionMarkdown: result.markdownCite
      descriptionMoreURL: result.url
      iconHTML: "<i class=\"#{iconClass}\"></i>"

  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->

  dispose: ->
    @manager = []

  getPrefix: (editor, bufferPosition) ->
    console.log "getPrefix"
    cmdprefixes = @commandList

    # Whatever your prefix regex might be
    regex = ///
            (#{cmdprefixes}) #command group
            ([\w-:]+)$ # machthing the prefix
            ///
    # Get the text for the line up to the triggered buffer position
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    console.log line
    # Match the regex to the line, and return the match
    line.match(regex)?[2] or ''
