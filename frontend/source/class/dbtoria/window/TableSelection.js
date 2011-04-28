/* ************************************************************************

  DbToRia - Database to Rich Internet Application

  http://www.dbtoria.org

   Copyright:
    2009 David Angleitner, Switzerland

   License:
    GPL: http://www.gnu.org/licenses/gpl-2.0.html

   Authors:
    * David Angleitner

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
qx.Class.define("dbtoria.window.TableSelection", {
   type : 'static',

//    extend : qx.ui.menu.Menu,
//    construct : function() {

   statics : {

   menuButtons: function() {
//       this.base(arguments);
        var rpc = dbtoria.communication.Rpc.getInstance();
        var that = this;
        var tableMenu = new qx.ui.menu.Menu();
        var viewMenu = new qx.ui.menu.Menu();
        var pearlMenu = new qx.ui.menu.Menu();
//        var tableButton = new qx.ui.menu.Button(this.tr('Tables'),null,null,tableMenu);
//        var viewButton = new qx.ui.menu.Button(this.tr('Views'),null,null,viewMenu);
        var tableButton = new qx.ui.toolbar.MenuButton('Tables',"icon/16/places/folder.png",tableMenu);
        var viewButton = new qx.ui.toolbar.MenuButton('Views',"icon/16/places/folder.png",viewMenu);
        var pearlButton = new qx.ui.toolbar.MenuButton('Pearls',"icon/16/places/folder.png",pearlMenu);
//        this.add(new qx.ui.menu.Button(this.tr('Tables'),null,null,tableMenu));
//        this.add(new qx.ui.menu.Button(this.tr('Views'),null,null,viewMenu));
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
                    var menuButton = new qx.ui.menu.Button(item.name);
                    if (item.type == 'TABLE'){
                        tableMenu.add(menuButton);
                    }
                    else {
                        viewMenu.add(menuButton);
                    }
                    menuButton.addListener("execute", function(e) {
                        new dbtoria.window.TableWindow(tableId, item.name);
                    }, this);
                }
            );
        },
        'getTables');
       return {
           tables: tableButton,
           views:  viewButton,
           pearls: pearlButton
       };
   }
   }
});
