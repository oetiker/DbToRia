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
#asset(qx/icon/${qx.icontheme}/16/places/folder.png)
#asset(qx/icon/${qx.icontheme}/16/actions/application-exit.png)

************************************************************************ */

/**
 * This class provides the main window for dbtoria.
 *
 * The main window consists of a menu bar, a desktop where the windows are
 * located and a taskbar where minimized windows are held.
 */
qx.Class.define("dbtoria.module.Main", {
    extend : qx.ui.container.Composite,

    construct : function() {
        var containerLayout = new qx.ui.layout.VBox();
        containerLayout.setSeparator("separator-vertical");
        this.base(arguments, containerLayout);

        // the desktop area is the largest part of dbtoria, make sure it is
        // scrollable
        var desktopContainer = new qx.ui.container.Scroll();

        // the desktop holds all other windows
        var desktop = dbtoria.module.desktop.Desktop.getInstance();

        desktopContainer.add(desktop, {
            width  : '100%',
            height : '100%'
        });

        var toolbar = dbtoria.module.desktop.Toolbar.getInstance();
        this.add(toolbar);

        this.add(desktopContainer, { flex : 1 });

        var taskbar = dbtoria.module.desktop.Taskbar.getInstance();
        this.add(taskbar);

    }
});
