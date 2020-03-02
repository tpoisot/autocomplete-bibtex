# Work with citeproc formatted bibliographies

This package uses [autocomplete+] and notifications to (i) autocomplete citation
keys from a JSON file and (ii) inspect the content of references.

[autocomplete+]: https://github.com/saschagehlich/autocomplete-plus

This package allows autocompletion of references keys from a file in the
citeproc format (as `json`). The citeproc format is used natively by pandoc, and
offers support for more document types than bibtex does. This package is a fork
of [autocomplete-bibtex], with the bibtex-only code removed, and some code from
[autocomplete-latex-cite].

[autocomplete-bibtex]: https://github.com/apcshields/autocomplete-bibtex
[autocomplete-latex-cite]: https://github.com/hesstobi/atom-autocomplete-latex-cite

The package will look for files called `bibliography.json`, `default.json`, or
`references.json`, stored *at the root of the project*.

## Key features

- Works with citeproc JSON files
- Gives context for each reference, including URL to source
- Icons for different types of documents
- Reload references in real time
- Uses autocomplete-+ v. 2
- Press `ctrl-alt-p` to see the content of the citation key under the cursor
- Press `ctrl-alt-b` to see a pane with all the references - clicking on a reference adds it under the cursor

## Screenshot

![screenshot](img/scrot.png)
