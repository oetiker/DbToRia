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

/* ************************************************************************

#asset(dbtoria/*)

************************************************************************ */

/**
 * This class provides a window to choose a table
 *
 * The database is asked for all available tables. A list of buttons is
 * generated and a click on them opens the detailled TableView.
 */
qx.Class.define("dbtoria.module.database.TableSelection", {
    extend : qx.ui.menu.Menu,
    type : "singleton",

    construct : function() {
        this.base(arguments);
        var rpc = dbtoria.data.Rpc.getInstance();
        var that = this;
        var tableMenu = new qx.ui.menu.Menu();
        var viewMenu  = new qx.ui.menu.Menu();
        var pearlMenu = new qx.ui.menu.Menu();
        var tableButton = new qx.ui.menu.Button(this.tr('Tables'), null, null, tableMenu).set({enabled: false});
        var viewButton  = new qx.ui.menu.Button(this.tr('Views'),  null, null, viewMenu).set({enabled: false});
        var pearlButton = new qx.ui.menu.Button(this.tr('Pearls'), null, null, pearlMenu).set({enabled: false});
        this.add(tableButton);
        this.add(viewButton);
        this.add(pearlButton);
        rpc.callAsyncSmart(function(ret) {
            // generate a button for each table
            var tables = [];
            for (var tableId in ret) {
                tables.push(tableId);
            }
            tables.sort(function(a,b){
                if (ret[a].name > ret[b].name) return 1;
                if (ret[a].name < ret[b].name) return -1;
                return 0;
            }).map(
                function(tableId) {
                    var item = ret[tableId];
                    item.label = item.name;
                    if (item.readOnly) {
                        item.label += '*';
                    }
                    var menuButton = new qx.ui.menu.Button(item.label);
                    if (item.type == 'TABLE'){
                        tableMenu.add(menuButton);
                        tableButton.setEnabled(true);
                    }
                    else if (item.type == 'VIEW') {
                        viewMenu.add(menuButton);
                        viewButton.setEnabled(true);
                    }
                    else if (item.type == 'PEARL') {
                        pearlMenu.add(menuButton);
                        pearlButton.setEnabled(true);
                    }
                    menuButton.addListener("execute", function(e) {
                        var viewMode = (item.type != 'TABLE');
                        new dbtoria.module.database.TableWindow(tableId, item.name, viewMode);
                    }, this);
                }
            );
        },
        'getTables');
   }

});
