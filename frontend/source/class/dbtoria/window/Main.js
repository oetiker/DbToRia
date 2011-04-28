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
#asset(qx/icon/${qx.icontheme}/16/places/folder.png)
#asset(qx/icon/${qx.icontheme}/16/actions/application-exit.png)

************************************************************************ */

/**
 * This class provides the main window for dbtoria.
 *
 * The main window consists of a menu bar, a desktop where the windows are
 * located and a taskbar where minimized windows are held.
 */
qx.Class.define("dbtoria.window.Main", {
    extend : qx.ui.container.Composite,




    /*
        *****************************************************************************
    	CONSTRUCTOR
        *****************************************************************************
        */

    construct : function() {
        var containerLayout = new qx.ui.layout.VBox();
        containerLayout.setSeparator("separator-vertical");
        this.base(arguments, containerLayout);

        // the desktop area is the largest part of dbtoria, make sure it is
        // scrollable
        var desktopContainer = new qx.ui.container.Scroll();

        // the desktop holds all other windows
        var desktop = dbtoria.window.Desktop.getInstance();

        desktopContainer.add(desktop, {
            width  : '100%',
            height : '100%'
        });

        var toolbar = dbtoria.window.Toolbar.getInstance();
        this.add(toolbar);

        this.add(desktopContainer, { flex : 1 });

        var taskbar = dbtoria.window.Taskbar.getInstance();
        this.add(taskbar);

    }
});
