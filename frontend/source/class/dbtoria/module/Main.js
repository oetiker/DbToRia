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

/* ************************************************************************

#asset(dbtoria/*)
#asset(qx/icon/${qx.icontheme}/16/places/folder.png)
#asset(qx/icon/${qx.icontheme}/16/actions/application-exit.png)

************************************************************************ */

/**
 * This class provides the main window for dbtoria.
 *
 * The main window consists of a menu bar and a tabview on which the
 * tables are placed.
 */
qx.Class.define("dbtoria.module.Main", {
    extend : qx.ui.container.Composite,

    construct : function() {
        var containerLayout = new qx.ui.layout.VBox();
        containerLayout.setSeparator("separator-vertical");
        this.base(arguments, containerLayout);

        var tabview = dbtoria.module.desktop.Desktop.getInstance();
        var toolbar = dbtoria.module.desktop.Toolbar.getInstance();

        this.add(toolbar);
        this.add(tabview, {flex:1});
    }
});
