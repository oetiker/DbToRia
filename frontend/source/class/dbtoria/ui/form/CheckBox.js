/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch?
   Utf8Check: äöü
************************************************************************ */

/* ************************************************************************
************************************************************************ */

qx.Class.define("dbtoria.ui.form.CheckBox", {
    extend : qx.ui.form.CheckBox,
    include : [ dbtoria.ui.form.MControlProperties ],

    /**
     * Create a customized CheckBox.
     *
     */
    construct : function() {
        this.base(arguments);
        this.set({allowGrowX : false});
    },

    members : {
        defaults: function(value) {
            if (this.getValue() != null) {
                return;
            }
            this.setter(value);
        },

        setter: function(value) {
            if (value == null) {
                this.setValue(false);
            }
            else {
                this.setValue(value);
            }
        },

        clear: function() {
            this.setValue(false);
        },

        validator: function() {
            return function(value,control){
                if (value == null && !control.getRequired()) {
                    control.setValid(true);
                    return true;
                }
                var msg = qx.locale.Manager.tr('This field must be a boolean.');
                var valid = qx.lang.Type.isBoolean(value);
                if (!valid){
                    control.setInvalidMessage(msg);
                    control.setValid(valid);
                }
                return valid;
            };
        }

    }

});
