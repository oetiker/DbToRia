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
    extend : dbtoria.module.desktop.AutoToolbar,
    type : "singleton",

    construct : function() {
        this.base(arguments);


        var partAction = new qx.ui.toolbar.Part();
        var partTables = new qx.ui.toolbar.Part();
        this.__partTables = partTables;
        var partLast   = new qx.ui.toolbar.Part();

        this.add(partAction);
        this.add(new qx.ui.toolbar.Separator());
        this.add(partTables);
        this.addSpacer();
        this.addOverflow();
        this.add(new qx.ui.toolbar.Separator());
        this.add(partLast);
        var menu    = dbtoria.module.database.TableSelection.getInstance();
        var menuBtn = new qx.ui.toolbar.MenuButton(this.tr("Menu"),"icon/16/places/folder.png", menu);
        menuBtn.set({ show: 'icon'});
        partAction.add(menuBtn);

        this.__rpc = dbtoria.data.Rpc.getInstance();
        this.__rpc.callAsyncSmart(qx.lang.Function.bind(this.__getTablesHandler, this),
                                  'getToolbarTables');

        var logoutBtn = new qx.ui.toolbar.Button(this.tr("Logout"),
                                                 "icon/16/actions/application-exit.png");
        this.__logoutBtn = logoutBtn;
        logoutBtn.set({
            show: 'icon'
        });
        var username = new qx.ui.basic.Label();
        username.set({
            alignY: 'middle',
            padding: 5
        });
        this.__username = username;
        partLast.add(username);
        partLast.add(logoutBtn);

        // call logout on the backend to destroy session
        logoutBtn.addListener("execute", function(e) {
            this.__rpc.callAsyncSmart(function() {
                window.location.href = window.location.href;
            }, 'logout');
        },
        this);

        this.__rpc = dbtoria.data.Rpc.getInstance();
        this.__rpc.callAsyncSmart(
            qx.lang.Function.bind(function(ret) {
                this.__username.setValue(ret);
            }, this), 'getUsername');

    },

    members : {
        __rpc:          null,
        __partTables:   null,
        _overflowMenu: null,
        __username:     null,

        setUsername: function(username) {
            this.__username.setValue(username);
        },

        __getTablesHandler:  function(tables) {
            var that = this;

            var prio = 0;
            var lastButton;
            tables.map(
                function(table) {
                    var handler = function() {
                        new dbtoria.module.database.TableWindow(table.tableId, table.name, null, table.readOnly);
                    };
                    table.label = table.name;
                    if (table.readOnly) {
                        table.label += '*';
                    }
                    var btn = new qx.ui.toolbar.Button(table.label);
                    lastButton = btn;
                    btn.addListener("execute", handler, this);
                    var btnO = new qx.ui.menu.Button(table.label);
                    btnO.addListener("execute", handler, this);
                    btnO.setVisibility("excluded");
                    that.setRemovePriority(btn, prio++);
                    btn.setUserData('menuBtn', btnO);
                    that.__partTables.add(btn);
                    that._overflowMenu.add(btnO);
                }
            );
            // force the overflow to be recalculate when all the buttons are there
            // naive me would expect this not to be neccessary
            lastButton.addListenerOnce('appear',function(){
                var pane = this.getLayoutParent();
                this.fireDataEvent('resize', pane.getBounds());
            },this);
            // nor this
            this.getOverflowIndicator().addListener('appear',function(){
                var pane = this.getLayoutParent();
                this.fireDataEvent('resize', pane.getBounds());
            },this);
        }
    }
});
