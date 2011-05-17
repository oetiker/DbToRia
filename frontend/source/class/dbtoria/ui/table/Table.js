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

            this.addListener('cellChange', this.__cellChange,   this);
        },

        /* we can't rely on the table showing/hiding tooltip as we
         * don't want the tooltip to be open if we are outside a
         * regular row and a column with reference.
         */
        __cellChange: function(e) {
            var data = e.getData();
            var row   = data.row;
            var col   = data.col;
            var mouse = data.mouse; // mouse event
            this.debug('__cellChange(): row='+row+', col='+col);

            // close and remove tooltip if not over a table cell
            if (row == null || row == -1) {
                this.setToolTip(null); // remove
                // force tooltip off
                qx.ui.tooltip.Manager.getInstance().setCurrent(null);
                return;
            }
            var tm       = this.getTableModel();
            var colId    = tm.getColumnId(col);
//            var tableId  = tm.getTableId();
            var tableId  = this.__tableId;
            var rowInfo  = tm.getRowData(row);
            var recordId;
            if (rowInfo) {
                recordId = rowInfo['ROWINFO'][0];
            }

            var params = {
                tableId:  tableId,
                recordId: recordId,
                columnId: colId
            };
            qx.dev.Debug.debugObject(params);
            // check if we are in a column referencing another table
//           if (true) {
//                return;
//           }

            this.__tooltip.placeToMouse(mouse);
            var rpc = dbtoria.data.Rpc.getInstance();
            // Get appropriate row from referenced table
            rpc.callAsyncSmart(qx.lang.Function.bind(this.__referenceHandler, this),
                               'getReferencedRecord', params);
        },

        __referenceHandler: function(ret) {
            return;
            this.__tooltip.setLabel(ret);
            this.setToolTip(this.__tooltip); // set
            this.__tooltip.show();           // show
        }

    },

    /*** DESTRUCTOR ***/
    destruct : function() {
        // Dispose fields/objects
        this.__cache   = null;
        this.__tooltip = null;
    }

});
