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
#asset(qx/decoration/Modern/table/boolean-true.png);

************************************************************************ */

/**
 * BooleanString
 */
qx.Class.define("dbtoria.cellrenderer.BooleanString", {
    extend : qx.ui.table.cellrenderer.Boolean,




    /*
        *****************************************************************************
    	CONSTRUCTOR
        *****************************************************************************
        */

    construct : function() {
        this.base(arguments);

        var aliasManager = qx.util.AliasManager.getInstance();

        this.__iconUrlTrue = aliasManager.resolve("decoration/table/boolean-true.png");
        this.__iconUrlFalse = aliasManager.resolve("decoration/table/boolean-false.png");
    },




    /*
        *****************************************************************************
           MEMBERS
        *****************************************************************************
        */

    members : {
        // @Override
        /**
         * TODOC
         *
         * @param cellInfo {var} TODOC
         * @return {var} TODOC
         */
        _identifyImage : function(cellInfo) {
            var imageHints = {
                imageWidth  : 11,
                imageHeight : 11
            };

            switch(cellInfo.value)
            {
                case "true":
                    case true:
                        imageHints.url = this.__iconUrlTrue;
                        break;

                    case "false":
                        case false:
                            imageHints.url = this.__iconUrlFalse;
                            break;

                        default:
                            imageHints.url = null;
                            break;
                    }

                    return imageHints;
                }
            }
        });