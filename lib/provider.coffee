fs = require "fs"
fuzzaldrin = require "fuzzaldrin"
XRegExp = require('xregexp').XRegExp
titlecaps = require "./titlecaps"
yaml = require "yaml-js"

module.exports =
class referencesProvider

  atom.deserializers.add(this)

  @deserialize: ({data}) -> new referencesProvider(data)

  constructor: (state) ->
    if state and Object.keys(state).length != 0
      @references = state.references
      @possibleWords = state.possibleWords
    else
      @buildWordListFromFiles(atom.config.get "autocomplete-citeproc.references")

    if @references.length == 0
      @buildWordListFromFiles(atom.config.get "autocomplete-citeproc.references")

    atom.config.onDidChange "autocomplete-citeproc.references", (referencesFiles) =>
      @buildWordListFromFiles(referencesFiles)

    @buildWordListFromFiles(atom.config.get "autocomplete-citeproc.references")
    allwords = @possibleWords

    resultTemplate = atom.config.get "autocomplete-citeproc.resultTemplate"
    atom.config.observe "autocomplete-citeproc.resultTemplate", (resultTemplate) =>
      @resultTemplate = resultTemplate

    @provider =
      selector: atom.config.get "autocomplete-citeproc.scope"
      disableForSelector: atom.config.get "autocomplete-citeproc.ignoreScope"
      inclusionPriority: 1
      excludeLowerPriority: true

      compare: (a,b) ->
        if a.score < b.score
          return -1
        if a.score > b.score
          return 1
        return 0

      getSuggestions: ({editor, bufferPosition}) ->
        prefix = @getPrefix(editor, bufferPosition)
        new Promise (resolve) ->
          if prefix[0] == "@"
            p = prefix.normalize().replace(/^@/, '')
            suggestions = []
            hits = fuzzaldrin.filter allwords, p, { key: 'author' }
            for h in hits
              h.score = fuzzaldrin.score(p, h.author)
            hits.sort @compare
            resultTemplate = atom.config.get "autocomplete-citeproc.resultTemplate"
            for word in hits
              tl = word.title.length
              if tl > 40
                word.title = word.title.substr(0, 39) + "\u2026"
              suggestion = {
                text: resultTemplate.replace("[key]", word.key)
                displayText: word.title
                replacementPrefix: prefix
                leftLabel: word.key
                rightLabel: word.by
                className: word.type
                iconHTML: '<i class="icon-mortar-board"></i>'
              }
              if word.in?
                suggestion.description = word.in
              if word.url?
                suggestion.descriptionMoreURL = word.url
              suggestions = suggestions.concat suggestion
            resolve(suggestions)

      getPrefix: (editor, bufferPosition) ->
        # Whatever your prefix regex might be
        regex = /@[\w-]+/
        wordregex = XRegExp('(?:^|[\\p{WhiteSpace}\\p{Punctuation}])@[\\p{Letter}\\p{Number}\._-]*')
        cursor = editor.getCursors()[0]
        start = cursor.getBeginningOfCurrentWordBufferPosition({ wordRegex: wordregex, allowPrevious: false })
        end = bufferPosition
        # Get the text for the line up to the triggered buffer position
        line = editor.getTextInRange([start, bufferPosition])
        # Match the regex to the line, and return the match
        line.match(regex)?[0] or ''


  serialize: -> {
    deserializer: 'referencesProvider'
    data: { references: @references, possibleWords: @possibleWords }
  }

  buildWordList: () =>
    possibleWords = []
    for citation in @references
      if (citation.author or citation.editor)
        citation.prettyTitle = @prettifyTitle citation.title

        if citation.author?
          citation.authors =
            @prettifyAuthors citation.author.concat @cleanAuthors citation.author
        if citation.editor?
          citation.editors =
            @prettifyAuthors citation.editor.concat @cleanAuthors citation.editor

        template = {
          author: "unknown",
          key: "#{citation.id}",
          type: "#{citation.type}",
          title: "#{citation.prettyTitle}"
        }
        if citation.url?
          template.url = citation.url
        if citation.in?
          template.in = citation.in

        if citation.author?
          template.by = citation.authors
          for author in citation.author
            new_word = (JSON.parse(JSON.stringify(template)));
            if author.family?
              new_word.author = author.family
            if author.litteral?
              new_word.author = author.litteral

            possibleWords.push new_word

    @possibleWords = possibleWords

  buildWordListFromFiles: (referencesFiles) =>
    @readreferencesFiles(referencesFiles)
    @buildWordList()

  readreferencesFiles: (referencesFiles) =>
    if referencesFiles.newValue?
      referencesFiles = referencesFiles.newValue
    # Make sure our list of files is an array, even if it's only one file
    if not Array.isArray(referencesFiles)
      referencesFiles = [referencesFiles]
    try
      references = []
      for file in referencesFiles

        # What type of file is this?
        ftype = file.split('.')
        ftype = ftype[ftype.length - 1]

      for file in referencesFiles
        if fs.statSync(file).isFile()

          if ftype is "json"
            references = JSON.parse fs.readFileSync(file, 'utf-8')

          if ftype is "yaml"
            references = yaml.load fs.readFileSync(file, 'utf-8')

        else
          console.warn("'#{file}' does not appear to be a file, so autocomplete-citeproc will not try to parse it.")

      @references = references
    catch error
      console.error error

  prettifyTitle: (title) ->
    return if not title
    title = titlecaps(title)
    return title

  cleanAuthors: (authors) ->
    if not authors?
      return [{ family: 'Unknown' }]
    else
      return authors

  prettifyAuthors: (authors) ->
    name = @prettifyName authors[0]
    if authors.length > 1 then "#{name} et al." else "#{name}"

  prettifyName: (person, separator = ' ') ->
      (if person.family? then person.family else '')
