/* ************************************************************************

  DbToRia - Database to Rich Internet Application

  http://www.dbtoria.org

   Copyright:
    2009 David Angleitner, Switzerland
    2011 Oetiker+Partner AG, Olten, Switzerland

   License:
    GPL: http://www.gnu.org/licenses/gpl-2.0.html

   Authors:
    * David Angleitner
    * Tobias Oetiker
    * Fritz Zaucker

************************************************************************ */

/**
 * Datastore for application configuration data.
 */

qx.Class.define( 'dbtoria.data.Config',
{
    extend: qx.core.Object,
    type:   'singleton',

    /**
    * Creates a new instance
    */
    construct: function () {
        this.base(arguments);
    }, // construct


    properties: {
        filterOps: { init: [],
                     // check: "String",
                     nullable: true
                  }
    },


    events: {
        "configUpdate" : "qx.event.type.Event"
    }, // events


    members: {
        /**
        * Refresh config.
        */
        refresh: function() {
            if (this.__loaded) {
                this.fireEvent('configUpdate');
                return;
            }
            if (this.__loading) {
                return;
            }
            this.__loading = true;
            var rpc = dbtoria.data.Rpc.getInstance();
            rpc.callAsync( qx.lang.Function.bind(this.__refreshHandler, this),
                           'getConfig');
        },

        /**
         * Callback for loading the config
         * @param data {Array} data returned from the JSON RPC call.
         * @param exc  {String} exception string.
         * @param id   {Integer} reference id for the RPC call.
         */
        __refreshHandler:  function(data,exc,id) {
            if (exc == null) {
                this.setFilterOps(data.filterOps);
                this.fireEvent('configUpdate');
                this.__loaded = true;
            }
            else {
                this.__loaded = false;
                dbtoria.ui.dialog.MsgBox.getInstance().exc(exc);
            }
            this.__loading = false;
        }

    } // members

});
