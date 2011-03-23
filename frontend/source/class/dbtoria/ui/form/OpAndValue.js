/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPL
   Authors:    Tobias Oetiker
   Utf8Check:  äöü

************************************************************************ */

/**
 * An SQL where statement fragment, providing a comparison operator
 * and a value field.
 *
 * @childControl operator {qx.ui.form.SelectBox} pick an sql operator
 * @childControl field {qx.ui.form.TextField} enter a value
 */
qx.Class.define("dbtoria.ui.form.OpAndValue", {
    extend : qx.ui.core.Widget,
    implement : [ qx.ui.form.IForm, qx.ui.form.IStringForm ],

    include : [
    // form methods
    qx.ui.form.MForm ],


    /**
                     * @param operatorArr {Array} possible operators to choose from
                     * @param operator {String} default operator
                     * @param text {String} default string
                     */
    construct : function(operatorArr, operator, text) {
        this.base(arguments);
        var layout = new qx.ui.layout.HBox(3);
        this._setLayout(layout);

        this.set({
            allowGrowY : false,
            allowGrowX : true
        });

        this.setOperators(operatorArr);

        if (operator && text) {
            this.setValue(operator + ' ' + text);
        }
    },

    events : {
        /**
                                         * Fires when either the operator or the text entry changes
                                         * event data holds the operator and the text value as an array ref
                                         */
        changeValue : "qx.event.type.Data"
    },

    properties : {
        value : {
            init     : '=',
            nullable : true,
            apply    : '_applyValue'
        },

        operators : {
            check : 'Array',
            apply : '_applyOperators'
        },

        appearance : {
            refine : true,
            init   : "opandvalue"
        }
    },

    members : {
        _skipApplyValue : 0,


        /**
         * set focus to first operator selector
         *
         * @return {void} 
         */
        focus : function() {
            this.getChildControl('operator').focus();
        },


        /**
         * get the kids ready
         *
         * @param id {var} TODOC
         * @return {var} TODOC
         */
        _createChildControlImpl : function(id) {
            var control;

            switch(id)
            {
                case "operator":
                    var control = new qx.ui.form.SelectBox();
                    control.addListener('changeSelection', this._fireValue, this);
                    this._add(control);
                    control.set({
                        allowGrowX   : false,
                        allowShrinkX : false,
                        width        : 60,
                        alignY       : 'middle'
                    });

                    break;

                case "field":
                    var control = new qx.ui.form.TextField();
                    control.addListener('changeValue', this._fireValue, this);
                    control.set({ alignY : 'middle' });
                    this._add(control);
                    break;
            }

            return control || this.base(arguments, id);
        },


        /**
         * TODOC
         *
         * @param e {Event} TODOC
         * @return {void} 
         */
        _fireValue : function(e) {
            var operator = this.getChildControl('operator').getModelSelection().getItem(0);
            var text = this.getChildControl('field').getValue();
            this.fireDataEvent('changeValue', [ operator, text ]);
            this._skipApplyValue++;
            this.setValue(operator + ' ' + text);
        },


        /**
         * provide string representation of the selection "operator text field"
         *
         * @param value {var} TODOC
         * @param old {var} TODOC
         * @return {void} 
         */
        _applyValue : function(value, old) {
            if (this._skipApplyValue > 0) {
                this._skipApplyValue--;
                return;
            }

            var opVal = value;
            var txVal = '';
            var spacePos = String(value).indexOf(' ');

            if (spacePos >= 0) {
                opVal = value.substr(0, spacePos);
                txVal = value.substr(spacePos + 1);
            }

            var operator = this.getChildControl('operator');
            operator.setModelSelection([ opVal ]);
            var text = this.getChildControl('field');
            text.setValue(txVal);
        },


        /**
         * TODOC
         *
         * @param ops {var} TODOC
         * @param old {var} TODOC
         * @return {void} 
         */
        _applyOperators : function(ops, old) {
            var opBox = this.getChildControl('operator');

            if (opBox.hasChildren()) {
                opBox._destroyAll();
            }

            for (var i=0; i<ops.length; i++) {
                var item = new qx.ui.form.ListItem(ops[i], null, ops[i]);
                opBox.add(item);
            }
        }
    }
});
