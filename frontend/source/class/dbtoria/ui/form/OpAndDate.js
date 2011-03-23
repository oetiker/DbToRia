/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPL
   Authors:    Tobias Oetiker
   Utf8Check:  äöü

************************************************************************ */

/**
 * A date value including a comparison operator.
 *
 * @childControl operator {qx.ui.form.SelectBox} pick an sql operator
 * @childControl datefield {qx.ui.form.DateField} enter a value
 */
qx.Class.define("dbtoria.ui.form.OpAndDate", {
    extend : dbtoria.ui.form.OpAndValue,

    properties : {
        appearance : {
            refine : true,
            init   : "opanddate"
        }
    },

    members : {
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
                case "field":
                    var control = new qx.ui.form.DateField();
                    control.addListener('changeValue', this._fireValue, this);
                    control.set({
                        alignY      : 'middle',

                        //                      dateFormat: new qx.util.format.DateFormat("dd.MM.yyyy"),
                        placeholder : this.tr('dd.mm.jjjj')
                    });

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
            var date = this.getChildControl('field').getValue();
            var epoch = null;

            if (date && date.getTime) {
                epoch = date.getTime() / 1000.0;
            }

            this.fireDataEvent('changeValue', [ operator, epoch ]);
            this._skipApplyValue++;
            this.setValue(operator + ' ' + date);
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
            var epoch = null;
            var spacePos = String(value).indexOf(' ');

            if (spacePos >= 0) {
                opVal = value.substr(0, spacePos);
                epoch = parseInt(value.substr(spacePos + 1));
            }

            var operator = this.getChildControl('operator');
            operator.setModelSelection([ opVal ]);
            var date = this.getChildControl('field');

            if (epoch) {
                date.setValue(new Date(epoch * 1000.0));
            } else {
                date.setValue(null);
            }
        }
    }
});
