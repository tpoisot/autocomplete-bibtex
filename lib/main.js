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
    // TODO only do it for the correct scope
    wc = ed.getWordUnderCursor();
    re = this.provider.manager.database[wc];
    if (re) {
      console.log(re);
      notification_title = re.prettyAuthors + "(" + re.prettyYear + ")";
      notification_detail = re.prettyTitle;
      notification_description = "";
      if (re["container-title"]) {
        notification_description += `In *${re["container-title"]}*   `;
      }
      if (re["URL"]) {
        notification_description += `[URL](${re.URL})   `
      }
      if (re["DOI"]) {
        notification_description += `[\`${re.DOI}\`](${re.DOI})   `
      }
      notification_options = {
        description: notification_description,
        detail: notification_detail,
        icon: "mortar-board",
        dismissable: true
      }
      atom.notifications.addInfo(notification_title, notification_options);
    }
  }

};
