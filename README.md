# autocomplete-citeproc package

Adds citation key autocompletion to
[autocomplete+] for [Atom].

[autocomplete+]: https://github.com/saschagehlich/autocomplete-plus
[Atom]: http://atom.io/

This package allows autocompletion of references keys from a file in the
citeproc format (either as `json`  or `yaml`). The citeproc format is used
natively by pandoc, and offers support for more document types than bibtex does.
This package is a fork of [autocomplete-bibtex], with the bibtex-only code
removed.

[autocomplete-bibtex]: https://github.com/apcshields/autocomplete-bibtex

The package will look for files called `bibliography.json`, `default.json`, or
`references.json`, stored *at the root of the project*.

## Key features

- Works with citeproc
- Gives context for each reference, including URL to source
- Icons for different types of documents
- Uses autocomplete-+ v. 2

## Screenshot

![screenshot](img/scrot.png)
