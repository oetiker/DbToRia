/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch?
   Utf8Check: äöü
************************************************************************ */

/* ************************************************************************
************************************************************************ */

qx.Class.define("dbtoria.ui.form.IntField", {
    extend : qx.ui.form.TextField,
    include : [ dbtoria.ui.form.MControlSetter ],

    /**
     * Create a customized TextField.
     *
     */
    construct : function() {
        this.base(arguments);
//        this.set({});
    },

    members : {
    }

});
