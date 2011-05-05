/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch?
   Utf8Check: äöü
************************************************************************ */

/* ************************************************************************
************************************************************************ */

qx.Mixin.define("dbtoria.ui.form.MControlReadOnly", {

    properties : {
        readOnly : {
            init     : false,
            check    : "Boolean",
            apply    : '_applyReadOnly',
            nullable : false
        }
    },

    members : {
      _applyReadOnly : function() {
          this.setEnabled(false);
      }
    }

});
