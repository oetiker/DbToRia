/* ************************************************************************

  DbToRia - Database to Rich Internet Application

  http://www.dbtoria.org

   Copyright:
    2009 David Angleitner, Switzerland
    2011 Oetiker+Partner AG, Switzerland

   License:
    GPL: http://www.gnu.org/licenses/gpl-2.0.html

   Authors:
    * David Angleitner
    * Fritz Zaucker

************************************************************************ */

/* ************************************************************************

#asset(dbtoria/*)
#asset(qx/icon/${qx.icontheme}/16/actions/help-about.png)
************************************************************************ */

/**
 * TODOs:
 *   - use dbtoria/ui/form/ControlBuilder.js to build form
 *   - more MS Access like layout
 */

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
qx.Class.define("dbtoria.module.database.TableFilter", {
    extend : qx.ui.window.Window,

    construct : function(title, columns, filterCallback) {
        // call super class
        this.base(arguments, title);

        // save references
        this.__columns        = columns;
        this.__filterCallback = filterCallback;

        this.set({
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
            checkBox.setValue(true);

            var textField1 = new qx.ui.form.TextField();
            textField1.setWidth(100);

            var textField2 = new qx.ui.form.TextField();
            textField2.setWidth(100);

            var labelAnd = new qx.ui.basic.Label('AND');

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
            opSelectBox.addListener('changeSelection',
                                       function() {
                                           this.__changeOp(opSelectBox,
                                                           textField1,
                                                           textField2,
                                                           labelAnd);
                                       }, this);

            opSelectBox.setWidth(180);
            var ops = dbtoria.data.Config.getInstance().getFilterOps();
            len = ops.length;
            var tooltip =
              new qx.ui.tooltip.ToolTip('', "icon/16/actions/help-about.png");;
            opSelectBox.setToolTip(tooltip);
            for (i =0; i<len; i++) {
                tooltip =
                    new qx.ui.tooltip.ToolTip(ops[i].help,
                                              "icon/16/actions/help-about.png");
                item    = new qx.ui.form.ListItem(ops[i].op, null, ops[i].op);
                item.setToolTip(tooltip);
                item.setUserData('type', ops[i].type);
                opSelectBox.add(item);
            }

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

            this.add(textField1, {
                row    : this.__rowCounter,
                column : 3
            });

            this.add(labelAnd, {
                row    : this.__rowCounter,
                column : 4
            });

            this.add(textField2, {
                row    : this.__rowCounter,
                column : 5
            });

            var applyButton = new qx.ui.form.Button(this.tr("Apply Filter"));
            var addButton = new qx.ui.form.Button(this.tr("Add Critera"));

            // on clicking the filter apply button the tableWindow
            // is updated with the current filter
            applyButton.addListener("execute",
                                      function(e) {
                                          this.debug('Calling __filterCallback()');
                                          this.__filterCallback(this.__getFilter());
                                      }, this);

            addButton.addListener("execute", function(e) {
                this.tableFilter.addSelectionProperty();
                this.addButton.destroy();
                this.applyButton.destroy();
            },
            {
                tableFilter   : this,
                addButton     : addButton,
                applyButton : applyButton
            });

            this.add(applyButton, {
                row    : this.__rowCounter,
                column : 6
            });

            this.add(addButton, {
                row    : this.__rowCounter,
                column : 7
            });

            this.__selection.push({
                fieldSelectBox : fieldSelectBox,
                opSelectBox    : opSelectBox,
                textField1     : textField1,
                textField2     : textField2,
                checkBox       : checkBox
            });

            this.__rowCounter++;
        },


        /**
         * Callback for changeSelection on opSelectBox
         *
         */
        __changeOp : function(selectBox, textField1, textField2, labelAnd) {
            var selection = selectBox.getSelection()[0];
            var type = selection.getUserData('type');
            this.debug('operator type: '+type);
            switch (type) {
            case 'simpleValue':
                textField1.show();
                labelAnd.exclude();
                textField2.exclude();
                break;
            case 'dualValue':
                textField1.show();
                labelAnd.show();
                textField2.show();
                break;
            case 'noValue':
                textField1.exclude();
                labelAnd.exclude();
                textField2.exclude();
                break;
            }
            selectBox.getToolTip().setLabel(selection.getToolTip().getLabel());
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
                        field:  selection.fieldSelectBox.getSelection()[0].getModel(),
                        op:     selection.opSelectBox.getSelection()[0].getModel(),
                        value1: selection.textField1.getValue(),
                        value2: selection.textField2.getValue()
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
