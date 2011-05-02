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

qx.Class.define("dbtoria.module.desktop.Taskbar", {
    extend : qx.ui.toolbar.ToolBar,
    type : "singleton",

    construct : function() {
        this.base(arguments);
    }

});
