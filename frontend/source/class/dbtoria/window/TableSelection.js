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
    extend : qx.ui.menu.Menu,
    construct : function() {
        this.base(arguments);
        var rpc = dbtoria.communication.Rpc.getInstance();
        var desktop = dbtoria.window.Desktop.getInstance();
        var that = this;
        var tableMenu = qx.ui.menu.Menu();
        var viewMenu = qx.ui.menu.Menu();
        this.add(new qx.ui.menu.Button(this.tr('Tables',null,null,tableMenu)));
        this.add(new qx.ui.menu.Button(this.tr('Views',null,null,viewMenu))); 
        rpc.callAsyncSmart(function(ret) {
            // generate a button for each table
            for (var i=0; i<ret.length; i++) {
                (function() {
                    var item = ret[i];
                    var menuButton = new qx.ui.menu.Button(item.name);
                    if (item.type == 'TABLE'){
                        tableMenu.add(menuButton);
                    }
                    else {
                        viewMenu.add(menuButton);
                    }
                    menuButton.addListener("execute", function(e) {
                        desktop.add(new dbtoria.window.TableWindow(table.id, table.name));
                    }, this);
                })();
            }
        },
        'getTables');
    }
});
