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
#asset(qx/icon/${qx.icontheme}/16/mimetypes/text-plain.png)

************************************************************************ */

/**
 * This class provides the basic functionality of DBToRia desktop windows:
 *
 * - Minimization of window to taskbar
 * - Adding window to bookmark bar (not yet implemented)
 */
qx.Class.define("dbtoria.window.DesktopWindow", {
    extend : qx.ui.window.Window,
    construct : function() {
        this.base(arguments);
        // this.set({
            // contentPadding : 0,
            // width          : 800,
            // height         : 500,
        // });

        // add to desktop
        dbtoria.window.Desktop.getInstance().add(this);

        // on clicking the minimize button a new button on the taskbar is
        // generated which allows to restore the window again
        this.addListener("minimize",
                         function(e) {
                             var taskbarButton =
                                 new qx.ui.toolbar.Button(this.getCaption(),
                                                          "icon/16/mimetypes/text-plain.png");
                             var taskbar = dbtoria.window.Taskbar.getInstance();
                             taskbar.add(taskbarButton);
                             taskbarButton.addListener("execute",
                                                       function(e) {
                                                           this.open();
                                                           taskbar.remove(taskbarButton);
                                                       },
                                                       this);
                         },
                         this);
    },

    members : {
    }

});
