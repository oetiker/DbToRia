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

        var partInfo = new qx.ui.toolbar.Part();
        this.add(partInfo);
        dbtoria.data.Rpc.getInstance().callAsyncSmart( function(name, exc){
            if (exc) {
                dbtoria.ui.dialog.MsgBox.getInstance().exc(exc);
            }
            else {
                var databaseName = new qx.ui.basic.Label().set({
                    alignY: 'middle',
                    value: name,
                    padding: 5
                });
                partInfo.add(databaseName);
            }
        }, 'getConnectionInfo');

        this.add(new qx.ui.toolbar.Separator());

        this.__partDock = new qx.ui.toolbar.Part();       
        this.add(this.__partDock);

        this.addSpacer();

        this.addOverflow();
    },

    members: {

        __databaseName: null,
        __partDock:     null,
        __priority: 0,

        __setDatabaseName: function(name) {
            this.__databaseName.setValue(name);
        },

        dock: function(btn, btnO) {
            this.__partDock.add(btn);
            this.getOverflowMenu().add(btnO);
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
