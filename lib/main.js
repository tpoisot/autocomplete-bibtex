/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const fs = require('fs')
const path = require('path')

const ReferencesProvider = require('./provider')
const pathWatcher = require('pathwatcher')

module.exports = {

  config: {
    references: {
      type: 'array',
      default: ['default.json', 'bibliography.json', 'references.json'],
      items: {
        type: 'string'
      }
    },
    scope: {
      type: 'string',
      default: '.gfm,.md'
    },
    ignoreScope: {
      type: 'string',
      default: '.comment'
    },
    resultTemplate: {
      type: 'string',
      default: '@[key]'
    }
  },

  activate(state) {
    let reload = false;
    if (state) {
      let error, stats;
      const tempReferencesFiles = atom.config.get("autocomplete-citeproc.references");
      let referencesFiles = [];
      // Add the reference files
      const projectpath = atom.project != null ? atom.project.getPaths()[0] : undefined;
      for (let t of Array.from(tempReferencesFiles)) {
        const tfile = [projectpath, t].join("/");
        try {
          stats = fs.statSync(tfile);
          if (stats.isFile()) {
            referencesFiles.push(tfile);
          }
        } catch (error1) {
          error = error1;
          console.log("No such reference file");
        }
      }
      this.stateTime = state.saveTime;
      if (!Array.isArray(referencesFiles)) {
        referencesFiles = [referencesFiles];
      }
      // reload everything if any files changed
      for (let file of Array.from(referencesFiles)) {
        try {
          stats = fs.statSync(file);
          if (stats.isFile()) {
            const watcher = pathWatcher.watch(file, function(type, path) {
              if (type === "change") {
                return console.log("Reference file changed -- currently unimplemented");
              }
            });
            if (state.saveTime <= stats.mtime.getTime()) {
              reload = true;
              this.stateTime = new Date().getTime();
            }
          }
        } catch (error2) {
          error = error2;
          console.log("No references file is present");
        }
      }
    }

    // Need to distinguish between the Autocomplete provider and the
    // containing class (which holds the serialize function)
    if (state && (reload === false)) {
      this.ReferencesProvider = atom.deserializers.deserialize(state.provider)
      // deserializer produces "undefined" if it fails, so double check
      if (!this.ReferencesProvider) {
        this.ReferencesProvider = new ReferencesProvider();
      }
    } else {
      this.ReferencesProvider = new ReferencesProvider();
    }

    return this.provider = this.ReferencesProvider.provider;
  },

  deactivate () {
    pathWatcher.closeAllWatchers()
    return this.provider.registration.dispose()
  },

  serialize () {
    const state = {
      provider: this.ReferencesProvider.serialize(),
      saveTime: this.stateTime != null ? this.stateTime : new Date().getTime()
    }
    return state
  },

  provide () {
    return this.provider
  }
}
