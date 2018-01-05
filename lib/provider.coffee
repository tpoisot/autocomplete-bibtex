CiteManager = require('./manager')
path = require 'path'

module.exports =
class CiteProvider

  # This line lists the scopes in which autocompletion of references will work
  selector: '.md,.gfm'
  # We don't want it to work in comments
  disableForSelector: '.comment'
  # Priorities for autocomplete
  inclusionPriority: 1
  suggestionPriority: 1
  excludeLowerPriority: false
  # We want citations to be triggered by the @ symbol
  commandList: "@"

  constructor: ->
    @manager = new CiteManager()
    @manager.initialize()

  getSuggestions: ({editor, bufferPosition}) ->
    prefix = @getPrefix(editor, bufferPosition)
    return unless prefix?.length
    new Promise (resolve) =>
      results = @manager.searchForPrefixInDatabase(prefix)
      suggestions = []
      for result in results
        suggestion = @suggestionForResult(result, prefix)
        suggestions.push suggestion
      resolve(suggestions)

  suggestionForResult: (result, prefix) ->
    console.log result
    iconClass = "icon-mortar-board"
    if (result.type == 'article-journal' || result.type == 'inproceedings' || result.type == "incollection")
      iconClass = "icon-file-text"
    else if (result.type == 'book' ||  result.type == 'chapter')
      iconClass = "icon-repo"

    suggestion =
      text: result.id
      leftLabel: result.id
      replacementPrefix: prefix
      type: result.type
      className: 'citeproc-cite'
      displayText: result.prettyTitle.replace(/(^.{35}).*$/,'$1...')
      descriptionMarkdown: result.prettyAuthors
      descriptionMoreURL: result.URL
      iconHTML: "<i class=\"#{iconClass}\"></i>"

  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->

  dispose: ->
    @manager = []

  getPrefix: (editor, bufferPosition) ->
    cmdprefixes = @commandList

    # Whatever your prefix regex might be
    regex = ///
            (#{cmdprefixes}) #command group
            ([\w-:]+)$ # machthing the prefix
            ///
    # Get the text for the line up to the triggered buffer position
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    # Match the regex to the line, and return the match
    line.match(regex)?[2] or ''
