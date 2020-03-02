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
    this.subscriptions.add(atom.commands.add('atom-text-editor', {
      ['autocomplete-citeproc:bibliography']: () => this.bibliography()
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
    if (re) {
      // console.log(re);
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
  },

  bibliography: function () {
    bibpanecontent = document.createElement("div");
    bibpanecontent.setAttribute("id", "citeproc-bibliography");
    for (var key in this.provider.manager.database) {
      refobject = this.provider.manager.database[key];
      refcontent = document.createElement("div");
      refcontent.setAttribute("id", refobject.id);
      refcontent.setAttribute("class", "citeproc-reference");
      refcontent.onclick = function() {
        ed = atom.workspace.getActiveTextEditor();
        po = ed.getCursorBufferPosition();
        ed.insertText("@".concat(refobject.id));
      },
      reftitle = document.createElement("div");
      reftitle.setAttribute("class", "title");
      reftitle.textContent = refobject.prettyTitle;
      refauth = document.createElement("div");
      refauth.setAttribute("class", "author");
      refauth.textContent = refobject.prettyAuthors;
      refcontent.appendChild(reftitle);
      refcontent.appendChild(refauth);
      bibpanecontent.appendChild(refcontent);
    }
    const item = {
      element: bibpanecontent,
      getTitle: () => 'References',
      getIconName: () => 'mortar-board',
      getURI: () => 'atom://autocomplete-citeproc/references',
      getPreferredWidth: () => 200,
      getDefaultLocation: () => 'right'
    };
    atom.workspace.open(item);
  }

};
