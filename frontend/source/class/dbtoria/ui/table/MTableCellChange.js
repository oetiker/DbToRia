/* ************************************************************************
   Copyright: 2011 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch?
   Utf8Check: äöü
************************************************************************ */

/**
 * Mixin for qx.ui.table.Table to fire events when the mouse is moved
 * for cell to cell (can for example be used for showing cell/header specific tooltips).
 */
qx.Mixin.define("dbtoria.ui.table.MTableCellChange", {
    construct : function() {
       this.addListener("mousemove", this._onMouseMove, this);
    },

    /*** EVENTS ***/
    events : {

        /**
         * Dispatched when the mouse position is changing cell.
         *
         * Data: map with row and col of cell, and origional mouse event.
         */
        "cellChange"   : "qx.event.type.Data"

    },

    /*** MEMBERS ***/
    members : {
        /**
         * {Integer}
         * Index of column over which the mouse was previously.
         */
        __prevOverCol : -1,

        /**
         * {Integer}
         * Index of row over which the mouse was previously.
         */
        __prevOverRow : -1,


        /**
         * The "mousemove" event handler.
         *
         * @param event {qx.event.type.MouseEvent} the event object.
         * @return {void}
         */
        _onMouseMove : function(e) {
            var pageX = e.getDocumentLeft();
            var pageY = e.getDocumentTop();
            var scroller = this.getTablePaneScrollerAtPageX(pageX);
            if (!scroller) {
                this.debug('_onMouseMove(): Outsider scroller.');
                return;
            }

            var row = scroller._getRowForPagePos(pageX, pageY);
            var col = scroller._getColumnForPageX(pageX);
            if (col != this.__prevOverCol || row != this.__prevOverRow) {
                this.fireDataEvent('cellChange', {'row' : row, 'col' : col, 'mouse' : e});
                this.__prevOverCol = col;
                this.__prevOverRow = row;
            }
        }
    },


    /*** DESTRUCTOR ***/
    destruct : function() {
        // Dispose fields/objects
        this.__prevOverCol = null;
        this.__prevOverRow = null;
    }
});
