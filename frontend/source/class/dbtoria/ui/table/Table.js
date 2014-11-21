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
    include : [ qx.ui.table.MTableContextMenu, dbtoria.ui.table.MTableCellChange ],

    construct : function(tm, tableId) {
        this.__tableId = tableId;
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
        this.getTableColumnModel().setBehavior(new dbtoria.ui.table.columnmodel.resizebehavior.Enhanced());

        this.__createTooltip();
    },

    members: {
        __tooltip: null,
        __cache:   null, // cache for referenced data
        __tableId: null,

        __createTooltip: function() {
            this.__tooltip = new qx.ui.tooltip.ToolTip();
            this.__tooltip.set({
                showTimeout : 250,
                hideTimeout : 100000000,
                rich        : true
            });
        },

        updateTooltip: function(text) {
	    text = '<b>'+this.__tableId+'</b><br/>'+text;
            this.__tooltip.setLabel(text);
            this.showTooltip();
        },

        showTooltip: function() {
            this.setToolTip(this.__tooltip);
            this.__tooltip.show(); // show
        },

        hideTooltip: function() {
            this.setToolTip(null);
            qx.ui.tooltip.Manager.getInstance().setCurrent(null);
            this.__tooltip.hide();
        }

        /* we can't rely on the table showing/hiding tooltip as we
         * don't want the tooltip to be open if we are outside a
         * regular row and a column with reference.
         */

    },

    /*** DESTRUCTOR ***/
    destruct : function() {
        // Dispose fields/objects
        this.__cache   = null;
        this.__tooltip = null;
    }

});
