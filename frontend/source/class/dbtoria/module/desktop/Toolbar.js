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

qx.Class.define("dbtoria.module.desktop.Toolbar", {
    extend : qx.ui.toolbar.ToolBar,
    type : "singleton",

    construct : function() {
        this.base(arguments);
        this.set({ spacing: 5 });
        var partAction = new qx.ui.toolbar.Part();
        var partTables = new qx.ui.toolbar.Part();
        this.__partTables = partTables;
        var partLast   = new qx.ui.toolbar.Part();

        var overflow = new qx.ui.toolbar.MenuButton("More...");
        var overflowMenu = this.__overflowMenu = new qx.ui.menu.Menu();
        overflow.setMenu(overflowMenu);

        this.add(partAction);
        this.add(new qx.ui.toolbar.Separator());
        this.add(partTables);
        this.add(overflow);
        this.setOverflowIndicator(overflow);
        this.addSpacer();
        this.add(new qx.ui.toolbar.Separator());
        this.add(partLast);
        var menu    = dbtoria.module.database.TableSelection.getInstance();
        var menuBtn = new qx.ui.toolbar.MenuButton(this.tr("Menu"),"icon/16/places/folder.png", menu);
        menuBtn.set({allowGrowX: false, allowGrowY: false, show: 'icon'});
        partAction.add(menuBtn);

        this.__rpc = dbtoria.data.Rpc.getInstance();
        this.__rpc.callAsyncSmart(qx.lang.Function.bind(this.__getTablesHandler, this),
                                  'getToolbarTables');

        var logoutBtn = new qx.ui.toolbar.Button(this.tr("Logout"),
                                                 "icon/16/actions/application-exit.png");
        this.__logoutBtn = logoutBtn;
        logoutBtn.set({
//            show: 'icon',
            allowGrowX: false,
            allowGrowY: false
        });
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
        __rpc:          null,
        __partTables:   null,
        __overflowMenu: null,

        __showItem: function(item) {
            item.setVisibility('visible');
            item.getUserData('menuBtn').setVisibility("excluded");
        },

        __hideItem: function(item) {
            item.setVisibility('excluded');
            item.getUserData('menuBtn').setVisibility("visible");
        },

        __getTablesHandler:  function(ret) {
            var btn, table, i, len=ret.length;
            var tables = [];
            for (i=0; i<len; i++) {
                tables.push(ret[i]);
            }
            var that = this;

            // handler for showing and hiding toolbar items
            this.addListener("showItem", function(e) {
                this.__showItem(e.getData());
            }, this);

            this.addListener("hideItem", function(e) {
                this.__hideItem(e.getData());
            }, this);
            this.setOverflowHandling(true);

            var prio = 0;
            tables.map(
                function(table) {
                    var handler = function() {
                        new dbtoria.module.database.TableWindow(table.tableId, table.name);
                    };
                    var btn = new qx.ui.toolbar.Button(table.name);
                    btn.addListener("execute", handler, this);
                    var btnO = new qx.ui.menu.Button(table.name);
                    btnO.addListener("execute", handler, this);
                    btnO.setVisibility("excluded");
                    that.setRemovePriority(btn, prio++);
                    btn.setUserData('menuBtn', btnO);
                    that.__partTables.add(btn);
                    that.__overflowMenu.add(btnO);
                }
            );

        }

    }
});
