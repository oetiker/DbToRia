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
//    extend : qx.ui.toolbar.ToolBar,
    extend : qx.ui.container.Composite,
    type : "singleton",

    /*
        *****************************************************************************
    	CONSTRUCTOR
        *****************************************************************************
        */

    construct : function() {
        this.base(arguments);

        this.setLayout(new qx.ui.layout.VBox());
        var layout = new qx.ui.layout.Grow();
        layout = new qx.ui.layout.Flow();
        var toolbar = new qx.ui.toolbar.ToolBar;
        this.add(toolbar);
        var buttons = dbtoria.window.TableSelection.menuButtons();
//        var menuBtn = new qx.ui.toolbar.MenuButton(this.tr("Menu"),"icon/16/places/folder.png", menu).set({show: 'icon'});
//        menuBtn.setAllowGrowX(false);
//        menuBtn.setAllowGrowY(false);
//        this.__menuBtn = menuBtn;
//        toolbar.add(menuBtn);
        toolbar.add(buttons.tables);
        toolbar.add(buttons.views);
        toolbar.add(buttons.pearls);

        this.__tableContainer = new qx.ui.container.Composite(layout);
//        this.__tableContainer.set({
//                     contentPadding: 0
//                 });
        this.add(this.__tableContainer);

//        var overflow = new qx.ui.toolbar.MenuButton("More...");
//        this.add(overflow);
//        this.setOverflowIndicator(overflow);
//        this.setOverflowHandling(true);

        toolbar.addSpacer();

        this.__rpc = dbtoria.communication.Rpc.getInstance();

        this.__rpc.callAsyncSmart(qx.lang.Function.bind(this.__getTablesHandler, this),
                                  'getToolbarTables');

        var logoutBtn = new qx.ui.toolbar.Button(this.tr("Logout"), "icon/16/actions/application-exit.png").set({show: 'icon'});
        this.__logoutBtn = logoutBtn;
        logoutBtn.setAllowGrowX(false);
        logoutBtn.setAllowGrowY(false);
        toolbar.add(logoutBtn);

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
        __menuBtn : null,
        __logoutBtn : null,
        __tableContainer: null,

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
                    btn.setAllowGrowX(false);
                    btn.setAllowGrowY(false);
                    btn.setPadding(2);
                    btn.addListener("execute", function(e) {
                        new dbtoria.window.TableWindow(item.tableId, item.name);
                    }, this);
                    qx.log.Logger.debug(null, item.name);
                    that.__tableContainer.add(btn);
                }
            );
        }

    }
});