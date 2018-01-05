'use babel';

function enhanceReferences(references) {
  for (let reference of references) {

    if (reference.title) {
      reference.title = reference.title.replace(/(^\{|\}$)/g, "")
      reference.prettyTitle = this.prettifyTitle(reference.title)
    }

    reference.prettyAuthors = ''
    if (reference.author) {
      reference.prettyAuthors = this.prettifyAuthors(reference.author)
    }

    reference.type = reference.type.toLowerCase()

    reference.in = reference.in || reference.journal || reference.booktitle || ''

    let author = reference.prettyAuthors
    if (author) {
      author = `${author}, `
    }

    let refin = reference.in
    if (refin) {
      refin = `*${refin}*, `
    }

    let year = reference.year || ''

    reference.markdownCite = `${author}"**${reference.prettyTitle}**", ${refin}${year}.`
  }
  return references
}

function prettifyTitle(title) {
  let colon
  if (!title) {
    return
  }
  if (((colon = title.indexOf(':')) !== -1) && (title.split(" ").length > 5)) {
    title = title.substring(0, colon)
  }

  return title
}

function prettifyAuthors(authors) {
  if ((authors == null)) {
    return ''
  }
  if (!authors.length) {
    return ''
  }


  let firstAuthors = []
  for (let author of authors.slice(0,3)) {
    firstAuthors.push(this.prettifyName(author))
  }

  let name = firstAuthors.join('; ')

  if (authors.length > 3) {
    return `${name} et al.`
  }
  return `${name}`
}

function prettifyName(person, inverted = false, separator = ' ') {
  return ((person.institution) ? person.institution : ((person.family) ? person.family : "Anonymous"));
}

module.exports = {enhanceReferences, prettifyTitle, prettifyAuthors, prettifyName}
