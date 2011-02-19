/* ************************************************************************

  DbToRia - Database to Rich Internet Application
  
  http://www.dbtoria.org

   Copyright:
    2009 David Angleitner, Switzerland
    
   License:
    GPL: http://www.gnu.org/licenses/gpl-2.0.html

   Authors:
    * David Angleitner

************************************************************************ */

/* ************************************************************************

#asset(dbtoria/*)

************************************************************************ */

/**
 * This class creates the Rpc object.
 * 
 * This is a singleton. Use getInstance() to retrieve the Rpc object.
 * 
 */
qx.Class.define("dbtoria.communication.Rpc", {
    type: "singleton",
    extend: qx.core.Object,

    /*
    *****************************************************************************
	CONSTRUCTOR
    *****************************************************************************
    */
    
    construct: function() {
    
	// call super class
	this.base(arguments);
    
	// create new rpc object if it doesn't exist
	if(!this.__rpc) {
	    //this.__rpc = new qx.io.remote.Rpc("/demo/jsonrpc.cgi", "dbtoria.wrapper");
	    //this.__rpc = new qx.io.remote.Rpc("/dbtoria/Testing/backend/bin/jsonrpc.pl", "dbtoria.wrapper");
	    //this.__rpc = new qx.io.remote.Rpc("../../backend/bin/jsonrpc.pl", "dbtoria.wrapper");
	    this.__rpc = new qx.io.remote.Rpc("../jsonrpc.cgi", "dbtoria.wrapper");
	}
	
	return this.__rpc;
    },
    
     /*
    *****************************************************************************
       MEMBERS
    *****************************************************************************
    */
    
    members: {
	
	// rpc object
	__rpc: null
    }
});
