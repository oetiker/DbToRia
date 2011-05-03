/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPL
   Authors:    Tobias Oetiker
   Utf8Check:  äöü

************************************************************************ */

/*
*/

/**
 * Create a table according to the instructions provided.
 */
qx.Class.define("dbtoria.ui.table.Table", {
    extend  : qx.ui.table.Table,
    include : [ qx.ui.table.MTableContextMenu ],

    construct : function(tm) {

        var tableOpts = {
            tableColumnModel : function(obj) {
                return new qx.ui.table.columnmodel.Resize(obj);
            }
//            tablePaneScroller : function(obj) {
//                return new dbtoria.ui.table.pane.Scroller(obj);
//            }
        };
        this.base(arguments, tm, tableOpts);
        this.set({
            showCellFocusIndicator : false,
            decorator              : null
        });
        this.getDataRowRenderer().setHighlightFocusRow(false);
        this.getTableColumnModel().setBehavior(new dbtoria.ui.table.columnmodel.resizebehavior.Enhanced());
    },

    members: {
    }

});
