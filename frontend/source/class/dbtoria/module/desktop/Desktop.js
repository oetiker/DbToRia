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
    * Fritz Zaucker
    * Tobi Oetiker (oetiker) <tobi@oetiker.ch>

************************************************************************ */

qx.Class.define("dbtoria.module.desktop.Desktop", {
    extend : qx.ui.window.Desktop,
    type : "singleton",

    construct : function() {
        this.base(arguments, new qx.ui.window.Manager());
        var logo = new qx.ui.basic.Label('made with dBtoria').set({
            font: new qx.bom.Font(60,['Amaranth','sans-serif']),
            textColor: '#eee',
//          alignX: 'center',
//          alignY: 'middle',
//          textAlign: 'center',
//          allowGrowX: true,
//          allowShrinkX: true,
            cursor: 'pointer'
        });
        logo.addListener('mouseover',function(){logo.setTextColor('#ddd')});
        logo.addListener('mouseout',function(){logo.setTextColor('#eee')});
        logo.addListener('click',function(){  qx.bom.Window.open('http://dbtoria.org/', '_blank');});        
        this.add(logo,{right: 40, bottom: 20 });
    }

});
