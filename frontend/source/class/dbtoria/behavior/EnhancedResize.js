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

************************************************************************ */

/**
 * This is an enhanced resize behavior for the tables in DbToRia
 * 
 * It's rather complex and expensive, but since tables are the main
 * part of DbToRia it is thought to be acceptable because it enhances
 * the usability a lot.
 *
 * There are two modes: Scrolling on or off
 * If scrolling is set to off, the columns are laid out in a way that all
 * column widths match the table width. If scrolling is set to yes it is
 * thought to be acceptable to be wider than the window.
 *
 * The behavior switches between these modes automatically, this is determined
 * by checking how many column headers would be cropped if it was displayed
 * without a scrollbar. If there is more than one the mode is switched to
 * scrolling.
 *
 * In scrolling mode the width of the column is at least wide enough to
 * display the table header. Further the longest data string in the first few
 * data rows (configured by __numSamples) is taken. If it is below 200px
 * the column width is set to fit the data.
 *
 * In non-scrolling mode a percentage value for each column is calculated - if
 * available from the first data rows, otherwise from the header name.
 * 
 */
qx.Class.define("dbtoria.behavior.EnhancedResize", {
    extend : qx.ui.table.columnmodel.resizebehavior.Abstract,




    /*
        *****************************************************************************
    	CONSTRUCTOR
        *****************************************************************************
        */

    construct : function() {
        this.base(arguments);
    },




    /*
        *****************************************************************************
           MEMBERS
        *****************************************************************************
        */

    members : {
        // table reference
        __table : null,

        // table model reference
        __tableModel : null,

        // table column reference
        __tableColumnModel : null,

        // array with percentage values for each column
        __cols : null,

        // number of data rows to check for longest data value to adjust
        // column width
        __numSamples : 5,

        // whether scrolling mode is active
        // if scrolling is on the behavior tries to keep all columns in
        // table width, otherwise it's ok to be wider
        __scrolling : false,

        // inner table width
        __tableWidth : null,

        // @Override
        /**
         * TODOC
         *
         * @param tableColumnModel {var} TODOC
         * @param event {var} TODOC
         * @return {void} 
         */
        onAppear : function(tableColumnModel, event) {
            // set references for easy access
            this.__table = tableColumnModel.getTable();
            this.__tableModel = tableColumnModel.getTable().getTableModel();
            this.__tableColumnModel = tableColumnModel;

            this.__tableWidth = this._getAvailableWidth(this.__tableColumnModel);

            // recalculate column widths on sorting
            this.__tableModel.addListener("metaDataChanged", function(e) {
                this._calculateColumnPercentage();
                this._updateColumnWidth();
            },
            this);

            // initial column width calculation
            this._calculateColumnPercentage();
            this._updateColumnWidth();
        },

        // @Override
        /**
         * TODOC
         *
         * @param tableColumnModel {var} TODOC
         * @param event {var} TODOC
         * @return {void} 
         */
        onTableWidthChanged : function(tableColumnModel, event) {
            this.__tableWidth = this._getAvailableWidth(this.__tableColumnModel);
            this._revalidate();
        },

        // overloaded
        /**
         * TODOC
         *
         * @param tableColumnModel {var} TODOC
         * @param event {var} TODOC
         * @return {void} 
         */
        onVerticalScrollBarChanged : function(tableColumnModel, event) {},


        /**
         * TODOC
         *
         * @param tableColumnModel {var} TODOC
         * @param event {var} TODOC
         * @return {void} 
         */
        onColumnWidthChanged : function(tableColumnModel, event) {
            var numColumns = this.__tableColumnModel.getVisibleColumnCount();

            // count sum of all column widths
            var columnWidthSum = 0;

            for (var i=0; i<numColumns; i++) {
                columnWidthSum += this.__tableColumnModel.getColumnWidth(i);
            }

            // if it doesn't fit adjust last column
            if (this.__tableWidth - columnWidthSum > 0) {
                var columnWidth = this.__tableColumnModel.getColumnWidth(numColumns - 1) + (this.__tableWidth - columnWidthSum);
                this.__tableColumnModel.setColumnWidth(numColumns - 1, columnWidth);
            }
        },

        // @Override
        /**
         * TODOC
         *
         * @param tableColumnModel {var} TODOC
         * @param event {var} TODOC
         * @return {void} 
         */
        onVisibilityChanged : function(tableColumnModel, event) {
            this._calculateColumnPercentage();
            this._revalidate();
        },

        // @Override
        /**
         * TODOC
         *
         * @param numColumns {var} TODOC
         * @return {void} 
         */
        _setNumColumns : function(numColumns) {},


        /**
         * Calculate which percentage each column gets from total table width
         *
         * @return {void} 
         */
        _calculateColumnPercentage : function() {
            // only calculate percentage if we need no scrollbar
            if (!this._needForScrolling()) {
                var numColumns = this.__tableModel.getColumnCount();

                // use content length as indicator to column width if data is present
                if (this.__tableModel.getRowCount() > 0) {
                    // determine number of samples, max __numSamples, if there are less, use all available
                    var numSamples = (this.__tableModel.getRowCount() < this.__numSamples) ? this.__tableModel.getRowCount() : this.__numSamples;

                    this.__cols = Array();
                    var rowData = Array();

                    // fetch row data
                    for (var i=0; i<numSamples; i++) {
                        rowData.push(this.__tableModel.getRowData(i));
                    }

                    var value = "";

                    // calculate longest data for each column
                    for (var i=0; i<numColumns; i++) {
                        if (this.__tableColumnModel.isColumnVisible(i)) {
                            var max = 0;

                            for (var j=0; j<numSamples; j++) {
                                if (rowData[j]) {
                                    value = rowData[j][this.__tableModel.getColumnId(i)];
                                    var dataLength = ((typeof (value) == "string") || (typeof (value) == "number")) ? String(value).length + 10 : 0;
                                }
                                else {
                                    var dataLength = 0;
                                }

                                dataLength = (dataLength > 50) ? 50 : dataLength;

                                max = Math.max(max, dataLength);
                                this.__cols[i] = max;
                            }
                        }
                    }

                    // check whether column name is wider than data
                    var rowSum = 0;

                    for (var i=0; i<numColumns; i++) {
                        if (this.__tableColumnModel.isColumnVisible(i)) {
                            var columnLength = this.__tableModel.getColumnName(i).length;
                            this.__cols[i] = (columnLength > this.__cols[i]) ? columnLength : this.__cols[i];
                            rowSum += this.__cols[i];
                        }
                    }

                    // calculate percentage from longest column name or row data
                    for (var i=0; i<numColumns; i++) {
                        if (this.__tableColumnModel.isColumnVisible(i)) {
                            this.__cols[i] = 1 / rowSum * this.__cols[i];
                        }
                    }
                }

                // otherwise divide according to column name
                else {
                    this.__cols = Array();

                    // add column name lenghts
                    var columnNameSum = 0;

                    for (var i=0; i<numColumns; i++) {
                        this.__cols[i] = this.__tableModel.getColumnName(i).length;
                        columnNameSum += this.__tableModel.getColumnName(i).length;
                    }

                    // calculate percentage
                    for (var i=0; i<numColumns; i++) {
                        this.__cols[i] = 1 / columnNameSum * this.__cols[i];
                    }
                }
            }
        },


        /**
         * Update widths for all columns. Depending on scrolling no/yes this is
         *  done according to percentage of column data or based on each columns
         *  name and data.
         *
         * @return {void} 
         */
        _updateColumnWidth : function() {
            var numColumns = this.__tableModel.getColumnCount();

            // if trying to arrange without scrollbar use percentage on tableWidth
            if (!this.__scrolling) {
                var columnWidthSum = 0;

                // determine width for each column
                for (var i=0; i<numColumns; i++) {
                    if (this.__cols != null && this.__cols[i] != undefined) {
                        var columnWidth = parseInt(this.__tableWidth * this.__cols[i]);

                        // if last column, make pixel perfect if in feasible range (10px)
                        if (i + 1 == numColumns) {
                            if (Math.abs(this.__tableWidth - columnWidthSum - columnWidth) < 10) {
                                columnWidth = this.__tableWidth - columnWidthSum;
                            }
                        }

                        this.__tableColumnModel.setColumnWidth(i, columnWidth);
                        columnWidthSum += columnWidth;
                    }
                }

                // check whether the updated table needs scrolling, if so
                // revalidate
                if (this._needForScrolling()) {
                    this._revalidate();
                }
            }

            // otherwise make sure all column names and narrow content is
            // fully displayed and long content is widen appropriately
            else {
                var cols = Array();

                // determine column name width for each column
                for (var i=0; i<numColumns; i++) {
                    var label = new qx.ui.basic.Label(this.__tableModel.getColumnName(i));

                    cols[i] = label.getSizeHint(true).width + 10;
                }

                // if there is row data consider it to size the column appropiately
                if (this.__tableModel.getRowCount() > 0) {
                    // determine number of samples, max __numSamples, if there are less, use all available
                    var numSamples = (this.__tableModel.getRowCount() < this.__numSamples) ? this.__tableModel.getRowCount() : this.__numSamples;

                    // fetch row data
                    var rowData = Array();

                    for (var i=0; i<numSamples; i++) {
                        rowData.push(this.__tableModel.getRowData(i));
                    }

                    var value = "";

                    // check whether content needs larger width than column header
                    for (var i=0; i<numColumns; i++) {
                        // determine needed width for content, max 200px
                        // possibly expensive, especially if numSamples is large
                        var max = 0;

                        for (var j=0; j<numSamples; j++) {
                            value = rowData[j][this.__tableModel.getColumnId(i)];

                            if ((typeof (value) == "string") || (typeof (value) == "number")) {
                                var label = new qx.ui.basic.Label(value);
                                var width = (label.getSizeHint(true).width < 400) ? (label.getSizeHint(true).width) + 20 : 400;

                                max = Math.max(max, width);
                            }
                        }

                        cols[i] = (max > cols[i]) ? max : cols[i];
                    }
                }

                // apply determined size
                for (var i=0; i<numColumns; i++) {
                    this.__tableColumnModel.setColumnWidth(i, cols[i]);
                }
            }
        },


        /**
         * Calculate column widths if scrolling mode has changed or if
         *  scrolling is disabled and requested manually (e.g. by changing
         *  table width)
         *
         * @return {void} 
         */
        _revalidate : function() {
            var noScrollingOld = this.__scrolling;

            this.__scrolling = this._needForScrolling();

            if (!this.__scrolling || noScrollingOld != this.__scrolling) {
                this._updateColumnWidth();
            }
        },


        /**
         * Determine if there is a need to change to scrolling mode.
         *  
         *  This is done by looking at the table headers and counting how many
         *  of them are cropped. If there is more than one, scrolling should be used.
         *
         * @return {boolean} Whether scrolling is needed
         */
        _needForScrolling : function() {
            var numColumns = this.__tableModel.getColumnCount();

            var cropped = 0;
            var sum = 0;

            for (var i=0; i<numColumns; i++) {
                if (this.__tableColumnModel.isColumnVisible(i)) {
                    sum += this.__tableColumnModel.getColumnWidth(i);

                    var label = new qx.ui.basic.Label(this.__tableModel.getColumnName(i));

                    if (label.getSizeHint(true).width - 10 > this.__tableColumnModel.getColumnWidth(i)) {
                        cropped++;
                    }
                }
            }

            return (cropped > 1 && sum >= this._getAvailableWidth(this.__tableColumnModel));
        }
    }
});