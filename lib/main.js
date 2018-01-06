'use babel';

import { CompositeDisposable } from 'atom';

export default {
  config: require('./config'),
  provider: null,
  subscriptions: null,

  activate: function() {
    this.subscriptions = new CompositeDisposable();
    this.subscriptions.add(atom.commands.add('atom-text-editor', {
      ['autocomplete-citeproc:notify']: () => this.notify()
    }));
  },

  deactivate: function() {
    this.provider = null;
    return this.subscriptions.dispose();
  },

  provide: function() {
    var CiteProvider;
    if (this.provider == null) {
      CiteProvider = require('./provider');
      this.provider = new CiteProvider();
    }
    return this.provider;
  },

  notify: function() {
    ed = atom.workspace.getActiveTextEditor();
    po = ed.getCursorBufferPosition();
    sc = ed.scopeDescriptorForBufferPosition(po);
    wc = ed.getWordUnderCursor();
    re = this.provider.manager.database[wc];
    console.log(re);
    notification_options = {description: re.prettyTitle, icon: "mortar-board", dismissable: true}
    notification_title = re.prettyAuthors;
    atom.notifications.addInfo(notification_title, notification_options);
  }

};
