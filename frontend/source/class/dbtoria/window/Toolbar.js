/* ************************************************************************

  DbToRia - Database to Rich Internet Application

  http://www.dbtoria.org

   Copyright:
    2011 Oetiker+Partner AG, Olten, Switzerland

   License:
    GPL: http://www.gnu.org/licenses/gpl-2.0.html

   Authors:
    * Fritz Zaucker

************************************************************************ */

qx.Class.define("dbtoria.window.Toolbar", {
    extend : qx.ui.toolbar.ToolBar,
    type : "singleton",

    /*
        *****************************************************************************
    	CONSTRUCTOR
        *****************************************************************************
        */

    construct : function() {
        this.base(arguments);
        this.set({ spacing: 5 });
        var partAction = new qx.ui.toolbar.Part();
        var partTables = new qx.ui.toolbar.Part();
        this.__partTables = partTables;
        var partLast   = new qx.ui.toolbar.Part();

        this.add(partAction);
        this.add(new qx.ui.toolbar.Separator());
        this.add(partTables);
        this.addSpacer();
        this.add(new qx.ui.toolbar.Separator());
        this.add(partLast);
        var menu    = dbtoria.window.TableSelection.getInstance();
        var menuBtn = new qx.ui.toolbar.MenuButton(this.tr("Menu"),"icon/16/places/folder.png", menu);
        menuBtn.set({allowGrowX: false, allowGrowY: false, show: 'icon'});
        partAction.add(menuBtn);
//        partAction.add(new qx.ui.toolbar.Separator());


        this.__rpc = dbtoria.communication.Rpc.getInstance();

        this.__rpc.callAsyncSmart(qx.lang.Function.bind(this.__getTablesHandler, this),
                                  'getToolbarTables');

        var logoutBtn = new qx.ui.toolbar.Button(this.tr("Logout"), "icon/16/actions/application-exit.png").set({show: 'icon'});
        this.__logoutBtn = logoutBtn;
        logoutBtn.setAllowGrowX(false);
        logoutBtn.setAllowGrowY(false);
        partLast.add(logoutBtn);

        // call logout on the backend to destroy session
        logoutBtn.addListener("execute", function(e) {
            this.__rpc.callAsyncSmart(function() {
                window.location.href = window.location.href;
            }, 'logout');
        },
        this);

    },

    members : {
        __rpc     : null,
        __partTables: null,

        __getTablesHandler:  function(ret) {
            var btn, table, i, len=ret.length;
            var tables = [];
            for (i=0; i<len; i++) {
                tables.push(ret[i]);
            }
            var that = this;
            tables.map(
                function(table) {
                    var item = table;
                    var btn = new qx.ui.toolbar.Button(item.name);
                    btn.set({ allowGrowX: false, allowGrowY: false});
                    btn.addListener("execute", function(e) {
                        new dbtoria.window.TableWindow(item.tableId, item.name);
                    }, this);
//                    qx.log.Logger.debug(that, item.name);
                    that.__partTables.add(btn);
                }
            );
        }

    }
});
