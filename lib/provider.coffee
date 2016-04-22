fs = require "fs"
fuzzaldrin = require "fuzzaldrin"
XRegExp = require('xregexp').XRegExp
titlecaps = require "./titlecaps"
citeproc = require "./citeproc"
yaml = require "yaml-js"

module.exports =
class referencesProvider

  atom.deserializers.add(this)

  @deserialize: ({data}) -> new referencesProvider(data)

  constructor: (state) ->
    console.log "Constructor"
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
        console.log "suggesting"
        prefix = @getPrefix(editor, bufferPosition)
        new Promise (resolve) ->
          if prefix[0] == "@"
            p = prefix.normalize().replace(/^@/, '')
            suggestions = []
            hits = fuzzaldrin.filter allwords, p, { key: 'author' }
            console.log hits
            for h in hits
              h.score = fuzzaldrin.score(p, h.author)
            hits.sort @compare
            resultTemplate = atom.config.get "autocomplete-citeproc.resultTemplate"
            for word in hits
              suggestion = {
                text: resultTemplate.replace("[key]", word.key)
                displayText: word.label
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
    console.log "build"
    possibleWords = []
    for citation in @references
      console.log citation
      if citation.entryTags and citation.entryTags.title and (citation.entryTags.author or citation.entryTags.editor)
        console.log "Inner loop"
        citation.entryTags.prettyTitle =
          @prettifyTitle citation.entryTags.title

        citation.authors = []

        if citation.entryTags.author?
          citation.authors =
            citation.entryTags.author.concat @cleanAuthors citation.entryTags.author

        console.log citation.authors

        if not citation.entryTags.editors
          if citation.entryTags.editor?
            citation.entryTags.authors =
              citation.entryTags.authors.concat @cleanAuthors citation.entryTags.editor.split ' and '

        citation.entryTags.prettyAuthors =
          @prettifyAuthors citation.entryTags.authors

        console.log citation
        for author in citation.entryTags.authors
          new_word = {
            author: @prettifyName(author),
            key: citation.citationKey,
            label: "#{citation.entryTags.prettyTitle}"
            by: "#{citation.entryTags.prettyAuthors}"
            type: "#{citation.entryTags.type}"
          }
          if citation.entryTags.url?
            new_word.url = citation.entryTags.url
          if citation.entryTags.in?
            new_word.in = citation.entryTags.in
          possibleWords.push new_word

    console.log possibleWords

    @possibleWords = possibleWords

  buildWordListFromFiles: (referencesFiles) =>
    @readreferencesFiles(referencesFiles)
    @buildWordList()

  readreferencesFiles: (referencesFiles) =>
    console.log "Reading references"
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
            cpobject = JSON.parse fs.readFileSync(file, 'utf-8')
            citeproc_refs = citeproc.parse cpobject
            references = references.concat citeproc_refs

          if ftype is "yaml"
            cpobject = yaml.load fs.readFileSync(file, 'utf-8')
            citeproc_refs = citeproc.parse cpobject
            references = references.concat citeproc_refs

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
    return [{ familyName: 'Unknown' }] if not authors?

    for author in authors
      [familyName, personalName] =
        if author.indexOf(', ') isnt -1 then author.split(', ') else [author]

      { personalName: personalName, familyName: familyName }

  prettifyAuthors: (authors) ->
    name = @prettifyName authors[0]
    if authors.length > 1 then "#{name} et al." else "#{name}"

  prettifyName: (person, separator = ' ') ->
      (if person.familyName? then person.familyName else '')
