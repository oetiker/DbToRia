/* ************************************************************************

  DbToRia - Database to Rich Internet Application

  http://www.dbtoria.org

   Copyright:
    2009 David Angleitner, Switzerland
    2011 Oetiker+Partner AG, Olten, Switzerland

   License:
    GPL: http://www.gnu.org/licenses/gpl-2.0.html

   Authors:
    * David Angleitner
    * Fritz Zaucker

************************************************************************ */

qx.Class.define("dbtoria.module.desktop.Taskbar", {
    extend : dbtoria.module.desktop.AutoToolbar,
    type : "singleton",

    construct : function() {
        this.base(arguments);

        var partInfo    = new qx.ui.toolbar.Part();
        this.__partDock = new qx.ui.toolbar.Part();
        var partLink    = new qx.ui.toolbar.Part();
        this.__databaseName = new qx.ui.basic.Label();
        this.__databaseName.set({
            alignY: 'middle',
            padding: 5
        });

        var link = new qx.ui.basic.Atom();
        link.set({
            rich:  true,
            label: "Created with <a target=\"_blank\" href=\"http://www.dbtoria.org\">DbToRia</a>"
                 });

        partLink.add(link);
        this.add(partInfo);
        this.add(new qx.ui.toolbar.Separator());
        this.add(this.__partDock);
        this.addSpacer();
        this.addOverflow();
        this.add(new qx.ui.toolbar.Separator());
        this.add(partLink);
        partInfo.add(this.__databaseName);

        this.__rpc = dbtoria.data.Rpc.getInstance();
        this.__rpc.callAsyncSmart(qx.lang.Function.bind(this.__setDatabaseName, this), 'getDatabaseName');

    },

    members: {

        __databaseName: null,
        __partDock:     null,
        __priority: 0,
        _overflowMenu: null,

        __setDatabaseName: function(name) {
//            this.debug('name='+name);
            this.__databaseName.setValue(name);
        },

        dock: function(btn, btnO) {
            this.__partDock.add(btn);
            this._overflowMenu.add(btnO);
            this.setRemovePriority(btn, this.__priority++);
            btn.setUserData('menuBtn', btnO);
            btn.addListener('appear', function() {
                var pane = this.getLayoutParent();
                this.fireDataEvent('resize', pane.getBounds());
            }, this);
            btn.addListener('disappear', function() {
                var pane = this.getLayoutParent();
                this.fireDataEvent('resize', pane.getBounds());
            }, this);
        }

    }

});
