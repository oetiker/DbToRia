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
#asset(qx/icon/${qx.icontheme}/22/actions/format-justify-left.png)
#asset(qx/icon/${qx.icontheme}/16/status/dialog-error.png)

************************************************************************ */

/**
 * This class provides the filter functionality in the table window
 *
 * This filter allows the user to restrict the displayed rows using
 * a search key for each column. All criteria are joined using AND.
 *
 * This may be improved in various ways (OR, brackets...) for better
 * selectabilty but its difficult to find a user friendly way to display these
 * options.
 */
qx.Class.define("dbtoria.window.TableFilter", {
    extend : qx.ui.window.Window,

    /*
        *****************************************************************************
    	CONSTRUCTOR
        *****************************************************************************

        * @param tableWindow {dbtoria.window.Table} The table window the filter is applied to
        * @param title {String} Title for window.
        */

    construct : function(title, columns, filterCallback) {
        // call super class
        this.base(arguments, title);

        // save references
        this.__columns        = columns;
        this.__filterCallback = filterCallback;

//        this.setLayout(new qx.ui.layout.Grid(5, 5));
        this.set({
                     // Why doesn't this work???
                     layout: new qx.ui.layout.Grid(5, 5),
                     showMinimize: false,
                     showMaximize: false,
                     modal: true});

        this.__selection = new Array();

        this.addSelectionProperty();
        this.open();
    },




    /*
        *****************************************************************************
    	MEMBERS
        *****************************************************************************
        */

    members : {
        // db table
        __dbTable : null,
        __columns : null,
        __filterCallback: null,

        // used to add and remove filter criteria
        __rowCounter : 0,

        // array containing references to all criteria
        __selection : null,


        /**
         * Add another filter critera
         *
         *  This function generates another row in the filter panel.
         *  It contains a checkbox to activate/deactivate a filter,
         *  a selectbox to choose which to column to search in and a
         *  checkbox to enter the search string.
         *
         * @return {void}
         */
        addSelectionProperty : function() {
            var checkBox = new qx.ui.form.CheckBox();
//            checkBox.setChecked(true);
            checkBox.setValue(true);

            var fieldSelectBox = new qx.ui.form.SelectBox();

            // generate list of columns
            var columns = this.__columns;
            var i, len=columns.length;
            var column, item;
            for (i=0; i<len; i++) {
                column = columns[i];
                item = new qx.ui.form.ListItem(column.name, null, column.id);
                fieldSelectBox.add(item);
            }

            var opSelectBox = new qx.ui.form.SelectBox();
            opSelectBox.setWidth(50);
            var ops = ['=', '<', '>', '<=', '>=', 'like', 'ilike', '...'];
            len = ops.length;
            for (i =0; i<len; i++) {
                item = new qx.ui.form.ListItem(ops[i], null, ops[i]);
                opSelectBox.add(item);
            }

            var textField = new qx.ui.form.TextField();
            textField.setWidth(200);

            this.getLayout().setRowAlign(this.__rowCounter, "left", "middle");
            this.getLayout().setColumnFlex(3, 1);

            this.add(checkBox, {
                row    : this.__rowCounter,
                column : 0
            });

            this.add(fieldSelectBox, {
                row    : this.__rowCounter,
                column : 1
            });

            this.add(opSelectBox, {
                row    : this.__rowCounter,
                column : 2
            });

            this.add(textField, {
                row    : this.__rowCounter,
                column : 3
            });

            var refreshButton = new qx.ui.form.Button(this.tr("Refresh Filter"));
            var addButton = new qx.ui.form.Button(this.tr("Add Critera"));

            // on clicking the filter refresh button the tableWindow
            // is updated with the current filter
            refreshButton.addListener("execute", function(e) {
                this.__filterCallback(this.__getFilter());
            }, this);

            addButton.addListener("execute", function(e) {
                this.tableFilter.addSelectionProperty();
                this.addButton.destroy();
                this.refreshButton.destroy();
            },
            {
                tableFilter   : this,
                addButton     : addButton,
                refreshButton : refreshButton
            });

            this.add(refreshButton, {
                row    : this.__rowCounter,
                column : 4
            });

            this.add(addButton, {
                row    : this.__rowCounter,
                column : 5
            });

            this.__selection.push({
                fieldSelectBox : fieldSelectBox,
                opSelectBox    : opSelectBox,
                textField      : textField,
                checkBox       : checkBox
            });

            this.__rowCounter++;
        },


        /**
         * Return current filter
         *
         *  This function returns an array of search column and value pairs.
         *
         * @return {var} TODOC
         */
        __getFilter : function() {
            var filter = new Array();

            for (var i=0; i<this.__selection.length; i++) {
                var selection = this.__selection[i];

                if (selection.checkBox.getValue()) {
                    var tmp = {
                        field: selection.fieldSelectBox.getSelection()[0],
                        op:    selection.opSelectBox.getSelection()[0],
                        value: selection.textField.getValue()
                    };
                    filter.push(tmp);
                }

                filter.push();
            }

            //qx.dev.Debug.debugObject(filter);
            return filter;
        }
    }
});