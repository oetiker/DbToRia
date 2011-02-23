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




    /*
        *****************************************************************************
    	CONSTRUCTOR
        *****************************************************************************
        */

    construct : function(showViews) {
        this.base(arguments);
        var rpc = dbtoria.communication.Rpc.getInstance();
        var desktop = dbtoria.window.Desktop.getInstance();
        var that = this;

        rpc.callAsyncSmart(function(ret) {
            // generate a button for each table
            for (var i=0; i<ret.length; i++) {
                (function() {
                    var table = ret[i];

                    if (!table.name) {
                        table.name = table.id;
                    }

                    var menuButton = new qx.ui.menu.Button(table.name);
                    that.add(menuButton);

                    menuButton.addListener("execute", function(e) {
                        desktop.add(new dbtoria.window.Table(table.id, table.name));
                    }, this);
                })();
            }
        },
        showViews ? 'getViews' : 'getTables');
    }
});
