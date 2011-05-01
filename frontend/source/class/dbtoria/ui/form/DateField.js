/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch?
   Utf8Check: äöü
************************************************************************ */

/* ************************************************************************
************************************************************************ */

qx.Class.define("dbtoria.ui.form.DateField", {
    extend : qx.ui.form.DateField,

    /**
     * Create a customized DateField.
     *
     */
    construct : function() {
        this.base(arguments);
        this.set({allowGrowX : false});
    },

    members : {
        setter: function(value) {
            if (value == null) {
                this.setValue(value);
            }
            else {
                this.setValue(new Date(value));
            }
        },

        validator: function() {
            return function(value,control){
                if (value == null && !control.getRequired()) {
                    control.setValid(true);
                    return true;
                }
                var msg = qx.locale.Manager.tr('This field must be a date.');
                var valid = qx.lang.Type.isDate(value);
                if (!valid){
                    control.setInvalidMessage(msg);
                    control.setValid(valid);
                }
                return valid;
            };
        }

    }

});
