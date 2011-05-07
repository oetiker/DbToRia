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
    extend : qx.ui.toolbar.ToolBar,
    type : "singleton",

    construct : function() {
        this.base(arguments);

        var partInfo = new qx.ui.toolbar.Part();
        this.__partDock = new qx.ui.toolbar.Part();

        this.__databaseName = new qx.ui.basic.Label();
        this.__databaseName.set({
            alignY: 'middle',
            padding: 5
        });


        this.add(partInfo);
        this.add(this.__partDock);
        partInfo.add(this.__databaseName);

        this.__rpc = dbtoria.data.Rpc.getInstance();
        this.__rpc.callAsyncSmart(qx.lang.Function.bind(this.__setDatabaseName, this), 'getDatabaseName');

    },

    members: {

        __databaseName: null,
        __partDock:     null,

        __setDatabaseName: function(name) {
//            this.debug('name='+name);
            this.__databaseName.setValue(name);
        },

        dock: function(btn) {
            this.__partDock.add(btn);
        }

    }

});
