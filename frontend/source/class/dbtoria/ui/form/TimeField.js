/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch?
   Utf8Check: äöü
************************************************************************ */

/* ************************************************************************
************************************************************************ */

qx.Class.define("dbtoria.ui.form.TimeField", {
    extend  : qx.ui.form.TextField,
    include : [ dbtoria.ui.form.MControlProperties,
                dbtoria.ui.form.MControlProperties ],

    /**
     * Create a customized TextField for time entries.
     */
    construct : function() {
        this.base(arguments);
        this.set({
            toolTip: new qx.ui.tooltip.ToolTip(qx.locale.Manager.tr('Use hh:mm or hh:mm::ss format.'))
        });
    },

    members : {

        __timeRegex:  /^(\d*?):(?:(\d+)|(\d+):(\d+))$/,

        validator: function(value,control) {
            if (value == null && !control.getRequired()) {
                control.setValid(true);
                return true;
            }
            var msg = qx.locale.Manager.tr('This field must be a time.');
            var valid = (value != null) && this.__timeRegex.exec(value);
            if (!valid){
                control.setInvalidMessage(msg);
                control.setValid(valid);
            }
            return valid;
        },

        setFormDataCallback: function(name, callback) {
            this.addListener('changeValue', function(e) {
                var value = e.getData();
                if (! this.__timeRegex.test(value)) {
                    value += ':00'; // add seconds
                }
                callback(name, value);
            }, this);
        }

    }

});
