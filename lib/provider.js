/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let referencesProvider;
const fs = require("fs");
const fuzzaldrin = require("fuzzaldrin");
const { XRegExp } = require('xregexp');
const titlecaps = require("./titlecaps");
const yaml = require("yaml-js");
const removeDiacritics = require('diacritics').remove;

module.exports =
(referencesProvider = (function() {
  referencesProvider = class referencesProvider {
    static initClass() {

      atom.deserializers.add(this);
    }

    static deserialize({data}) { return new referencesProvider(data); }

    constructor(state) {

      this.buildWordList = this.buildWordList.bind(this);
      this.buildWordListFromFiles = this.buildWordListFromFiles.bind(this);
      this.readreferencesFiles = this.readreferencesFiles.bind(this);
      const tempReferencesFiles = atom.config.get("autocomplete-citeproc.references");
      const referencesFiles = [];
      // Add the reference files
      const projectpath = atom.project != null ? atom.project.getPaths()[0] : undefined;
      for (let t of Array.from(tempReferencesFiles)) {
        const tfile = [projectpath, t].join("/");
        try {
          const stats = fs.statSync(tfile);
          if (stats.isFile()) {
            referencesFiles.push(tfile);
          }
        } catch (error) {
          console.log("No such reference file");
        }
      }

      if (state && (Object.keys(state).length !== 0)) {
        this.references = state.references;
        this.possibleWords = state.possibleWords;
      } else {
        this.buildWordListFromFiles(referencesFiles);
      }

      if (this.references) {
        if (this.references.length === 0) {
          this.buildWordListFromFiles(referencesFiles);
        }
      }

      atom.config.onDidChange("autocomplete-citeproc.references", referencesFiles => {
        return this.buildWordListFromFiles(referencesFiles);
      });

      this.buildWordListFromFiles(referencesFiles);
      const allwords = this.possibleWords;

      let resultTemplate = atom.config.get("autocomplete-citeproc.resultTemplate");
      atom.config.observe("autocomplete-citeproc.resultTemplate", resultTemplate => {
        return this.resultTemplate = resultTemplate;
      });

      this.provider = {
        selector: atom.config.get("autocomplete-citeproc.scope"),
        disableForSelector: atom.config.get("autocomplete-citeproc.ignoreScope"),
        inclusionPriority: 1,
        excludeLowerPriority: true,

        compare(a,b) {
          if (a.score < b.score) {
            return -1;
          }
          if (a.score > b.score) {
            return 1;
          }
          return 0;
        },

        getSuggestions({editor, bufferPosition}) {
          const prefix = this.getPrefix(editor, bufferPosition);
          return new Promise(function(resolve) {
            if (prefix[0] === "@") {
              let p = prefix.normalize().replace(/^@/, '');
              p = removeDiacritics(p);
              let suggestions = [];
              const hits = fuzzaldrin.filter(allwords, p, { key: 'author' });
              for (let h of Array.from(hits)) {
                h.score = fuzzaldrin.score(p, h.author);
              }
              hits.sort(this.compare);
              resultTemplate = atom.config.get("autocomplete-citeproc.resultTemplate");
              for (let word of Array.from(hits)) {
                // We cut the title to 32 chars
                const tl = word.title.length;
                if (tl > 36) {
                  word.title = word.title.substr(0, 35) + "\u2026";
                }
                // A nifty logo for the different types
                let icon = "mortar-board";
                if (word.type === "article-journal") {
                  icon = "file-text";
                }
                if (word.type === "dataset") {
                  icon = "database";
                }
                if (word.type === "book") {
                  icon = "book";
                }
                const suggestion = {
                  text: resultTemplate.replace("[key]", word.key),
                  displayText: word.title,
                  replacementPrefix: prefix,
                  leftLabel: word.key,
                  rightLabel: word.by,
                  className: word.type,
                  iconHTML: `<i class='icon-${icon}'></i>`
                };

                if (word.tagline != null) {
                  suggestion.description = word.tagline;
                }

                if (word.url != null) {
                  suggestion.descriptionMoreURL = word.url;
                }
                suggestions = suggestions.concat(suggestion);
              }
              return resolve(suggestions);
            }
          });
        },

        getPrefix(editor, bufferPosition) {
          // Whatever your prefix regex might be
          const regex = /@[\w-]+/;
          const wordregex = XRegExp('(?:^|[\\p{WhiteSpace}\\p{Punctuation}])@[\\p{Letter}\\p{Number}\._-]*');
          const cursor = editor.getCursors()[0];
          const start = cursor.getBeginningOfCurrentWordBufferPosition({ wordRegex: wordregex, allowPrevious: false });
          const end = bufferPosition;
          // Get the text for the line up to the triggered buffer position
          const line = editor.getTextInRange([start, bufferPosition]);
          // Match the regex to the line, and return the match
          return __guard__(line.match(regex), x => x[0]) || '';
        }
      };
    }


    serialize() { return {
      deserializer: 'referencesProvider',
      data: { references: this.references, possibleWords: this.possibleWords }
    }; }

    buildWordList() {
      const possibleWords = [];
      for (let citation of Array.from(this.references)) {
        if (citation.author || citation.editor) {
          citation.prettyTitle = this.prettifyTitle(citation.title);

          if (citation.author != null) {
            citation.authors =
              this.prettifyAuthors(this.cleanAuthors(citation.author));
          }
          if (citation.editor != null) {
            citation.editors =
              this.prettifyAuthors(this.cleanAuthors(citation.editor));
          }

          let date = "";
          if (citation.issued != null) {
            if (citation.issued["date-parts"] != null) {
              date = ` (${citation.issued["date-parts"][0][0]})`;
            }
          }

          // Then we add the title of the container
          let container = "";
          if (citation["container-title"] != null) {
            container = citation["container-title"];
          }
            // TODO add some infos like page, volume, issue, ...

          const tagline = `${container}${date}`;

          const template = {
            author: "unknown",
            key: `${citation.id}`,
            type: `${citation.type}`,
            title: `${citation.prettyTitle}`,
            tagline: `${tagline}`
          };

          // If the citation has a URL, we use a URL
          if (citation.URL != null) {
            template.url = citation.URL;
          }
          // But a DOI is better, so we use that instead if applicable
          if (citation.DOI != null) {
            template.url = `http://dx.doi.org/${citation.DOI}`;
          }



          if (citation.author != null) {
            template.by = citation.authors;
            for (let author of Array.from(citation.author)) {
              const new_word = (JSON.parse(JSON.stringify(template)));
              if (author.family != null) {
                new_word.author = removeDiacritics(author.family);
              }
              if (author.litteral != null) {
                new_word.author = removeDiacritics(author.litteral);
              }

              possibleWords.push(new_word);
            }
          }
        }
      }

      return this.possibleWords = possibleWords;
    }

    buildWordListFromFiles(referencesFiles) {
      this.readreferencesFiles(referencesFiles);
      if (this.references) {
        return this.buildWordList();
      }
    }

    readreferencesFiles(referencesFiles) {
      if (referencesFiles.newValue != null) {
        referencesFiles = referencesFiles.newValue;
      }
      // Make sure our list of files is an array, even if it's only one file
      if (!Array.isArray(referencesFiles)) {
        referencesFiles = [referencesFiles];
      }
      try {
        let ftype;
        let references = [];
        for (var file of Array.from(referencesFiles)) {

          // What type of file is this?
          ftype = file.split('.');
          ftype = ftype[ftype.length - 1];
        }

        for (file of Array.from(referencesFiles)) {
          if (fs.statSync(file).isFile()) {

            if (ftype === "json") {
              references = JSON.parse(fs.readFileSync(file, 'utf-8'));
            }

            if (ftype === "yaml") {
              references = yaml.load(fs.readFileSync(file, 'utf-8'));
            }

          } else {
            console.warn(`'${file}' does not appear to be a file, so autocomplete-citeproc will not try to parse it.`);
          }
        }

        return this.references = references;
      } catch (error) {
        return console.error(error);
      }
    }

    prettifyTitle(title) {
      if (!title) { return; }
      title = titlecaps(title);
      return title;
    }

    cleanAuthors(authors) {
      if ((authors == null)) {
        return [{ family: 'Unknown' }];
      } else {
        return authors;
      }
    }

    prettifyAuthors(authors) {
      const name = this.prettifyName(authors[0]);
      let author_string = `${name}`;
      if (authors.length === 2) {
        const name2 = this.prettifyName(authors[1]);
        author_string = `${name} & ${name2}`;
      }
      if (authors.length > 2) {
        author_string = `${name} et al.`;
      }
      return author_string;
    }

    prettifyName(person, separator) {
        if (separator == null) { separator = ' '; }
        if (person.family != null) { return person.family; } else { return ''; }
      }
  };
  referencesProvider.initClass();
  return referencesProvider;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
