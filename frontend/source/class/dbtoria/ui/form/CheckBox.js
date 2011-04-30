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

    /**
     * Create a customized CheckBox.
     *
     */
    construct : function() {
        this.base(arguments);
        this.set({allowGrowX : false});
    },

    members : {
        setter: function(value) {
            if (value == null) {
                this.setValue(false);
            }
            else {
                this.setValue(value);
            }
        },

        validator: function() {
            return function(value,control){
                        var msg = qx.locale.Manager.tr('This field must be a boolean.');
                        var valid = qx.lang.Type.isBoolean(value) || value == null;
                        if (!valid){
                            control.setInvalidMessage(msg);
                            control.setValid(valid);
                        }
                        return valid;
                   };
        }

    }

});
