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
    extend : qx.ui.table.Table,
    include : [ qx.ui.table.MTableContextMenu ],

    construct : function(tm) {

        var tableOpts = {
            tableColumnModel : function(obj) {
                return new qx.ui.table.columnmodel.Resize(obj);
            }
        };
        this.base(arguments, tm, tableOpts);
        this.set({
            showCellFocusIndicator : false,
            decorator              : null
        });
        this.getDataRowRenderer().setHighlightFocusRow(false);
    },

    members: {

        // selectRow: function(recordId) {
        //     var tm = this.getTableModel();
        //     var sm = this.getSelectionModel();
        //     var sa, si = tm.getSortColumnIndex();
        //     this.debug('sortIndex='+si);
        //     if (si>=0) {
        //         sa = tm.isSortAscending();
        //     }
        //     this.debug('sortAscending='+sa);
        //     tm.sortByColumn(0, false);
        //     sm.setSelectionInterval(0,0);
        //     this.scrollCellVisible(0, 0);
        //     if (si >= 0) {
        //         tm.sortByColumn(si, sa);
        //     }
        // }

    }

});
