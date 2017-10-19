/// @file JSRootPainter.js
/// JavaScript ROOT graphics

(function( factory ) {
   if ( typeof define === "function" && define.amd ) {
      // AMD. Register as an anonymous module.
      define( ['JSRootCore', 'd3'], factory );
   } else
   if (typeof exports === 'object' && typeof module !== 'undefined') {
      var jsroot = require("./JSRootCore.js");
      factory(jsroot, require("./d3.min.js"));
      if (jsroot.nodejs) jsroot.Painter.readStyleFromURL("?interactive=0&tooltip=0&nomenu&noprogress&notouch&toolbar=0&webgl=0");
   } else {

      if (typeof JSROOT == 'undefined')
         throw new Error('JSROOT is not defined', 'JSRootPainter.js');

      if (typeof d3 != 'object')
         throw new Error('d3 is not defined', 'JSRootPainter.js');

      if (typeof JSROOT.Painter == 'object')
         throw new Error('JSROOT.Painter already defined', 'JSRootPainter.js');

      factory(JSROOT, d3);
   }
} (function(JSROOT, d3) {

   JSROOT.sources.push("2d");

   // do it here while require.js does not provide method to load css files
   if ( typeof define === "function" && define.amd )
      JSROOT.loadScript('$$$style/JSRootPainter.css');

   // list of user painters, called with arguments func(vis, obj, opt)
   JSROOT.DrawFuncs = {lst:[], cache:{}};

   // add draw function for the class
   // List of supported draw options could be provided, separated  with ';'
   // Several different draw functions for the same class or kind could be specified
   JSROOT.addDrawFunc = function(_name, _func, _opt) {
      if ((arguments.length == 1) && (typeof arguments[0] == 'object')) {
         JSROOT.DrawFuncs.lst.push(arguments[0]);
         return arguments[0];
      }
      var handle = { name:_name, func:_func, opt:_opt };
      JSROOT.DrawFuncs.lst.push(handle);
      return handle;
   }

    // icons taken from http://uxrepo.com/

   JSROOT.ToolbarIcons = {
      camera: { path: 'M 152.00,304.00c0.00,57.438, 46.562,104.00, 104.00,104.00s 104.00-46.562, 104.00-104.00s-46.562-104.00-104.00-104.00S 152.00,246.562, 152.00,304.00z M 480.00,128.00L 368.00,128.00 c-8.00-32.00-16.00-64.00-48.00-64.00L 192.00,64.00 c-32.00,0.00-40.00,32.00-48.00,64.00L 32.00,128.00 c-17.60,0.00-32.00,14.40-32.00,32.00l0.00,288.00 c0.00,17.60, 14.40,32.00, 32.00,32.00l 448.00,0.00 c 17.60,0.00, 32.00-14.40, 32.00-32.00L 512.00,160.00 C 512.00,142.40, 497.60,128.00, 480.00,128.00z M 256.00,446.00c-78.425,0.00-142.00-63.574-142.00-142.00c0.00-78.425, 63.575-142.00, 142.00-142.00c 78.426,0.00, 142.00,63.575, 142.00,142.00 C 398.00,382.426, 334.427,446.00, 256.00,446.00z M 480.00,224.00l-64.00,0.00 l0.00-32.00 l 64.00,0.00 L 480.00,224.00 z' },
      disk: { path: 'M384,0H128H32C14.336,0,0,14.336,0,32v448c0,17.656,14.336,32,32,32h448c17.656,0,32-14.344,32-32V96L416,0H384z M352,160   V32h32v128c0,17.664-14.344,32-32,32H160c-17.664,0-32-14.336-32-32V32h128v128H352z M96,288c0-17.656,14.336-32,32-32h256   c17.656,0,32,14.344,32,32v192H96V288z' },
      question: { path: 'M256,512c141.375,0,256-114.625,256-256S397.375,0,256,0S0,114.625,0,256S114.625,512,256,512z M256,64   c63.719,0,128,36.484,128,118.016c0,47.453-23.531,84.516-69.891,110.016C300.672,299.422,288,314.047,288,320   c0,17.656-14.344,32-32,32c-17.664,0-32-14.344-32-32c0-40.609,37.25-71.938,59.266-84.031   C315.625,218.109,320,198.656,320,182.016C320,135.008,279.906,128,256,128c-30.812,0-64,20.227-64,64.672   c0,17.664-14.336,32-32,32s-32-14.336-32-32C128,109.086,193.953,64,256,64z M256,449.406c-18.211,0-32.961-14.75-32.961-32.969   c0-18.188,14.75-32.953,32.961-32.953c18.219,0,32.969,14.766,32.969,32.953C288.969,434.656,274.219,449.406,256,449.406z' },
      undo: { path: 'M450.159,48.042c8.791,9.032,16.983,18.898,24.59,29.604c7.594,10.706,14.146,22.207,19.668,34.489  c5.509,12.296,9.82,25.269,12.92,38.938c3.113,13.669,4.663,27.834,4.663,42.499c0,14.256-1.511,28.863-4.532,43.822  c-3.009,14.952-7.997,30.217-14.953,45.795c-6.955,15.577-16.202,31.52-27.755,47.826s-25.88,32.9-42.942,49.807  c-5.51,5.444-11.787,11.67-18.834,18.651c-7.033,6.98-14.496,14.366-22.39,22.168c-7.88,7.802-15.955,15.825-24.187,24.069  c-8.258,8.231-16.333,16.203-24.252,23.888c-18.3,18.13-37.354,37.016-57.191,56.65l-56.84-57.445  c19.596-19.472,38.54-38.279,56.84-56.41c7.75-7.685,15.772-15.604,24.108-23.757s16.438-16.163,24.33-24.057  c7.894-7.893,15.356-15.33,22.402-22.312c7.034-6.98,13.312-13.193,18.821-18.651c22.351-22.402,39.165-44.648,50.471-66.738  c11.279-22.09,16.932-43.567,16.932-64.446c0-15.785-3.217-31.005-9.638-45.671c-6.422-14.665-16.229-28.504-29.437-41.529  c-3.282-3.282-7.358-6.395-12.217-9.325c-4.871-2.938-10.381-5.503-16.516-7.697c-6.121-2.201-12.815-3.992-20.058-5.373  c-7.242-1.374-14.9-2.064-23.002-2.064c-8.218,0-16.802,0.834-25.788,2.507c-8.961,1.674-18.053,4.429-27.222,8.271  c-9.189,3.842-18.456,8.869-27.808,15.089c-9.358,6.219-18.521,13.819-27.502,22.793l-59.92,60.271l93.797,94.058H0V40.91  l93.27,91.597l60.181-60.532c13.376-15.018,27.222-27.248,41.536-36.697c14.308-9.443,28.608-16.776,42.89-21.992  c14.288-5.223,28.505-8.74,42.623-10.557C294.645,0.905,308.189,0,321.162,0c13.429,0,26.389,1.185,38.84,3.562  c12.478,2.377,24.2,5.718,35.192,10.029c11.006,4.311,21.126,9.404,30.374,15.265C434.79,34.724,442.995,41.119,450.159,48.042z' },
      arrow_right : { path : 'M30.796,226.318h377.533L294.938,339.682c-11.899,11.906-11.899,31.184,0,43.084c11.887,11.899,31.19,11.893,43.077,0  l165.393-165.386c5.725-5.712,8.924-13.453,8.924-21.539c0-8.092-3.213-15.84-8.924-21.551L338.016,8.925  C332.065,2.975,324.278,0,316.478,0c-7.802,0-15.603,2.968-21.539,8.918c-11.899,11.906-11.899,31.184,0,43.084l113.391,113.384  H30.796c-16.822,0-30.463,13.645-30.463,30.463C0.333,212.674,13.974,226.318,30.796,226.318z' },
      arrow_up : { path : 'M295.505,629.446V135.957l148.193,148.206c15.555,15.559,40.753,15.559,56.308,0c15.555-15.538,15.546-40.767,0-56.304  L283.83,11.662C276.372,4.204,266.236,0,255.68,0c-10.568,0-20.705,4.204-28.172,11.662L11.333,227.859  c-7.777,7.777-11.666,17.965-11.666,28.158c0,10.192,3.88,20.385,11.657,28.158c15.563,15.555,40.762,15.555,56.317,0  l148.201-148.219v493.489c0,21.993,17.837,39.82,39.82,39.82C277.669,669.267,295.505,651.439,295.505,629.446z' },
      arrow_diag : { path : 'M279.875,511.994c-1.292,0-2.607-0.102-3.924-0.312c-10.944-1.771-19.333-10.676-20.457-21.71L233.97,278.348  L22.345,256.823c-11.029-1.119-19.928-9.51-21.698-20.461c-1.776-10.944,4.031-21.716,14.145-26.262L477.792,2.149  c9.282-4.163,20.167-2.165,27.355,5.024c7.201,7.189,9.199,18.086,5.024,27.356L302.22,497.527  C298.224,506.426,289.397,511.994,279.875,511.994z M118.277,217.332l140.534,14.294c11.567,1.178,20.718,10.335,21.878,21.896  l14.294,140.519l144.09-320.792L118.277,217.332z' },
      auto_zoom: { path : 'M505.441,242.47l-78.303-78.291c-9.18-9.177-24.048-9.171-33.216,0c-9.169,9.172-9.169,24.045,0.006,33.217l38.193,38.188  H280.088V80.194l38.188,38.199c4.587,4.584,10.596,6.881,16.605,6.881c6.003,0,12.018-2.297,16.605-6.875  c9.174-9.172,9.174-24.039,0.011-33.217L273.219,6.881C268.803,2.471,262.834,0,256.596,0c-6.229,0-12.202,2.471-16.605,6.881  l-78.296,78.302c-9.178,9.172-9.178,24.045,0,33.217c9.177,9.171,24.051,9.171,33.21,0l38.205-38.205v155.4H80.521l38.2-38.188  c9.177-9.171,9.177-24.039,0.005-33.216c-9.171-9.172-24.039-9.178-33.216,0L7.208,242.464c-4.404,4.403-6.881,10.381-6.881,16.611  c0,6.227,2.477,12.207,6.881,16.61l78.302,78.291c4.587,4.581,10.599,6.875,16.605,6.875c6.006,0,12.023-2.294,16.61-6.881  c9.172-9.174,9.172-24.036-0.005-33.211l-38.205-38.199h152.593v152.063l-38.199-38.211c-9.171-9.18-24.039-9.18-33.216-0.022  c-9.178,9.18-9.178,24.059-0.006,33.222l78.284,78.302c4.41,4.404,10.382,6.881,16.611,6.881c6.233,0,12.208-2.477,16.611-6.881  l78.302-78.296c9.181-9.18,9.181-24.048,0-33.205c-9.174-9.174-24.054-9.174-33.21,0l-38.199,38.188v-152.04h152.051l-38.205,38.199  c-9.18,9.175-9.18,24.037-0.005,33.211c4.587,4.587,10.596,6.881,16.604,6.881c6.01,0,12.024-2.294,16.605-6.875l78.303-78.285  c4.403-4.403,6.887-10.378,6.887-16.611C512.328,252.851,509.845,246.873,505.441,242.47z' },
      statbox : {
         path : 'M28.782,56.902H483.88c15.707,0,28.451-12.74,28.451-28.451C512.331,12.741,499.599,0,483.885,0H28.782   C13.074,0,0.331,12.741,0.331,28.451C0.331,44.162,13.074,56.902,28.782,56.902z' +
                'M483.885,136.845H28.782c-15.708,0-28.451,12.741-28.451,28.451c0,15.711,12.744,28.451,28.451,28.451H483.88   c15.707,0,28.451-12.74,28.451-28.451C512.331,149.586,499.599,136.845,483.885,136.845z' +
                'M483.885,273.275H28.782c-15.708,0-28.451,12.731-28.451,28.452c0,15.707,12.744,28.451,28.451,28.451H483.88   c15.707,0,28.451-12.744,28.451-28.451C512.337,286.007,499.599,273.275,483.885,273.275z' +
                'M256.065,409.704H30.492c-15.708,0-28.451,12.731-28.451,28.451c0,15.707,12.744,28.451,28.451,28.451h225.585   c15.707,0,28.451-12.744,28.451-28.451C284.516,422.436,271.785,409.704,256.065,409.704z'
      },
      circle: { path: "M256,256 m-150,0 a150,150 0 1,0 300,0 a150,150 0 1,0 -300,0" },
      three_circles: { path: "M256,85 m-70,0 a70,70 0 1,0 140,0 a70,70 0 1,0 -140,0  M256,255 m-70,0 a70,70 0 1,0 140,0 a70,70 0 1,0 -140,0  M256,425 m-70,0 a70,70 0 1,0 140,0 a70,70 0 1,0 -140,0 " },
      diamand: { path: "M256,0L384,256L256,511L128,256z" },
      rect: { path: "M80,80h352v352h-352z" },

      CreateSVG : function(group,btn,size,title) {
         var svg = group.append("svg:svg")
                     .attr("class", "svg_toolbar_btn")
                     .attr("width",size+"px")
                     .attr("height",size+"px")
                     .attr("viewBox", "0 0 512 512")
                     .style("overflow","hidden");

           if ('recs' in btn) {
              var rec = {};
              for (var n=0;n<btn.recs.length;++n) {
                 JSROOT.extend(rec, btn.recs[n]);
                 svg.append('rect').attr("x", rec.x).attr("y", rec.y)
                     .attr("width", rec.w).attr("height", rec.h)
                     .attr("fill", rec.f);
              }
           } else {
              svg.append('svg:path').attr('d',btn.path);
           }

           //  special rect to correctly get mouse events for whole button area
           svg.append("svg:rect").attr("x",0).attr("y",0).attr("width",512).attr("height",512)
              .style('opacity',0).style('fill',"none").style("pointer-events","visibleFill")
              .append("svg:title").text(title);

           return svg;
      }
   };


   JSROOT.DrawOptions = function(opt) {
      this.opt = opt && (typeof opt=="string") ? opt.toUpperCase().trim() : "";
      this.part = "";
   }

   JSROOT.DrawOptions.prototype.empty = function() {
      return this.opt.length === 0;
   }

   JSROOT.DrawOptions.prototype.check = function(name,postpart) {
      var pos = this.opt.indexOf(name);
      if (pos < 0) return false;
      this.opt = this.opt.substr(0, pos) + this.opt.substr(pos + name.length);
      this.part = "";
      if (!postpart) return true;

      var pos2 = pos;
      while ((pos2<this.opt.length) && (this.opt[pos2] !== ' ') && (this.opt[pos2] !== ',') && (this.opt[pos2] !== ';')) pos2++;
      if (pos2 > pos) {
         this.part = this.opt.substr(pos, pos2-pos);
         this.opt = this.opt.substr(0, pos) + this.opt.substr(pos2);
      }
      return true;
   }

   JSROOT.DrawOptions.prototype.partAsInt = function(offset, dflt) {
      var val = this.part.replace( /^\D+/g, '');
      val = val ? parseInt(val,10) : Number.NaN;
      return isNaN(val) ? (dflt || 0) : val + (offset || 0);
   }

   /**
    * @class JSROOT.Painter Holder of different functions and classes for drawing
    */
   JSROOT.Painter = {};

   JSROOT.Painter.createMenu = function(painter, maincallback) {
      // dummy functions, forward call to the jquery function
      document.body.style.cursor = 'wait';
      JSROOT.AssertPrerequisites('jq2d', function() {
         document.body.style.cursor = 'auto';
         JSROOT.Painter.createMenu(painter, maincallback);
      });
   }

   JSROOT.Painter.closeMenu = function(menuname) {
      var x = document.getElementById(menuname || 'root_ctx_menu');
      if (x) { x.parentNode.removeChild(x); return true; }
      return false;
   }

   JSROOT.Painter.readStyleFromURL = function(url) {
      var optimize = JSROOT.GetUrlOption("optimize", url);
      if (optimize=="") JSROOT.gStyle.OptimizeDraw = 2; else
      if (optimize!==null) {
         JSROOT.gStyle.OptimizeDraw = parseInt(optimize);
         if (isNaN(JSROOT.gStyle.OptimizeDraw)) JSROOT.gStyle.OptimizeDraw = 2;
      }

      var inter = JSROOT.GetUrlOption("interactive", url);
      if ((inter=="") || (inter=="1")) inter = "11111"; else
      if (inter=="0") inter = "00000";
      if ((inter!==null) && (inter.length==5)) {
         JSROOT.gStyle.Tooltip =     parseInt(inter[0]);
         JSROOT.gStyle.ContextMenu = (inter[1] != '0');
         JSROOT.gStyle.Zooming  =    (inter[2] != '0');
         JSROOT.gStyle.MoveResize =  (inter[3] != '0');
         JSROOT.gStyle.DragAndDrop = (inter[4] != '0');
      }

      var tt = JSROOT.GetUrlOption("tooltip", url);
      if (tt !== null) JSROOT.gStyle.Tooltip = parseInt(tt);

      var mathjax = JSROOT.GetUrlOption("mathjax", url);
      if ((mathjax!==null) && (mathjax!="0")) JSROOT.gStyle.MathJax = 1;

      if (JSROOT.GetUrlOption("nomenu", url)!=null) JSROOT.gStyle.ContextMenu = false;
      if (JSROOT.GetUrlOption("noprogress", url)!=null) JSROOT.gStyle.ProgressBox = false;
      if (JSROOT.GetUrlOption("notouch", url)!=null) JSROOT.touches = false;

      JSROOT.gStyle.fOptStat = JSROOT.GetUrlOption("optstat", url, JSROOT.gStyle.fOptStat);
      JSROOT.gStyle.fOptFit = JSROOT.GetUrlOption("optfit", url, JSROOT.gStyle.fOptFit);
      JSROOT.gStyle.fStatFormat = JSROOT.GetUrlOption("statfmt", url, JSROOT.gStyle.fStatFormat);
      JSROOT.gStyle.fFitFormat = JSROOT.GetUrlOption("fitfmt", url, JSROOT.gStyle.fFitFormat);

      var toolbar = JSROOT.GetUrlOption("toolbar", url);
      if (toolbar !== null)
         if (toolbar==='popup') JSROOT.gStyle.ToolBar = 'popup';
                           else JSROOT.gStyle.ToolBar = (toolbar !== "0") && (toolbar !== "false");

      var palette = JSROOT.GetUrlOption("palette", url);
      if (palette!==null) {
         palette = parseInt(palette);
         if (!isNaN(palette) && (palette>0) && (palette<113)) JSROOT.gStyle.Palette = palette;
      }

      var embed3d = JSROOT.GetUrlOption("embed3d", url);
      if (embed3d !== null) JSROOT.gStyle.Embed3DinSVG = parseInt(embed3d);

      var webgl = JSROOT.GetUrlOption("webgl", url);
      if ((webgl === "0") || (webgl === "false")) JSROOT.gStyle.NoWebGL = true; else
      if (webgl === "ie") JSROOT.gStyle.NoWebGL = !JSROOT.browser.isIE;

      var geosegm = JSROOT.GetUrlOption("geosegm", url);
      if (geosegm!==null) JSROOT.gStyle.GeoGradPerSegm = Math.max(2, parseInt(geosegm));
      var geocomp = JSROOT.GetUrlOption("geocomp", url);
      if (geocomp!==null) JSROOT.gStyle.GeoCompressComp = (geocomp!=='0') && (geocomp!=='false');
   }

   JSROOT.Painter.Coord = {
      kCARTESIAN : 1,
      kPOLAR : 2,
      kCYLINDRICAL : 3,
      kSPHERICAL : 4,
      kRAPIDITY : 5
   }

   /** Function that generates all root colors */
   JSROOT.Painter.root_colors = [];

   JSROOT.Painter.createRootColors = function() {
      var colorMap = ['white','black','red','green','blue','yellow','magenta','cyan','rgb(89,212,84)','rgb(89,84,217)', 'white'];
      colorMap[110] = 'white';

      var moreCol = [
        {col:11,str:'c1b7ad4d4d4d6666668080809a9a9ab3b3b3cdcdcde6e6e6f3f3f3cdc8accdc8acc3c0a9bbb6a4b3a697b8a49cae9a8d9c8f83886657b1cfc885c3a48aa9a1839f8daebdc87b8f9a768a926983976e7b857d9ad280809caca6c0d4cf88dfbb88bd9f83c89a7dc08378cf5f61ac8f94a6787b946971d45a549300ff7b00ff6300ff4b00ff3300ff1b00ff0300ff0014ff002cff0044ff005cff0074ff008cff00a4ff00bcff00d4ff00ecff00fffd00ffe500ffcd00ffb500ff9d00ff8500ff6d00ff5500ff3d00ff2600ff0e0aff0022ff003aff0052ff006aff0082ff009aff00b1ff00c9ff00e1ff00f9ff00ffef00ffd700ffbf00ffa700ff8f00ff7700ff6000ff4800ff3000ff1800ff0000'},
        {col:201,str:'5c5c5c7b7b7bb8b8b8d7d7d78a0f0fb81414ec4848f176760f8a0f14b81448ec4876f1760f0f8a1414b84848ec7676f18a8a0fb8b814ecec48f1f1768a0f8ab814b8ec48ecf176f10f8a8a14b8b848ecec76f1f1'},
        {col:390,str:'ffffcdffff9acdcd9affff66cdcd669a9a66ffff33cdcd339a9a33666633ffff00cdcd009a9a00666600333300'},
        {col:406,str:'cdffcd9aff9a9acd9a66ff6666cd66669a6633ff3333cd33339a3333663300ff0000cd00009a00006600003300'},
        {col:422,str:'cdffff9affff9acdcd66ffff66cdcd669a9a33ffff33cdcd339a9a33666600ffff00cdcd009a9a006666003333'},
        {col:590,str:'cdcdff9a9aff9a9acd6666ff6666cd66669a3333ff3333cd33339a3333660000ff0000cd00009a000066000033'},
        {col:606,str:'ffcdffff9affcd9acdff66ffcd66cd9a669aff33ffcd33cd9a339a663366ff00ffcd00cd9a009a660066330033'},
        {col:622,str:'ffcdcdff9a9acd9a9aff6666cd66669a6666ff3333cd33339a3333663333ff0000cd00009a0000660000330000'},
        {col:791,str:'ffcd9acd9a669a66339a6600cd9a33ffcd66ff9a00ffcd33cd9a00ffcd00ff9a33cd66006633009a3300cd6633ff9a66ff6600ff6633cd3300ff33009aff3366cd00336600339a0066cd339aff6666ff0066ff3333cd0033ff00cdff9a9acd66669a33669a009acd33cdff669aff00cdff339acd00cdff009affcd66cd9a339a66009a6633cd9a66ffcd00ff6633ffcd00cd9a00ffcd33ff9a00cd66006633009a3333cd6666ff9a00ff9a33ff6600cd3300ff339acdff669acd33669a00339a3366cd669aff0066ff3366ff0033cd0033ff339aff0066cd00336600669a339acd66cdff009aff33cdff009acd00cdffcd9aff9a66cd66339a66009a9a33cdcd66ff9a00ffcd33ff9a00cdcd00ff9a33ff6600cd33006633009a6633cd9a66ff6600ff6633ff3300cd3300ffff339acd00666600339a0033cd3366ff669aff0066ff3366cd0033ff0033ff9acdcd669a9a33669a0066cd339aff66cdff009acd009aff33cdff009a'},
        {col:920,str:'cdcdcd9a9a9a666666333333'}];

      for (var indx = 0; indx < moreCol.length; ++indx) {
         var entry = moreCol[indx];
         for (var n=0; n<entry.str.length; n+=6) {
            var num = parseInt(entry.col) + parseInt(n/6);
            colorMap[num] = 'rgb(' + parseInt("0x" +entry.str.slice(n,n+2)) + "," + parseInt("0x" + entry.str.slice(n+2,n+4)) + "," + parseInt("0x" + entry.str.slice(n+4,n+6)) + ")";
         }
      }

      JSROOT.Painter.root_colors = colorMap;
   }

   JSROOT.Painter.MakeColorRGB = function(col) {
      if ((col==null) || (col._typename != 'TColor')) return null;
      var rgb = Math.round(col.fRed*255) + "," + Math.round(col.fGreen*255) + "," + Math.round(col.fBlue*255);
      if ((col.fAlpha === undefined) || (col.fAlpha == 1.))
         rgb = "rgb(" + rgb + ")";
      else
         rgb = "rgba(" + rgb + "," + col.fAlpha.toFixed(3) + ")";

      switch (rgb) {
         case 'rgb(255,255,255)': rgb = 'white'; break;
         case 'rgb(0,0,0)': rgb = 'black'; break;
         case 'rgb(255,0,0)': rgb = 'red'; break;
         case 'rgb(0,255,0)': rgb = 'green'; break;
         case 'rgb(0,0,255)': rgb = 'blue'; break;
         case 'rgb(255,255,0)': rgb = 'yellow'; break;
         case 'rgb(255,0,255)': rgb = 'magenta'; break;
         case 'rgb(0,255,255)': rgb = 'cyan'; break;
      }
      return rgb;
   }

   JSROOT.Painter.adoptRootColors = function(objarr) {
      if (!objarr || !objarr.arr) return;

      for (var n = 0; n < objarr.arr.length; ++n) {
         var col = objarr.arr[n];
         if (!col || (col._typename != 'TColor')) continue;

         var num = col.fNumber;
         if ((num<0) || (num>4096)) continue;

         var rgb = JSROOT.Painter.MakeColorRGB(col);
         if (rgb == null) continue;

         if (JSROOT.Painter.root_colors[num] != rgb)
            JSROOT.Painter.root_colors[num] = rgb;
      }
   }

   JSROOT.Painter.root_line_styles = ["", "", "3,3", "1,2",
         "3,4,1,4", "5,3,1,3", "5,3,1,3,1,3,1,3", "5,5",
         "5,3,1,3,1,3", "20,5", "20,10,1,10", "1,3"];

   // Initialize ROOT markers
   JSROOT.Painter.root_markers =
         [ 0, 100,   8,   7,   0,  //  0..4
           9, 100, 100, 100, 100,  //  5..9
         100, 100, 100, 100, 100,  // 10..14
         100, 100, 100, 100, 100,  // 15..19
         100, 103, 105, 104,   0,  // 20..24
           3,   4,   2,   1, 106,  // 25..29
           6,   7,   5, 102, 101]; // 30..34

   /** Function returns the ready to use marker for drawing */
   JSROOT.Painter.createAttMarker = function(attmarker, style) {

      var marker_color = JSROOT.Painter.root_colors[attmarker.fMarkerColor];

      if (!style || (style<0)) style = attmarker.fMarkerStyle;

      var res = { x0: 0, y0: 0, color: marker_color, style: style, size: 8, scale: 1, stroke: true, fill: true, marker: "",  ndig: 0, used: true, changed: false };

      res.Change = function(color, style, size) {

         this.changed = true;

         if (color!==undefined) this.color = color;
         if ((style!==undefined) && (style>=0)) this.style = style;
         if (size!==undefined) this.size = size; else size = this.size;

         this.x0 = this.y0 = 0;

         this.reset_pos = function() {
            this.lastx = this.lasty = null;
         }

         if ((this.style === 1) || (this.style === 777)) {
            this.fill = false;
            this.marker = "h1";
            this.size = 1;

            // use special create function to handle relative position movements
            this.create = function(x,y) {
               var xx = Math.round(x), yy = Math.round(y), m1 = "M"+xx+","+yy+"h1";
               var m2 = (this.lastx===null) ? m1 : ("m"+(xx-this.lastx)+","+(yy-this.lasty)+"h1");
               this.lastx = xx+1; this.lasty = yy;
               return (m2.length < m1.length) ? m2 : m1;
            }

            this.reset_pos();
            return true;
         }

         var marker_kind = ((this.style>0) && (this.style<JSROOT.Painter.root_markers.length)) ? JSROOT.Painter.root_markers[this.style] : 100;
         var shape = marker_kind % 100;

         this.fill = (marker_kind>=100);

         switch(this.style) {
            case 1: this.size = 1; this.scale = 1; break;
            case 6: this.size = 2; this.scale = 1; break;
            case 7: this.size = 3; this.scale = 1; break;
            default: this.size = size; this.scale = 8;
         }

         size = this.size*this.scale;

         this.ndig = (size>7) ? 0 : ((size>2) ? 1 : 2);
         if (shape == 6) this.ndig++;
         var half = (size/2).toFixed(this.ndig), full = size.toFixed(this.ndig);

         switch(shape) {
         case 0: // circle
            this.x0 = -size/2;
            this.marker = "a"+half+","+half+" 0 1,0 "+full+",0a"+half+","+half+" 0 1,0 -"+full+",0z";
            break;
         case 1: // cross
            var d = (size/3).toFixed(res.ndig);
            this.x0 = this.y0 = size/6;
            this.marker = "h"+d+"v-"+d+"h-"+d+"v-"+d+"h-"+d+"v"+d+"h-"+d+"v"+d+"h"+d+"v"+d+"h"+d+"z";
            break;
         case 2: // diamond
            this.x0 = -size/2;
            this.marker = "l"+half+",-"+half+"l"+half+","+half+"l-"+half+","+half + "z";
            break;
         case 3: // square
            this.x0 = this.y0 = -size/2;
            this.marker = "v"+full+"h"+full+"v-"+full+"z";
            break;
         case 4: // triangle-up
            this.y0 = size/2;
            this.marker = "l-"+ half+",-"+full+"h"+full+"z";
            break;
         case 5: // triangle-down
            this.y0 = -size/2;
            this.marker = "l-"+ half+","+full+"h"+full+"z";
            break;
         case 6: // star
            this.y0 = -size/2;
            this.marker = "l" + (size/3).toFixed(res.ndig)+","+full +
                         "l-"+ (5/6*size).toFixed(res.ndig) + ",-" + (5/8*size).toFixed(res.ndig) +
                         "h" + full +
                         "l-" + (5/6*size).toFixed(res.ndig) + "," + (5/8*size).toFixed(res.ndig) + "z";
            break;
         case 7: // asterisk
            this.x0 = this.y0 = -size/2;
            this.marker = "l"+full+","+full +
                         "m0,-"+full+"l-"+full+","+full+
                         "m0,-"+half+"h"+full+"m-"+half+",-"+half+"v"+full;
            break;
         case 8: // plus
            this.y0 = -size/2;
            this.marker = "v"+full+"m-"+half+",-"+half+"h"+full;
            break;
         case 9: // mult
            this.x0 = this.y0 = -size/2;
            this.marker = "l"+full+","+full + "m0,-"+full+"l-"+full+","+full;
            break;
         default: // diamand
            this.x0 = -size/2;
            this.marker = "l"+half+",-"+half+"l"+half+","+half+"l-"+half+","+half + "z";
            break;
         }

         this.create = function(x,y) {
            return "M" + (x+this.x0).toFixed(this.ndig)+ "," + (y+this.y0).toFixed(this.ndig) + this.marker;
         }

         return true;
      }

      res.Apply = function(selection) {
         selection.style('stroke', this.stroke ? this.color : "none");
         selection.style('fill', this.fill ? this.color : "none");
      }

      res.func = res.Apply.bind(res);

      res.Change(marker_color, style, attmarker.fMarkerSize);

      res.changed = false;

      return res;
   }

   JSROOT.Painter.createAttLine = function(attline, borderw, can_excl) {

      var color = 'black', _width = 0, style = 0;
      if (typeof attline == 'string') {
         color = attline;
         if (color!=='none') _width = 1;
      } else
      if (typeof attline == 'object') {
         if ('fLineColor' in attline) color = JSROOT.Painter.root_colors[attline.fLineColor];
         if ('fLineWidth' in attline) _width = attline.fLineWidth;
         if ('fLineStyle' in attline) style = attline.fLineStyle;
      } else
      if ((attline!==undefined) && !isNaN(attline)) {
         color = JSROOT.Painter.root_colors[attline];
      }

      if (borderw!==undefined) _width = borderw;

      var line = {
          used: true, // can mark object if it used or not,
          color: color,
          width: _width,
          dash: JSROOT.Painter.root_line_styles[style]
      };

      if (_width==0) line.color = 'none';

      if (can_excl) {
         line.excl_side = 0;
         line.excl_width = 0;
         if (Math.abs(line.width) > 99) {
            // exclusion graph
            line.excl_side = (line.width < 0) ? -1 : 1;
            line.excl_width = Math.floor(line.width / 100) * 5;
            line.width = line.width % 100; // line width
         }

         line.ChangeExcl = function(side,width) {
            if (width !== undefined) this.excl_width = width;
            if (side !== undefined) {
               this.excl_side = side;
               if ((this.excl_width===0) && (this.excl_side!==0)) this.excl_width = 20;
            }
            this.changed = true;
         }
      }

      // if custom color number used, use lightgrey color to show lines
      if ((line.color === undefined) && (line.width>0))
         line.color = 'lightgrey';

      line.Apply = function(selection) {
         this.used = true;
         if (this.color=='none') {
            selection.style('stroke',null).style('stroke-width',null).style('stroke-dasharray',null);
         } else {
            selection.style('stroke',this.color).style('stroke-width',this.width);
            if (this.dash && (this.dash.length>0)) selection.style('stroke-dasharray',this.dash);
         }
      }

      line.Change = function(color, width, dash) {
         if (color !== undefined) this.color = color;
         if (width !== undefined) this.width = width;
         if (dash !== undefined) this.dash = dash;
         this.changed = true;
      }

      line.func = line.Apply.bind(line);

      return line;
   }

   JSROOT.Painter.clearCuts = function(chopt) {
      /* decode string "chopt" and remove graphical cuts */
      var left = chopt.indexOf('[');
      var right = chopt.indexOf(']');
      if ((left>=0) && (right>=0) && (left<right))
          for (var i = left; i <= right; ++i) chopt[i] = ' ';
      return chopt;
   }

   JSROOT.Painter.root_fonts = new Array('Arial', 'Times New Roman',
         'bTimes New Roman', 'biTimes New Roman', 'Arial',
         'oArial', 'bArial', 'boArial', 'Courier New',
         'oCourier New', 'bCourier New', 'boCourier New',
         'Symbol', 'Times New Roman', 'Wingdings', 'Symbol', 'Verdana');

   JSROOT.Painter.getFontDetails = function(fontIndex, size) {

      var res = { name: "Arial", size: Math.round(size || 11), weight: null, style: null },
          fontName = JSROOT.Painter.root_fonts[Math.floor(fontIndex / 10)] || "";

      while (fontName.length > 0) {
         if (fontName[0]==='b') res.weight = "bold"; else
         if (fontName[0]==='i') res.style = "italic"; else
         if (fontName[0]==='o') res.style = "oblique"; else break;
         fontName = fontName.substr(1);
      }

      if (fontName == 'Symbol')
         res.weight = res.style = null;

      res.name = fontName;

      res.SetFont = function(selection) {
         selection.attr("font-family", this.name)
                  .attr("font-size", this.size)
                  .attr("xml:space","preserve");
         if (this.weight)
            selection.attr("font-weight", this.weight);
         if (this.style)
            selection.attr("font-style", this.style);
      }

      res.asStyle = function(sz) {
         return (sz ? sz : this.size) + "px " + this.name;
      }

      res.stringWidth = function(svg, line) {
         /* compute the bounding box of a string by using temporary svg:text */
         var text = svg.append("svg:text")
                     .attr("xml:space","preserve")
                     .style("opacity", 0)
                     .text(line);
         this.SetFont(text);
         var w = text.node().getBBox().width;
         text.remove();
         return w;
      }

      res.func = res.SetFont.bind(res);

      return res;
   }

   JSROOT.Painter.chooseTimeFormat = function(awidth, ticks) {
      if (awidth < .5) return ticks ? "%S.%L" : "%M:%S.%L";
      if (awidth < 30) return ticks ? "%Mm%S" : "%H:%M:%S";
      awidth /= 60; if (awidth < 30) return ticks ? "%Hh%M" : "%d/%m %H:%M";
      awidth /= 60; if (awidth < 12) return ticks ? "%d-%Hh" : "%d/%m/%y %Hh";
      awidth /= 24; if (awidth < 15.218425) return ticks ? "%d/%m" : "%d/%m/%y";
      awidth /= 30.43685; if (awidth < 6) return "%d/%m/%y";
      awidth /= 12; if (awidth < 2) return ticks ? "%m/%y" : "%d/%m/%y";
      return "%Y";
   }

   JSROOT.Painter.getTimeFormat = function(axis) {
      var idF = axis.fTimeFormat.indexOf('%F');
      if (idF >= 0) return axis.fTimeFormat.substr(0, idF);
      return axis.fTimeFormat;
   }

   JSROOT.Painter.getTimeOffset = function(axis) {
      var idF = axis.fTimeFormat.indexOf('%F');
      if (idF < 0) return JSROOT.gStyle.fTimeOffset*1000;
      var sof = axis.fTimeFormat.substr(idF + 2);
      // default string in axis offset
      if (sof.indexOf('1995-01-01 00:00:00s0')==0) return 788918400000;
      // special case, used from DABC painters
      if ((sof == "0") || (sof == "")) return 0;

      // decode time from ROOT string
      function next(separ, min, max) {
         var pos = sof.indexOf(separ);
         if (pos < 0) { pos = ""; return min; }
         var val = parseInt(sof.substr(0,pos));
         sof = sof.substr(pos+1);
         if (isNaN(val) || (val<min) || (val>max)) { pos = ""; return min; }
         return val;
      }

      var year = next("-", 1970, 2300),
          month = next("-", 1, 12) - 1,
          day = next(" ", 1, 31),
          hour = next(":", 0, 23),
          min = next(":", 0, 59),
          sec = next("s", 0, 59),
          msec = next(" ", 0, 999);

      var dt = new Date(Date.UTC(year, month, day, hour, min, sec, msec));
      return dt.getTime();
   }

   JSROOT.Painter.superscript_symbols_map = {
       '1': '\xB9',
       '2': '\xB2',
       '3': '\xB3',
       'o': '\xBA',
       '0': '\u2070',
       'i': '\u2071',
       '4': '\u2074',
       '5': '\u2075',
       '6': '\u2076',
       '7': '\u2077',
       '8': '\u2078',
       '9': '\u2079',
       '+': '\u207A',
       '-': '\u207B',
       '=': '\u207C',
       '(': '\u207D',
       ')': '\u207E',
       'n': '\u207F',
       'a': '\xAA',
       'v': '\u2C7D',
       'h': '\u02B0',
       'j': '\u02B2',
       'r': '\u02B3',
       'w': '\u02B7',
       'y': '\u02B8',
       'l': '\u02E1',
       's': '\u02E2',
       'x': '\u02E3'
   }

   JSROOT.Painter.subscript_symbols_map = {
         '0': '\u2080',
         '1': '\u2081',
         '2': '\u2082',
         '3': '\u2083',
         '4': '\u2084',
         '5': '\u2085',
         '6': '\u2086',
         '7': '\u2087',
         '8': '\u2088',
         '9': '\u2089',
         '+': '\u208A',
         '-': '\u208B',
         '=': '\u208C',
         '(': '\u208D',
         ')': '\u208E',
         'a': '\u2090',
         'e': '\u2091',
         'o': '\u2092',
         'x': '\u2093',
         'ə': '\u2094',
         'h': '\u2095',
         'k': '\u2096',
         'l': '\u2097',
         'm': '\u2098',
         'n': '\u2099',
         'p': '\u209A',
         's': '\u209B',
         't': '\u209C',
         'j': '\u2C7C'
    }

   JSROOT.Painter.translateSuperscript = function(_exp) {
      var res = "";
      for (var n=0;n<_exp.length;++n)
         res += (this.superscript_symbols_map[_exp[n]] || _exp[n]);
      return res;
   }

   JSROOT.Painter.translateSubscript = function(_sub) {
      var res = "";
      for (var n=0;n<_sub.length;++n)
         res += (this.subscript_symbols_map[_sub[n]] || _sub[n]);
      return res;
   }

   JSROOT.Painter.formatExp = function(label) {
      var str = label.toLowerCase().replace('e+', 'x10@').replace('e-', 'x10@-'),
          pos = str.indexOf('@'),
          exp = JSROOT.Painter.translateSuperscript(str.substr(pos+1)),
          str = str.substr(0, pos);

      return ((str === "1x10") ? "10" : str) + exp;
   }

   JSROOT.Painter.symbols_map = {
      // greek letters
      '#alpha': '\u03B1',
      '#beta': '\u03B2',
      '#chi': '\u03C7',
      '#delta': '\u03B4',
      '#varepsilon': '\u03B5',
      '#phi': '\u03C6',
      '#gamma': '\u03B3',
      '#eta': '\u03B7',
      '#iota': '\u03B9',
      '#varphi': '\u03C6',
      '#kappa': '\u03BA',
      '#lambda': '\u03BB',
      '#mu': '\u03BC',
      '#nu': '\u03BD',
      '#omicron': '\u03BF',
      '#pi': '\u03C0',
      '#theta': '\u03B8',
      '#rho': '\u03C1',
      '#sigma': '\u03C3',
      '#tau': '\u03C4',
      '#upsilon': '\u03C5',
      '#varomega': '\u03D6',
      '#omega': '\u03C9',
      '#xi': '\u03BE',
      '#psi': '\u03C8',
      '#zeta': '\u03B6',
      '#Alpha': '\u0391',
      '#Beta': '\u0392',
      '#Chi': '\u03A7',
      '#Delta': '\u0394',
      '#Epsilon': '\u0395',
      '#Phi': '\u03A6',
      '#Gamma': '\u0393',
      '#Eta': '\u0397',
      '#Iota': '\u0399',
      '#vartheta': '\u03D1',
      '#Kappa': '\u039A',
      '#Lambda': '\u039B',
      '#Mu': '\u039C',
      '#Nu': '\u039D',
      '#Omicron': '\u039F',
      '#Pi': '\u03A0',
      '#Theta': '\u0398',
      '#Rho': '\u03A1',
      '#Sigma': '\u03A3',
      '#Tau': '\u03A4',
      '#Upsilon': '\u03A5',
      '#varsigma': '\u03C2',
      '#Omega': '\u03A9',
      '#Xi': '\u039E',
      '#Psi': '\u03A8',
      '#Zeta': '\u0396',
      '#varUpsilon': '\u03D2',
      '#epsilon': '\u03B5',
      // math symbols

      '#sqrt': '\u221A',

      // from TLatex tables #2 & #3
      '#leq': '\u2264',
      '#/': '\u2044',
      '#infty': '\u221E',
      '#voidb': '\u0192',
      '#club': '\u2663',
      '#diamond': '\u2666',
      '#heart': '\u2665',
      '#spade': '\u2660',
      '#leftrightarrow': '\u2194',
      '#leftarrow': '\u2190',
      '#uparrow': '\u2191',
      '#rightarrow': '\u2192',
      '#downarrow': '\u2193',
      '#circ': '\u02C6', // ^
      '#pm': '\xB1',
      '#doublequote': '\u2033',
      '#geq': '\u2265',
      '#times': '\xD7',
      '#propto': '\u221D',
      '#partial': '\u2202',
      '#bullet': '\u2022',
      '#divide': '\xF7',
      '#neq': '\u2260',
      '#equiv': '\u2261',
      '#approx': '\u2248', // should be \u2245 ?
      '#3dots': '\u2026',
      '#cbar': '\u007C',
      '#topbar': '\xAF',
      '#downleftarrow': '\u21B5',
      '#aleph': '\u2135',
      '#Jgothic': '\u2111',
      '#Rgothic': '\u211C',
      '#voidn': '\u2118',
      '#otimes': '\u2297',
      '#oplus': '\u2295',
      '#oslash': '\u2205',
      '#cap': '\u2229',
      '#cup': '\u222A',
      '#supseteq': '\u2287',
      '#supset': '\u2283',
      '#notsubset': '\u2284',
      '#subseteq': '\u2286',
      '#subset': '\u2282',
      '#int': '\u222B',
      '#in': '\u2208',
      '#notin': '\u2209',
      '#angle': '\u2220',
      '#nabla': '\u2207',
      '#oright': '\xAE',
      '#ocopyright': '\xA9',
      '#trademark': '\u2122',
      '#prod': '\u220F',
      '#surd': '\u221A',
      '#upoint': '\u22C5',
      '#corner': '\xAC',
      '#wedge': '\u2227',
      '#vee': '\u2228',
      '#Leftrightarrow': '\u21D4',
      '#Leftarrow': '\u21D0',
      '#Uparrow': '\u21D1',
      '#Rightarrow': '\u21D2',
      '#Downarrow': '\u21D3',
      '#LT': '\x3C',
      '#void1': '\xAE',
      '#copyright': '\xA9',
      '#void3': '\u2122',
      '#sum': '\u2211',
      '#arctop': '',
      '#lbar': '',
      '#arcbottom': '',
      '#void8': '',
      '#bottombar': '\u230A',
      '#arcbar': '',
      '#ltbar': '',
      '#AA': '\u212B',
      '#aa': '\u00E5',
      '#void06': '',
      '#GT': '\x3E',
      '#forall': '\u2200',
      '#exists': '\u2203',
      '#bar': '',
      '#vec': '',
      '#dot': '\u22C5',
      '#hat': '\xB7',
      '#ddot': '',
      '#acute': '\acute',
      '#grave': '',
      '#check': '\u2713',
      '#tilde': '\u02DC',
      '#slash': '\u2044',
      '#hbar': '\u0127',
      '#box': '',
      '#Box': '',
      '#parallel': '',
      '#perp': '\u22A5',
      '#odot': '',
      '#left': '',
      '#right': ''
   };

   JSROOT.Painter.translateLaTeX = function(_string) {
      var str = _string, i;

      var lstr = str.match(/\^{(.*?)}/gi);
      if (lstr)
         for (i = 0; i < lstr.length; ++i)
            str = str.replace(lstr[i], JSROOT.Painter.translateSuperscript(lstr[i].substr(2, lstr[i].length-3)));

      lstr = str.match(/\_{(.*?)}/gi);
      if (lstr)
         for (i = 0; i < lstr.length; ++i)
            str = str.replace(lstr[i], JSROOT.Painter.translateSubscript(lstr[i].substr(2, lstr[i].length-3)));

      lstr = str.match(/\#sqrt{(.*?)}/gi);
      if (lstr)
         for (i = 0; i < lstr.length; ++i)
            str = str.replace(lstr[i], lstr[i].replace(' ', '').replace('#sqrt{', '#sqrt').replace('}', ''));

      for (i in JSROOT.Painter.symbols_map)
         str = str.replace(new RegExp(i,'g'), JSROOT.Painter.symbols_map[i]);

      // simple workaround for simple #splitline{first_line}{second_line}
      if ((str.indexOf("#splitline{")==0) && (str[str.length-1]=="}")) {
         var pos = str.indexOf("}{");
         if ((pos>0) && (pos === str.lastIndexOf("}{")))
            str = str.replace("}{", "\n ").slice(11, str.length-1)
      }

      return str.replace(/\^2/gi,'\xB2').replace(/\^3/gi,'\xB3');
   }

   JSROOT.Painter.isAnyLatex = function(str) {
      return (str.indexOf("#")>=0) || (str.indexOf("\\")>=0) || (str.indexOf("{")>=0);
   }

   JSROOT.Painter.math_symbols_map = {
         '#LT':"\\langle",
         '#GT':"\\rangle",
         '#club':"\\clubsuit",
         '#spade':"\\spadesuit",
         '#heart':"\\heartsuit",
         '#diamond':"\\diamondsuit",
         '#voidn':"\\wp",
         '#voidb':"f",
         '#copyright':"(c)",
         '#ocopyright':"(c)",
         '#trademark':"TM",
         '#void3':"TM",
         '#oright':"R",
         '#void1':"R",
         '#3dots':"\\ldots",
         '#lbar':"\\mid",
         '#void8':"\\mid",
         '#divide':"\\div",
         '#Jgothic':"\\Im",
         '#Rgothic':"\\Re",
         '#doublequote':"\"",
         '#plus':"+",
         '#diamond':"\\diamondsuit",
         '#voidn':"\\wp",
         '#voidb':"f",
         '#copyright':"(c)",
         '#ocopyright':"(c)",
         '#trademark':"TM",
         '#void3':"TM",
         '#oright':"R",
         '#void1':"R",
         '#3dots':"\\ldots",
         '#lbar':"\\mid",
         '#void8':"\\mid",
         '#divide':"\\div",
         '#Jgothic':"\\Im",
         '#Rgothic':"\\Re",
         '#doublequote':"\"",
         '#plus':"+",
         '#minus':"-",
         '#\/':"/",
         '#upoint':".",
         '#aa':"\\mathring{a}",
         '#AA':"\\mathring{A}",
         '#omicron':"o",
         '#Alpha':"A",
         '#Beta':"B",
         '#Epsilon':"E",
         '#Zeta':"Z",
         '#Eta':"H",
         '#Iota':"I",
         '#Kappa':"K",
         '#Mu':"M",
         '#Nu':"N",
         '#Omicron':"O",
         '#Rho':"P",
         '#Tau':"T",
         '#Chi':"X",
         '#varomega':"\\varpi",
         '#corner':"?",
         '#ltbar':"?",
         '#bottombar':"?",
         '#notsubset':"?",
         '#arcbottom':"?",
         '#cbar':"?",
         '#arctop':"?",
         '#topbar':"?",
         '#arcbar':"?",
         '#downleftarrow':"?",
         '#splitline':"\\genfrac{}{}{0pt}{}",
         '#it':"\\textit",
         '#bf':"\\textbf",
         '#frac':"\\frac",
         '#left{':"\\lbrace",
         '#right}':"\\rbrace",
         '#left\\[':"\\lbrack",
         '#right\\]':"\\rbrack",
         '#\\[\\]{':"\\lbrack",
         ' } ':"\\rbrack",
         '#\\[':"\\lbrack",
         '#\\]':"\\rbrack",
         '#{':"\\lbrace",
         '#}':"\\rbrace",
         ' ':"\\;"
   };

   JSROOT.Painter.translateMath = function(str, kind, color) {
      // function translate ROOT TLatex into MathJax format

      if (kind!=2) {
         for (var x in JSROOT.Painter.math_symbols_map)
            str = str.replace(new RegExp(x,'g'), JSROOT.Painter.math_symbols_map[x]);

         for (var x in JSROOT.Painter.symbols_map)
            str = str.replace(new RegExp(x,'g'), "\\" + x.substr(1));
      } else {
         str = str.replace(/\\\^/g, "\\hat");
      }

      if (typeof color != 'string') return "\\(" + str + "\\)";

      // MathJax SVG converter use colors in normal form
      //if (color.indexOf("rgb(")>=0)
      //   color = color.replace(/rgb/g, "[RGB]")
      //                .replace(/\(/g, '{')
      //                .replace(/\)/g, '}');
      return "\\(\\color{" + color + '}' + str + "\\)";
   }

   JSROOT.Painter.BuildSvgPath = function(kind, bins, height, ndig) {
      // function used to provide svg:path for the smoothed curves
      // reuse code from d3.js. Used in TH1, TF1 and TGraph painters
      // kind should contain "bezier" or "line".
      // If first symbol "L", than it used to continue drawing

      var smooth = kind.indexOf("bezier") >= 0;

      if (ndig===undefined) ndig = smooth ? 2 : 0;
      if (height===undefined) height = 0;

      function jsroot_d3_svg_lineSlope(p0, p1) {
         return (p1.gry - p0.gry) / (p1.grx - p0.grx);
      }
      function jsroot_d3_svg_lineFiniteDifferences(points) {
         var i = 0, j = points.length - 1, m = [], p0 = points[0], p1 = points[1], d = m[0] = jsroot_d3_svg_lineSlope(p0, p1);
         while (++i < j) {
            m[i] = (d + (d = jsroot_d3_svg_lineSlope(p0 = p1, p1 = points[i + 1]))) / 2;
         }
         m[i] = d;
         return m;
      }
      function jsroot_d3_svg_lineMonotoneTangents(points) {
         var d, a, b, s, m = jsroot_d3_svg_lineFiniteDifferences(points), i = -1, j = points.length - 1;
         while (++i < j) {
            d = jsroot_d3_svg_lineSlope(points[i], points[i + 1]);
            if (Math.abs(d) < 1e-6) {
               m[i] = m[i + 1] = 0;
            } else {
               a = m[i] / d;
               b = m[i + 1] / d;
               s = a * a + b * b;
               if (s > 9) {
                  s = d * 3 / Math.sqrt(s);
                  m[i] = s * a;
                  m[i + 1] = s * b;
               }
            }
         }
         i = -1;
         while (++i <= j) {
            s = (points[Math.min(j, i + 1)].grx - points[Math.max(0, i - 1)].grx) / (6 * (1 + m[i] * m[i]));
            points[i].dgrx = s || 0;
            points[i].dgry = m[i]*s || 0;
         }
      }

      var res = {}, bin = bins[0], prev, maxy = Math.max(bin.gry, height+5),
          currx = Math.round(bin.grx), curry = Math.round(bin.gry), dx, dy;

      res.path = ((kind[0] == "L") ? "L" : "M") +
                  bin.grx.toFixed(ndig) + "," + bin.gry.toFixed(ndig);

      // just calculate all deltas, can be used to build exclusion
      if (smooth || kind.indexOf('calc')>=0)
         jsroot_d3_svg_lineMonotoneTangents(bins);

      if (smooth)
         res.path +=  "c" + bin.dgrx.toFixed(ndig) + "," + bin.dgry.toFixed(ndig) + ",";

      for(var n=1; n<bins.length; ++n) {
          prev = bin;
          bin = bins[n];
          if (smooth) {
             if (n > 1) res.path += "s";
             res.path += (bin.grx-bin.dgrx-prev.grx).toFixed(ndig) + "," + (bin.gry-bin.dgry-prev.gry).toFixed(ndig) + "," + (bin.grx-prev.grx).toFixed(ndig) + "," + (bin.gry-prev.gry).toFixed(ndig);
             maxy = Math.max(maxy, prev.gry);
          } else {
             dx = Math.round(bin.grx - currx);
             dy = Math.round(bin.gry - curry);
             res.path += "l" + dx + "," + dy;
             currx+=dx; curry+=dy;
             maxy = Math.max(maxy, curry);
          }
      }

      if (height>0)
         res.close = "L" + bin.grx.toFixed(ndig) +"," + maxy.toFixed(ndig) +
                     "L" + bins[0].grx.toFixed(ndig) +"," + maxy.toFixed(ndig) + "Z";

      return res;
   }

   // ==============================================================================

   JSROOT.TBasePainter = function() {
      this.divid = null; // either id of element (preferable) or element itself
   }

   JSROOT.TBasePainter.prototype.AccessTopPainter = function(on) {
      // access painter in the first child element
      // on === true - set this as painter
      // on === false - delete painter
      // on === undefined - return painter
      var main = this.select_main().node(),
         chld = main ? main.firstChild : null;
      if (!chld) return null;
      if (on===true) chld.painter = this; else
      if (on===false) delete chld.painter;
      return chld.painter;
   }

   JSROOT.TBasePainter.prototype.Cleanup = function() {
      // generic method to cleanup painter

      this.layout_main('simple');
      this.AccessTopPainter(false);
      this.divid = null;

      if (this._hpainter && typeof this._hpainter.ClearPainter === 'function') this._hpainter.ClearPainter(this);

      delete this._hitemname;
      delete this._hdrawopt;
      delete this._hpainter;
   }

   JSROOT.TBasePainter.prototype.DrawingReady = function(res_painter) {
      // function should be called by the painter when first drawing is completed

      this._ready_called_ = true;
      if (this._ready_callback_ !== undefined) {
         if (!this._return_res_painter) res_painter = this;
                                   else delete this._return_res_painter;

         while (this._ready_callback_.length)
            JSROOT.CallBack(this._ready_callback_.shift(), res_painter);
         delete this._ready_callback_;
      }
      return this;
   }

   JSROOT.TBasePainter.prototype.WhenReady = function(callback) {
      // call back will be called when painter ready with the drawing
      if (typeof callback !== 'function') return;
      if ('_ready_called_' in this) return JSROOT.CallBack(callback, this);
      if (this._ready_callback_ === undefined) this._ready_callback_ = [];
      this._ready_callback_.push(callback);
   }

   JSROOT.TBasePainter.prototype.GetObject = function() {
      return null;
   }

   JSROOT.TBasePainter.prototype.MatchObjectType = function(typ) {
      return false;
   }

   JSROOT.TBasePainter.prototype.UpdateObject = function(obj) {
      return false;
   }

   JSROOT.TBasePainter.prototype.RedrawPad = function(resize) {
   }

   JSROOT.TBasePainter.prototype.RedrawObject = function(obj) {
      if (!this.UpdateObject(obj)) return false;
      var current = document.body.style.cursor;
      document.body.style.cursor = 'wait';
      this.RedrawPad();
      document.body.style.cursor = current;
      return true;
   }

   JSROOT.TBasePainter.prototype.CheckResize = function(arg) {
      return false; // indicate if resize is processed
   }

   JSROOT.TBasePainter.prototype.select_main = function(is_direct) {
      // return d3.select for main element for drawing, defined with divid
      // if main element was layout, returns main element inside layout

      if (!this.divid) return d3.select(null);
      var id = this.divid;
      if ((typeof id == "string") && (id[0]!='#')) id = "#" + id;
      var res = d3.select(id);
      if (res.empty() || (is_direct==='origin')) return res;

      var use_enlarge = res.property('use_enlarge'),
          layout = res.property('layout');

      if (layout && (layout !=="simple")) {
         switch(is_direct) {
            case 'header': res = res.select(".canvas_header"); break;
            case 'footer': res = res.select(".canvas_footer"); break;
            default: res = res.select(".canvas_main");
         }
      } else {
         if (typeof is_direct === 'string') return d3.select(null);
      }

      // one could redirect here
      if (!is_direct && !res.empty() && use_enlarge) res = d3.select("#jsroot_enlarge_div");

      return res;
   }

   JSROOT.TBasePainter.prototype.layout_main = function(kind) {

      kind = kind || "simple";

      // first extract all childs
      var origin = this.select_main('origin');
      if (origin.empty() || (origin.property('layout') === kind)) return false;

      var main = this.select_main(), lst = [];

      while (main.node().firstChild)
         lst.push(main.node().removeChild(main.node().firstChild));

      if (kind === "simple") {
         // simple layout - nothing inside
         origin.html("");
         main = origin;
      } else {

         // now create all necessary divs

         var maindiv = origin.html("")
                          .append("div")
                          .attr("class","jsroot")
                          .style('display','flex')
                          .style('flex-direction','column')
                          .style('width','100%')
                          .style('height','100%');

         var header = maindiv.append("div").attr('class','canvas_header').style('width','100%');

         main = maindiv.append("div")
                       .style('flex',1) // use all available vertical space in the parent div
                       .style('width','100%')
                       .style("position","relative") // one should use absolute position for
                       .attr("class", "canvas_main");

         var footer = maindiv.append("div").attr('class','canvas_footer').style('width','100%');
      }

      // now append all childs to the newmain
      for (var k=0;k<lst.length;++k)
         main.node().appendChild(lst[k]);

      origin.property('layout', kind);

      return lst.length > 0; // return true when layout changed and there are elements inside
   }

   JSROOT.TBasePainter.prototype.check_main_resize = function(check_level, new_size, height_factor) {
      // function checks if geometry of main div changed
      // returns size of area when main div is drawn
      // take into account enlarge state

      var enlarge = this.enlarge_main('state'),
          main_origin = this.select_main('origin'),
          main = this.select_main(),
          lmt = 5; // minimal size

      if (enlarge !== 'on') {
         if (new_size && new_size.width && new_size.height)
            main_origin.style('width',new_size.width+"px")
                       .style('height',new_size.height+"px");
      }

      var rect_origin = this.get_visible_rect(main_origin, true);

      var can_resize = main_origin.attr('can_resize'),
          do_resize = false;

      if (can_resize == "height")
         if (height_factor && Math.abs(rect_origin.width*height_factor - rect_origin.height) > 0.1*rect_origin.width) do_resize = true;

      if (((rect_origin.height <= lmt) || (rect_origin.width <= lmt)) &&
           can_resize && can_resize !== 'false') do_resize = true;

      if (do_resize && (enlarge !== 'on')) {
          // if zero size and can_resize attribute set, change container size

         if (rect_origin.width > lmt) {
            height_factor = height_factor || 0.66;
            main_origin.style('height', Math.round(rect_origin.width * height_factor)+'px');
         } else
         if (can_resize !== 'height') {
            main_origin.style('width', '200px').style('height', '100px');
         }
      }

      var rect = this.get_visible_rect(main),
          old_h = main.property('draw_height'), old_w = main.property('draw_width');

      rect.changed = false;

      if (old_h && old_w && (old_h>0) && (old_w>0)) {
         if ((old_h !== rect.height) || (old_w !== rect.width))
            if ((check_level>1) || (rect.width/old_w<0.66) || (rect.width/old_w>1.5) ||
                  (rect.height/old_h<0.66) && (rect.height/old_h>1.5)) rect.changed = true;
      } else {
         rect.changed = true;
      }

      return rect;
   }

   JSROOT.TBasePainter.prototype.enlarge_main = function(action) {
      // action can be:  true, false, 'toggle', 'state', 'verify'
      // if action not specified, just return possibility to enlarge main div

      var main = this.select_main(true),
          origin = this.select_main('origin');

      if (main.empty() || !JSROOT.gStyle.CanEnlarge || (origin.property('can_enlarge')===false)) return false;

      if (action===undefined) return true;

      if (action==='verify') return true;

      var state = origin.property('use_enlarge') ? "on" : "off";

      if (action === 'state') return state;

      if (action === 'toggle') action = (state==="off");

      var enlarge = d3.select("#jsroot_enlarge_div");

      if ((action === true) && (state!=="on")) {
         if (!enlarge.empty()) return false;

         enlarge = d3.select(document.body)
                       .append("div")
                       .attr("id","jsroot_enlarge_div");

         var rect1 = this.get_visible_rect(main),
             rect2 = this.get_visible_rect(enlarge);

         // if new enlarge area not big enough, do not do it
         if ((rect2.width<=rect1.width) || (rect2.height<=rect1.height))
            if (rect2.width*rect2.height < rect1.width*rect1.height) {
               console.log('Enlarged area ' +rect2.width+"x"+rect2.height+' smaller then original drawing ' + rect1.width+"x"+rect1.height);
               enlarge.remove();
               return false;
            }

         while (main.node().childNodes.length > 0)
            enlarge.node().appendChild(main.node().firstChild);

         origin.property('use_enlarge', true);

         return true;
      }
      if ((action === false) && (state!=="off")) {

         while (enlarge.node() && enlarge.node().childNodes.length > 0)
            main.node().appendChild(enlarge.node().firstChild);

         enlarge.remove();
         origin.property('use_enlarge', false);
         return true;
      }

      return false;
   }

   JSROOT.TBasePainter.prototype.GetStyleValue = function(elem, name) {
      if (!elem || elem.empty()) return 0;
      var value = elem.style(name);
      if (!value || (typeof value !== 'string')) return 0;
      value = parseFloat(value.replace("px",""));
      return isNaN(value) ? 0 : Math.round(value);
   }

   JSROOT.TBasePainter.prototype.get_visible_rect = function(elem, fullsize) {
      // return rect with width/height which correspond to the visible area of drawing region

      if (JSROOT.nodejs)
         return { width : parseInt(elem.attr("width")), height: parseInt(elem.attr("height")) };

      var rect = elem.node().getBoundingClientRect(),
          res = { width: Math.round(rect.width), height: Math.round(rect.height) };

      if (!fullsize) {
         // this is size exclude padding area
         res.width -= this.GetStyleValue(elem,'padding-left') + this.GetStyleValue(elem,'padding-right');
         res.height -= this.GetStyleValue(elem,'padding-top') - this.GetStyleValue(elem,'padding-bottom');
      }

      return res;
   }

   JSROOT.TBasePainter.prototype.SetDivId = function(divid) {
      // base painter does not creates canvas or frames
      // it registered in the first child element
      if (arguments.length > 0)
         this.divid = divid;

      this.AccessTopPainter(true);
   }

   JSROOT.TBasePainter.prototype.SetItemName = function(name, opt, hpainter) {
      if (typeof name === 'string') this._hitemname = name;
                               else delete this._hitemname;
      // only upate draw option, never delete. null specified when update drawing
      if (typeof opt === 'string') this._hdrawopt = opt;

      this._hpainter = hpainter;
   }

   JSROOT.TBasePainter.prototype.GetItemName = function() {
      return ('_hitemname' in this) ? this._hitemname : null;
   }

   JSROOT.TBasePainter.prototype.GetItemDrawOpt = function() {
      return ('_hdrawopt' in this) ? this._hdrawopt : "";
   }

   JSROOT.TBasePainter.prototype.CanZoomIn = function(axis,left,right) {
      // check if it makes sense to zoom inside specified axis range
      return false;
   }

   // ==============================================================================

   JSROOT.TObjectPainter = function(obj) {
      JSROOT.TBasePainter.call(this);
      this.draw_g = null; // container for all drawn objects
      this.pad_name = ""; // name of pad where object is drawn
      this.main = null;  // main painter, received from pad
      this.draw_object = ((obj!==undefined) && (typeof obj == 'object')) ? obj : null;
   }

   JSROOT.TObjectPainter.prototype = Object.create(JSROOT.TBasePainter.prototype);

   JSROOT.TObjectPainter.prototype.Cleanup = function() {

      this.RemoveDrawG();

      // generic method to cleanup painters
      //if (this.is_main_painter())
      //   this.select_main().html("");

      // cleanup all existing references
      this.pad_name = "";
      this.main = null;
      this.draw_object = null;

      // remove attributes objects (if any)
      delete this.fillatt;
      delete this.lineatt;
      delete this.markeratt;
      delete this.bins;

      JSROOT.TBasePainter.prototype.Cleanup.call(this);
   }

   JSROOT.TObjectPainter.prototype.GetObject = function() {
      return this.draw_object;
   }

   JSROOT.TObjectPainter.prototype.MatchObjectType = function(arg) {
      if ((arg === undefined) || (arg === null) || (this.draw_object===null)) return false;
      if (typeof arg === 'string') return this.draw_object._typename === arg;
      return (typeof arg === 'object') && (this.draw_object._typename === arg._typename);
   }

   JSROOT.TObjectPainter.prototype.SetItemName = function(name, opt, hpainter) {
      JSROOT.TBasePainter.prototype.SetItemName.call(this, name, opt, hpainter);
      if (this.no_default_title || (name=="")) return;
      var can = this.svg_canvas();
      if (!can.empty()) can.select("title").text(name);
                   else this.select_main().attr("title", name);
   }

   JSROOT.TObjectPainter.prototype.UpdateObject = function(obj) {
      // generic method to update object
      // just copy all members from source object
      if (!this.MatchObjectType(obj)) return false;
      JSROOT.extend(this.GetObject(), obj);
      return true;
   }

   JSROOT.TObjectPainter.prototype.GetTipName = function(append) {
      var res = this.GetItemName();
      if (res===null) res = "";
      if ((res.length === 0) && ('fName' in this.GetObject()))
         res = this.GetObject().fName;
      if (res.lenght > 20) res = res.substr(0,17)+"...";
      if ((res.length > 0) && (append!==undefined)) res += append;
      return res;
   }

   JSROOT.TObjectPainter.prototype.pad_painter = function(active_pad) {
      var can = active_pad ? this.svg_pad() : this.svg_canvas();
      return can.empty() ? null : can.property('pad_painter');
   }

   JSROOT.TObjectPainter.prototype.CheckResize = function(arg) {
      // no painter - no resize
      var pad_painter = this.pad_painter();
      if (!pad_painter) return false;

      // only canvas should be checked
      pad_painter.CheckCanvasResize(arg);
      return true;
   }

   JSROOT.TObjectPainter.prototype.RemoveDrawG = function() {
      // generic method to delete all graphical elements, associated with painter
      if (this.draw_g != null) {
         this.draw_g.remove();
         this.draw_g = null;
      }
   }

   /** function (re)creates svg:g element used for specific object drawings
     *  either one attached svg:g to pad (take_pad==true) or to the frame (take_pad==false)
     *  svg:g element can be attached to different layers */
   JSROOT.TObjectPainter.prototype.RecreateDrawG = function(take_pad, layer) {
      if (this.draw_g) {
         // one should keep svg:g element on its place
         // d3.selectAll(this.draw_g.node().childNodes).remove();
         this.draw_g.selectAll('*').remove();
      } else
      if (take_pad) {
         if (typeof layer != 'string') layer = "text_layer";
         if (layer[0] == ".") layer = layer.substr(1);
         this.draw_g = this.svg_layer(layer).append("svg:g");
      } else {
         if (typeof layer != 'string') layer = ".main_layer";
         if (layer[0] != ".") layer = "." + layer;
         this.draw_g = this.svg_frame().select(layer).append("svg:g");
      }

      // set attributes for debugging
      if (this.draw_object!==null) {
         this.draw_g.attr('objname', encodeURI(this.draw_object.fName || "name"));
         this.draw_g.attr('objtype', encodeURI(this.draw_object._typename || "type"));
      }

      return this.draw_g;
   }

   /** This is main graphical SVG element, where all Canvas drawing are performed */
   JSROOT.TObjectPainter.prototype.svg_canvas = function() {
      return this.select_main().select(".root_canvas");
   }

   /** This is SVG element, correspondent to current pad */
   JSROOT.TObjectPainter.prototype.svg_pad = function(pad_name) {
      var c = this.svg_canvas();
      if (pad_name === undefined) pad_name = this.pad_name;
      if (pad_name && !c.empty())
         c = c.select(".subpads_layer").select("[pad=" + pad_name + ']');
      return c;
   }

   /** Method selects immediate layer under canvas/pad main element */
   JSROOT.TObjectPainter.prototype.svg_layer = function(name, pad_name) {
      var svg = this.svg_pad(pad_name);
      if (svg.empty()) return svg;

      var node = svg.node().firstChild;

      while (node!==null) {
         var elem = d3.select(node);
         if (elem.classed(name)) return elem;
         node = node.nextSibling;
      }

      return d3.select(null);
   }

   JSROOT.TObjectPainter.prototype.CurrentPadName = function(new_name) {
      var svg = this.svg_canvas();
      if (svg.empty()) return "";
      var curr = svg.property('current_pad');
      if (new_name !== undefined) svg.property('current_pad', new_name);
      return curr;
   }

   JSROOT.TObjectPainter.prototype.root_pad = function() {
      var pad_painter = this.pad_painter(true);
      return pad_painter ? pad_painter.pad : null;
   }

   /** Converts pad x or y coordinate into NDC value */
   JSROOT.TObjectPainter.prototype.ConvertToNDC = function(axis, value, isndc) {
      if (isndc) return value;
      var pad = this.root_pad();
      if (!pad) return value;

      if (axis=="y") {
         if (pad.fLogy)
            value = (value>0) ? JSROOT.log10(value) : pad.fUymin;
         return (value - pad.fY1) / (pad.fY2 - pad.fY1);
      }
      if (pad.fLogx)
         value = (value>0) ? JSROOT.log10(value) : pad.fUxmin;
      return (value - pad.fX1) / (pad.fX2 - pad.fX1);
   }

   /** Converts x or y coordinate into SVG pad coordinates,
    *  which could be used directly for drawing in the pad.
    *  Parameters: axis should be "x" or "y", value to convert
    *  Always return rounded values */
   JSROOT.TObjectPainter.prototype.AxisToSvg = function(axis, value, isndc) {
      var main = this.main_painter();
      if (main && !isndc) {
         // this is frame coordinates
         value = (axis=="y") ? main.gry(value) + main.frame_y()
                             : main.grx(value) + main.frame_x();
      } else {
         if (!isndc) value = this.ConvertToNDC(axis, value);
         value = (axis=="y") ? (1-value)*this.pad_height() : value*this.pad_width();
      }
      return Math.round(value);
   }

   /** This is SVG element with current frame */
   JSROOT.TObjectPainter.prototype.svg_frame = function() {
      return this.svg_pad().select(".root_frame");
   }

   JSROOT.TObjectPainter.prototype.frame_painter = function() {
      var elem = this.svg_frame();
      var res = elem.empty() ? null : elem.property('frame_painter');
      return res ? res : null;
   }

   JSROOT.TObjectPainter.prototype.pad_width = function(pad_name) {
      var sel = this.svg_pad(pad_name);
      var res = this.svg_pad(pad_name).property("draw_width");
      return isNaN(res) ? 0 : res;
   }

   JSROOT.TObjectPainter.prototype.pad_height = function(pad_name) {
      var res = this.svg_pad(pad_name).property("draw_height");
      return isNaN(res) ? 0 : res;
   }

   JSROOT.TObjectPainter.prototype.frame_x = function() {
      var res = parseInt(this.svg_frame().attr("x"));
      return isNaN(res) ? 0 : res;
   }

   JSROOT.TObjectPainter.prototype.frame_y = function() {
      var res = parseInt(this.svg_frame().attr("y"));
      return isNaN(res) ? 0 : res;
   }

   JSROOT.TObjectPainter.prototype.frame_width = function() {
      var res = parseInt(this.svg_frame().attr("width"));
      return isNaN(res) ? 0 : res;
   }

   JSROOT.TObjectPainter.prototype.frame_height = function() {
      var res = parseInt(this.svg_frame().attr("height"));
      return isNaN(res) ? 0 : res;
   }

   JSROOT.TObjectPainter.prototype.embed_3d = function() {
      // returns embed mode for 3D drawings (three.js) inside SVG
      // 0 - no embedding, 3D drawing take full size of canvas
      // 1 - no embedding, canvas placed over svg with proper size (resize problem may appear)
      // 2 - normall embedding via ForeginObject, works only with Firefox
      // 3 - embedding 3D drawing as SVG canvas, requires SVG renderer

      if (JSROOT.BatchMode) return 3;
      if (JSROOT.gStyle.Embed3DinSVG < 2) return JSROOT.gStyle.Embed3DinSVG;
      if (JSROOT.browser.isFirefox /*|| JSROOT.browser.isWebKit*/)
         return JSROOT.gStyle.Embed3DinSVG; // use specified mode
      return 1; // default is overlay
   }

   JSROOT.TObjectPainter.prototype.access_3d_kind = function(new_value) {

      var svg = this.svg_pad(this.this_pad_name);
      if (svg.empty()) return -1;

      // returns kind of currently created 3d canvas
      var kind = svg.property('can3d');
      if (new_value !== undefined) svg.property('can3d', new_value);
      return ((kind===null) || (kind===undefined)) ? -1 : kind;
   }

   JSROOT.TObjectPainter.prototype.size_for_3d = function(can3d) {
      // one uses frame sizes for the 3D drawing - like TH2/TH3 objects

      if (can3d === undefined) can3d = this.embed_3d();

      var pad = this.svg_pad(this.this_pad_name),
          clname = "draw3d_" + (this.this_pad_name || this.pad_name || 'canvas');

      if (pad.empty()) {
         // this is a case when object drawn without canvas

         var rect = this.get_visible_rect(this.select_main());

         if ((rect.height<10) && (rect.width>10)) {
            rect.height = Math.round(0.66*rect.width);
            this.select_main().style('height', rect.height + "px");
         }
         rect.x = 0; rect.y = 0; rect.clname = clname; rect.can3d = -1;
         return rect;
      }

      var elem = pad;
      if (can3d === 0) elem = this.svg_canvas();

      var size = { x: 0, y: 0, width: 100, height: 100, clname: clname, can3d: can3d };

      if (this.frame_painter()!==null) {
         elem = this.svg_frame();
         size.x = elem.property("draw_x");
         size.y = elem.property("draw_y");
      }

      size.width = elem.property("draw_width");
      size.height = elem.property("draw_height");

      if ((this.frame_painter()===null) && (can3d > 0)) {
         size.x = Math.round(size.x + size.width*JSROOT.gStyle.fPadLeftMargin);
         size.y = Math.round(size.y + size.height*JSROOT.gStyle.fPadTopMargin);
         size.width = Math.round(size.width*(1 - JSROOT.gStyle.fPadLeftMargin - JSROOT.gStyle.fPadRightMargin));
         size.height = Math.round(size.height*(1- JSROOT.gStyle.fPadTopMargin - JSROOT.gStyle.fPadBottomMargin));
      }

      var pw = this.pad_width(this.this_pad_name), x2 = pw - size.x - size.width,
          ph = this.pad_height(this.this_pad_name), y2 = ph - size.y - size.height;

      if ((x2 >= 0) && (y2 >= 0)) {
         // while 3D canvas uses area also for the axis labels, extend area relative to normal frame
         size.x = Math.round(size.x * 0.3);
         size.y = Math.round(size.y * 0.9);
         size.width = pw - size.x - Math.round(x2*0.3);
         size.height = ph - size.y - Math.round(y2*0.5);
      }

      if (can3d === 1)
         this.CalcAbsolutePosition(this.svg_pad(this.this_pad_name), size);

      return size;
   }

   JSROOT.TObjectPainter.prototype.clear_3d_canvas = function() {
      var can3d = this.access_3d_kind(null);
      if (can3d < 0) return;

      var size = this.size_for_3d(can3d);

      if (size.can3d === 0) {
         d3.select(this.svg_canvas().node().nextSibling).remove(); // remove html5 canvas
         this.svg_canvas().style('display', null); // show SVG canvas
      } else {
         if (this.svg_pad(this.this_pad_name).empty()) return;

         this.apply_3d_size(size).remove();

         this.svg_frame().style('display', null);  // clear display property
      }
   }

   JSROOT.TObjectPainter.prototype.add_3d_canvas = function(size, canv) {

      if (!canv || (size.can3d < -1)) return;

      if (size.can3d === -1) {
         // case when 3D object drawn without canvas

         var main = this.select_main().node();
         if (main !== null) {
            main.appendChild(canv);
            canv.painter = this;
         }

         return;
      }

      this.access_3d_kind(size.can3d);

      if (size.can3d === 0) {
         this.svg_canvas().style('display', 'none'); // hide SVG canvas

         this.svg_canvas().node().parentNode.appendChild(canv); // add directly
      } else {
         if (this.svg_pad(this.this_pad_name).empty()) return;

         // first hide normal frame
         this.svg_frame().style('display', 'none');

         var elem = this.apply_3d_size(size);

         elem.attr('title','').node().appendChild(canv);
      }
   }

   JSROOT.TObjectPainter.prototype.apply_3d_size = function(size, onlyget) {

      if (size.can3d < 0) return d3.select(null);

      var elem;

      if (size.can3d > 1) {

         var layer = this.svg_layer("special_layer");

         elem = layer.select("." + size.clname);
         if (onlyget) return elem;

         if (size.can3d === 3) {
            // this is SVG mode

            if (elem.empty())
               elem = layer.append("g").attr("class", size.clname);

            elem.attr("transform", "translate(" + size.x + "," + size.y + ")");

         } else {

            if (elem.empty())
               elem = layer.append("foreignObject").attr("class", size.clname);

            elem.attr('x', size.x)
                .attr('y', size.y)
                .attr('width', size.width)
                .attr('height', size.height)
                .attr('viewBox', "0 0 " + size.width + " " + size.height)
                .attr('preserveAspectRatio','xMidYMid');
         }

      } else {
         var prnt = this.svg_canvas().node().parentNode;

         elem = d3.select(prnt).select("." + size.clname);
         if (onlyget) return elem;

         // force redraw by resize
         this.svg_canvas().property('redraw_by_resize', true);

         if (elem.empty())
            elem = d3.select(prnt).append('div').attr("class", size.clname + " jsroot_noselect");

         // our position inside canvas, but to set 'absolute' position we should use
         // canvas element offset relative to first parent with non-static position
         // now try to use getBoundingClientRect - it should be more precise

         var pos0 = prnt.getBoundingClientRect();

         while (prnt) {
            if (prnt === document) { prnt = null; break; }
            try {
               if (getComputedStyle(prnt).position !== 'static') break;
            } catch(err) {
               break;
            }
            prnt = prnt.parentNode;
         }

         var pos1 = prnt ? prnt.getBoundingClientRect() : { top: 0, left: 0 };

         var offx = Math.round(pos0.left - pos1.left),
             offy = Math.round(pos0.top - pos1.top);

         elem.style('position','absolute').style('left',(size.x+offx)+'px').style('top',(size.y+offy)+'px').style('width',size.width+'px').style('height',size.height+'px');
      }

      return elem;
   }


   /** Returns main pad painter - normally TH1/TH2 painter, which draws all axis */
   JSROOT.TObjectPainter.prototype.main_painter = function(not_store, pad_name) {
      var res = this.main;
      if (!res) {
         var svg_p = this.svg_pad(pad_name);
         if (svg_p.empty()) {
            res = this.AccessTopPainter();
         } else {
            res = svg_p.property('mainpainter');
         }
         if (!res) res = null;
         if (!not_store) this.main = res;
      }
      return res;
   }

   JSROOT.TObjectPainter.prototype.is_main_painter = function() {
      return this === this.main_painter();
   }

   JSROOT.TObjectPainter.prototype.SetDivId = function(divid, is_main, pad_name) {
      // Assigns id of top element (normally <div></div> where drawing is done
      // is_main - -1 - not add to painters list,
      //            0 - normal painter (default),
      //            1 - major objects like TH1/TH2 (required canvas with frame)
      //            2 - if canvas missing, create it, but not set as main object
      //            3 - if canvas and (or) frame missing, create them, but not set as main object
      //            4 - major objects like TH3 (required canvas, but no frame)
      //            5 - major objects like TGeoVolume (do not require canvas)
      // pad_name - when specified, subpad name used for object drawin
      // In some situations canvas may not exists - for instance object drawn as html, not as svg.
      // In such case the only painter will be assigned to the first element

      if (divid !== undefined)
         this.divid = divid;

      if (!is_main) is_main = 0;

      this.create_canvas = false;

      // SVG element where canvas is drawn
      var svg_c = this.svg_canvas();

      if (svg_c.empty() && (is_main > 0) && (is_main!==5)) {
         JSROOT.Painter.drawCanvas(divid, null, ((is_main == 2) || (is_main == 4)) ? "noframe" : "");
         svg_c = this.svg_canvas();
         this.create_canvas = true;
      }

      if (svg_c.empty()) {
         if ((is_main < 0) || (is_main===5) || this.iscan) return;
         this.AccessTopPainter(true);
         return;
      }

      // SVG element where current pad is drawn (can be canvas itself)
      this.pad_name = pad_name;
      if (this.pad_name === undefined)
         this.pad_name = this.CurrentPadName();

      if (is_main < 0) return;

      // create TFrame element if not exists
      if (this.svg_frame().select(".main_layer").empty() && ((is_main == 1) || (is_main == 3))) {
         JSROOT.Painter.drawFrame(divid, null);
         if (this.svg_frame().empty()) return alert("Fail to draw dummy TFrame");
      }

      var svg_p = this.svg_pad();
      if (svg_p.empty()) return;

      if (svg_p.property('pad_painter') !== this)
         svg_p.property('pad_painter').painters.push(this);

      if (((is_main === 1) || (is_main === 4) || (is_main === 5)) && !svg_p.property('mainpainter'))
         // when this is first main painter in the pad
         svg_p.property('mainpainter', this);
   }

   JSROOT.TObjectPainter.prototype.CalcAbsolutePosition = function(sel, pos) {
      while (!sel.empty() && !sel.classed('root_canvas')) {
         if (sel.classed('root_frame') || sel.classed('root_pad')) {
           pos.x += sel.property("draw_x");
           pos.y += sel.property("draw_y");
         }
         sel = d3.select(sel.node().parentNode);
      }
      return pos;
   }


   JSROOT.TObjectPainter.prototype.createAttFill = function(attfill, pattern, color, kind) {

      // fill kind can be 1 or 2
      // 1 means object drawing where combination fillcolor==0 and fillstyle==1001 means no filling
      // 2 means all other objects where such combination is white-color filling

      var fill = { color: "none", colorindx: 0, pattern: 0, used: true, kind: 2, changed: false };

      if (kind!==undefined) fill.kind = kind;

      fill.Apply = function(selection) {
         this.used = true;

         selection.style('fill', this.color);

         if ('opacity' in this)
            selection.style('opacity', this.opacity);

         if ('antialias' in this)
            selection.style('antialias', this.antialias);
      }
      fill.func = fill.Apply.bind(fill);

      fill.empty = function() {
         // return true if color not specified or fill style not specified
         return (this.color == 'none');
      };

      fill.Change = function(color, pattern, svg) {
         this.changed = true;

         if ((color !== undefined) && !isNaN(color))
            this.colorindx = color;

         if ((pattern !== undefined) && !isNaN(pattern)) {
            this.pattern = pattern;
            delete this.opacity;
            delete this.antialias;
         }

         if (this.pattern < 1001) {
            this.color = 'none';
            return true;
         }

         if ((this.pattern === 1001) && (this.colorindx===0) && (this.kind===1)) {
            this.color = 'none';
            return true;
         }

         this.color = JSROOT.Painter.root_colors[this.colorindx];
         if (typeof this.color != 'string') this.color = "none";

         if (this.pattern === 1001) return true;

         if ((this.pattern >= 4000) && (this.pattern <= 4100)) {
            // special transparent colors (use for subpads)
            this.opacity = (this.pattern - 4000)/100;
            return true;
         }

         if ((svg===undefined) || svg.empty() || (this.pattern < 3000) || (this.pattern > 3025)) return false;

         var id = "pat_" + this.pattern + "_" + this.colorindx;

         var defs = svg.select('.canvas_defs');
         if (defs.empty())
            defs = svg.insert("svg:defs",":first-child").attr("class","canvas_defs");

         var line_color = this.color;
         this.color = "url(#" + id + ")";
         this.antialias = false;

         if (!defs.select("."+id).empty()) return true;

         var patt = defs.append('svg:pattern').attr("id", id).attr("class",id).attr("patternUnits","userSpaceOnUse");

         switch (this.pattern) {
           case 3001:
             patt.attr("width", 2).attr("height", 2);
             patt.append('svg:rect').attr("x", 0).attr("y", 0).attr("width", 1).attr("height", 1);
             patt.append('svg:rect').attr("x", 1).attr("y", 1).attr("width", 1).attr("height", 1);
             break;
           case 3002:
             patt.attr("width", 4).attr("height", 2);
             patt.append('svg:rect').attr("x", 1).attr("y", 0).attr("width", 1).attr("height", 1);
             patt.append('svg:rect').attr("x", 3).attr("y", 1).attr("width", 1).attr("height", 1);
             break;
           case 3003:
             patt.attr("width", 4).attr("height", 4);
             patt.append('svg:rect').attr("x", 2).attr("y", 1).attr("width", 1).attr("height", 1);
             patt.append('svg:rect').attr("x", 0).attr("y", 3).attr("width", 1).attr("height", 1);
             break;
           case 3005:
             patt.attr("width", 8).attr("height", 8);
             patt.append("svg:line").attr("x1", 0).attr("y1", 0).attr("x2", 8).attr("y2", 8);
             break;
           case 3006:
             patt.attr("width", 4).attr("height", 4);
             patt.append("svg:line").attr("x1", 1).attr("y1", 0).attr("x2", 1).attr("y2", 3);
             break;
           case 3007:
             patt.attr("width", 4).attr("height", 4);
             patt.append("svg:line").attr("x1", 0).attr("y1", 1).attr("x2", 3).attr("y2", 1);
             break;
           case 3010: // bricks
             patt.attr("width", 10).attr("height", 10);
             patt.append("svg:line").attr("x1", 0).attr("y1", 2).attr("x2", 10).attr("y2", 2);
             patt.append("svg:line").attr("x1", 0).attr("y1", 7).attr("x2", 10).attr("y2", 7);
             patt.append("svg:line").attr("x1", 2).attr("y1", 0).attr("x2", 2).attr("y2", 2);
             patt.append("svg:line").attr("x1", 7).attr("y1", 2).attr("x2", 7).attr("y2", 7);
             patt.append("svg:line").attr("x1", 2).attr("y1", 7).attr("x2", 2).attr("y2", 10);
             break;
           case 3021: // stairs
           case 3022:
             patt.attr("width", 10).attr("height", 10);
             patt.append("svg:line").attr("x1", 0).attr("y1", 5).attr("x2", 5).attr("y2", 5);
             patt.append("svg:line").attr("x1", 5).attr("y1", 5).attr("x2", 5).attr("y2", 0);
             patt.append("svg:line").attr("x1", 5).attr("y1", 10).attr("x2", 10).attr("y2", 10);
             patt.append("svg:line").attr("x1", 10).attr("y1", 10).attr("x2", 10).attr("y2", 5);
             break;
           default: /* == 3004 */
             patt.attr("width", 8).attr("height", 8);
             patt.append("svg:line").attr("x1", 8).attr("y1", 0).attr("x2", 0).attr("y2", 8);
             break;
         }

         patt.selectAll('line').style('stroke',line_color).style("stroke-width",1);
         patt.selectAll('rect').style("fill",line_color);

         return true;
      }

      if ((attfill!==null) && (typeof attfill == 'object')) {
         if ('fFillStyle' in attfill) pattern = attfill.fFillStyle;
         if ('fFillColor' in attfill) color = attfill.fFillColor;
      }

      fill.Change(color, pattern, this.svg_canvas());

      fill.changed = false;

      return fill;
   }

   JSROOT.TObjectPainter.prototype.ForEachPainter = function(userfunc) {
      // Iterate over all known painters

      // special case of the painter set as pointer of first child of main element
      var painter = this.AccessTopPainter();
      if (painter) return userfunc(painter);

      // iterate over all painters from pad list
      var pad_painter = this.pad_painter(true);
      if (pad_painter)
         pad_painter.ForEachPainterInPad(userfunc);
   }

   JSROOT.TObjectPainter.prototype.RedrawPad = function() {
      // call Redraw methods for each painter in the frame
      // if selobj specified, painter with selected object will be redrawn
      var pad_painter = this.pad_painter(true);
      if (pad_painter) pad_painter.Redraw();
   }

   JSROOT.TObjectPainter.prototype.SwitchTooltip = function(on) {
      var fp = this.frame_painter();
      if (fp) fp.ProcessTooltipEvent(null, on);
      // this is 3D control object
      if (this.control && (typeof this.control.SwitchTooltip == 'function'))
         this.control.SwitchTooltip(on);
   }

   JSROOT.TObjectPainter.prototype.AddDrag = function(callback) {
      if (!JSROOT.gStyle.MoveResize) return;

      var pthis = this;

      var rect_width = function() { return Number(pthis.draw_g.attr("width")); };
      var rect_height = function() { return Number(pthis.draw_g.attr("height")); };

      var acc_x = 0, acc_y = 0, pad_w = 1, pad_h = 1, drag_tm = null;

      function detectRightButton(event) {
         if ('buttons' in event) return event.buttons === 2;
         else if ('which' in event) return event.which === 3;
         else if ('button' in event) return event.button === 2;
         return false;
      }

      var resize_corner1 = this.draw_g.select('.resize_corner1');
      if (resize_corner1.empty())
         resize_corner1 = this.draw_g
                              .append("path")
                              .attr('class','resize_corner1')
                              .attr("d","M2,2 h15 v-5 h-20 v20 h5 Z");

      var resize_corner2 = this.draw_g.select('.resize_corner2');
      if (resize_corner2.empty())
         resize_corner2 = this.draw_g
                              .append("path")
                              .attr('class','resize_corner2')
                              .attr("d","M-2,-2 h-15 v5 h20 v-20 h-5 Z");

      resize_corner1.style('opacity',0).style('cursor',"nw-resize");

      resize_corner2.style('opacity',0).style('cursor',"se-resize")
                    .attr("transform", "translate(" + rect_width() + "," + rect_height() + ")");

      var drag_rect = null;

      function complete_drag() {
         drag_rect.style("cursor", "auto");

         var oldx = Number(pthis.draw_g.attr("x")),
             oldy = Number(pthis.draw_g.attr("y")),
             newx = Number(drag_rect.attr("x")),
             newy = Number(drag_rect.attr("y")),
             newwidth = Number(drag_rect.attr("width")),
             newheight = Number(drag_rect.attr("height"));

         if (callback.minwidth && newwidth < callback.minwidth) newwidth = callback.minwidth;
         if (callback.minheight && newheight < callback.minheight) newheight = callback.minheight;

         var change_size = (newwidth !== rect_width()) || (newheight !== rect_height()),
             change_pos = (newx !== oldx) || (newy !== oldy);

         pthis.draw_g.attr('x', newx).attr('y', newy)
                     .attr("transform", "translate(" + newx + "," + newy + ")")
                     .attr('width', newwidth).attr('height', newheight);

         drag_rect.remove();
         drag_rect = null;

         pthis.SwitchTooltip(true);

         resize_corner2.attr("transform", "translate(" + newwidth + "," + newheight + ")");

         if (change_size || change_pos) {
            if (change_size && ('resize' in callback)) callback.resize(newwidth, newheight);
            if (change_pos && ('move' in callback)) callback.move(newx, newy, newx - oldxx, newy-oldy);

            if (change_size || change_pos) {
               if ('obj' in callback) {
                  callback.obj.fX1NDC = newx / pthis.pad_width();
                  callback.obj.fX2NDC = (newx + newwidth)  / pthis.pad_width();
                  callback.obj.fY1NDC = 1 - (newy + newheight) / pthis.pad_height();
                  callback.obj.fY2NDC = 1 - newy / pthis.pad_height();
                  callback.obj.modified_NDC = true; // indicate that NDC was interactively changed, block in updated
               }
               if ('redraw' in callback) callback.redraw();
            }
         }

         return change_size || change_pos;
      }

      var prefix = "", drag_move, drag_resize;
      if (JSROOT._test_d3_ === 3) {
         prefix = "drag";
         drag_move = d3.behavior.drag().origin(Object);
         drag_resize = d3.behavior.drag().origin(Object);
      } else {
         drag_move = d3.drag().subject(Object);
         drag_resize = d3.drag().subject(Object);
      }

      drag_move
         .on(prefix+"start",  function() {
            if (detectRightButton(d3.event.sourceEvent)) return;

            JSROOT.Painter.closeMenu(); // close menu

            pthis.SwitchTooltip(false); // disable tooltip

            d3.event.sourceEvent.preventDefault();
            d3.event.sourceEvent.stopPropagation();

            acc_x = 0; acc_y = 0;
            pad_w = pthis.pad_width() - rect_width();
            pad_h = pthis.pad_height() - rect_height();

            drag_tm = new Date();

            drag_rect = d3.select(pthis.draw_g.node().parentNode).append("rect")
                 .classed("zoom", true)
                 .attr("x",  pthis.draw_g.attr("x"))
                 .attr("y", pthis.draw_g.attr("y"))
                 .attr("width", rect_width())
                 .attr("height", rect_height())
                 .style("cursor", "move")
                 .style("pointer-events","none"); // let forward double click to underlying elements
          }).on("drag", function() {
               if (drag_rect == null) return;

               d3.event.sourceEvent.preventDefault();

               var x = Number(drag_rect.attr("x")), y = Number(drag_rect.attr("y"));
               var dx = d3.event.dx, dy = d3.event.dy;

               if ((acc_x<0) && (dx>0)) { acc_x+=dx; dx=0; if (acc_x>0) { dx=acc_x; acc_x=0; }}
               if ((acc_x>0) && (dx<0)) { acc_x+=dx; dx=0; if (acc_x<0) { dx=acc_x; acc_x=0; }}
               if ((acc_y<0) && (dy>0)) { acc_y+=dy; dy=0; if (acc_y>0) { dy=acc_y; acc_y=0; }}
               if ((acc_y>0) && (dy<0)) { acc_y+=dy; dy=0; if (acc_y<0) { dy=acc_y; acc_y=0; }}

               if (x+dx<0) { acc_x+=(x+dx); x=0; } else
               if (x+dx>pad_w) { acc_x+=(x+dx-pad_w); x=pad_w; } else x+=dx;

               if (y+dy<0) { acc_y+=(y+dy); y = 0; } else
               if (y+dy>pad_h) { acc_y+=(y+dy-pad_h); y=pad_h; } else y+=dy;

               drag_rect.attr("x", x).attr("y", y);

               d3.event.sourceEvent.stopPropagation();
          }).on(prefix+"end", function() {
               if (drag_rect==null) return;

               d3.event.sourceEvent.preventDefault();

               if (complete_drag() === false)
                  if(callback['ctxmenu'] && ((new Date()).getTime() - drag_tm.getTime() > 600)) {
                     var rrr = resize_corner2.node().getBoundingClientRect();
                     pthis.ShowContextMenu('main', { clientX: rrr.left, clientY: rrr.top } );
                  }
            });

      drag_resize
        .on(prefix+"start", function() {
           if (detectRightButton(d3.event.sourceEvent)) return;

           d3.event.sourceEvent.stopPropagation();
           d3.event.sourceEvent.preventDefault();

           pthis.SwitchTooltip(false); // disable tooltip

           acc_x = 0; acc_y = 0;
           pad_w = pthis.pad_width();
           pad_h = pthis.pad_height();
           drag_rect = d3.select(pthis.draw_g.node().parentNode).append("rect")
                        .classed("zoom", true)
                        .attr("x", pthis.draw_g.attr("x"))
                        .attr("y", pthis.draw_g.attr("y"))
                        .attr("width", rect_width())
                        .attr("height", rect_height())
                        .style("cursor", d3.select(this).style("cursor"));
         }).on("drag", function() {
            if (drag_rect == null) return;

            d3.event.sourceEvent.preventDefault();

            var w = Number(drag_rect.attr("width")), h = Number(drag_rect.attr("height")),
                x = Number(drag_rect.attr("x")), y = Number(drag_rect.attr("y"));
            var dx = d3.event.dx, dy = d3.event.dy;
            if ((acc_x<0) && (dx>0)) { acc_x+=dx; dx=0; if (acc_x>0) { dx=acc_x; acc_x=0; }}
            if ((acc_x>0) && (dx<0)) { acc_x+=dx; dx=0; if (acc_x<0) { dx=acc_x; acc_x=0; }}
            if ((acc_y<0) && (dy>0)) { acc_y+=dy; dy=0; if (acc_y>0) { dy=acc_y; acc_y=0; }}
            if ((acc_y>0) && (dy<0)) { acc_y+=dy; dy=0; if (acc_y<0) { dy=acc_y; acc_y=0; }}

            if (d3.select(this).classed('resize_corner1')) {
               if (x+dx < 0) { acc_x += (x+dx); w += x; x = 0; } else
               if (w-dx < 0) { acc_x -= (w-dx); x += w; w = 0; } else { x+=dx; w-=dx; }
               if (y+dy < 0) { acc_y += (y+dy); h += y; y = 0; } else
               if (h-dy < 0) { acc_y -= (h-dy); y += h; h = 0; } else { y+=dy; h-=dy; }
            } else {
               if (x+w+dx > pad_w) { acc_x += (x+w+dx-pad_w); w = pad_w-x; } else
               if (w+dx < 0) { acc_x += (w+dx); w = 0; } else w += dx;
               if (y+h+dy > pad_h) { acc_y += (y+h+dy-pad_h); h = pad_h-y; } else
               if (h+dy < 0) { acc_y += (h+dy); h=0; } else h += dy;
            }

            drag_rect.attr("x", x).attr("y", y).attr("width", w).attr("height", h);

            d3.event.sourceEvent.stopPropagation();
         }).on(prefix+"end", function() {
            if (drag_rect == null) return;

            d3.event.sourceEvent.preventDefault();

            complete_drag();
         });

      if (!callback.only_resize)
         this.draw_g.style("cursor", "move").call(drag_move);

      resize_corner1.call(drag_resize);
      resize_corner2.call(drag_resize);
   }

   JSROOT.TObjectPainter.prototype.startTouchMenu = function(kind) {
      // method to let activate context menu via touch handler

      var arr = d3.touches(this.svg_frame().node());
      if (arr.length != 1) return;

      if (!kind || (kind=="")) kind = "main";
      var fld = "touch_" + kind;

      d3.event.preventDefault();
      d3.event.stopPropagation();

      this[fld] = { dt: new Date(), pos: arr[0] };

      this.svg_frame().on("touchcancel", this.endTouchMenu.bind(this, kind))
                      .on("touchend", this.endTouchMenu.bind(this, kind));
   }

   JSROOT.TObjectPainter.prototype.endTouchMenu = function(kind) {
      var fld = "touch_" + kind;

      if (! (fld in this)) return;

      d3.event.preventDefault();
      d3.event.stopPropagation();

      var diff = new Date().getTime() - this[fld].dt.getTime();

      this.svg_frame().on("touchcancel", null)
                      .on("touchend", null);

      if (diff>500) {
         var rect = this.svg_frame().node().getBoundingClientRect();
         this.ShowContextMenu(kind, { clientX: rect.left + this[fld].pos[0],
                                      clientY: rect.top + this[fld].pos[1] } );
      }

      delete this[fld];
   }

   JSROOT.TObjectPainter.prototype.AddColorMenuEntry = function(menu, name, value, set_func, fill_kind) {
      if (value === undefined) return;
      menu.add("sub:"+name, function() {
         // todo - use jqury dialog here
         var useid = (typeof value !== 'string');
         var col = prompt("Enter color " + (useid ? "(only id number)" : "(name or id)"), value);
         if (col == null) return;
         var id = parseInt(col);
         if (!isNaN(id) && (JSROOT.Painter.root_colors[id] !== undefined)) {
            col = JSROOT.Painter.root_colors[id];
         } else {
            if (useid) return;
         }
         set_func.bind(this)(useid ? id : col);
      });
      var useid = (typeof value !== 'string');
      for (var n=-1;n<11;++n) {
         if ((n<0) && useid) continue;
         if ((n==10) && (fill_kind!==1)) continue;
         var col = (n<0) ? 'none' : JSROOT.Painter.root_colors[n];
         if ((n==0) && (fill_kind==1)) col = 'none';
         var svg = "<svg width='100' height='18' style='margin:0px;background-color:" + col + "'><text x='4' y='12' style='font-size:12px' fill='" + (n==1 ? "white" : "black") + "'>"+col+"</text></svg>";
         menu.addchk((value == (useid ? n : col)), svg, (useid ? n : col), set_func);
      }
      menu.add("endsub:");
   }

   JSROOT.TObjectPainter.prototype.AddSizeMenuEntry = function(menu, name, min, max, step, value, set_func) {
      if (value === undefined) return;

      menu.add("sub:"+name, function() {
         // todo - use jqury dialog here
         var entry = value.toFixed(4);
         if (step>=0.1) entry = value.toFixed(2);
         if (step>=1) entry = value.toFixed(0);
         var val = prompt("Enter value of " + name, entry);
         if (val==null) return;
         var val = parseFloat(val);
         if (!isNaN(val)) set_func.bind(this)((step>=1) ? Math.round(val) : val);
      });
      for (var val=min;val<=max;val+=step) {
         var entry = val.toFixed(2);
         if (step>=0.1) entry = val.toFixed(1);
         if (step>=1) entry = val.toFixed(0);
         menu.addchk((Math.abs(value - val) < step/2), entry, val, set_func);
      }
      menu.add("endsub:");
   }


   JSROOT.LongPollSocket = function(addr) {

      this.path = addr;
      this.connid = null;
      this.req = null;

      this.nextrequest = function(data, kind) {
         var url = this.path;
         if (kind === "connect") {
            url+="?connect";
            this.connid = "connect";
         } else
         if (kind === "close") {
            if ((this.connid===null) || (this.connid==="close")) return;
            url+="?connection="+this.connid + "&close";
            this.connid = "close";
         } else
         if ((this.connid===null) || (typeof this.connid!=='number')) {
            return console.error("No connection");
         } else {
            url+="?connection="+this.connid;
            if (kind==="dummy") url+="&dummy";
         }

         if (data) {
            // special workaround to avoid POST request, which is not supported in WebEngine
            var post = "&post=";
            for (var k=0;k<data.length;++k) post+=data.charCodeAt(k).toString(16);
            url += post;
         }

         var req = JSROOT.NewHttpRequest(url, "text", function(res) {
            if (res===null) res = this.response; // workaround for WebEngine - it does not handle content correctly
            if (this.handle.req === this) {
               this.handle.req = null; // get response for existing dummy request
               if (res == "<<nope>>") res = "";
            }
            this.handle.processreq(res);
         });

         req.handle = this;
         if (kind==="dummy") this.req = req; // remember last dummy request, wait for reply
         req.send();
      }

      this.processreq = function(res) {

         if (res===null) {
            if (typeof this.onerror === 'function') this.onerror("receive data with connid " + (this.connid || "---"));
            // if (typeof this.onclose === 'function') this.onclose();
            this.connid = null;
            return;
         }

         if (this.connid==="connect") {
            this.connid = parseInt(res);
            console.log('Get new longpoll connection with id ' + this.connid);
            if (typeof this.onopen == 'function') this.onopen();
         } else
         if (this.connid==="close") {
            if (typeof this.onclose == 'function') this.onclose();
            return;
         } else {
            if ((typeof this.onmessage==='function') && res)
               this.onmessage({ data: res });
         }
         if (!this.req) this.nextrequest("","dummy"); // send new poll request when necessary
      }

      this.send = function(str) { this.nextrequest(str); }

      this.close = function() { this.nextrequest("", "close"); }

      this.nextrequest("","connect");

      return this;
   }


   JSROOT.TObjectPainter.prototype.OpenWebsocket = function(use_longpoll) {
      // create websocket for current object (canvas)
      // via websocket one recieved many extra information

      delete this._websocket;

      var path = window.location.href, conn = null;

      if (!use_longpoll) {
         path = path.replace("http://", "ws://");
         path = path.replace("https://", "wss://");
         var pos = path.indexOf("draw.htm");
         if (pos < 0) return;
         path = path.substr(0,pos) + "root.websocket";
         console.log('open websocket ' + path);
         conn = new WebSocket(path);
      } else {
         var pos = path.indexOf("draw.htm");
         if (pos < 0) return;
         path = path.substr(0,pos) + "root.longpoll";
         console.log('open longpoll ' + path);
         conn = JSROOT.LongPollSocket(path);
      }

      this._websocket = conn;

      var pthis = this, sum1 = 0, sum2 = 0, cnt = 0;

      conn.onopen = function() {
         console.log('websocket initialized');
         conn.send('READY'); // indicate that we are ready to recieve JSON code (or any other big peace)
      }

      conn.onmessage = function (e) {
         var d = e.data;
         if (typeof d != 'string') return console.log("msg",d);

         if (d.substr(0,4)=='SNAP') {
            var snap = JSROOT.parse(d.substr(4));

            if (typeof pthis.RedrawSnap === 'function') {
               pthis.RedrawSnap(snap, function() {
                  conn.send('READY'); // send ready message back
               });
            } else {
               conn.send('READY'); // send ready message back
            }

         } else
         if (d.substr(0,4)=='JSON') {
            var obj = JSROOT.parse(d.substr(4));
            // console.log("get JSON ", d.length-4, obj._typename);
            var tm1 = new Date().getTime();
            pthis.RedrawObject(obj);
            var tm2 = new Date().getTime();
            sum1+=1;
            sum2+=(tm2-tm1);
            if (sum1>10) { console.log('Redraw ', Math.round(sum2/sum1)); sum1=sum2=0; }

            conn.send('READY'); // send ready message back
            // if (++cnt > 10) conn.close();

         } else
         if (d.substr(0,4)=='MENU') {
            var lst = JSROOT.parse(d.substr(4));
            console.log("get MENUS ", typeof lst, 'nitems', lst.length, d.length-4);
            conn.send('READY'); // send ready message back
            if (typeof pthis._getmenu_callback == 'function')
               pthis._getmenu_callback(lst);
         } else
         if (d.substr(0,7)=='GETIMG:') {

            console.log('d',d);

            d = d.substr(7);
            var p = d.indexOf(":"),
                id = d.substr(0,p),
                fname = d.substr(p+1);
            conn.send('READY'); // send ready message back

            console.log('GET REQUEST FOR FILE', fname, id);

            var painter = pthis.FindSnap(id);
            if (painter)
               painter.SaveAsPng(painter.iscan, "image.svg", function(res) {
                  console.log('SVG IMAGE CREATED', res ? res.length : "");
                  if (res) conn.send("GETIMG:" + fname + ":" + res);
               });

         } else {
            if (d) console.log("urecognized msg",d);
         }
      }

      conn.onclose = function() {
         console.log('websocket closed');
         delete pthis._websocket;
         window.close(); // close window when socked disapper
      }

      conn.onerror = function (err) {
         console.log("err "+err);
         // conn.close();
      }
   }


   JSROOT.TObjectPainter.prototype.FillObjectExecMenu = function(menu, call_back) {

      var canvp = this.pad_painter();

      if (!this.snapid || !canvp || !canvp._websocket || canvp._getmenu_callback)
         return JSROOT.CallBack(call_back);

      function DoExecMenu(arg) {
         console.log('execute method ' + arg + ' for object ' + this.snapid);

         var canvp = this.pad_painter();

         if (canvp && canvp._websocket && this.snapid)
            canvp._websocket.send('OBJEXEC:' + this.snapid + ":" + arg);
      }

      function DoFillMenu(_menu, _call_back, items) {

         // avoid multiple call of the callback after timeout
         if (!canvp._getmenu_callback) return;
         delete canvp._getmenu_callback;

         if (items && items.length) {
            _menu.add("separator");
            _menu.add("sub:Online");

            for (var n=0;n<items.length;++n) {
               var item = items[n];
               if ('chk' in item)
                  _menu.addchk(item.chk, item.name, item.exec, DoExecMenu);
               else
                  _menu.add(item.name, item.exec, DoExecMenu);
            }

            _menu.add("endsub:");
         }

         JSROOT.CallBack(_call_back);
      }


      canvp._getmenu_callback = DoFillMenu.bind(this, menu, call_back);

      canvp._websocket.send('GETMENU:' + this.snapid); // request menu items for given painter

      setTimeout(canvp._getmenu_callback, 2000); // set timeout to avoid menu hanging
   }

   JSROOT.TObjectPainter.prototype.DeleteAtt = function() {
      // remove all created draw attributes
      delete this.lineatt;
      delete this.fillatt;
      delete this.markeratt;
   }

   JSROOT.TObjectPainter.prototype.FillAttContextMenu = function(menu, preffix) {
      // this method used to fill entries for different attributes of the object
      // like TAttFill, TAttLine, ....
      // all menu call-backs need to be rebind, while menu can be used from other painter

      if (!preffix) preffix = "";

      if (this.lineatt && this.lineatt.used) {
         menu.add("sub:"+preffix+"Line att");
         this.AddSizeMenuEntry(menu, "width", 1, 10, 1, this.lineatt.width,
                               function(arg) { this.lineatt.Change(undefined, parseInt(arg)); this.Redraw(); }.bind(this));
         this.AddColorMenuEntry(menu, "color", this.lineatt.color,
                          function(arg) { this.lineatt.Change(arg); this.Redraw(); }.bind(this));
         menu.add("sub:style", function() {
            var id = prompt("Enter line style id (1-solid)", 1);
            if (id == null) return;
            id = parseInt(id);
            if (isNaN(id) || (JSROOT.Painter.root_line_styles[id] === undefined)) return;
            this.lineatt.Change(undefined, undefined, JSROOT.Painter.root_line_styles[id]);
            this.Redraw();
         }.bind(this));
         for (var n=1;n<11;++n) {
            var style = JSROOT.Painter.root_line_styles[n];

            var svg = "<svg width='100' height='18'><text x='1' y='12' style='font-size:12px'>" + n + "</text><line x1='30' y1='8' x2='100' y2='8' stroke='black' stroke-width='3' stroke-dasharray='" + style + "'></line></svg>";

            menu.addchk((this.lineatt.dash==style), svg, style, function(arg) { this.lineatt.Change(undefined, undefined, arg); this.Redraw(); }.bind(this));
         }
         menu.add("endsub:");
         menu.add("endsub:");

         if (('excl_side' in this.lineatt) && (this.lineatt.excl_side!==0))  {
            menu.add("sub:Exclusion");
            menu.add("sub:side");
            for (var side=-1;side<=1;++side)
               menu.addchk((this.lineatt.excl_side==side), side, side, function(arg) {
                  this.lineatt.ChangeExcl(parseInt(arg));
                  this.Redraw();
               }.bind(this));
            menu.add("endsub:");

            this.AddSizeMenuEntry(menu, "width", 10, 100, 10, this.lineatt.excl_width,
                  function(arg) { this.lineatt.ChangeExcl(undefined, parseInt(arg)); this.Redraw(); }.bind(this));

            menu.add("endsub:");
         }
      }

      if (this.fillatt && this.fillatt.used) {
         menu.add("sub:"+preffix+"Fill att");
         this.AddColorMenuEntry(menu, "color", this.fillatt.colorindx,
               function(arg) { this.fillatt.Change(parseInt(arg), undefined, this.svg_canvas()); this.Redraw(); }.bind(this), this.fillatt.kind);
         menu.add("sub:style", function() {
            var id = prompt("Enter fill style id (1001-solid, 3000..3010)", this.fillatt.pattern);
            if (id == null) return;
            id = parseInt(id);
            if (isNaN(id)) return;
            this.fillatt.Change(undefined, id, this.svg_canvas());
            this.Redraw();
         }.bind(this));

         var supported = [1, 1001, 3001, 3002, 3003, 3004, 3005, 3006, 3007, 3010, 3021, 3022];

         var clone = JSROOT.clone(this.fillatt);
         if (clone.colorindx<=0) clone.colorindx = 1;

         for (var n=0; n<supported.length; ++n) {

            clone.Change(undefined, supported[n], this.svg_canvas());

            var svg = "<svg width='100' height='18'><text x='1' y='12' style='font-size:12px'>" + supported[n].toString() + "</text><rect x='40' y='0' width='60' height='18' stroke='none' fill='" + clone.color + "'></rect></svg>";

            menu.addchk(this.fillatt.pattern == supported[n], svg, supported[n], function(arg) {
               this.fillatt.Change(undefined, parseInt(arg), this.svg_canvas());
               this.Redraw();
            }.bind(this));
         }
         menu.add("endsub:");
         menu.add("endsub:");
      }

      if (this.markeratt && this.markeratt.used) {
         menu.add("sub:"+preffix+"Marker att");
         this.AddColorMenuEntry(menu, "color", this.markeratt.color,
                   function(arg) { this.markeratt.Change(arg); this.Redraw(); }.bind(this));
         this.AddSizeMenuEntry(menu, "size", 0.5, 6, 0.5, this.markeratt.size,
               function(arg) { this.markeratt.Change(undefined, undefined, parseFloat(arg)); this.Redraw(); }.bind(this));

         menu.add("sub:style");
         var supported = [1,2,3,4,5,6,7,8,21,22,23,24,25,26,27,28,29,30,31,32,33,34];

         var clone = JSROOT.clone(this.markeratt);
         for (var n=0; n<supported.length; ++n) {
            clone.Change(undefined, supported[n], 1.7);
            clone.reset_pos();
            var svg = "<svg width='60' height='18'><text x='1' y='12' style='font-size:12px'>" + supported[n].toString() + "</text><path stroke='black' fill='" + (clone.fill ? "black" : "none") + "' d='" + clone.create(40,8) + "'></path></svg>";

            menu.addchk(this.markeratt.style == supported[n], svg, supported[n],
                     function(arg) { this.markeratt.Change(undefined, parseInt(arg)); this.Redraw(); }.bind(this));
         }
         menu.add("endsub:");
         menu.add("endsub:");
      }
   }

   JSROOT.TObjectPainter.prototype.TextAttContextMenu = function(menu, prefix) {
      // for the moment, text attributes accessed directly from objects

      var obj = this.GetObject();
      if (!obj || !('fTextColor' in obj)) return;

      menu.add("sub:" + (prefix ? prefix : "Text"));
      this.AddColorMenuEntry(menu, "color", obj.fTextColor,
            function(arg) { this.GetObject().fTextColor = parseInt(arg); this.Redraw(); }.bind(this));

      var align = [11, 12, 13, 21, 22, 23, 31, 32, 33],
          hnames = ['left', 'centered' , 'right'],
          vnames = ['bottom', 'centered', 'top'];

      menu.add("sub:align");
      for (var n=0; n<align.length; ++n) {
         menu.addchk(align[n] == obj.fTextAlign,
                  align[n], align[n],
                  // align[n].toString() + "_h:" + hnames[Math.floor(align[n]/10) - 1] + "_v:" + vnames[align[n]%10-1], align[n],
                  function(arg) { this.GetObject().fTextAlign = parseInt(arg); this.Redraw(); }.bind(this));
      }
      menu.add("endsub:");

      menu.add("sub:font");
      for (var n=1; n<16; ++n) {
         menu.addchk(n == Math.floor(obj.fTextFont/10), n, n,
                  function(arg) { this.GetObject().fTextFont = parseInt(arg)*10+2; this.Redraw(); }.bind(this));
      }
      menu.add("endsub:");

      menu.add("endsub:");
   }


   JSROOT.TObjectPainter.prototype.FillContextMenu = function(menu) {

      var title = this.GetTipName();
      if (this.GetObject() && ('_typename' in this.GetObject()))
         title = this.GetObject()._typename + "::" + title;

      menu.add("header:"+ title);

      this.FillAttContextMenu(menu);

      if (menu.size()>0)
         menu.add('Inspect', function() {
             JSROOT.draw(this.divid, this.GetObject(), 'inspect');
         });

      return menu.size() > 0;
   }

   JSROOT.TObjectPainter.prototype.GetShowStatusFunc = function() {
      // return function used to display object status
      // automatically disabled when drawing is enlarged - status line will be inisible

      var pp = this.pad_painter(), res = JSROOT.Painter.ShowStatus;

      if (pp && (typeof pp.ShowStatus === 'function')) res = pp.ShowStatus;

      if (res && (this.enlarge_main('state')==='on')) res = null;

      return res;
   }

   JSROOT.TObjectPainter.prototype.ShowObjectStatus = function() {
      // method called normally when mouse enter main object element

      var obj = this.GetObject(),
          status_func = this.GetShowStatusFunc();

      if (obj && status_func) status_func(this.GetItemName() || obj.fName, obj.fTitle || obj._typename, obj._typename);
   }


   JSROOT.TObjectPainter.prototype.FindInPrimitives = function(objname) {
      // try to find object by name in list of pad primitives
      // used to find title drawing

      var painter = this.pad_painter(true);
      if ((painter === null) || (painter.pad === null)) return null;

      if (painter.pad.fPrimitives !== null)
         for (var n=0;n<painter.pad.fPrimitives.arr.length;++n) {
            var prim = painter.pad.fPrimitives.arr[n];
            if (('fName' in prim) && (prim.fName === objname)) return prim;
         }

      return null;
   }

   JSROOT.TObjectPainter.prototype.FindPainterFor = function(selobj,selname,seltype) {
      // try to find painter for sepcified object
      // can be used to find painter for some special objects, registered as
      // histogram functions

      var painter = this.pad_painter(true);
      var painters = (painter === null) ? null : painter.painters;
      if (painters === null) return null;

      for (var n = 0; n < painters.length; ++n) {
         var pobj = painters[n].GetObject();
         if (!pobj) continue;

         if (selobj && (pobj === selobj)) return painters[n];
         if (!selname && !seltype) continue;
         if (selname && (pobj.fName !== selname)) continue;
         if (seltype && (pobj._typename !== seltype)) continue;
         return painters[n];
      }

      return null;
   }

   JSROOT.TObjectPainter.prototype.ConfigureUserTooltipCallback = function(call_back, user_timeout) {
      // hook for the users to get tooltip information when mouse cursor moves over frame area
      // call_back function will be called every time when new data is selected
      // when mouse leave frame area, call_back(null) will be called

      if ((call_back === undefined) || (typeof call_back !== 'function')) {
         delete this.UserTooltipCallback;
         return;
      }

      if (user_timeout===undefined) user_timeout = 500;

      this.UserTooltipCallback = call_back;
      this.UserTooltipTimeout = user_timeout;
   }

   JSROOT.TObjectPainter.prototype.IsUserTooltipCallback = function() {
      return typeof this.UserTooltipCallback == 'function';
   }

   JSROOT.TObjectPainter.prototype.ProvideUserTooltip = function(data) {

      if (!this.IsUserTooltipCallback()) return;

      if (this.UserTooltipTimeout <= 0)
         return this.UserTooltipCallback(data);

      if (typeof this.UserTooltipTHandle != 'undefined') {
         clearTimeout(this.UserTooltipTHandle);
         delete this.UserTooltipTHandle;
      }

      if (data==null)
         return this.UserTooltipCallback(data);

      this.UserTooltipTHandle = setTimeout(function(d) {
         // only after timeout user function will be called
         delete this.UserTooltipTHandle;
         this.UserTooltipCallback(d);
      }.bind(this, data), this.UserTooltipTimeout);
   }

   JSROOT.TObjectPainter.prototype.Redraw = function() {
      // basic method, should be reimplemented in all derived objects
      // for the case when drawing should be repeated
   }

   JSROOT.TObjectPainter.prototype.StartTextDrawing = function(font_face, font_size, draw_g, max_font_size) {
      // we need to preserve font to be able rescle at the end

      if (!draw_g) draw_g = this.draw_g;

      var font = JSROOT.Painter.getFontDetails(font_face, font_size);

      draw_g.call(font.func);

      draw_g.property('draw_text_completed', false)
            .property('text_font', font)
            .property('mathjax_use', false)
            .property('normaltext_use', false)
            .property('text_factor', 0.)
            .property('max_text_width', 0) // keep maximal text width, use it later
            .property('max_font_size', max_font_size);
   }

   JSROOT.TObjectPainter.prototype.TextScaleFactor = function(value, draw_g) {
      // function used to remember maximal text scaling factor
      if (!draw_g) draw_g = this.draw_g;
      if (value && (value > draw_g.property('text_factor'))) draw_g.property('text_factor', value);
   }

   JSROOT.TObjectPainter.prototype.GetBoundarySizes = function(elem) {
      // getBBox does not work in mozilla when object is not displayed or not visisble :(
      // getBoundingClientRect() returns wrong sizes for MathJax
      // are there good solution?

      if (elem===null) { console.warn('empty node in GetBoundarySizes'); return { width:0, height:0 }; }
      var box = elem.getBoundingClientRect(); // works always, but returns sometimes results in ex values, which is difficult to use
      if (parseFloat(box.width) > 0) box = elem.getBBox(); // check that elements visible, request precise value
      var res = { width : parseInt(box.width), height : parseInt(box.height) };
      if ('left' in box) { res.x = parseInt(box.left); res.y = parseInt(box.right); } else
      if ('x' in box) { res.x = parseInt(box.x); res.y = parseInt(box.y); }
      return res;
   }

   JSROOT.TObjectPainter.prototype.FinishTextDrawing = function(draw_g, call_ready) {
      if (!draw_g) draw_g = this.draw_g;

      if (draw_g.property('draw_text_completed')) {
         JSROOT.CallBack(call_ready);
         return draw_g.property('max_text_width');
      }

      if (call_ready) draw_g.node().text_callback = call_ready;

      var svgs = null;

      if (draw_g.property('mathjax_use')) {

         var missing = 0;
         svgs = draw_g.selectAll(".math_svg");

         svgs.each(function() {
            var fo_g = d3.select(this);
            if (fo_g.node().parentNode !== draw_g.node()) return;
            if (fo_g.select("svg").empty()) missing++;
         });

         // is any svg missing we should wait until drawing is really finished
         if (missing) return;
      }

      //if (!svgs) svgs = draw_g.selectAll(".math_svg");

      //var missing = 0;
      //svgs.each(function() {
      //   var fo_g = d3.select(this);
      //   if (fo_g.node().parentNode !== draw_g.node()) return;
      //   var entry = fo_g.property('_element');
      //   if (d3.select(entry).select("svg").empty()) missing++;
      //});
      //if (missing) console.warn('STILL SVG MISSING', missing);

      // adjust font size (if there are normal text)
      var painter = this,
          svg_factor = 0,
          f = draw_g.property('text_factor'),
          font = draw_g.property('text_font'),
          font_size = font.size;

      if ((f>0) && ((f<0.9) || (f>1.))) {
         font.size = Math.floor(font.size/f);
         if (draw_g.property('max_font_size') && (font.size > draw_g.property('max_font_size')))
            font.size = draw_g.property('max_font_size');
         draw_g.call(font.func);
         font_size = font.size;
      } else {
         //if (!draw_g.property('normaltext_use') && JSROOT.browser.isFirefox && (font.size<20)) {
         //   // workaround for firefox, where mathjax has problem when font size too small
         //   font.size = 20;
         //   draw_g.call(font.func);
         //}
      }

      // first analyze all MathJax SVG and repair width/height attributes
      if (svgs)
      svgs.each(function() {
         var fo_g = d3.select(this);
         if (fo_g.node().parentNode !== draw_g.node()) return;

         var vvv = fo_g.select("svg");
         if (vvv.empty()) {
            console.log('MathJax SVG ouptut error');
            return;
         }

         function transform(value) {
            if (!value || (typeof value !== "string")) return null;
            if (value.indexOf("ex")!==value.length-2) return null;
            value = parseFloat(value.substr(0, value.length-2));
            return isNaN(value) ? null : value*font_size*0.5;
         }

         var width = transform(vvv.attr("width")),
             height = transform(vvv.attr("height")),
             valign = vvv.attr("style");

         if (valign && valign.indexOf("vertical-align:")==0 && valign.indexOf("ex;")==valign.length-3) {
            valign = transform(valign.substr(16, valign.length-17));
         } else {
            valign = null;
         }

         width = (!width || (width<=0.5)) ? 1 : Math.round(width);
         height = (!height || (height<=0.5)) ? 1 : Math.round(height);

         vvv.attr("width", width).attr('height', height).attr("style",null);

         fo_g.property('_valign', valign);

         if (!JSROOT.nodejs) {
            var box = painter.GetBoundarySizes(fo_g.node());
            width = 1.05*box.width; height = 1.05*box.height;
         }

         if (fo_g.property('_scale'))
            svg_factor = Math.max(svg_factor, width / fo_g.property('_width'), height / fo_g.property('_height'));
      });

      if (svgs)
      svgs.each(function() {
         var fo_g = d3.select(this);
         // only direct parent
         if (fo_g.node().parentNode !== draw_g.node()) return;

         var valign = fo_g.property('_valign'),
             m = fo_g.select("svg"), // MathJax svg
             mw = parseInt(m.attr("width")),
             mh = parseInt(m.attr("height"));

         if (!isNaN(mh) && !isNaN(mw)) {
            if (svg_factor > 0.) {
               mw = mw/svg_factor;
               mh = mh/svg_factor;
               m.attr("width", Math.round(mw)).attr("height", Math.round(mh));
            }
         } else {
            var box = painter.GetBoundarySizes(fo_g.node()); // sizes before rotation
            mw = box.width || mw || 100;
            mh = box.height || mh || 10;
         }

         if ((svg_factor > 0.) && valign) valign = valign/svg_factor;

         if (valign===null) valign = (font_size - mh)/2;

         var align = fo_g.property('_align'),
             rotate = fo_g.property('_rotate'),
             fo_w = fo_g.property('_width'),
             fo_h = fo_g.property('_height'),
             tr = { x: fo_g.property('_x'), y: fo_g.property('_y') };

         var sign = { x:1, y:1 }, nx = "x", ny = "y";
         if (rotate == 180) { sign.x = sign.y = -1; } else
         if ((rotate == 270) || (rotate == 90)) {
            sign.x = (rotate===270) ? -1 : 1;
            sign.y = -sign.x;
            nx = "y"; ny = "x"; // replace names to which align applied
         }

         if (!fo_g.property('_scale')) fo_w = fo_h = 0;

         if (align[0] == 'middle') tr[nx] += sign.x*(fo_w - mw)/2; else
         if (align[0] == 'end')    tr[nx] += sign.x*(fo_w - mw);

         if (align[1] == 'middle') tr[ny] += sign.y*(fo_h - mh)/2; else
         if (align[1] == 'bottom') tr[ny] += sign.y*(fo_h - mh); else
         if (align[1] == 'bottom-base') tr[ny] += sign.y*(fo_h - mh - valign);

         var trans = "translate("+tr.x+","+tr.y+")";
         if (rotate!==0) trans += " rotate("+rotate+",0,0)";

         fo_g.attr('transform', trans).attr('visibility', null);
      });

      // now hidden text after rescaling can be shown
      draw_g.selectAll('.hidden_text').attr('opacity', '1').classed('hidden_text',false);

      if (!call_ready) call_ready = draw_g.node().text_callback;
      draw_g.node().text_callback = null;

      draw_g.property('draw_text_completed', true);

      // if specified, call ready function
      JSROOT.CallBack(call_ready);

      return draw_g.property('max_text_width');
   }

   JSROOT.TObjectPainter.prototype.DrawText = function(align_arg, x, y, w, h, label, tcolor, latex_kind, draw_g) {

      if (!draw_g) draw_g = this.draw_g;
      var align;

      if (typeof align_arg == 'string') {
         align = align_arg.split(";");
         if (align.length==1) align.push('middle');
      } else {
         align = ['start', 'middle'];
         if ((align_arg / 10) >= 3) align[0] = 'end'; else
         if ((align_arg / 10) >= 2) align[0] = 'middle';
         if ((align_arg % 10) == 0) align[1] = 'bottom'; else
         if ((align_arg % 10) == 1) align[1] = 'bottom-base'; else
         if ((align_arg % 10) == 3) align[1] = 'top';
      }

      var scale = (w>0) && (h>0);

      if (latex_kind==null) latex_kind = 1;
      if (latex_kind<2)
         if (!JSROOT.Painter.isAnyLatex(label)) latex_kind = 0;

      var use_normal_text = ((JSROOT.gStyle.MathJax<1) && (latex_kind!==2)) || (latex_kind<1),
          font = draw_g.property('text_font');

      // only Firefox can correctly rotate incapsulated SVG, produced by MathJax
      // if (!use_normal_text && (h<0) && !JSROOT.browser.isFirefox) use_normal_text = true;

      if (use_normal_text) {
         if (latex_kind>0) label = JSROOT.Painter.translateLaTeX(label);

         var pos_x = x.toFixed(1), pos_y = y.toFixed(1), pos_dy = "", middleline = false;

         if (w>0) {
            // adjust x position when scale into specified rectangle
            if (align[0]=="middle") pos_x = (x+w*0.5).toFixed(1); else
            if (align[0]=="end") pos_x = (x+w).toFixed(1);
         }

         if (h>0) {
            if (align[1].indexOf('bottom')===0) pos_y = (y + h).toFixed(1); else
            if (align[1] == 'top') pos_dy = ".8em"; else {
               pos_y = (y + h/2 + 1).toFixed(1);
               if (JSROOT.browser.isIE) pos_dy = ".4em"; else middleline = true;
            }
         } else {
            if (align[1] == 'top') pos_dy = ".8em"; else
            if (align[1] == 'middle') {
               if (JSROOT.browser.isIE) pos_dy = ".4em"; else middleline = true;
            }
         }

         // use translate and then rotate to avoid complex sign calculations
         var trans = "translate("+pos_x+","+pos_y+")";
         if (!scale && (h<0)) trans += " rotate("+(-h)+",0,0)";

         var txt = draw_g.append("text")
                         .attr("text-anchor", align[0])
                         .attr("x", 0)
                         .attr("y", 0)
                         .attr("fill", tcolor ? tcolor : null)
                         .attr("transform", trans)
                         .text(label);
         if (pos_dy) txt.attr("dy", pos_dy);
         if (middleline) txt.attr("dominant-baseline", "middle");

         draw_g.property('normaltext_use', true);

         // workaround for Node.js - use primitive estimation of textbox size
         // later can be done with Node.js (via SVG) or with alternative implementation of jsdom
         var box = !JSROOT.nodejs ? this.GetBoundarySizes(txt.node()) :
                    { height: Math.round(font.size*1.2), width: Math.round(label.length*font.size*0.4) };

         if (scale) txt.classed('hidden_text',true).attr('opacity','0'); // hide rescale elements

         if (box.width > draw_g.property('max_text_width')) draw_g.property('max_text_width', box.width);
         if ((w>0) && scale) this.TextScaleFactor(1.05*box.width / w, draw_g);
         if ((h>0) && scale) this.TextScaleFactor(1.*box.height / h, draw_g);

         return box.width;
      }

      w = Math.round(w); h = Math.round(h);
      x = Math.round(x); y = Math.round(y);

      var rotate = 0;

      if (!scale && h<0) { rotate = Math.abs(h); h = 0; }

      var mtext = JSROOT.Painter.translateMath(label, latex_kind, tcolor),
          fo_g = draw_g.append("svg:g")
                       .attr('class', 'math_svg')
                       .attr('visibility','hidden')
                       .property('_x',x) // used for translation later
                       .property('_y',y)
                       .property('_width',w) // used to check scaling
                       .property('_height',h)
                       .property('_scale', scale)
                       .property('_rotate', rotate)
                       .property('_align', align);

      draw_g.property('mathjax_use', true);  // one need to know that mathjax is used

      if (JSROOT.nodejs) {
         // special handling for Node.js

         if (!JSROOT.nodejs_mathjax) {
            JSROOT.nodejs_mathjax = require("mathjax-node");
            JSROOT.nodejs_mathjax.config({
               TeX: { extensions: ["color.js"] },
               SVG: { mtextFontInherit: true, minScaleAdjust: 100, matchFontHeight: true, useFontCache: false }
            });
            JSROOT.nodejs_mathjax.start();
         }

         if ((mtext.indexOf("\\(")==0) && (mtext.lastIndexOf("\\)")==mtext.length-2))
            mtext = mtext.substr(2,mtext.length-4);

         JSROOT.nodejs_mathjax.typeset({
            jsroot_painter: this,
            jsroot_drawg: draw_g,
            jsroot_fog: fo_g,
            ex: font.size,
            math: mtext,
            useFontCache: false,
            useGlobalCache: false,
            format: "TeX", // "TeX", "inline-TeX", "MathML"
            svg: true //  svg:true,
          }, function (data, opt) {
             if (!data.errors) {
                opt.jsroot_fog.html(data.svg);
             } else {
                console.log('MathJax error', opt.math);
                opt.jsroot_fog.html("<svg></svg>");
             }
             opt.jsroot_painter.FinishTextDrawing(opt.jsroot_drawg);
          });

         return 0;
      }

      var element = document.createElement("p");

      d3.select(element).style('visibility',"hidden").style('overflow',"hidden").style('position',"absolute")
                        .style("font-size",font.size+'px').style("font-family",font.name)
                        .html('<mtext>' + mtext + '</mtext>');
      document.body.appendChild(element);

      fo_g.property('_element', element);

      var painter = this;

      JSROOT.AssertPrerequisites('mathjax', function() {

         MathJax.Hub.Typeset(element, ["FinishMathjax", painter, draw_g, fo_g]);

         MathJax.Hub.Queue(["FinishMathjax", painter, draw_g, fo_g]); // repeat once again, while Typeset not always invoke callback
      });

      return 0;
   }

   JSROOT.TObjectPainter.prototype.FinishMathjax = function(draw_g, fo_g, id) {
      // function should be called when processing of element is completed

      if (fo_g.node().parentNode !== draw_g.node()) return;
      var entry = fo_g.property('_element');
      if (!entry) return;

      var vvv = d3.select(entry).select("svg");
      if (vvv.empty()) return; // not yet finished

      fo_g.property('_element', null);

      vvv.remove();
      document.body.removeChild(entry);

      fo_g.append(function() { return vvv.node(); });

      this.FinishTextDrawing(draw_g); // check if all other elements are completed
   }


   // ===========================================================

   JSROOT.TFramePainter = function(tframe) {
      JSROOT.TObjectPainter.call(this, tframe);
      this.tooltip_enabled = true;
      this.tooltip_allowed = (JSROOT.gStyle.Tooltip > 0);
   }

   JSROOT.TFramePainter.prototype = Object.create(JSROOT.TObjectPainter.prototype);

   JSROOT.TFramePainter.prototype.Shrink = function(shrink_left, shrink_right) {
      this.fX1NDC += shrink_left;
      this.fX2NDC -= shrink_right;
   }

   JSROOT.TFramePainter.prototype.UpdateAttributes = function(force) {
      var pad = this.root_pad(),
          tframe = this.GetObject();

      if ((this.fX1NDC === undefined) || (force && !this.modified_NDC)) {
         if (!pad) {
            JSROOT.extend(this, JSROOT.gStyle.FrameNDC);
         } else {
            JSROOT.extend(this, {
               fX1NDC: pad.fLeftMargin,
               fX2NDC: 1 - pad.fRightMargin,
               fY1NDC: pad.fBottomMargin,
               fY2NDC: 1 - pad.fTopMargin
            });
         }
      }

      if (this.fillatt === undefined) {
         if (tframe)
            this.fillatt = this.createAttFill(tframe);
         else
         if (pad)
            this.fillatt = this.createAttFill(null, pad.fFrameFillStyle, pad.fFrameFillColor);
         else
            this.fillatt = this.createAttFill(null, 1001, 0);

         // force white color for the frame
         // if (this.fillatt.color == 'none') this.fillatt.color = 'white';
      }

      if (this.lineatt === undefined)
         this.lineatt = JSROOT.Painter.createAttLine(tframe ? tframe : 'black');
   }

   JSROOT.TFramePainter.prototype.SizeChanged = function() {
      // function called at the end of resize of frame
      // One should apply changes to the pad

      var pad = this.root_pad(),
          main = this.main_painter();

      if (pad) {
         pad.fLeftMargin = this.fX1NDC;
         pad.fRightMargin = 1 - this.fX2NDC;
         pad.fBottomMargin = this.fY1NDC;
         pad.fTopMargin = 1 - this.fY2NDC;
         if (main) main.SetRootPadRange(pad);
      }

      this.RedrawPad();
   }

   JSROOT.TFramePainter.prototype.Redraw = function() {

      // first update all attributes from objects
      this.UpdateAttributes();

      var width = this.pad_width(),
          height = this.pad_height(),
          lm = Math.round(width * this.fX1NDC),
          w = Math.round(width * (this.fX2NDC - this.fX1NDC)),
          tm = Math.round(height * (1 - this.fY2NDC)),
          h = Math.round(height * (this.fY2NDC - this.fY1NDC));

      // this is svg:g object - container for every other items belonging to frame
      this.draw_g = this.svg_frame();
      if (this.draw_g.empty())
         return console.error('did not found frame layer');

      var top_rect = this.draw_g.select("rect"),
          main_svg = this.draw_g.select(".main_layer");

      if (main_svg.empty()) {
         this.draw_g.append("svg:title").text("");

         top_rect = this.draw_g.append("svg:rect");

         // append for the moment three layers - for drawing and axis
         this.draw_g.append('svg:g').attr('class','grid_layer');

         main_svg = this.draw_g.append('svg:svg')
                           .attr('class','main_layer')
                           .attr("x", 0)
                           .attr("y", 0)
                           .attr('overflow', 'hidden');

         this.draw_g.append('svg:g').attr('class','axis_layer');
         this.draw_g.append('svg:g').attr('class','upper_layer');
      }

      // simple way to access painter via frame container
      this.draw_g.property('frame_painter', this);

      this.draw_g.attr("x", lm)
             .attr("y", tm)
             .attr("width", w)
             .attr("height", h)
             .property('draw_x', lm)
             .property('draw_y', tm)
             .property('draw_width', w)
             .property('draw_height', h)
             .attr("transform", "translate(" + lm + "," + tm + ")");

      top_rect.attr("x", 0)
              .attr("y", 0)
              .attr("width", w)
              .attr("height", h)
              .call(this.fillatt.func)
              .call(this.lineatt.func);

      main_svg.attr("width", w)
              .attr("height", h)
              .attr("viewBox", "0 0 " + w + " " + h);

      this.AddDrag({ obj: this, only_resize: true, minwidth: 20, minheight: 20,
                     redraw: this.SizeChanged.bind(this) });

      var tooltip_rect = this.draw_g.select(".interactive_rect");

      if (JSROOT.gStyle.Tooltip === 0)
         return tooltip_rect.remove();

      var painter = this;

      function MouseMoveEvent() {
         var pnt = d3.mouse(tooltip_rect.node());
         painter.ProcessTooltipEvent({ x: pnt[0], y: pnt[1], touch: false });
      }

      function MouseCloseEvent() {
         painter.ProcessTooltipEvent(null);
      }

      function TouchMoveEvent() {
         var pnt = d3.touches(tooltip_rect.node());
         if (!pnt || pnt.length !== 1) return painter.ProcessTooltipEvent(null);
         painter.ProcessTooltipEvent({ x: pnt[0][0], y: pnt[0][1], touch: true });
      }

      function TouchCloseEvent() {
         painter.ProcessTooltipEvent(null);
      }

      if (tooltip_rect.empty()) {
         tooltip_rect =
            this.draw_g
                .append("rect")
                .attr("class","interactive_rect")
                .style('opacity',0).style('fill',"none").style("pointer-events","visibleFill")
                .on('mouseenter', MouseMoveEvent)
                .on('mousemove', MouseMoveEvent)
                .on('mouseleave', MouseCloseEvent);

         if (JSROOT.touches)
            tooltip_rect.on("touchstart", TouchMoveEvent)
                        .on("touchmove", TouchMoveEvent)
                        .on("touchend", TouchCloseEvent)
                        .on("touchcancel", TouchCloseEvent);
      }

      tooltip_rect.attr("x", 0)
                  .attr("y", 0)
                  .attr("width", w)
                  .attr("height", h);

      var hintsg = this.svg_layer("stat_layer").select(".objects_hints");
      // if tooltips were visible before, try to reconstruct them after short timeout
      if (!hintsg.empty() && (JSROOT.gStyle.Tooltip > 0))
         setTimeout(this.ProcessTooltipEvent.bind(this, hintsg.property('last_point')), 10);
   }


   JSROOT.TFramePainter.prototype.FillContextMenu = function(menu) {
      // fill context menu for the frame
      // it could be appended to the histogram menus

      var main = this.main_painter(), alone = menu.size()==0, pad = this.root_pad();

      if (alone)
         menu.add("header:Frame");
      else
         menu.add("separator");

      if (main) {
         if (main.zoom_xmin !== main.zoom_xmax)
            menu.add("Unzoom X", main.Unzoom.bind(main,"x"));
         if (main.zoom_ymin !== main.zoom_ymax)
            menu.add("Unzoom Y", main.Unzoom.bind(main,"y"));
         if (main.zoom_zmin !== main.zoom_zmax)
            menu.add("Unzoom Z", main.Unzoom.bind(main,"z"));
         menu.add("Unzoom all", main.Unzoom.bind(main,"xyz"));

         if (pad) {
            menu.addchk(pad.fLogx, "SetLogx", main.ToggleLog.bind(main,"x"));

            menu.addchk(pad.fLogy, "SetLogy", main.ToggleLog.bind(main,"y"));

            if (main.Dimension() == 2)
               menu.addchk(pad.fLogz, "SetLogz", main.ToggleLog.bind(main,"z"));
         }
         menu.add("separator");
      }

      menu.addchk(this.tooltip_allowed, "Show tooltips", function() {
         var fp = this.frame_painter();
         if (fp) fp.tooltip_allowed = !fp.tooltip_allowed;
      });
      this.FillAttContextMenu(menu,alone ? "" : "Frame ");
      menu.add("separator");
      menu.add("Save as frame.png", function(arg) {
         var top = this.svg_frame();
         if (!top.empty())
            JSROOT.saveSvgAsPng(top.node(), { name: "frame.png" } );
      });

      return true;
   }

   JSROOT.saveSvgAsPng = function(el, options, call_back) {
      JSROOT.AssertPrerequisites("savepng", function() {
         JSROOT.saveSvgAsPng(el, options, call_back);
      });
   }

   JSROOT.TFramePainter.prototype.IsTooltipShown = function() {
      // return true if tooltip is shown, use to prevent some other action
      if (JSROOT.gStyle.Tooltip < 1) return false;
      return ! (this.svg_layer("stat_layer").select(".objects_hints").empty());
   }

   JSROOT.TFramePainter.prototype.ProcessTooltipEvent = function(pnt, enabled) {

      if (enabled !== undefined) this.tooltip_enabled = enabled;

      var hints = [], nhints = 0, maxlen = 0, lastcolor1 = 0, usecolor1 = false,
          textheight = 11, hmargin = 3, wmargin = 3, hstep = 1.2,
          height = this.frame_height(),
          width = this.frame_width(),
          pad_width = this.pad_width(),
          frame_x = this.frame_x(),
          pp = this.pad_painter(true),
          maxhinty = this.pad_height() - this.draw_g.property('draw_y'),
          font = JSROOT.Painter.getFontDetails(160, textheight),
          status_func = this.GetShowStatusFunc(),
          disable_tootlips = !this.tooltip_allowed || !this.tooltip_enabled;

      if ((pnt === undefined) || (disable_tootlips && !status_func)) pnt = null;
      if (pnt && disable_tootlips) pnt.disabled = true; // indicate that highlighting is not required

      // collect tooltips from pad painter - it has list of all drawn objects
      if (pp) hints = pp.GetTooltips(pnt);

      if (pnt && pnt.touch) textheight = 15;

      for (var n=0; n < hints.length; ++n) {
         var hint = hints[n];
         if (!hint) continue;
         if (!hint.lines || (hint.lines.length===0)) {
            hints[n] = null; continue;
         }

         // check if fully duplicated hint already exsits
         for (var k=0;k<n;++k) {
            var hprev = hints[k], diff = false;
            if (!hprev || (hprev.lines.length !== hint.lines.length)) continue;
            for (var l=0;l<hint.lines.length && !diff;++l)
               if (hprev.lines[l] !== hint.lines[l]) diff = true;
            if (!diff) { hints[n] = null; break; }
         }
         if (!hints[n]) continue;

         nhints++;

         for (var l=0;l<hint.lines.length;++l)
            maxlen = Math.max(maxlen, hint.lines[l].length);

         hint.height = Math.round(hint.lines.length*textheight*hstep + 2*hmargin - textheight*(hstep-1));

         if ((hint.color1!==undefined) && (hint.color1!=='none')) {
            if ((lastcolor1!==0) && (lastcolor1 !== hint.color1)) usecolor1 = true;
            lastcolor1 = hint.color1;
         }
      }

      var layer = this.svg_layer("stat_layer"),
          hintsg = layer.select(".objects_hints"); // group with all tooltips

      if (status_func) {
         var title = "", name = "", coordinates = "", info = "";
         if (pnt) coordinates = Math.round(pnt.x)+","+Math.round(pnt.y);
         var hint = null, best_dist2 = 1e10, best_hint = null;
         // try to select hint with exact match of the position when several hints available
         if (hints && hints.length>0)
            for (var k=0;k<hints.length;++k) {
               if (!hints[k]) continue;
               if (!hint) hint = hints[k];
               if (hints[k].exact && (!hint || !hint.exact)) { hint = hints[k]; break; }

               if (!pnt || (hints[k].x===undefined) || (hints[k].y===undefined)) continue;

               var dist2 = (pnt.x-hints[k].x)*(pnt.x-hints[k].x) + (pnt.y-hints[k].y)*(pnt.y-hints[k].y);
               if (dist2<best_dist2) { best_dist2 = dist2; best_hint = hints[k]; }
            }

         if ((!hint || !hint.exact) && (best_dist2 < 400)) hint = best_hint;

         if (hint) {
            name = (hint.lines && hint.lines.length>1) ? hint.lines[0] : hint.name;
            title = hint.title || "";
            info = hint.line;
            if (!info && hint.lines) info = hint.lines.slice(1).join(' ');
         }

         status_func(name, title, info, coordinates);
      }

      // end of closing tooltips
      if (!pnt || disable_tootlips || (hints.length===0) || (maxlen===0) || (nhints > 15)) {
         hintsg.remove();
         return;
      }

      // we need to set pointer-events=none for all elements while hints
      // placed in front of so-called interactive rect in frame, used to catch mouse events

      if (hintsg.empty())
         hintsg = layer.append("svg:g")
                       .attr("class", "objects_hints")
                       .style("pointer-events","none");

      // copy transform attributes from frame itself
      hintsg.attr("transform", this.draw_g.attr("transform"));

      hintsg.property("last_point", pnt);

      var viewmode = hintsg.property('viewmode');
      if (viewmode === undefined) viewmode = "";

      var actualw = 0, posx = pnt.x + 15;

      if (nhints > 1) {
         // if there are many hints, place them left or right

         var bleft = 0.5, bright = 0.5;

         if (viewmode=="left") bright = 0.7; else
         if (viewmode=="right") bleft = 0.3;

         if (pnt.x <= bleft*width) {
            viewmode = "left";
            posx = 20;
         } else
         if (pnt.x >= bright*width) {
            viewmode = "right";
            posx = width - 60;
         } else {
            posx = hintsg.property('startx');
         }
      } else {
         viewmode = "single";
      }

      if (viewmode !== hintsg.property('viewmode')) {
         hintsg.property('viewmode', viewmode);
         hintsg.selectAll("*").remove();
      }

      var curry = 10, // normal y coordiante
          gapy = 10, // y coordiante, taking into account all gaps
          gapminx = -1111, gapmaxx = -1111;

      function FindPosInGap(y) {
         for (var n=0;(n<hints.length) && (y < maxhinty); ++n) {
            var hint = hints[n];
            if (!hint) continue;
            if ((hint.y>=y-5) && (hint.y <= y+hint.height+5)) {
               y = hint.y+10;
               n = -1;
            }
         }
         return y;
      }

      for (var n=0; n < hints.length; ++n) {
         var hint = hints[n],
             group = hintsg.select(".painter_hint_"+n);
         if (hint===null) {
            group.remove();
            continue;
         }

         var was_empty = group.empty();

         if (was_empty)
            group = hintsg.append("svg:svg")
                          .attr("class", "painter_hint_"+n)
                          .attr('opacity',0) // use attribute, not style to make animation with d3.transition()
                          .style('overflow','hidden').style("pointer-events","none");

         if (viewmode == "single") {
            curry = pnt.touch ? (pnt.y - hint.height - 5) : Math.min(pnt.y + 15, maxhinty - hint.height - 3);
         } else {
            gapy = FindPosInGap(gapy);
            if ((gapminx === -1111) && (gapmaxx === -1111)) gapminx = gapmaxx = hint.x;
            gapminx = Math.min(gapminx, hint.x);
            gapmaxx = Math.min(gapmaxx, hint.x);
         }

         group.attr("x", posx)
              .attr("y", curry)
              .property("gapy", gapy);

         curry += hint.height + 5;
         gapy += hint.height + 5;

         if (!was_empty)
            group.selectAll("*").remove();

         group.attr("width", 60)
              .attr("height", hint.height);

         var r = group.append("rect")
                      .attr("x",0)
                      .attr("y",0)
                      .attr("width", 60)
                      .attr("height", hint.height)
                      .attr("fill","lightgrey")
                      .style("pointer-events","none");

         if (nhints > 1) {
            var col = usecolor1 ? hint.color1 : hint.color2;
            if ((col !== undefined) && (col!=='none'))
               r.attr("stroke", col).attr("stroke-width", hint.exact ? 3 : 1);
         }

         if (hint.lines != null) {
            for (var l=0;l<hint.lines.length;l++)
               if (hint.lines[l]!==null) {
                  var txt = group.append("svg:text")
                                 .attr("text-anchor", "start")
                                 .attr("x", wmargin)
                                 .attr("y", hmargin + l*textheight*hstep)
                                 .attr("dy", ".8em")
                                 .attr("fill","black")
                                 .style("pointer-events","none")
                                 .call(font.func)
                                 .text(hint.lines[l]);

                  var box = this.GetBoundarySizes(txt.node());

                  actualw = Math.max(actualw, box.width);
               }
         }

         function translateFn() {
            // We only use 'd', but list d,i,a as params just to show can have them as params.
            // Code only really uses d and t.
            return function(d, i, a) {
               return function(t) {
                  return t < 0.8 ? "0" : (t-0.8)*5;
               };
            };
         }

         if (was_empty)
            if (JSROOT.gStyle.TooltipAnimation > 0)
               group.transition().duration(JSROOT.gStyle.TooltipAnimation).attrTween("opacity", translateFn());
            else
               group.attr('opacity',1);
      }

      actualw += 2*wmargin;

      var svgs = hintsg.selectAll("svg");

      if ((viewmode == "right") && (posx + actualw > width - 20)) {
         posx = width - actualw - 20;
         svgs.attr("x", posx);
      }

      if ((viewmode == "single") && (posx + actualw > pad_width - frame_x) && (posx > actualw+20)) {
         posx -= (actualw + 20);
         svgs.attr("x", posx);
      }

      // if gap not very big, apply gapy coordinate to open view on the histogram
      if ((viewmode !== "single") && (gapy < maxhinty) && (gapy !== curry))
         if ((gapminx <= posx+actualw+5) && (gapmaxx >= posx-5))
            svgs.attr("y", function() { return d3.select(this).property('gapy'); });

      if (actualw > 10)
         svgs.attr("width", actualw)
             .select('rect').attr("width", actualw);

      hintsg.property('startx', posx);
   }

   JSROOT.Painter.drawFrame = function(divid, obj) {
      var p = new JSROOT.TFramePainter(obj);
      p.SetDivId(divid, 2);
      p.Redraw();
      return p.DrawingReady();
   }

   // ============================================================

   // base class for all objects, derived from TPave
   JSROOT.TPavePainter = function(pave) {
      JSROOT.TObjectPainter.call(this, pave);
      this.Enabled = true;
      this.UseContextMenu = true;
      this.UseTextColor = false; // indicates if text color used, enabled menu entry
      this.FirstRun = 1; // counter required to correctly complete drawing
      this.AssignFinishPave();
   }

   JSROOT.TPavePainter.prototype = Object.create(JSROOT.TObjectPainter.prototype);

   JSROOT.TPavePainter.prototype.AssignFinishPave = function() {
      function func() {
         // function used to signal drawing ready, required when text drawing posponed due to mathjax
         if (this.FirstRun <= 0) return;
         this.FirstRun--;
         if (this.FirstRun!==0) return;
         delete this.FinishPave; // no need for that callback
         this.DrawingReady();
      }
      this.FinishPave = func.bind(this);
   }

   JSROOT.TPavePainter.prototype.DrawPave = function(arg) {
      // this draw only basic TPave

      this.UseTextColor = false;

      if (!this.Enabled)
         return this.RemoveDrawG();

      var pt = this.GetObject();

      if (pt.fInit===0) {
         pt.fInit = 1;
         var pad = this.root_pad();
         if (pt.fOption.indexOf("NDC")>=0) {
            pt.fX1NDC = pt.fX1; pt.fX2NDC = pt.fX2;
            pt.fY1NDC = pt.fY1; pt.fY2NDC = pt.fY2;
         } else
         if (pad !== null) {
            if (pad.fLogx) {
               if (pt.fX1 > 0) pt.fX1 = JSROOT.log10(pt.fX1);
               if (pt.fX2 > 0) pt.fX2 = JSROOT.log10(pt.fX2);
            }
            if (pad.fLogy) {
               if (pt.fY1 > 0) pt.fY1 = JSROOT.log10(pt.fY1);
               if (pt.fY2 > 0) pt.fY2 = JSROOT.log10(pt.fY2);
            }
            pt.fX1NDC = (pt.fX1-pad.fX1) / (pad.fX2 - pad.fX1);
            pt.fY1NDC = (pt.fY1-pad.fY1) / (pad.fY2 - pad.fY1);
            pt.fX2NDC = (pt.fX2-pad.fX1) / (pad.fX2 - pad.fX1);
            pt.fY2NDC = (pt.fY2-pad.fY1) / (pad.fY2 - pad.fY1);
         } else {
            pt.fX1NDC = pt.fY1NDC = 0.1;
            pt.fX2NDC = pt.fY2NDC = 0.9;
         }
      }

      var pos_x = Math.round(pt.fX1NDC * this.pad_width()),
          pos_y = Math.round((1.0 - pt.fY2NDC) * this.pad_height()),
          width = Math.round((pt.fX2NDC - pt.fX1NDC) * this.pad_width()),
          height = Math.round((pt.fY2NDC - pt.fY1NDC) * this.pad_height()),
          lwidth = pt.fBorderSize;

      // container used to recalculate coordinates
      this.RecreateDrawG(true, this.IsStats() ? "stat_layer" : "text_layer");

      // position and size required only for drag functions
      this.draw_g
           .attr("x", pos_x)
           .attr("y", pos_y)
           .attr("width", width)
           .attr("height", height)
           .attr("transform", "translate(" + pos_x + "," + pos_y + ")");

      // add shadow decoration before main rect
      if ((lwidth > 1) && (pt.fShadowColor > 0))
         this.draw_g.append("svg:path")
             .attr("d","M" + width + "," + height +
                      " v" + (-height + lwidth) + " h" + lwidth +
                      " v" + height + " h" + (-width) +
                      " v" + (-lwidth) + " Z")
            .style("fill", JSROOT.Painter.root_colors[pt.fShadowColor])
            .style("stroke", JSROOT.Painter.root_colors[pt.fShadowColor])
            .style("stroke-width", "1px");

      if (this.lineatt === undefined)
         this.lineatt = JSROOT.Painter.createAttLine(pt, lwidth>0 ? 1 : 0);
      if (this.fillatt === undefined)
         this.fillatt = this.createAttFill(pt);

      var rect =
         this.draw_g.append("rect")
          .attr("x", 0)
          .attr("y", 0)
          .attr("width", width)
          .attr("height", height)
          .call(this.fillatt.func)
          .call(this.lineatt.func);

      if ('PaveDrawFunc' in this)
         this.PaveDrawFunc(width, height, arg);

      if (JSROOT.BatchMode) return;

      // here all kind of interactive settings

      rect.style("pointer-events", "visibleFill")
          .on("mouseenter", this.ShowObjectStatus.bind(this))

      this.AddDrag({ obj: pt, minwidth: 10, minheight: 20,
                     redraw: this.DrawPave.bind(this),
                     ctxmenu: JSROOT.touches && JSROOT.gStyle.ContextMenu && this.UseContextMenu });

      if (this.UseContextMenu && JSROOT.gStyle.ContextMenu)
         this.draw_g.on("contextmenu", this.ShowContextMenu.bind(this));
   }

   JSROOT.TPavePainter.prototype.DrawPaveLabel = function(width, height) {
      this.UseTextColor = true;

      var pave = this.GetObject();

      this.StartTextDrawing(pave.fTextFont, height/1.2);

      this.DrawText(pave.fTextAlign, 0, 0, width, height, pave.fLabel, JSROOT.Painter.root_colors[pave.fTextColor]);

      this.FinishTextDrawing(null, this.FinishPave);
   }

   JSROOT.TPavePainter.prototype.DrawPaveText = function(width, height, refill) {

      if (refill && this.IsStats()) this.FillStatistic();

      var pt = this.GetObject(),
          tcolor = JSROOT.Painter.root_colors[pt.fTextColor],
          lwidth = pt.fBorderSize,
          first_stat = 0,
          num_cols = 0,
          nlines = pt.fLines.arr.length,
          lines = [],
          maxlen = 0,
          draw_header = (pt.fLabel.length>0) && !this.IsStats();

      if (draw_header) this.FirstRun++; // increment finish counter

      // adjust font size
      for (var j = 0; j < nlines; ++j) {
         var line = pt.fLines.arr[j].fTitle;
         lines.push(line);
         if (j>0) maxlen = Math.max(maxlen, line.length);
         if (!this.IsStats() || (j == 0) || (line.indexOf('|') < 0)) continue;
         if (first_stat === 0) first_stat = j;
         var parts = line.split("|");
         if (parts.length > num_cols)
            num_cols = parts.length;
      }

      if ((nlines===1) && !this.IsStats() &&
          (lines[0].indexOf("#splitline{")===0) && (lines[0][lines[0].length-1]=="}")) {
            var pos = lines[0].indexOf("}{");
            if ((pos>0) && (pos == lines[0].lastIndexOf("}{"))) {
               lines[1] = lines[0].substr(pos+2, lines[0].length - pos - 3);
               lines[0] = lines[0].substr(11, pos - 11);
               nlines = 2;
               this.UseTextColor = true;
            }
         }

      // for characters like 'p' or 'y' several more pixels required to stay in the box when drawn in last line
      var stepy = height / nlines, has_head = false, margin_x = pt.fMargin * width;

      this.StartTextDrawing(pt.fTextFont, height/(nlines * 1.2));

      if (nlines == 1) {
         this.DrawText(pt.fTextAlign, 0, 0, width, height, lines[0], tcolor);
         this.UseTextColor = true;
      } else {
         for (var j = 0; j < nlines; ++j) {
            var posy = j*stepy, jcolor = tcolor;
            if (!this.UseTextColor && (j<pt.fLines.arr.length) && (pt.fLines.arr[j].fTextColor!==0))
               jcolor = JSROOT.Painter.root_colors[pt.fLines.arr[j].fTextColor];
            if (jcolor===undefined) {
               jcolor = tcolor;
               this.UseTextColor = true;
            }

            if (this.IsStats()) {
               if ((first_stat > 0) && (j >= first_stat)) {
                  var parts = lines[j].split("|");
                  for (var n = 0; n < parts.length; ++n)
                     this.DrawText("middle",
                                    width * n / num_cols, posy,
                                    width/num_cols, stepy, parts[n], jcolor);
               } else if (lines[j].indexOf('=') < 0) {
                  if (j==0) {
                     has_head = true;
                     if (lines[j].length > maxlen + 5)
                        lines[j] = lines[j].substr(0,maxlen+2) + "...";
                  }
                  this.DrawText((j == 0) ? "middle" : "start",
                                 margin_x, posy, width-2*margin_x, stepy, lines[j], jcolor);
               } else {
                  var parts = lines[j].split("="), sumw = 0;
                  for (var n = 0; n < 2; ++n)
                     sumw += this.DrawText((n == 0) ? "start" : "end",
                                      margin_x, posy, width-2*margin_x, stepy, parts[n], jcolor);
                  this.TextScaleFactor(1.05*sumw/(width-2*margin_x), this.draw_g);
               }
            } else {
               this.DrawText(pt.fTextAlign, margin_x, posy, width-2*margin_x, stepy, lines[j], jcolor);
            }
         }
      }

      this.FinishTextDrawing(undefined, this.FinishPave);

      if ((lwidth > 0) && has_head) {
         this.draw_g.append("svg:line")
                    .attr("x1", 0)
                    .attr("y1", stepy.toFixed(1))
                    .attr("x2", width)
                    .attr("y2", stepy.toFixed(1))
                    .call(this.lineatt.func);
      }

      if ((first_stat > 0) && (num_cols > 1)) {
         for (var nrow = first_stat; nrow < nlines; ++nrow)
            this.draw_g.append("svg:line")
                       .attr("x1", 0)
                       .attr("y1", (nrow * stepy).toFixed(1))
                       .attr("x2", width)
                       .attr("y2", (nrow * stepy).toFixed(1))
                       .call(this.lineatt.func);

         for (var ncol = 0; ncol < num_cols - 1; ++ncol)
            this.draw_g.append("svg:line")
                        .attr("x1", (width / num_cols * (ncol + 1)).toFixed(1))
                        .attr("y1", (first_stat * stepy).toFixed(1))
                        .attr("x2", (width / num_cols * (ncol + 1)).toFixed(1))
                        .attr("y2", height)
                        .call(this.lineatt.func);
      }

      if (draw_header) {
         var x = Math.round(width*0.25),
             y = Math.round(-height*0.02),
             w = Math.round(width*0.5),
             h = Math.round(height*0.04);

         var lbl_g = this.draw_g.append("svg:g");

         lbl_g.append("rect")
               .attr("x", x)
               .attr("y", y)
               .attr("width", w)
               .attr("height", h)
               .call(this.fillatt.func)
               .call(this.lineatt.func);

         this.StartTextDrawing(pt.fTextFont, h/1.5, lbl_g);

         this.DrawText(22, x, y, w, h, pt.fLabel, tcolor, 1, lbl_g);

         this.FinishTextDrawing(lbl_g, this.FinishPave);

         this.UseTextColor = true;
      }
   }

   JSROOT.TPavePainter.prototype.Format = function(value, fmt) {
      // method used to convert value to string according specified format
      // format can be like 5.4g or 4.2e or 6.4f
      if (!fmt) fmt = "stat";

      var pave = this.GetObject();

      if (fmt=="stat") {
         fmt = pave.fStatFormat;
         if (!fmt) fmt = JSROOT.gStyle.fStatFormat;
      } else
      if (fmt=="fit") {
         fmt = pave.fFitFormat;
         if (!fmt) fmt = JSROOT.gStyle.fFitFormat;
      } else
      if (fmt=="entries") {
         if (value < 1e9) return value.toFixed(0);
         fmt = "14.7g";
      } else
      if (fmt=="last") {
         fmt = this.lastformat;
      }

      delete this.lastformat;

      if (!fmt) fmt = "6.4g";

      var res = JSROOT.FFormat(value, fmt);

      this.lastformat = JSROOT.lastFFormat;

      return res;
   }

   JSROOT.TPavePainter.prototype.FillContextMenu = function(menu) {
      var pave = this.GetObject();

      menu.add("header: " + pave._typename + "::" + pave.fName);
      if (this.IsStats()) {
         menu.add("Default position", function() {
            pave.fX2NDC = JSROOT.gStyle.fStatX;
            pave.fX1NDC = pave.fX2NDC - JSROOT.gStyle.fStatW;
            pave.fY2NDC = JSROOT.gStyle.fStatY;
            pave.fY1NDC = pave.fY2NDC - JSROOT.gStyle.fStatH;
            pave.fInit = 1;
            this.Redraw();
         });

         menu.add("SetStatFormat", function() {
            var fmt = prompt("Enter StatFormat", pave.fStatFormat);
            if (fmt!=null) {
               pave.fStatFormat = fmt;
               this.Redraw();
            }
         });
         menu.add("SetFitFormat", function() {
            var fmt = prompt("Enter FitFormat", pave.fFitFormat);
            if (fmt!=null) {
               pave.fFitFormat = fmt;
               this.Redraw();
            }
         });
         menu.add("separator");
         menu.add("sub:SetOptStat", function() {
            // todo - use jqury dialog here
            var fmt = prompt("Enter OptStat", pave.fOptStat);
            if (fmt!=null) { pave.fOptStat = parseInt(fmt); this.Redraw(); }
         });
         function AddStatOpt(pos, name) {
            var opt = (pos<10) ? pave.fOptStat : pave.fOptFit;
            opt = parseInt(parseInt(opt) / parseInt(Math.pow(10,pos % 10))) % 10;
            menu.addchk(opt, name, opt * 100 + pos, function(arg) {
               var newopt = (arg % 100 < 10) ? pave.fOptStat : pave.fOptFit;
               var oldopt = parseInt(arg / 100);
               newopt -= (oldopt>0 ? oldopt : -1) * parseInt(Math.pow(10, arg % 10));
               if (arg % 100 < 10) pave.fOptStat = newopt;
               else pave.fOptFit = newopt;
               this.Redraw();
            });
         }

         AddStatOpt(0, "Histogram name");
         AddStatOpt(1, "Entries");
         AddStatOpt(2, "Mean");
         AddStatOpt(3, "Std Dev");
         AddStatOpt(4, "Underflow");
         AddStatOpt(5, "Overflow");
         AddStatOpt(6, "Integral");
         AddStatOpt(7, "Skewness");
         AddStatOpt(8, "Kurtosis");
         menu.add("endsub:");

         menu.add("sub:SetOptFit", function() {
            // todo - use jqury dialog here
            var fmt = prompt("Enter OptStat", pave.fOptFit);
            if (fmt!=null) { pave.fOptFit = parseInt(fmt); this.Redraw(); }
         });
         AddStatOpt(10, "Fit parameters");
         AddStatOpt(11, "Par errors");
         AddStatOpt(12, "Chi square / NDF");
         AddStatOpt(13, "Probability");
         menu.add("endsub:");

         menu.add("separator");
      } else
      if (pave.fName === "title")
         menu.add("Default position", function() {
            pave.fX1NDC = 0.28;
            pave.fY1NDC = 0.94;
            pave.fX2NDC = 0.72;
            pave.fY2NDC = 0.99;
            pave.fInit = 1;
            this.Redraw();
         });

      if (this.UseTextColor)
         this.TextAttContextMenu(menu);

      this.FillAttContextMenu(menu);

      return menu.size() > 0;
   }

   JSROOT.TPavePainter.prototype.ShowContextMenu = function(evnt) {
      if (!evnt) {
         d3.event.stopPropagation(); // disable main context menu
         d3.event.preventDefault();  // disable browser context menu

         // one need to copy event, while after call back event may be changed
         evnt = d3.event;
      }

      JSROOT.Painter.createMenu(this, function(menu) {
         menu.painter.FillContextMenu(menu);
         menu.show(evnt);
      }); // end menu creation
   }

   JSROOT.TPavePainter.prototype.IsStats = function() {
      return this.MatchObjectType('TPaveStats');
   }

   JSROOT.TPavePainter.prototype.FillStatistic = function() {
      var pave = this.GetObject(), main = this.main_painter();

      if (pave.fName !== "stats") return false;
      if ((main===null) || !('FillStatistic' in main)) return false;

      // no need to refill statistic if histogram is dummy
      if (main.IsDummyHisto()) return true;

      var dostat = parseInt(pave.fOptStat), dofit = parseInt(pave.fOptFit);
      if (isNaN(dostat)) dostat = JSROOT.gStyle.fOptStat;
      if (isNaN(dofit)) dofit = JSROOT.gStyle.fOptFit;

      // make empty at the beginning
      pave.Clear();

      // we take statistic from first painter
      main.FillStatistic(this, dostat, dofit);

      return true;
   }

   JSROOT.TPavePainter.prototype.UpdateObject = function(obj) {
      if (!this.MatchObjectType(obj)) return false;

      var pave = this.GetObject();

      if (!('modified_NDC' in pave)) {
         // if position was not modified interactively, update from source object
         pave.fInit = obj.fInit;
         pave.fX1 = obj.fX1; pave.fX2 = obj.fX2;
         pave.fY1 = obj.fY1; pave.fY2 = obj.fY2;
         pave.fX1NDC = obj.fX1NDC; pave.fX2NDC = obj.fX2NDC;
         pave.fY1NDC = obj.fY1NDC; pave.fY2NDC = obj.fY2NDC;
      }

      if (obj._typename === 'TPaveText') {
         pave.fLines = JSROOT.clone(obj.fLines);
         return true;
      } else
      if (obj._typename === 'TPaveLabel') {
         pave.fLabel = obj.fLabel;
         return true;
      } else
      if (obj._typename === 'TPaveStats') {
         pave.fOptStat = obj.fOptStat;
         pave.fOptFit = obj.fOptFit;
         return true;
      } else
      if (obj._typename === 'TLegend') {
         pave.fPrimitives = obj.fPrimitives;
         pave.fNColumns = obj.fNColumns;
         return true;
      }

      return false;
   }

   JSROOT.TPavePainter.prototype.Redraw = function() {
      // if pavetext artificially disabled, do not redraw it

      this.DrawPave(true);
   }

   JSROOT.Painter.drawPaveText = function(divid, pave, opt) {

      // one could force drawing of PaveText on specific sub-pad
      var onpad = ((typeof opt == 'string') && (opt.indexOf("onpad:")==0)) ? opt.substr(6) : undefined;

      var painter = new JSROOT.TPavePainter(pave);
      painter.SetDivId(divid, 2, onpad);

      switch (pave._typename) {
         case "TPaveLabel":
            painter.PaveDrawFunc = painter.DrawPaveLabel;
            break;
         case "TPaveStats":
         case "TPaveText":
            painter.PaveDrawFunc = painter.DrawPaveText;
            break;
      }

      painter.Redraw();

      // drawing ready handled in special painters, if not exists - drawing is done
      if (!this.PaveDrawFunc) painter.DrawingReady();

      return painter;
   }

   // ===========================================================================

   JSROOT.TPadPainter = function(pad, iscan) {
      JSROOT.TObjectPainter.call(this, pad);
      this.pad = pad;
      this.iscan = iscan; // indicate if workign with canvas
      this.this_pad_name = "";
      if (!this.iscan && (pad !== null) && ('fName' in pad))
         this.this_pad_name = pad.fName.replace(" ", "_"); // avoid empty symbol in pad name
      this.painters = []; // complete list of all painters in the pad
      this.has_canvas = true;
   }

   JSROOT.TPadPainter.prototype = Object.create(JSROOT.TObjectPainter.prototype);


   JSROOT.TPadPainter.prototype.Cleanup = function() {
      // cleanup only pad itself, all child elements will be collected and cleanup separately

      var svg_p = this.svg_pad();
      if (svg_p) {
         svg_p.property('pad_painter', null);
         svg_p.property('mainpainter', null);
      }

      this.painters = [];
      this.pad = null;
      this.this_pad_name = "";
      this.has_canvas = false;

      JSROOT.TObjectPainter.prototype.Cleanup.call(this);
   }

   JSROOT.TPadPainter.prototype.ForEachPainterInPad = function(userfunc, onlypadpainters) {

      userfunc(this);

      for (var k = 0; k < this.painters.length; ++k) {
         var sub =  this.painters[k];

         if (typeof sub.ForEachPainterInPad === 'function')
            sub.ForEachPainterInPad(userfunc, onlypadpainters);
         else
         if (!onlypadpainters) userfunc(sub);
      }
   }

   JSROOT.TPadPainter.prototype.ButtonSize = function(fact) {
      return Math.round((!fact ? 1 : fact) * (this.iscan || !this.has_canvas ? 16 : 12));
   }

   JSROOT.TPadPainter.prototype.ToggleEventStatus = function() {
      // when function called, jquery should be already loaded

      if (this.enlarge_main('state')==='on') return;

      this.has_event_status = !this.has_event_status;
      if (JSROOT.Painter.ShowStatus) this.has_event_status = false;

      var resized = this.layout_main(this.has_event_status || this._websocket ? "canvas" : "simple");

      var footer = this.select_main('footer');

      if (!this.has_event_status) {
         footer.html("");
         delete this.status_layout;
         delete this.ShowStatus;
         delete this.ShowStatusFunc;
      } else {

         this.status_layout = new JSROOT.GridDisplay(footer.node(), 'horizx4_1213');

         var frame_titles = ['object name','object title','mouse coordiantes','object info'];
         for (var k=0;k<4;++k)
            d3.select(this.status_layout.GetFrame(k)).attr('title', frame_titles[k]).style('overflow','hidden')
            .append("label").attr("class","jsroot_status_label");

         this.ShowStatusFunc = function(name, title, info, coordinates) {
            if (!this.status_layout) return;
            $(this.status_layout.GetFrame(0)).children('label').text(name || "");
            $(this.status_layout.GetFrame(1)).children('label').text(title || "");
            $(this.status_layout.GetFrame(2)).children('label').text(coordinates || "");
            $(this.status_layout.GetFrame(3)).children('label').text(info || "");
         }

         this.ShowStatus = this.ShowStatusFunc.bind(this);

         this.ShowStatus("canvas","title","info","");
      }

      if (resized) this.CheckCanvasResize(); // redraw with resize
   }

   JSROOT.TPadPainter.prototype.ShowCanvasMenu = function(name) {

      d3.event.stopPropagation(); // disable main context menu
      d3.event.preventDefault();  // disable browser context menu

      var evnt = d3.event;

      function HandleClick(arg) {
         if (!this._websocket) return;
         console.log('click', arg);

         if (arg=="Interrupt") { this._websocket.send("GEXE:gROOT->SetInterrupt()"); }
         if (arg=="Quit ROOT") { this._websocket.send("GEXE:gApplication->Terminate(0)"); }
      }

      JSROOT.Painter.createMenu(this, function(menu) {

         switch(name) {
            case "File": {
               menu.add("Close canvas", HandleClick);
               menu.add("separator");
               menu.add("Save PNG", HandleClick);
               var ext = ["ps","eps","pdf","tex","gif","jpg","png","C","root"];
               menu.add("sub:Save");
               for (var k in ext) menu.add("canvas."+ext[k], HandleClick);
               menu.add("endsub:");
               menu.add("separator");
               menu.add("Interrupt", HandleClick);
               menu.add("separator");
               menu.add("Quit ROOT", HandleClick);
               break;
            }
            case "Edit":
               menu.add("Clear pad", HandleClick);
               menu.add("Clear canvas", HandleClick);
               break;
            case "View": {
               menu.addchk(menu.painter.has_event_status, "Event status", menu.painter.ToggleEventStatus.bind(menu.painter));
               var fp = menu.painter.frame_painter();
               menu.addchk(fp && fp.tooltip_allowed, "Tooltip info", function() { if (fp) fp.tooltip_allowed = !fp.tooltip_allowed; });
               break;
            }
            case "Options": {
               var main = menu.painter.main_painter();
               menu.addchk(main && main.ToggleStat('only-check'), "Statistic", function() { if (main) main.ToggleStat(); });
               menu.addchk(main && main.ToggleTitle('only-check'), "Histogram title",  function() { if (main) main.ToggleTitle(); });
               menu.addchk(main && main.ToggleStat('fitpar-check'), "Fit parameters", function() { if (main) main.ToggleStat('fitpar-toggle'); });
               break;
            }
            case "Tools":
               menu.add("Inspector", HandleClick);
               break;
            case "Help":
               menu.add("header:Basic help on...");
               menu.add("Canvas", HandleClick);
               menu.add("Menu", HandleClick);
               menu.add("Browser", HandleClick);
               menu.add("separator");
               menu.add("About ROOT", HandleClick);
               break;
         }
         if (menu.size()>0) menu.show(evnt);
      });
   }

   JSROOT.TPadPainter.prototype.CreateCanvasMenu = function() {

      if (this.enlarge_main('state')==='on') return;

      this.layout_main("canvas");

      var header = this.select_main('header');

      header.html("").style('background','lightgrey');

      var items = ['File','Edit','View','Options','Tools','Help'];
      var painter = this;
      for (var k in items) {
         var elem = header.append("p").attr("class","canvas_menu").text(items[k]);
         if (items[k]=='Help') elem.style('float','right');
         elem.on('click', this.ShowCanvasMenu.bind(this, items[k]));
      }
   }

   JSROOT.TPadPainter.prototype.CreateCanvasSvg = function(check_resize, new_size) {

      var factor = null, svg = null, lmt = 5, rect = null;

      if (check_resize > 0) {

         svg = this.svg_canvas();

         factor = svg.property('height_factor');

         rect = this.check_main_resize(check_resize, null, factor);

         if (!rect.changed) return false;

      } else {

         if (this._websocket)
            this.CreateCanvasMenu();

         var render_to = this.select_main();

         if (render_to.style('position')=='static')
            render_to.style('position','relative');

         svg = render_to.append("svg")
             .attr("class", "jsroot root_canvas")
             .property('pad_painter', this) // this is custom property
             .property('mainpainter', null) // this is custom property
             .property('current_pad', "") // this is custom property
             .property('redraw_by_resize', false); // could be enabled to force redraw by each resize

         svg.append("svg:title").text("ROOT canvas");
         var frect = svg.append("svg:rect").attr("class","canvas_fillrect")
                               .attr("x",0).attr("y",0);
         if (!JSROOT.BatchMode)
            frect.style("pointer-events", "visibleFill")
                 .on("dblclick", this.EnlargePad.bind(this))
                 .on("mouseenter", this.ShowObjectStatus.bind(this))

         svg.append("svg:g").attr("class","root_frame");
         svg.append("svg:g").attr("class","subpads_layer");
         svg.append("svg:g").attr("class","special_layer");
         svg.append("svg:g").attr("class","text_layer");
         svg.append("svg:g").attr("class","stat_layer");
         svg.append("svg:g").attr("class","btns_layer");

         if (JSROOT.gStyle.ContextMenu)
            svg.select(".canvas_fillrect").on("contextmenu", this.ShowContextMenu.bind(this));

         factor = 0.66;
         if (this.pad && this.pad.fCw && this.pad.fCh && (this.pad.fCw > 0)) {
            factor = this.pad.fCh / this.pad.fCw;
            if ((factor < 0.1) || (factor > 10)) factor = 0.66;
         }

         rect = this.check_main_resize(2, new_size, factor);
      }

      if (!this.fillatt || !this.fillatt.changed)
         this.fillatt = this.createAttFill(this.pad, 1001, 0);

      if ((rect.width<=lmt) || (rect.height<=lmt)) {
         svg.style("display", "none");
         console.warn("Hide canvas while geometry too small w=",rect.width," h=",rect.height);
         rect.width = 200; rect.height = 100; // just to complete drawing
      } else {
         svg.style("display", null);
      }

      svg.attr("x", 0)
         .attr("y", 0)
         .style("width", "100%")
         .style("height", "100%")
         .style("position", "absolute")
         .style("left", 0)
         .style("top", 0)
         .style("right", 0)
         .style("bottom", 0);

      svg.attr("viewBox", "0 0 " + rect.width + " " + rect.height)
         .attr("preserveAspectRatio", "none")  // we do not preserve relative ratio
         .property('height_factor', factor)
         .property('draw_x', 0)
         .property('draw_y', 0)
         .property('draw_width', rect.width)
         .property('draw_height', rect.height);

      svg.select(".canvas_fillrect")
         .attr("width",rect.width)
         .attr("height",rect.height)
         .call(this.fillatt.func);

      this.svg_layer("btns_layer")
          .attr("transform","translate(2," + (rect.height - this.ButtonSize(1.25)) + ")")
          .attr("display", svg.property("pad_enlarged") ? "none" : null); // hide buttons when sub-pad is enlarged

      return true;
   }

   JSROOT.TPadPainter.prototype.EnlargePad = function() {

      if (d3.event) {
         d3.event.preventDefault();
         d3.event.stopPropagation();
      }

      var svg_can = this.svg_canvas(),
          pad_enlarged = svg_can.property("pad_enlarged");

      if (this.iscan || !this.has_canvas || (!pad_enlarged && !this.HasObjectsToDraw())) {
         if (!this.enlarge_main('toggle')) return;
         if (this.enlarge_main('state')=='off') svg_can.property("pad_enlarged", null);
      } else {
         if (!pad_enlarged) {
            this.enlarge_main(true);
            svg_can.property("pad_enlarged", this.pad);
         } else
         if (pad_enlarged === this.pad) {
            this.enlarge_main(false);
            svg_can.property("pad_enlarged", null);
         } else {
            console.error('missmatch with pad double click events');
         }
      }

      this.CheckResize({force:true});
   }

   JSROOT.TPadPainter.prototype.CreatePadSvg = function(only_resize) {
      // returns true when pad is displayed and all its items should be redrawn

      if (!this.has_canvas) {
         this.CreateCanvasSvg(only_resize ? 2 : 0);
         return true;
      }

      var svg_can = this.svg_canvas(),
          width = svg_can.property("draw_width"),
          height = svg_can.property("draw_height"),
          pad_enlarged = svg_can.property("pad_enlarged"),
          pad_visible = !pad_enlarged || (pad_enlarged === this.pad),
          w = Math.round(this.pad.fAbsWNDC * width),
          h = Math.round(this.pad.fAbsHNDC * height),
          x = Math.round(this.pad.fAbsXlowNDC * width),
          y = Math.round(height * (1 - this.pad.fAbsYlowNDC)) - h,
          svg_pad = null, svg_rect = null, btns = null;

      if (pad_enlarged === this.pad) { w = width; h = height; x = y = 0; }

      if (only_resize) {
         svg_pad = this.svg_pad(this.this_pad_name);
         svg_rect = svg_pad.select(".root_pad_border");
         btns = this.svg_layer("btns_layer", this.this_pad_name);
      } else {
         svg_pad = svg_can.select(".subpads_layer")
             .append("g")
             .attr("class", "root_pad")
             .attr("pad", this.this_pad_name) // set extra attribute  to mark pad name
             .property('pad_painter', this) // this is custom property
             .property('mainpainter', null); // this is custom property
         svg_rect = svg_pad.append("svg:rect").attr("class", "root_pad_border");

         svg_pad.append("svg:g").attr("class","root_frame");
         svg_pad.append("svg:g").attr("class","special_layer");
         svg_pad.append("svg:g").attr("class","text_layer");
         svg_pad.append("svg:g").attr("class","stat_layer");
         btns = svg_pad.append("svg:g").attr("class","btns_layer");

         if (JSROOT.gStyle.ContextMenu)
            svg_rect.on("contextmenu", this.ShowContextMenu.bind(this));

         if (!JSROOT.BatchMode)
            svg_rect.attr("pointer-events", "visibleFill") // get events also for not visisble rect
                    .on("dblclick", this.EnlargePad.bind(this))
                    .on("mouseenter", this.ShowObjectStatus.bind(this));

         if (!this.fillatt || !this.fillatt.changed)
            this.fillatt = this.createAttFill(this.pad, 1001, 0);
         if (!this.lineatt || !this.lineatt.changed)
            this.lineatt = JSROOT.Painter.createAttLine(this.pad);
         if (this.pad.fBorderMode == 0) this.lineatt.color = 'none';
      }

      svg_pad.attr("transform", "translate(" + x + "," + y + ")")
             .attr("display", pad_visible ? null : "none")
             .property('draw_x', x) // this is to make similar with canvas
             .property('draw_y', y)
             .property('draw_width', w)
             .property('draw_height', h);

      svg_rect.attr("x", 0)
              .attr("y", 0)
              .attr("width", w)
              .attr("height", h)
              .call(this.fillatt.func)
              .call(this.lineatt.func);

      if (svg_pad.property('can3d') === 1)
         // special case of 3D canvas overlay
          this.select_main()
              .select(".draw3d_" + this.this_pad_name)
              .style('display', pad_visible ? '' : 'none');

      btns.attr("transform","translate("+ (w - (btns.property('nextx') || 0) - this.ButtonSize(1.25)) + "," + (h - this.ButtonSize(1.25)) + ")");

      return pad_visible;
   }

   JSROOT.TPadPainter.prototype.CheckColors = function(can) {
      if (!can || !can.fPrimitives) return;

      for (var i = 0; i < can.fPrimitives.arr.length; ++i) {
         var obj = can.fPrimitives.arr[i];
         if (obj==null) continue;
         if ((obj._typename=="TObjArray") && (obj.name == "ListOfColors")) {
            JSROOT.Painter.adoptRootColors(obj);
            can.fPrimitives.arr.splice(i,1);
            can.fPrimitives.opt.splice(i,1);
            return;
         }
      }
   }

   JSROOT.TPadPainter.prototype.RemovePrimitive = function(obj) {
      if ((this.pad===null) || (this.pad.fPrimitives === null)) return;
      var indx = this.pad.fPrimitives.arr.indexOf(obj);
      if (indx>=0) this.pad.fPrimitives.RemoveAt(indx);
   }

   JSROOT.TPadPainter.prototype.FindPrimitive = function(exact_obj, classname, name) {
      if ((this.pad===null) || (this.pad.fPrimitives === null)) return null;

      for (var i=0; i < this.pad.fPrimitives.arr.length; i++) {
         var obj = this.pad.fPrimitives.arr[i];

         if ((exact_obj!==null) && (obj !== exact_obj)) continue;

         if ((classname !== undefined) && (classname !== null))
            if (obj._typename !== classname) continue;

         if ((name !== undefined) && (name !== null))
            if (obj.fName !== name) continue;

         return obj;
      }

      return null;
   }

   JSROOT.TPadPainter.prototype.HasObjectsToDraw = function() {
      // return true if any objects beside sub-pads exists in the pad

      if ((this.pad===null) || !this.pad.fPrimitives || (this.pad.fPrimitives.arr.length==0)) return false;

      for (var n=0;n<this.pad.fPrimitives.arr.length;++n)
         if (this.pad.fPrimitives.arr[n] && this.pad.fPrimitives.arr[n]._typename != "TPad") return true;

      return false;
   }

   JSROOT.TPadPainter.prototype.DrawPrimitive = function(indx, callback) {
      if (!this.pad || (indx >= this.pad.fPrimitives.arr.length))
         return JSROOT.CallBack(callback);

      var pp = JSROOT.draw(this.divid, this.pad.fPrimitives.arr[indx], this.pad.fPrimitives.opt[indx], this.DrawPrimitive.bind(this, indx+1, callback));
      if (pp) pp._primitive = true; // mark painter as belonging to primitives
   }

   JSROOT.TPadPainter.prototype.GetTooltips = function(pnt) {
      var painters = [], hints = [];

      // first count - how many processors are there
      if (this.painters !== null)
         this.painters.forEach(function(obj) {
            if ('ProcessTooltip' in obj) painters.push(obj);
         });

      if (pnt) pnt.nproc = painters.length;

      painters.forEach(function(obj) {
         var hint = obj.ProcessTooltip(pnt);
         hints.push(hint);
         if (hint && pnt.painters) hint.painter = obj;
      });

      return hints;
   }

   JSROOT.TPadPainter.prototype.FillContextMenu = function(menu) {

      if (this.pad)
         menu.add("header: " + this.pad._typename + "::" + this.pad.fName);
      else
         menu.add("header: Canvas");

      menu.addchk((JSROOT.gStyle.Tooltip > 0), "Enable tooltips (global)", function() {
         JSROOT.gStyle.Tooltip = (JSROOT.gStyle.Tooltip === 0) ? 1 : -JSROOT.gStyle.Tooltip;
         var can_painter = this;
         if (!this.iscan && this.has_canvas) can_painter = this.pad_painter();
         if (can_painter && can_painter.ForEachPainterInPad)
            can_painter.ForEachPainterInPad(function(fp) {
               if (fp.tooltip_allowed!==undefined) fp.tooltip_allowed = (JSROOT.gStyle.Tooltip > 0);
            });
      });

      if (!this._websocket) {

         function ToggleField(arg) {
            this.pad[arg] = this.pad[arg] ? 0 : 1;
            var main = this.svg_pad(this.this_pad_name).property('mainpainter');
            if (!main) return;

            if ((arg.indexOf('fGrid')==0) && (typeof main.DrawGrids == 'function'))
               return main.DrawGrids();

            if ((arg.indexOf('fTick')==0) && (typeof main.DrawAxes == 'function'))
               return main.DrawAxes();
         }

         menu.addchk(this.pad.fGridx, 'Grid x', 'fGridx', ToggleField);
         menu.addchk(this.pad.fGridy, 'Grid y', 'fGridy', ToggleField);
         menu.addchk(this.pad.fTickx, 'Tick x', 'fTickx', ToggleField);
         menu.addchk(this.pad.fTicky, 'Tick y', 'fTicky', ToggleField);

         this.FillAttContextMenu(menu);
      }

      menu.add("separator");

      menu.addchk(this.has_event_status, "Event status", this.ToggleEventStatus.bind(this));

      if (this.enlarge_main() || (this.has_canvas && this.HasObjectsToDraw()))
         menu.addchk((this.enlarge_main('state')=='on'), "Enlarge " + (this.iscan ? "canvas" : "pad"), this.EnlargePad.bind(this));

      var fname = this.this_pad_name;
      if (fname.length===0) fname = this.iscan ? "canvas" : "pad";
      fname += ".png";

      menu.add("Save as "+fname, fname, this.SaveAsPng.bind(this, false));

      return true;
   }

   JSROOT.TPadPainter.prototype.ShowContextMenu = function(evnt) {
      if (!evnt) {

         // for debug purposes keep original context menu for small region in top-left corner
         var pos = d3.mouse(this.svg_pad(this.this_pad_name).node());
         if (pos && (pos.length==2) && (pos[0]>0) && (pos[0]<10) && (pos[1]>0) && pos[1]<10) return;

         d3.event.stopPropagation(); // disable main context menu
         d3.event.preventDefault();  // disable browser context menu

         // one need to copy event, while after call back event may be changed
         evnt = d3.event;
      }

      JSROOT.Painter.createMenu(this, function(menu) {

         menu.painter.FillContextMenu(menu);

         menu.painter.FillObjectExecMenu(menu, function() { menu.show(evnt); });
      }); // end menu creation
   }

   JSROOT.TPadPainter.prototype.Redraw = function(resize) {

      var showsubitems = true;

      if (this.iscan) {
         this.CreateCanvasSvg(2);
      } else {
         showsubitems = this.CreatePadSvg(true);
      }

      // even sub-pad is not visisble, we should redraw sub-sub-pads to hide them as well
      for (var i = 0; i < this.painters.length; ++i) {
         var sub = this.painters[i];
         if (showsubitems || sub.this_pad_name) sub.Redraw(resize);
      }
   }

   JSROOT.TPadPainter.prototype.NumDrawnSubpads = function() {
      if (this.painters === undefined) return 0;

      var num = 0;

      for (var i = 0; i < this.painters.length; ++i) {
         var obj = this.painters[i].GetObject();
         if ((obj!==null) && (obj._typename === "TPad")) num++;
      }

      return num;
   }

   JSROOT.TPadPainter.prototype.RedrawByResize = function() {
      if (this.access_3d_kind() === 1) return true;

      for (var i = 0; i < this.painters.length; ++i)
         if (typeof this.painters[i].RedrawByResize === 'function')
            if (this.painters[i].RedrawByResize()) return true;

      return false;
   }

   JSROOT.TPadPainter.prototype.CheckCanvasResize = function(size, force) {

      if (!this.iscan && this.has_canvas) return false;

      if (size && (typeof size === 'object') && size.force) force = true;

      if (!force) force = this.RedrawByResize();

      var changed = this.CreateCanvasSvg(force ? 2 : 1, size);

      // if canvas changed, redraw all its subitems.
      // If redrawing was forced for canvas, same applied for sub-elements
      if (changed)
         for (var i = 0; i < this.painters.length; ++i)
            this.painters[i].Redraw(force ? false : true);

      return changed;
   }

   JSROOT.TPadPainter.prototype.UpdateObject = function(obj) {
      if (!obj) return false;

      this.pad.fGridx = obj.fGridx;
      this.pad.fGridy = obj.fGridy;
      this.pad.fTickx = obj.fTickx;
      this.pad.fTicky = obj.fTicky;
      this.pad.fLogx  = obj.fLogx;
      this.pad.fLogy  = obj.fLogy;
      this.pad.fLogz  = obj.fLogz;

      this.pad.fUxmin = obj.fUxmin;
      this.pad.fUxmax = obj.fUxmax;
      this.pad.fUymin = obj.fUymin;
      this.pad.fUymax = obj.fUymax;

      this.pad.fLeftMargin   = obj.fLeftMargin;
      this.pad.fRightMargin  = obj.fRightMargin;
      this.pad.fBottomMargin = obj.fBottomMargin
      this.pad.fTopMargin    = obj.fTopMargin;

      this.pad.fFillColor = obj.fFillColor;
      this.pad.fFillStyle = obj.fFillStyle;
      this.pad.fLineColor = obj.fLineColor;
      this.pad.fLineStyle = obj.fLineStyle;
      this.pad.fLineWidth = obj.fLineWidth;

      if (this.iscan) this.CheckColors(obj);

      var fp = this.frame_painter();
      if (fp) fp.UpdateAttributes(!fp.modified_NDC);

      if (!obj.fPrimitives) return false;

      var isany = false, p = 0;
      for (var n = 0; n < obj.fPrimitives.arr.length; ++n) {
         while (p < this.painters.length) {
            var pp = this.painters[p++];
            if (!pp._primitive) continue;
            if (pp.UpdateObject(obj.fPrimitives.arr[n])) isany = true;
            break;
         }
      }

      return isany;
   }

   JSROOT.TPadPainter.prototype.DrawNextSnap = function(lst, indx, call_back, objpainter) {
      // function called when drawing next snapshot from the list
      // it is also used as callback for drawing of previous snap

      // console.log('Draw next snap', indx);

      if (objpainter && lst && lst.arr[indx]) {
         // keep snap id in painter, will be used for the
         if (this.painters.indexOf(objpainter)<0) this.painters.push(objpainter);
         objpainter.snapid = lst.arr[indx].fObjectID;
      }

      ++indx; // change to the next snap

      if (!lst || indx >= lst.arr.length) return JSROOT.CallBack(call_back, this);

      var snap = lst.arr[indx], painter = null;

      // first find existing painter for the object
      for (var k=0; k<this.painters.length; ++k) {
         if (this.painters[k].snapid === snap.fObjectID) { painter = this.painters[k]; break;  }
      }

      // function which should be called when drawing of next item finished
      var draw_callback = this.DrawNextSnap.bind(this, lst, indx, call_back);

      if (painter) {
         if (typeof painter.RedrawSnap==='function')
            return painter.RedrawSnap(snap, draw_callback);

         if (snap.fKind === 1) { // object itself
            if (painter.UpdateObject(snap.fSnapshot)) painter.Redraw();
            return draw_callback(painter); // call next
         }

         if (snap.fKind === 2) { // update SVG
            if (painter.UpdateObject(snap.fSnapshot)) painter.Redraw();
            return draw_callback(painter); // call next
         }

         return draw_callback(painter); // call next
      }

      // here the case of normal drawing, can be improved
      if (snap.fKind === 1) {
         var obj = snap.fSnapshot;
         if (obj) obj.$snapid = snap.fObjectID; // mark object itself, workaround for stats drawing
         return JSROOT.draw(this.divid, obj, snap.fOption, draw_callback);
      }

      if (snap.fKind === 2)
         return JSROOT.draw(this.divid, snap.fSnapshot, snap.fOption, draw_callback);

      draw_callback(null);
   }

   JSROOT.TPadPainter.prototype.FindSnap = function(snapid) {

      if (this.snapid === snapid) return this;

      if (!this.painters) return null;

      for (var k=0;k<this.painters.length;++k) {
         var sub = this.painters[k];

         if (typeof sub.FindSnap === 'function') sub = sub.FindSnap(snapid);
         else if (sub.snapid !== snapid) sub = null;

         if (sub) return sub;
      }

      return null;
   }

   JSROOT.TPadPainter.prototype.RedrawSnap = function(snap, call_back) {
      // for the canvas snapshot constains list of objects
      // as first entry, graphical properties of canvas itself is provided
      // in ROOT6 it also includes primitives, but we ignore them

      if (!snap || !snap.arr) return;

      var first = snap.arr[0].fSnapshot;
      first.fPrimitives = null; // primitives are not interesting, just cannot disable in IO

      // console.log('REDRAW SNAP');

      if (this.snapid === undefined) {
         // first time getting snap, create all gui elements first

         this.snapid = snap.arr[0].fObjectID;

         this.draw_object = first;
         this.pad = first;

         this.CreateCanvasSvg(0);
         this.SetDivId(this.divid);  // now add to painters list

         this.AddButton(JSROOT.ToolbarIcons.camera, "Create PNG", "CanvasSnapShot", "Ctrl PrintScreen");
         if (JSROOT.gStyle.ContextMenu)
            this.AddButton(JSROOT.ToolbarIcons.question, "Access context menus", "PadContextMenus");

         if (this.enlarge_main('verify'))
            this.AddButton(JSROOT.ToolbarIcons.circle, "Enlarge canvas", "EnlargePad");

         JSROOT.Painter.drawFrame(this.divid, null);

         this.DrawNextSnap(snap, 0, call_back);

         return;

      }

      this.UpdateObject(first); // update only object attributes

      // apply all changes in the object (pad or canvas)
      if (this.iscan) {
         this.CreateCanvasSvg(2);
      } else {
         this.CreatePadSvg(true);
      }

      // find and remove painters which no longer exists in the list
      for (var k=0;k<this.painters.length;++k) {
         var sub = this.painters[k];
         if (sub.snapid===undefined) continue; // look only for painters with snapid

         for (var i=1;i<snap.arr.length;++i)
            if (snap.arr[i].fObjectID === sub.snapid) { sub = null; break; }

         if (sub) {
            // remove painter which does not found in the list of snaps
            this.painters.splice(k--,1);
            sub.Cleanup(); // cleanup such painter
         }
      }

      this.DrawNextSnap(snap, 0, call_back, null); // update all snaps after each other

      // show we redraw all other painters without snapid?
   }


   JSROOT.TPadPainter.prototype.ItemContextMenu = function(name) {
       var rrr = this.svg_pad(this.this_pad_name).node().getBoundingClientRect();
       var evnt = { clientX: rrr.left+10, clientY: rrr.top + 10 };

       // use timeout to avoid conflict with mouse click and automatic menu close
       if (name=="pad")
          return setTimeout(this.ShowContextMenu.bind(this, evnt), 50);

       var selp = null, selkind;

       switch(name) {
          case "xaxis":
          case "yaxis":
          case "zaxis":
             selp = this.main_painter();
             selkind = name[0];
             break;
          case "frame":
             selp = this.frame_painter();
             break;
          default: {
             var indx = parseInt(name);
             if (!isNaN(indx)) selp = this.painters[indx];
          }
       }

       if (!selp || (typeof selp.FillContextMenu !== 'function')) return;

       JSROOT.Painter.createMenu(selp, function(menu) {
          if (selp.FillContextMenu(menu,selkind))
             setTimeout(menu.show.bind(menu, evnt), 50);
       });

   }

   JSROOT.TPadPainter.prototype.SaveAsPng = function(full_canvas, filename, call_back) {
      if (!filename) {
         filename = this.this_pad_name;
         if (filename.length === 0) filename = this.iscan ? "canvas" : "pad";
         filename += ".png";
      }

      var elem = full_canvas ? this.svg_canvas() : this.svg_pad(this.this_pad_name);

      if (elem.empty()) return;

      var painter = full_canvas ? this.pad_painter() : this;

      document.body.style.cursor = 'wait';

      painter.ForEachPainterInPad(function(pp) {

         var main = pp.main_painter(true, pp.this_pad_name);
         if (!main || (typeof main.Render3D !== 'function')) return;

         var can3d = main.access_3d_kind();
         if ((can3d !== 1) && (can3d !== 2)) return;

         var sz = main.size_for_3d(3); // get size for SVG canvas

         var svg3d = main.Render3D(-1111); // render SVG

         //var rrr = new THREE.SVGRenderer({ antialias : true, alpha: true });
         //rrr.setSize(sz.width, sz.height);
         //rrr.render(main.scene, main.camera);

         var svg = d3.select(svg3d);

         var layer = main.svg_layer("special_layer");
         group = layer.append("g")
                      .attr("class","temp_saveaspng")
                      .attr("transform", "translate(" + sz.x + "," + sz.y + ")");
         group.node().appendChild(svg3d);
      }, true);

//      if (((can3d === 1) || (can3d === 2)) && main && main.Render3D) {
           // this was saving of image buffer from 3D render
//         var canvas = main.renderer.domElement;
//         main.Render3D(0); // WebGL clears buffers, therefore we should render scene and convert immedaitely
//         var dataUrl = canvas.toDataURL("image/png");
//         dataUrl.replace("image/png", "image/octet-stream");
//         var link = document.createElement('a');
//         if (typeof link.download === 'string') {
//            document.body.appendChild(link); //Firefox requires the link to be in the body
//            link.download = filename;
//            link.href = dataUrl;
//            link.click();
//            document.body.removeChild(link); //remove the link when done
//         }
//      } else


      var options = { name: filename, removeClass: "btns_layer" };
      if (call_back) options.result = "svg";

      JSROOT.saveSvgAsPng(elem.node(), options , function(res) {

         if (res===null) console.warn('problem when produce image');

         elem.selectAll(".temp_saveaspng").remove();

         document.body.style.cursor = 'auto';

         if (call_back) JSROOT.CallBack(call_back, res);
      });

   }

   JSROOT.TPadPainter.prototype.PadButtonClick = function(funcname) {

      if (funcname == "CanvasSnapShot") return this.SaveAsPng(true);

      if (funcname == "EnlargePad") return this.EnlargePad();

      if (funcname == "PadSnapShot") return this.SaveAsPng(false);

      if (funcname == "PadContextMenus") {

         d3.event.preventDefault();
         d3.event.stopPropagation();

         if (JSROOT.Painter.closeMenu()) return;

         var pthis = this, evnt = d3.event;

         JSROOT.Painter.createMenu(pthis, function(menu) {
            menu.add("header:Menus");

            if (pthis.iscan)
               menu.add("Canvas", "pad", pthis.ItemContextMenu);
            else
               menu.add("Pad", "pad", pthis.ItemContextMenu);

            if (pthis.frame_painter())
               menu.add("Frame", "frame", pthis.ItemContextMenu);

            var main = pthis.main_painter();

            if (main) {
               menu.add("X axis", "xaxis", pthis.ItemContextMenu);
               menu.add("Y axis", "yaxis", pthis.ItemContextMenu);
               if ((typeof main.Dimension === 'function') && (main.Dimension() > 1))
                  menu.add("Z axis", "zaxis", pthis.ItemContextMenu);
            }

            if (pthis.painters && (pthis.painters.length>0)) {
               menu.add("separator");
               var shown = [];
               for (var n=0;n<pthis.painters.length;++n) {
                  var pp = pthis.painters[n];
                  var obj = pp ? pp.GetObject() : null;
                  if (!obj || (shown.indexOf(obj)>=0)) continue;

                  var name = ('_typename' in obj) ? (obj._typename + "::") : "";
                  if ('fName' in obj) name += obj.fName;
                  if (name.length==0) name = "item" + n;
                  menu.add(name, n, pthis.ItemContextMenu);
               }
            }

            menu.show(evnt);
         });

         return;
      }

      // click automatically goes to all sub-pads
      // if any painter indicates that processing completed, it returns true
      var done = false;

      for (var i = 0; i < this.painters.length; ++i) {
         var pp = this.painters[i];

         if (typeof pp.PadButtonClick == 'function')
            pp.PadButtonClick(funcname);

         if (!done && (typeof pp.ButtonClick == 'function'))
            done = pp.ButtonClick(funcname);
      }
   }

   JSROOT.TPadPainter.prototype.FindButton = function(keyname) {
      var group = this.svg_layer("btns_layer", this.this_pad_name);
      if (group.empty()) return;

      var found_func = "";

      group.selectAll("svg").each(function() {
         if (d3.select(this).attr("key") === keyname)
            found_func = d3.select(this).attr("name");
      });

      return found_func;

   }

   JSROOT.TPadPainter.prototype.toggleButtonsVisibility = function(action) {
      var group = this.svg_layer("btns_layer", this.this_pad_name),
          btn = group.select("[name='Toggle']");

      if (btn.empty()) return;

      var state = btn.property('buttons_state');

      if (btn.property('timout_handler')) {
         if (action!=='timeout') clearTimeout(btn.property('timout_handler'));
         btn.property('timout_handler', null);
      }

      var is_visible = false;
      switch(action) {
         case 'enable': is_visible = true; break;
         case 'enterbtn': return; // do nothing, just cleanup timeout
         case 'timeout': isvisible = false; break;
         case 'toggle': {
            state = !state; btn.property('buttons_state', state);
            is_visible = state;
            break;
         }
         case 'disable':
         case 'leavebtn': {
            if (state) return;
            return btn.property('timout_handler', setTimeout(this.toggleButtonsVisibility.bind(this,'timeout'),500));
         }
      }

      group.selectAll('svg').each(function() {
         if (this===btn.node()) return;
         d3.select(this).style('display', is_visible ? "" : "none");
      });
   }

   JSROOT.TPadPainter.prototype.AddButton = function(btn, tooltip, funcname, keyname) {

      // do not add buttons when not allowed
      if (!JSROOT.gStyle.ToolBar) return;

      var group = this.svg_layer("btns_layer", this.this_pad_name);
      if (group.empty()) return;

      // avoid buttons with duplicate names
      if (!group.select("[name='" + funcname + "']").empty()) return;

      var iscan = this.iscan || !this.has_canvas, ctrl;

      var x = group.property("nextx");
      if (!x) {
         ctrl = JSROOT.ToolbarIcons.CreateSVG(group, JSROOT.ToolbarIcons.rect, this.ButtonSize(), "Toggle tool buttons");

         ctrl.attr("name", "Toggle").attr("x", 0).attr("y", 0).attr("normalx",0)
             .property("buttons_state", (JSROOT.gStyle.ToolBar!=='popup'))
             .on("click", this.toggleButtonsVisibility.bind(this, 'toggle'))
             .on("mouseenter", this.toggleButtonsVisibility.bind(this, 'enable'))
             .on("mouseleave", this.toggleButtonsVisibility.bind(this, 'disable'));

         x = iscan ? this.ButtonSize(1.25) : 0;
      } else {
         ctrl = group.select("[name='Toggle']");
      }

      var svg = JSROOT.ToolbarIcons.CreateSVG(group, btn, this.ButtonSize(),
            tooltip + (iscan ? "" : (" on pad " + this.this_pad_name)) + (keyname ? " (keyshortcut " + keyname + ")" : ""));

      svg.attr("name", funcname).attr("x", x).attr("y", 0).attr("normalx",x)
         .style('display', (ctrl.property("buttons_state") ? '' : 'none'))
         .on("mouseenter", this.toggleButtonsVisibility.bind(this, 'enterbtn'))
         .on("mouseleave", this.toggleButtonsVisibility.bind(this, 'leavebtn'));

      if (keyname) svg.attr("key", keyname);

      svg.on("click", this.PadButtonClick.bind(this, funcname));

      group.property("nextx", x + this.ButtonSize(1.25));

      if (!iscan) {
         group.attr("transform","translate("+ (this.pad_width(this.this_pad_name) - group.property('nextx') - this.ButtonSize(1.25)) + "," + (this.pad_height(this.this_pad_name)-this.ButtonSize(1.25)) + ")");
         ctrl.attr("x", group.property('nextx'));
      }

      if (!iscan && (funcname.indexOf("Pad")!=0) && (this.pad_painter()!==this) && (funcname !== "EnlargePad"))
         this.pad_painter().AddButton(btn, tooltip, funcname);
   }

   JSROOT.TPadPainter.prototype.DecodeOptions = function(opt) {
      var pad = this.GetObject();
      if (!pad) return;

      var d = new JSROOT.DrawOptions(opt);

      if (d.check('WEBSOCKET')) this.OpenWebsocket();

      if (d.check('WHITE')) pad.fFillColor = 0;
      if (d.check('LOGX')) pad.fLogx = 1;
      if (d.check('LOGY')) pad.fLogy = 1;
      if (d.check('LOGZ')) pad.fLogz = 1;
      if (d.check('LOG')) pad.fLogx = pad.fLogy = pad.fLogz = 1;
      if (d.check('GRIDX')) pad.fGridx = 1;
      if (d.check('GRIDY')) pad.fGridy = 1;
      if (d.check('GRID')) pad.fGridx = pad.fGridy = 1;
      if (d.check('TICKX')) pad.fTickx = 1;
      if (d.check('TICKY')) pad.fTicky = 1;
      if (d.check('TICK')) pad.fTickx = pad.fTicky = 1;
   }

   JSROOT.Painter.drawCanvas = function(divid, can, opt) {
      var nocanvas = (can===null);
      if (nocanvas) can = JSROOT.Create("TCanvas");

      var painter = new JSROOT.TPadPainter(can, true);
      painter.DecodeOptions(opt);

      painter.SetDivId(divid, -1); // just assign id
      painter.CheckColors(can);
      painter.CreateCanvasSvg(0);
      painter.SetDivId(divid);  // now add to painters list

      painter.AddButton(JSROOT.ToolbarIcons.camera, "Create PNG", "CanvasSnapShot", "Ctrl PrintScreen");
      if (JSROOT.gStyle.ContextMenu)
         painter.AddButton(JSROOT.ToolbarIcons.question, "Access context menus", "PadContextMenus");

      if (painter.enlarge_main('verify'))
         painter.AddButton(JSROOT.ToolbarIcons.circle, "Enlarge canvas", "EnlargePad");

      if (nocanvas && opt.indexOf("noframe") < 0)
         JSROOT.Painter.drawFrame(divid, null);

      painter.DrawPrimitive(0, function() { painter.DrawingReady(); });
      return painter;
   }

   JSROOT.Painter.drawPad = function(divid, pad, opt) {
      var painter = new JSROOT.TPadPainter(pad, false);
      painter.DecodeOptions(opt);

      painter.SetDivId(divid); // pad painter will be registered in the canvas painters list

      if (painter.svg_canvas().empty()) {
         painter.has_canvas = false;
         painter.this_pad_name = "";
      }

      painter.CreatePadSvg();

      if (painter.MatchObjectType("TPad") && (!painter.has_canvas || painter.HasObjectsToDraw())) {
         painter.AddButton(JSROOT.ToolbarIcons.camera, "Create PNG", "PadSnapShot");

         if ((painter.has_canvas && painter.HasObjectsToDraw()) || painter.enlarge_main('verify'))
            painter.AddButton(JSROOT.ToolbarIcons.circle, "Enlarge pad", "EnlargePad");

         if (JSROOT.gStyle.ContextMenu)
            painter.AddButton(JSROOT.ToolbarIcons.question, "Access context menus", "PadContextMenus");
      }

      var prev_name;

      if (painter.has_canvas)
         // we select current pad, where all drawing is performed
         prev_name = painter.CurrentPadName(painter.this_pad_name);

      painter.DrawPrimitive(0, function() {
         // we restore previous pad name
         painter.CurrentPadName(prev_name);
         painter.DrawingReady();
      });

      return painter;
   }

   // =======================================================================

   JSROOT.TAxisPainter = function(axis, embedded) {
      JSROOT.TObjectPainter.call(this, axis);

      this.embedded = embedded; // indicate that painter embedded into the histo painter

      this.name = "yaxis";
      this.kind = "normal";
      this.func = null;
      this.order = 0; // scaling order for axis labels

      this.full_min = 0;
      this.full_max = 1;
      this.scale_min = 0;
      this.scale_max = 1;
      this.ticks = []; // list of major ticks
      this.invert_side = false;
   }

   JSROOT.TAxisPainter.prototype = Object.create(JSROOT.TObjectPainter.prototype);

   JSROOT.TAxisPainter.prototype.Cleanup = function() {

      this.ticks = [];
      this.func = null;
      delete this.format;
      delete this.range;

      JSROOT.TObjectPainter.prototype.Cleanup.call(this);
   }

   JSROOT.TAxisPainter.prototype.SetAxisConfig = function(name, kind, func, min, max, smin, smax) {
      this.name = name;
      this.kind = kind;
      this.func = func;

      this.full_min = min;
      this.full_max = max;
      this.scale_min = smin;
      this.scale_max = smax;
   }

   JSROOT.TAxisPainter.prototype.CreateFormatFuncs = function() {

      var axis = this.GetObject(),
          is_gaxis = (axis && axis._typename === 'TGaxis');

      delete this.format;// remove formatting func

      var ndiv = 508;
      if (axis !== null)
         ndiv = Math.max(is_gaxis ? axis.fNdiv : axis.fNdivisions, 4) ;

      this.nticks = ndiv % 100;
      this.nticks2 = (ndiv % 10000 - this.nticks) / 100;
      this.nticks3 = Math.floor(ndiv/10000);

      if (axis && !is_gaxis && (this.nticks > 7)) this.nticks = 7;

      var gr_range = Math.abs(this.func.range()[1] - this.func.range()[0]);
      if (gr_range<=0) gr_range = 100;

      if (this.kind == 'time') {
         if (this.nticks > 8) this.nticks = 8;

         var scale_range = this.scale_max - this.scale_min;

         var tf1 = JSROOT.Painter.getTimeFormat(axis);
         if ((tf1.length == 0) || (scale_range < 0.1 * (this.full_max - this.full_min)))
            tf1 = JSROOT.Painter.chooseTimeFormat(scale_range / this.nticks, true);
         var tf2 = JSROOT.Painter.chooseTimeFormat(scale_range / gr_range, false);

         this.tfunc1 = this.tfunc2 = d3.timeFormat(tf1);
         if (tf2!==tf1)
            this.tfunc2 = d3.timeFormat(tf2);

         this.format = function(d, asticks) {
            return asticks ? this.tfunc1(d) : this.tfunc2(d);
         }

      } else
      if (this.kind == 'log') {
         this.nticks2 = 1;
         this.noexp = axis ? axis.TestBit(JSROOT.EAxisBits.kNoExponent) : false;
         if ((this.scale_max < 300) && (this.scale_min > 0.3)) this.noexp = true;
         this.moreloglabels = axis ? axis.TestBit(JSROOT.EAxisBits.kMoreLogLabels) : false;

         this.format = function(d, asticks, notickexp) {

            var val = parseFloat(d);

            if (!asticks) {
               var rnd = Math.round(val);
               return ((rnd === val) && (Math.abs(rnd)<1e9)) ? rnd.toString() : val.toExponential(4);
            }

            if (val <= 0) return null;
            var vlog = JSROOT.log10(val);
            if (this.moreloglabels || (Math.abs(vlog - Math.round(vlog))<0.001)) {
               if (!this.noexp && !notickexp)
                  return JSROOT.Painter.formatExp(val.toExponential(0));
               else
               if (vlog<0)
                  return val.toFixed(Math.round(-vlog+0.5));
               else
                  return val.toFixed(0);
            }
            return null;
         }
      } else
      if (this.kind == 'labels') {
         this.nticks = 50; // for text output allow max 50 names
         var scale_range = this.scale_max - this.scale_min;
         if (this.nticks > scale_range)
            this.nticks = Math.round(scale_range);
         this.nticks2 = 1;

         this.axis = axis;

         this.format = function(d) {
            var indx = Math.round(parseInt(d)) + 1;
            if ((indx<1) || (indx>this.axis.fNbins)) return null;
            for (var i = 0; i < this.axis.fLabels.arr.length; ++i) {
               var tstr = this.axis.fLabels.arr[i];
               if (tstr.fUniqueID == indx) return tstr.fString;
            }
            return null;
         }
      } else {

         this.range = Math.abs(this.scale_max - this.scale_min);
         if (this.range <= 0)
            this.ndig = -3;
         else
            this.ndig = Math.round(JSROOT.log10(this.nticks / this.range) + 0.7);

         this.format = function(d, asticks) {
            var val = parseFloat(d), rnd = Math.round(val);
            if (asticks) {
               if (this.order===0) {
                  if (val === rnd) return rnd.toString();
                  if (Math.abs(val) < 1e-10 * this.range) return 0;
                  val = (this.ndig>10) ? val.toExponential(4) : val.toFixed(this.ndig > 0 ? this.ndig : 0);
                  if ((typeof d == 'string') && (d.length <= val.length+1)) return d;
                  return val;
               }
               val = val / Math.pow(10, this.order);
               rnd = Math.round(val);
               if (val === rnd) return rnd.toString();
               return val.toFixed(this.ndig + this.order > 0 ? this.ndig + this.order : 0 );
            }

            if (val === rnd)
               return (Math.abs(rnd)<1e9) ? rnd.toString() : val.toExponential(4);

            return this.ndig>10 ? val.toExponential(4) : val.toFixed(this.ndig+2 > 0 ? this.ndig+2 : 0);
         }
      }
   }

   JSROOT.TAxisPainter.prototype.CreateTicks = function(only_major_as_array) {
      // function used to create array with minor/middle/major ticks

      var handle = { nminor: 0, nmiddle: 0, nmajor: 0, func: this.func };

      handle.minor = handle.middle = handle.major = this.func.ticks(this.nticks);

      if (only_major_as_array) {
         var res = handle.major;
         var delta = (this.scale_max - this.scale_min)*1e-5;
         if (res[0] > this.scale_min + delta) res.unshift(this.scale_min);
         if (res[res.length-1] < this.scale_max - delta) res.push(this.scale_max);
         return res;
      }

      if (this.nticks2 > 1) {
         handle.minor = handle.middle = this.func.ticks(handle.major.length * this.nticks2);

         var gr_range = Math.abs(this.func.range()[1] - this.func.range()[0]);

         // avoid black filling by middle-size
         if ((handle.middle.length <= handle.major.length) || (handle.middle.length > gr_range/3.5)) {
            handle.minor = handle.middle = handle.major;
         } else
         if ((this.nticks3 > 1) && (this.kind !== 'log'))  {
            handle.minor = this.func.ticks(handle.middle.length * this.nticks3);
            if ((handle.minor.length <= handle.middle.length) || (handle.minor.length > gr_range/1.7)) handle.minor = handle.middle;
         }
      }

      handle.reset = function() {
         this.nminor = this.nmiddle = this.nmajor = 0;
      }

      handle.next = function(doround) {
         if (this.nminor >= this.minor.length) return false;

         this.tick = this.minor[this.nminor++];
         this.grpos = this.func(this.tick);
         if (doround) this.grpos = Math.round(this.grpos);
         this.kind = 3;

         if ((this.nmiddle < this.middle.length) && (Math.abs(this.grpos - this.func(this.middle[this.nmiddle])) < 1)) {
            this.nmiddle++;
            this.kind = 2;
         }

         if ((this.nmajor < this.major.length) && (Math.abs(this.grpos - this.func(this.major[this.nmajor])) < 1) ) {
            this.nmajor++;
            this.kind = 1;
         }
         return true;
      }

      handle.last_major = function() {
         return (this.kind !== 1) ? false : this.nmajor == this.major.length;
      }

      handle.next_major_grpos = function() {
         if (this.nmajor >= this.major.length) return null;
         return this.func(this.major[this.nmajor]);
      }

      return handle;
   }

   JSROOT.TAxisPainter.prototype.IsCenterLabels = function() {
      if (this.kind === 'labels') return true;
      if (this.kind === 'log') return false;
      var axis = this.GetObject();
      return axis && axis.TestBit(JSROOT.EAxisBits.kCenterLabels);
   }

   JSROOT.TAxisPainter.prototype.AddTitleDrag = function(title_g, vertical, offset_k, reverse, axis_length) {
      if (!JSROOT.gStyle.MoveResize) return;

      var pthis = this,  drag_rect = null, prefix = "", drag_move,
          acc_x, acc_y, new_x, new_y, sign_0, center_0, alt_pos;
      if (JSROOT._test_d3_ === 3) {
         prefix = "drag";
         drag_move = d3.behavior.drag().origin(Object);
      } else {
         drag_move = d3.drag().subject(Object);
      }

      drag_move
         .on(prefix+"start",  function() {

            d3.event.sourceEvent.preventDefault();
            d3.event.sourceEvent.stopPropagation();

            var box = title_g.node().getBBox(), // check that elements visible, request precise value
                axis = pthis.GetObject();

            new_x = acc_x = title_g.property('shift_x');
            new_y = acc_y = title_g.property('shift_y');

            sign_0 = vertical ? (acc_x>0) : (acc_y>0); // sign should remain

            if (axis.TestBit(JSROOT.EAxisBits.kCenterTitle))
               alt_pos = (reverse === vertical) ? axis_length : 0;
            else
               alt_pos = Math.round(axis_length/2);

            drag_rect = title_g.append("rect")
                 .classed("zoom", true)
                 .attr("x", box.x)
                 .attr("y", box.y)
                 .attr("width", box.width)
                 .attr("height", box.height)
                 .style("cursor", "move");
//                 .style("pointer-events","none"); // let forward double click to underlying elements
          }).on("drag", function() {
               if (!drag_rect) return;

               d3.event.sourceEvent.preventDefault();
               d3.event.sourceEvent.stopPropagation();

               acc_x += d3.event.dx;
               acc_y += d3.event.dy;

               var set_x = title_g.property('shift_x'),
                   set_y = title_g.property('shift_y');

               if (vertical) {
                  set_x = acc_x;
                  if (Math.abs(acc_y - set_y) > Math.abs(acc_y - alt_pos)) set_y = alt_pos;
               } else {
                  set_y = acc_y;
                  if (Math.abs(acc_x - set_x) > Math.abs(acc_x - alt_pos)) set_x = alt_pos;
               }

               if (sign_0 === (vertical ? (set_x>0) : (set_y>0))) {
                  new_x = set_x; new_y = set_y;
                  title_g.attr('transform', 'translate(' + new_x + ',' + new_y +  ')');
               }

          }).on(prefix+"end", function() {
               if (!drag_rect) return;

               d3.event.sourceEvent.preventDefault();
               d3.event.sourceEvent.stopPropagation();

               title_g.property('shift_x', new_x)
                      .property('shift_y', new_y);

               var axis = pthis.GetObject();

               axis.fTitleOffset = (vertical ? new_x : new_y) / offset_k;
               if ((vertical ? new_y : new_x) === alt_pos) axis.InvertBit(JSROOT.EAxisBits.kCenterTitle);

               drag_rect.remove();
               drag_rect = null;
            });

      title_g.style("cursor", "move").call(drag_move);
   }

   JSROOT.TAxisPainter.prototype.DrawAxis = function(vertical, layer, w, h, transform, reverse, second_shift) {
      // function draw complete TAxis
      // later will be used to draw TGaxis

      var axis = this.GetObject(),
          is_gaxis = (axis && axis._typename === 'TGaxis'),
          side = (this.name === "zaxis") ? -1  : 1, both_sides = 0,
          axis_g = layer, tickSize = 10, scaling_size = 100, text_scaling_size = 100,
          pad_w = this.pad_width() || 10,
          pad_h = this.pad_height() || 10;

      this.vertical = vertical;

      // shift for second ticks set (if any)
      if (!second_shift) second_shift = 0; else
      if (this.invert_side) second_shift = -second_shift;

      if (is_gaxis) {
         if (!this.lineatt) this.lineatt = JSROOT.Painter.createAttLine(axis);
         scaling_size = (vertical ? pad_w : pad_h);
         tickSize = Math.round(axis.fTickSize * scaling_size);
      } else {
         if (!this.lineatt) this.lineatt = JSROOT.Painter.createAttLine(axis.fAxisColor, 1);
         scaling_size = (vertical ? w : h);
         tickSize = Math.round(axis.fTickLength * scaling_size);
      }

      text_scaling_size = Math.min(pad_w, pad_h);

      if (!is_gaxis || (this.name === "zaxis")) {
         axis_g = layer.select("." + this.name + "_container");
         if (axis_g.empty())
            axis_g = layer.append("svg:g").attr("class",this.name+"_container");
         else
            axis_g.selectAll("*").remove();
         if (this.invert_side) side = -side;
      } else {

         if ((axis.fChopt.indexOf("-")>=0) && (axis.fChopt.indexOf("+")<0)) side = -1; else
         if (vertical && axis.fChopt=="+L") side = -1; else
         if ((axis.fChopt.indexOf("-")>=0) && (axis.fChopt.indexOf("+")>=0)) { side = 1; both_sides = 1; }

         axis_g.append("svg:line")
               .attr("x1",0).attr("y1",0)
               .attr("x1",vertical ? 0 : w)
               .attr("y1", vertical ? h : 0)
               .call(this.lineatt.func);
      }

      if (transform !== undefined)
         axis_g.attr("transform", transform);

      this.CreateFormatFuncs();

      var center_lbls = this.IsCenterLabels(),
          res = "", res2 = "", lastpos = 0, lasth = 0,
          textscale = 1, maxtextlen = 0;

      // first draw ticks

      this.ticks = [];

      var handle = this.CreateTicks();

      while (handle.next(true)) {
         var h1 = Math.round(tickSize/4), h2 = 0;

         if (handle.kind < 3)
            h1 = Math.round(tickSize/2);

         if (handle.kind == 1) {
            // if not showing lables, not show large tick
            if (!('format' in this) || (this.format(handle.tick,true)!==null)) h1 = tickSize;
            this.ticks.push(handle.grpos); // keep graphical positions of major ticks
         }

         if (both_sides > 0) h2 = -h1; else
         if (side < 0) { h2 = -h1; h1 = 0; } else { h2 = 0; }

         if (res.length == 0) {
            res = vertical ? ("M"+h1+","+handle.grpos) : ("M"+handle.grpos+","+(-h1));
            res2 = vertical ? ("M"+(second_shift-h1)+","+handle.grpos) : ("M"+handle.grpos+","+(second_shift+h1));
         } else {
            res += vertical ? ("m"+(h1-lasth)+","+(handle.grpos-lastpos)) : ("m"+(handle.grpos-lastpos)+","+(lasth-h1));
            res2 += vertical ? ("m"+(lasth-h1)+","+(handle.grpos-lastpos)) : ("m"+(handle.grpos-lastpos)+","+(h1-lasth));
         }

         res += vertical ? ("h"+ (h2-h1)) : ("v"+ (h1-h2));
         res2 += vertical ? ("h"+ (h1-h2)) : ("v"+ (h2-h1));

         lastpos = handle.grpos;
         lasth = h2;
      }

      if (res.length > 0)
         axis_g.append("svg:path").attr("d", res).call(this.lineatt.func);

      if ((second_shift!==0) && (res2.length>0))
         axis_g.append("svg:path").attr("d", res2).call(this.lineatt.func);

      var last = vertical ? h : 0,
          labelsize = (axis.fLabelSize >= 1) ? axis.fLabelSize : Math.round(axis.fLabelSize * (is_gaxis ? this.pad_height() : h)),
          labelfont = JSROOT.Painter.getFontDetails(axis.fLabelFont, labelsize),
          label_color = JSROOT.Painter.root_colors[axis.fLabelColor],
          labeloffset = 3 + Math.round(axis.fLabelOffset * scaling_size),
          label_g = axis_g.append("svg:g")
                         .attr("class","axis_labels")
                         .call(labelfont.func);

      this.order = 0;
      if ((this.kind=="normal") && /*vertical && */ !axis.TestBit(JSROOT.EAxisBits.kNoExponent)) {
         var maxtick = Math.max(Math.abs(handle.major[0]),Math.abs(handle.major[handle.major.length-1]));
         for(var order=18;order>-18;order-=3) {
            if (order===0) continue;
            if ((order<0) && ((this.range>=0.1) || (maxtick>=1.))) break;
            var mult = Math.pow(10, order);
            if ((this.range > mult * 9.99999) || ((maxtick > mult*50) && (this.range > mult * 0.05))) {
               this.order = order;
               break;
            }
         }
      }

      for (var nmajor=0;nmajor<handle.major.length;++nmajor) {
         var pos = Math.round(this.func(handle.major[nmajor])),
             lbl = this.format(handle.major[nmajor], true);
         if (lbl === null) continue;

         var t = label_g.append("svg:text").attr("fill", label_color).text(lbl);

         maxtextlen = Math.max(maxtextlen, lbl.length);

         if (vertical)
            t.attr("x", -labeloffset*side)
             .attr("y", pos)
             .style("text-anchor", (side > 0) ? "end" : "start")
             .style("dominant-baseline", "middle");
         else
            t.attr("x", pos)
             .attr("y", 2+labeloffset*side  + both_sides*tickSize)
             .attr("dy", (side > 0) ? ".7em" : "-.3em")
             .style("text-anchor", "middle");

         var tsize = !JSROOT.nodejs ? this.GetBoundarySizes(t.node()) :
                      { height: Math.round(labelfont.size*1.2), width: Math.round(lbl.length*labelfont.size*0.4) },
             space_before = (nmajor > 0) ? (pos - last) : (vertical ? h/2 : w/2),
             space_after = (nmajor < handle.major.length-1) ? (Math.round(this.func(handle.major[nmajor+1])) - pos) : space_before,
             space = Math.min(Math.abs(space_before), Math.abs(space_after));

         if (vertical) {

            if ((space > 0) && (tsize.height > 5) && (this.kind !== 'log'))
               textscale = Math.min(textscale, space / tsize.height);

            if (center_lbls) {
               // if position too far top, remove label
               if (pos + space_after/2 - textscale*tsize.height/2 < -10)
                  t.remove();
               else
                  t.attr("y", Math.round(pos + space_after/2));
            }

         } else {

            // test if label consume too much space
            if ((space > 0) && (tsize.width > 10) && (this.kind !== 'log'))
               textscale = Math.min(textscale, space / tsize.width);

            if (center_lbls) {
               // if position too far right, remove label
               if (pos + space_after/2 - textscale*tsize.width/2 > w - 10)
                  t.remove();
               else
                  t.attr("x", Math.round(pos + space_after/2));
            }
         }

         last = pos;
     }

     if (this.order!==0)
        label_g.append("svg:text")
               .attr("fill", label_color)
               .attr("x", vertical ? labeloffset : w+5)
               .attr("y", 0)
               .style("text-anchor", "start")
               .style("dominant-baseline", "middle")
               .attr("dy", "-.5em")
               .text('\xD7' + JSROOT.Painter.formatExp(Math.pow(10,this.order).toExponential(0)));

     if ((textscale>0) && (textscale<1.)) {
        // rotate X lables if they are too big
        if ((textscale < 0.7) && !vertical && (side>0) && (maxtextlen > 5)) {
           label_g.selectAll("text").each(function() {
              var txt = d3.select(this), x = txt.attr("x"), y = txt.attr("y") - 5;

              txt.attr("transform", "translate(" + x + "," + y + ") rotate(25)")
                 .style("text-anchor", "start")
                 .attr("x",null).attr("y",null);
           });
           textscale *= 3.5;
        }
        // round to upper boundary for calculated value like 4.4
        labelfont.size = Math.floor(labelfont.size * textscale + 0.7);
        label_g.call(labelfont.func);
     }

     if (JSROOT.gStyle.Zooming && !this.disable_zooming) {
        var r =  axis_g.append("svg:rect")
                       .attr("class", "axis_zoom")
                       .style("opacity", "0")
                       .style("cursor", "crosshair");

        if (vertical)
           r.attr("x", (side>0) ? (-2*labelfont.size - 3) : 3)
            .attr("y", 0)
            .attr("width", 2*labelfont.size + 3)
            .attr("height", h)
        else
           r.attr("x", 0).attr("y", (side>0) ? 0 : -labelfont.size-3)
            .attr("width", w).attr("height", labelfont.size + 3);
      }

      if (axis.fTitle.length > 0) {
         var title_g = axis_g.append("svg:g").attr("class", "axis_title"),
             title_fontsize = (axis.fTitleSize >= 1) ? axis.fTitleSize : Math.round(axis.fTitleSize * text_scaling_size),
             title_offest_k = 1.6*(axis.fTitleSize<1 ? axis.fTitleSize : axis.fTitleSize/text_scaling_size),
             center = axis.TestBit(JSROOT.EAxisBits.kCenterTitle),
             rotate = axis.TestBit(JSROOT.EAxisBits.kRotateTitle) ? -1 : 1,
             title_color = JSROOT.Painter.root_colors[axis.fTitleColor],
             shift_x = 0, shift_y = 0;

         this.StartTextDrawing(axis.fTitleFont, title_fontsize, title_g);

         var myxor = ((rotate<0) && !reverse) || ((rotate>=0) && reverse);

         if (vertical) {
            title_offest_k *= -side*pad_w;

            shift_x = Math.round(title_offest_k*axis.fTitleOffset);

            if ((this.name == "zaxis") && is_gaxis && ('getBoundingClientRect' in axis_g.node())) {
               // special handling for color palette labels - draw them always on right side
               var rect = axis_g.node().getBoundingClientRect();
               if (shift_x < rect.width - tickSize) shift_x = Math.round(rect.width - tickSize);
            }

            shift_y = Math.round(center ? h/2 : (reverse ? h : 0));

            this.DrawText((center ? "middle" : (myxor ? "begin" : "end" ))+ ";middle",
                           0, 0, 0, (rotate<0 ? -90 : -270),
                           axis.fTitle, title_color, 1, title_g);
         } else {
            title_offest_k *= side*pad_h;

            shift_x = Math.round(center ? w/2 : (reverse ? 0 : w));
            shift_y = Math.round(title_offest_k*axis.fTitleOffset);
            this.DrawText((center ? 'middle' : (myxor ? 'begin' : 'end')) + ";middle",
                          0, 0, 0, (rotate<0 ? -180 : 0),
                          axis.fTitle, title_color, 1, title_g);
         }

         this.FinishTextDrawing(title_g);

         title_g.attr('transform', 'translate(' + shift_x + ',' + shift_y +  ')')
                .property('shift_x',shift_x)
                .property('shift_y',shift_y);

         this.AddTitleDrag(title_g, vertical, title_offest_k, reverse, vertical ? h : w);
      }

      this.position = 0;

      if ('getBoundingClientRect' in axis_g.node()) {
         var rect1 = axis_g.node().getBoundingClientRect(),
             rect2 = this.svg_pad().node().getBoundingClientRect();

         this.position = rect1.left - rect2.left; // use to control left position of Y scale
      }
   }

   JSROOT.TAxisPainter.prototype.Redraw = function() {

      var gaxis = this.GetObject(),
          x1 = this.AxisToSvg("x", gaxis.fX1),
          y1 = this.AxisToSvg("y", gaxis.fY1),
          x2 = this.AxisToSvg("x", gaxis.fX2),
          y2 = this.AxisToSvg("y", gaxis.fY2),
          w = x2 - x1, h = y1 - y2,
          vertical = w < 5, kind = "normal", func = null,
          min = gaxis.fWmin, max = gaxis.fWmax, reverse = false;

      if (gaxis.fChopt.indexOf("G")>=0) {
         func = d3.scaleLog();
         kind = "log";
      } else {
         func = d3.scaleLinear();
      }

      func.domain([min, max]);

      if (vertical) {
         if (h > 0) {
            func.range([h,0]);
         } else {
            var d = y1; y1 = y2; y2 = d;
            h = -h; reverse = true;
            func.range([0,h]);
         }
      } else {
         if (w > 0) {
            func.range([0,w]);
         } else {
            var d = x1; x1 = x2; x2 = d;
            w = -w; reverse = true;
            func.range([w,0]);
         }
      }

      this.SetAxisConfig(vertical ? "yaxis" : "xaxis", kind, func, min, max, min, max);

      this.RecreateDrawG(true, "text_layer");

      this.DrawAxis(vertical, this.draw_g, w, h, "translate(" + x1 + "," + y2 +")", reverse);
   }

   JSROOT.drawGaxis = function(divid, obj, opt) {
      var painter = new JSROOT.TAxisPainter(obj, false);

      painter.SetDivId(divid);

      painter.disable_zooming = true;

      painter.Redraw();

      return painter.DrawingReady();
   }


   // =============================================================

   JSROOT.THistPainter = function(histo) {
      JSROOT.TObjectPainter.call(this, histo);
      this.histo = histo;
      this.shrink_frame_left = 0.;
      this.draw_content = true;
      this.nbinsx = 0;
      this.nbinsy = 0;
      this.x_kind = 'normal'; // 'normal', 'time', 'labels'
      this.y_kind = 'normal'; // 'normal', 'time', 'labels'
      this.keys_handler = null;
      this.accept_drops = true; // indicate that one can drop other objects like doing Draw("same")
      this.mode3d = false;
      this.zoom_changed_interactive = 0;
   }

   JSROOT.THistPainter.prototype = Object.create(JSROOT.TObjectPainter.prototype);

   JSROOT.THistPainter.prototype.IsDummyHisto = function() {
      return !this.histo || (!this.draw_content && !this.create_stats) || (this.options.Axis>0);
   }

   JSROOT.THistPainter.prototype.IsTProfile = function() {
      return this.MatchObjectType('TProfile');
   }

   JSROOT.THistPainter.prototype.IsTH2Poly = function() {
      return this.histo && this.histo._typename.match(/^TH2Poly/);
   }

   JSROOT.THistPainter.prototype.Cleanup = function() {
      if (this.keys_handler) {
         window.removeEventListener( 'keydown', this.keys_handler, false );
         this.keys_handler = null;
      }

      // clear all 3D buffers
      if (typeof this.Create3DScene === 'function')
         this.Create3DScene(-1);

      this.histo = null; // cleanup histogram reference
      delete this.x; delete this.grx;
      delete this.ConvertX; delete this.RevertX;
      delete this.y; delete this.gry;
      delete this.ConvertY; delete this.RevertY;
      delete this.z; delete this.grz;

      if (this.x_handle) {
         this.x_handle.Cleanup();
         delete this.x_handle;
      }

      if (this.y_handle) {
         this.y_handle.Cleanup();
         delete this.y_handle;
      }

      if (this.z_handle) {
         this.z_handle.Cleanup();
         delete this.z_handle;
      }

      delete this.fPalette;
      delete this.fContour;
      delete this.options;

      JSROOT.TObjectPainter.prototype.Cleanup.call(this);
   }

   JSROOT.THistPainter.prototype.Dimension = function() {
      if (!this.histo) return 0;
      if (this.histo._typename.indexOf("TH2")==0) return 2;
      if (this.histo._typename.indexOf("TProfile2D")==0) return 2;
      if (this.histo._typename.indexOf("TH3")==0) return 3;
      return 1;
   }

   JSROOT.THistPainter.prototype.DecodeOptions = function(opt, interactive) {

      /* decode string 'opt' and fill the option structure */
      var option = { Axis: 0, Bar: 0, Curve: 0, Hist: 0, Line: 0,
             Error: 0, errorX: JSROOT.gStyle.fErrorX,
             Mark: 0, Fill: 0, Same: 0, Scat: 0, ScatCoef: 1., Func: 1, Star: 0,
             Arrow: 0, Box: 0, Text: 0, Char: 0, Color: 0, Contour: 0,
             Lego: 0, Surf: 0, Off: 0, Tri: 0, Proj: 0, AxisPos: 0,
             Spec: 0, Pie: 0, List: 0, Zscale: 0, FrontBox: 1, BackBox: 1, Candle: "",
             GLBox: 0, GLColor: 0,
             System: JSROOT.Painter.Coord.kCARTESIAN,
             AutoColor : 0, NoStat : 0, AutoZoom : false,
             HighRes: 0, Zero: 1, Palette: 0, BaseLine: false,
             Optimize: JSROOT.gStyle.OptimizeDraw,
             minimum: -1111, maximum: -1111 },
           d = new JSROOT.DrawOptions(opt ? opt : this.histo.fOption),
           hdim = this.Dimension(),
           pad = this.root_pad(),
           need_fillcol = false;

      // use error plot only when any sumw2 bigger than 0
      if ((hdim===1) && (this.histo.fSumw2.length > 0))
         for (var n=0;n<this.histo.fSumw2.length;++n)
            if (this.histo.fSumw2[n] > 0) { option.Error = 2; option.Zero = 0; break; }

      if (d.check('PAL', true)) option.Palette = d.partAsInt();
      if (d.check('MINIMUM:', true)) option.minimum = parseFloat(d.part); else option.minimum = this.histo.fMinimum;
      if (d.check('MAXIMUM:', true)) option.maximum = parseFloat(d.part); else option.maximum = this.histo.fMaximum;

      if (d.check('NOOPTIMIZE')) option.Optimize = 0;
      if (d.check('OPTIMIZE')) option.Optimize = 2;

      if (d.check('AUTOCOL')) { option.AutoColor = 1; option.Hist = 1; }
      if (d.check('AUTOZOOM')) { option.AutoZoom = 1; option.Hist = 1; }

      if (d.check('NOSTAT')) option.NoStat = 1;

      var tooltip = null;
      if (d.check('NOTOOLTIP')) tooltip = false;
      if (d.check('TOOLTIP')) tooltip = true;
      if ((tooltip!==null) && this.frame_painter()) this.frame_painter().tooltip_allowed = tooltip;

      if (d.check('LOGX')) pad.fLogx = 1;
      if (d.check('LOGY')) pad.fLogy = 1;
      if (d.check('LOGZ')) pad.fLogz = 1;
      if (d.check('GRIDXY')) pad.fGridx = pad.fGridy = 1;
      if (d.check('GRIDX')) pad.fGridx = 1;
      if (d.check('GRIDY')) pad.fGridy = 1;
      if (d.check('TICKXY')) pad.fTickx = pad.fTicky = 1;
      if (d.check('TICKX')) pad.fTickx = 1;
      if (d.check('TICKY')) pad.fTicky = 1;

      if (d.check('FILL_', true)) {
         if (d.partAsInt(1)>0) this.histo.fFillColor = d.partAsInt(); else
         for (var col=0;col<8;++col)
            if (JSROOT.Painter.root_colors[col].toUpperCase() === d.part) this.histo.fFillColor = col;
      }
      if (d.check('LINE_', true)) {
         if (d.partAsInt(1)>0) this.histo.fLineColor = d.partAsInt(); else
         for (var col=0;col<8;++col)
            if (JSROOT.Painter.root_colors[col].toUpperCase() === d.part) this.histo.fLineColor = col;
      }

      if (d.check('X+')) option.AxisPos = 10;
      if (d.check('Y+')) option.AxisPos += 1;

      if (d.check('SAMES')) option.Same = 2;
      if (d.check('SAME')) option.Same = 1;

      // if here rest option is empty, draw histograms by default
      if (d.empty()) option.Hist = 1;

      if (d.check('SPEC')) { option.Scat = 0; option.Spec = 1; }

      if (d.check('BASE0')) option.BaseLine = 0; else
      if (JSROOT.gStyle.fHistMinimumZero) option.BaseLine = 0;

      if (d.check('PIE')) option.Pie = 1;

      if (d.check('CANDLE', true)) option.Candle = d.part;

      if (d.check('GLBOX',true)) option.GLBox = 10 + d.partAsInt();
      if (d.check('GLCOL')) option.GLColor = 1;

      d.check('GL'); // suppress GL

      if (d.check('LEGO', true)) {
         option.Scat = 0;
         option.Lego = 1;
         if (d.part.indexOf('0') >= 0) option.Zero = 0;
         if (d.part.indexOf('1') >= 0) option.Lego = 11;
         if (d.part.indexOf('2') >= 0) option.Lego = 12;
         if (d.part.indexOf('3') >= 0) option.Lego = 13;
         if (d.part.indexOf('4') >= 0) option.Lego = 14;
         if (d.part.indexOf('FB') >= 0) option.FrontBox = 0;
         if (d.part.indexOf('BB') >= 0) option.BackBox = 0;
         if (d.part.indexOf('Z') >= 0) option.Zscale = 1;
      }

      if (d.check('SURF', true)) {
         option.Scat = 0;
         option.Surf = d.partAsInt(10, 1);
         if (d.part.indexOf('FB') >= 0) option.FrontBox = 0;
         if (d.part.indexOf('BB') >= 0) option.BackBox = 0;
         if (d.part.indexOf('Z')>=0) option.Zscale = 1;
      }

      if (d.check('TF3', true)) {
         if (d.part.indexOf('FB') >= 0) option.FrontBox = 0;
         if (d.part.indexOf('BB') >= 0) option.BackBox = 0;
      }

      if (d.check('ISO', true)) {
         if (d.part.indexOf('FB') >= 0) option.FrontBox = 0;
         if (d.part.indexOf('BB') >= 0) option.BackBox = 0;
      }

      if (d.check('LIST')) option.List = 1;

      if (d.check('CONT', true)) {
         if (hdim > 1) {
            option.Scat = 0;
            option.Contour = 1;
            if (d.part.indexOf('Z') >= 0) option.Zscale = 1;
            if (d.part.indexOf('1') >= 0) option.Contour = 11; else
            if (d.part.indexOf('2') >= 0) option.Contour = 12; else
            if (d.part.indexOf('3') >= 0) option.Contour = 13; else
            if (d.part.indexOf('4') >= 0) option.Contour = 14;
         } else {
            option.Hist = 1;
         }
      }

      // decode bar/hbar option
      if (d.check('HBAR', true)) option.Bar = 20; else
      if (d.check('BAR', true)) option.Bar = 10;
      if (option.Bar > 0) {
         option.Hist = 0; need_fillcol = true;
         option.Bar += d.partAsInt();
      }

      if (d.check('ARR')) {
         if (hdim > 1) {
            option.Arrow = 1;
            option.Scat = 0;
         } else {
            option.Hist = 1;
         }
      }

      if (d.check('BOX',true)) option.Box = 10 + d.partAsInt();

      if (option.Box)
         if (hdim > 1) option.Scat = 0;
                  else option.Hist = 1;

      if (d.check('COL', true)) {
         option.Color = 1;

         if (d.part.indexOf('0')>=0) option.Color = 11;
         if (d.part.indexOf('1')>=0) option.Color = 11;
         if (d.part.indexOf('2')>=0) option.Color = 12;
         if (d.part.indexOf('3')>=0) option.Color = 13;

         if (d.part.indexOf('Z')>=0) option.Zscale = 1;
         if (hdim == 1) option.Hist = 1;
                   else option.Scat = 0;
      }

      if (d.check('CHAR')) { option.Char = 1; option.Scat = 0; }
      if (d.check('FUNC')) { option.Func = 2; option.Hist = 0; }
      if (d.check('AXIS')) option.Axis = 1;
      if (d.check('AXIG')) option.Axis = 2;

      if (d.check('TEXT', true)) {
         option.Text = 1;
         option.Scat = 0;
         option.Hist = 0;

         var angle = Math.min(d.partAsInt(), 90);
         if (angle) option.Text = 1000 + angle;

         if (d.part.indexOf('N')>=0 && this.IsTH2Poly())
            option.Text = 3000 + angle;

         if (d.part.indexOf('E')>=0)
            option.Text = 2000 + angle;
      }

      if (d.check('SCAT=', true)) {
         option.Scat = 1;
         option.ScatCoef = parseFloat(d.part);
         if (isNaN(option.ScatCoef) || (option.ScatCoef<=0)) option.ScatCoef = 1.;
      }

      if (d.check('SCAT')) option.Scat = 1;
      if (d.check('POL')) option.System = JSROOT.Painter.Coord.kPOLAR;
      if (d.check('CYL')) option.System = JSROOT.Painter.Coord.kCYLINDRICAL;
      if (d.check('SPH')) option.System = JSROOT.Painter.Coord.kSPHERICAL;
      if (d.check('PSR')) option.System = JSROOT.Painter.Coord.kRAPIDITY;

      if (d.check('TRI', true)) {
         option.Scat = 0;
         option.Color = 0;
         option.Tri = 1;
         if (d.part.indexOf('FB') >= 0) option.FrontBox = 0;
         if (d.part.indexOf('BB') >= 0) option.BackBox = 0;
         if (d.part.indexOf('ERR') >= 0) option.Error = 1;
      }
      if (d.check('AITOFF')) option.Proj = 1;
      if (d.check('MERCATOR')) option.Proj = 2;
      if (d.check('SINUSOIDAL')) option.Proj = 3;
      if (d.check('PARABOLIC')) option.Proj = 4;

      if (option.Proj > 0) { option.Scat = 0; option.Contour = 14; }

      if ((hdim==3) && d.check('FB')) option.FrontBox = 0;
      if ((hdim==3) && d.check('BB')) option.BackBox = 0;

      if (d.check('LF2')) { option.Line = 2; option.Hist = -1; option.Error = 0; need_fillcol = true; }
      if (d.check('L')) { option.Line = 1; option.Hist = -1; option.Error = 0; }

      if (d.check('A')) option.Axis = -1;
      if (d.check('B1')) { option.Bar = 1; option.BaseLine = 0; option.Hist = -1; need_fillcol = true; }
      if (d.check('B')) { option.Bar = 1; option.Hist = -1; need_fillcol = true; }
      if (d.check('C')) { option.Curve = 1; option.Hist = -1; }
      if (d.check('][')) { option.Off = 1; option.Hist = 1; }
      if (d.check('F')) option.Fill = 1;

      if (d.check('P0')) { option.Mark = 1; option.Hist = -1; option.Zero = 1; }
      if (d.check('P')) { option.Mark = 1; option.Hist = -1; option.Zero = 0; }
      if (d.check('Z')) option.Zscale = 1;
      if (d.check('*H') || d.check('*')) { option.Mark = 23; option.Hist = -1; }

      if (d.check('HIST')) { option.Hist = 2; option.Func = 0; option.Error = 0; }

      if (this.IsTH2Poly()) {
         if (option.Fill + option.Line + option.Mark != 0) option.Scat = 0;
      }

      if (d.check('E', true)) {
         if (hdim == 1) {
            option.Error = 1;
            option.Zero = 0; // do not draw empty bins with erros
            if (!isNaN(parseInt(d.part[0]))) option.Error = 10 + parseInt(d.part[0]);
            if ((option.Error === 13) || (option.Error === 14)) need_fillcol = true;
            if (option.Error === 10) option.Zero = 1; // enable drawing of empty bins
            if (d.part.indexOf('X0')>=0) option.errorX = 0;
         } else {
            if (option.Error == 0) {
               option.Error = 100;
               option.Scat = 0;
            }
         }
      }
      if (d.check('9')) option.HighRes = 1;
      if (d.check('0')) option.Zero = 0;

      if (interactive) {
         if (need_fillcol && this.fillatt && (this.fillatt.color=='none'))
            this.fillatt.Change(5,1001);
      }

      //if (option.Surf == 15)
      //   if (option.System == JSROOT.Painter.Coord.kPOLAR || option.System == JSROOT.Painter.Coord.kCARTESIAN)
      //      option.Surf = 13;

      return option;
   }

   JSROOT.THistPainter.prototype.GetAutoColor = function(col) {
      if (this.options.AutoColor<=0) return col;

      var id = this.options.AutoColor;
      this.options.AutoColor = id % 8 + 1;
      return JSROOT.Painter.root_colors[id];
   }

   JSROOT.THistPainter.prototype.ScanContent = function(when_axis_changed) {
      // function will be called once new histogram or
      // new histogram content is assigned
      // one should find min,max,nbins, maxcontent values
      // if when_axis_changed === true specified, content will be scanned after axis zoom changed

      alert("HistPainter.prototype.ScanContent not implemented");
   }

   JSROOT.THistPainter.prototype.CheckPadRange = function() {

      if (!this.is_main_painter()) return;

      this.zoom_xmin = this.zoom_xmax = 0;
      this.zoom_ymin = this.zoom_ymax = 0;
      this.zoom_zmin = this.zoom_zmax = 0;


      var ndim = this.Dimension(),
          xaxis = this.histo.fXaxis,
          yaxis = this.histo.fYaxis,
          zaxis = this.histo.fXaxis;

      // apply selected user range from histogram itself
      if (xaxis.TestBit(JSROOT.EAxisBits.kAxisRange)) {
         //xaxis.InvertBit(JSROOT.EAxisBits.kAxisRange); // axis range is not used for main painter
         if ((xaxis.fFirst !== xaxis.fLast) && ((xaxis.fFirst > 1) || (xaxis.fLast < xaxis.fNbins))) {
            this.zoom_xmin = xaxis.fFirst > 1 ? xaxis.GetBinLowEdge(xaxis.fFirst) : xaxis.fXmin;
            this.zoom_xmax = xaxis.fLast < xaxis.fNbins ? xaxis.GetBinLowEdge(xaxis.fLast+1) : xaxis.fXmax;
         }
      }

      if ((ndim>1) && yaxis.TestBit(JSROOT.EAxisBits.kAxisRange)) {
         //yaxis.InvertBit(JSROOT.EAxisBits.kAxisRange); // axis range is not used for main painter
         if ((yaxis.fFirst !== yaxis.fLast) && ((yaxis.fFirst > 1) || (yaxis.fLast < yaxis.fNbins))) {
            this.zoom_ymin = yaxis.fFirst > 1 ? yaxis.GetBinLowEdge(yaxis.fFirst) : yaxis.fXmin;
            this.zoom_ymax = yaxis.fLast < yaxis.fNbins ? yaxis.GetBinLowEdge(yaxis.fLast+1) : yaxis.fXmax;
         }
      }

      if ((ndim>2) && zaxis.TestBit(JSROOT.EAxisBits.kAxisRange)) {
         //zaxis.InvertBit(JSROOT.EAxisBits.kAxisRange); // axis range is not used for main painter
         if ((zaxis.fFirst !== zaxis.fLast) && ((zaxis.fFirst > 1) || (zaxis.fLast < zaxis.fNbins))) {
            this.zoom_zmin = zaxis.fFirst > 1 ? zaxis.GetBinLowEdge(zaxis.fFirst) : zaxis.fXmin;
            this.zoom_zmax = zaxis.fLast < zaxis.fNbins ? zaxis.GetBinLowEdge(zaxis.fLast+1) : zaxis.fXmax;
         }
      }

      var pad = this.root_pad();

      if (!pad || !('fUxmin' in pad) || this.create_canvas) return;

      var min = pad.fUxmin, max = pad.fUxmax;

      // first check that non-default values are there
      if ((ndim < 3) && ((min !== 0) || (max !== 1))) {
         if (pad.fLogx > 0) {
            min = Math.exp(min * Math.log(10));
            max = Math.exp(max * Math.log(10));
         }

         if (min !== xaxis.fXmin || max !== xaxis.fXmax)
            if (min >= xaxis.fXmin && max <= xaxis.fXmax) {
               // set zoom values if only inside range
               this.zoom_xmin = min;
               this.zoom_xmax = max;
            }
      }

      min = pad.fUymin; max = pad.fUymax;

      if ((ndim == 2) && ((min !== 0) || (max !== 1))) {
         if (pad.fLogy > 0) {
            min = Math.exp(min * Math.log(10));
            max = Math.exp(max * Math.log(10));
         }

         if (min !== yaxis.fXmin || max !== yaxis.fXmax)
            if (min >= yaxis.fXmin && max <= yaxis.fXmax) {
               // set zoom values if only inside range
               this.zoom_ymin = min;
               this.zoom_ymax = max;
            }
      }
   }

   JSROOT.THistPainter.prototype.CheckHistDrawAttributes = function() {

      if (!this.fillatt || !this.fillatt.changed)
         this.fillatt = this.createAttFill(this.histo, undefined, undefined, 1);

      if (!this.lineatt || !this.lineatt.changed) {
         this.lineatt = JSROOT.Painter.createAttLine(this.histo);
         var main = this.main_painter();

         if (main) {
            var newcol = main.GetAutoColor(this.lineatt.color);
            if (newcol !== this.lineatt.color) { this.lineatt.color = newcol; this.lineatt.changed = true; }
         }
      }
   }

   JSROOT.THistPainter.prototype.UpdateObject = function(obj) {

      var histo = this.GetObject();

      if (obj !== histo) {

         if (!this.MatchObjectType(obj)) return false;

         // TODO: simple replace of object does not help - one can have different
         // complex relations between histo and stat box, histo and colz axis,
         // one could have THStack or TMultiGraph object
         // The only that could be done is update of content

         // this.histo = obj;

         histo.fFillColor = obj.fFillColor;
         histo.fFillStyle = obj.fFillStyle;
         histo.fLineColor = obj.fLineColor;
         histo.fLineStyle = obj.fLineStyle;
         histo.fLineWidth = obj.fLineWidth;

         histo.fEntries = obj.fEntries;
         histo.fTsumw = obj.fTsumw;
         histo.fTsumwx = obj.fTsumwx;
         histo.fTsumwx2 = obj.fTsumwx2;
         histo.fXaxis.fNbins = obj.fXaxis.fNbins;
         if (this.Dimension() > 1) {
            histo.fTsumwy = obj.fTsumwy;
            histo.fTsumwy2 = obj.fTsumwy2;
            histo.fTsumwxy = obj.fTsumwxy;
            histo.fYaxis.fNbins = obj.fYaxis.fNbins;
            if (this.Dimension() > 2) {
               histo.fTsumwz = obj.fTsumwz;
               histo.fTsumwz2 = obj.fTsumwz2;
               histo.fTsumwxz = obj.fTsumwxz;
               histo.fTsumwyz = obj.fTsumwyz;
               histo.fZaxis.fNbins = obj.fZaxis.fNbins;
            }
         }
         histo.fArray = obj.fArray;
         histo.fNcells = obj.fNcells;
         histo.fTitle = obj.fTitle;
         histo.fMinimum = obj.fMinimum;
         histo.fMaximum = obj.fMaximum;
         function CopyAxis(tgt,src) {
            tgt.fTitle = src.fTitle;
            tgt.fLabels = src.fLabels;
         }
         CopyAxis(histo.fXaxis, obj.fXaxis);
         CopyAxis(histo.fYaxis, obj.fYaxis);
         CopyAxis(histo.fZaxis, obj.fZaxis);
         if (!this.main_painter().zoom_changed_interactive) {
            function CopyZoom(tgt,src) {
               tgt.fXmin = src.fXmin;
               tgt.fXmax = src.fXmax;
               tgt.fFirst = src.fFirst;
               tgt.fLast = src.fLast;
               tgt.fBits = src.fBits;
            }
            CopyZoom(histo.fXaxis, obj.fXaxis);
            CopyZoom(histo.fYaxis, obj.fYaxis);
            CopyZoom(histo.fZaxis, obj.fZaxis);
         }
         histo.fSumw2 = obj.fSumw2;

         if (this.IsTProfile()) {
            histo.fBinEntries = obj.fBinEntries;
         }

         if (obj.fFunctions && !this.options.Same && this.options.Func)
            for (var n=0;n<obj.fFunctions.arr.length;++n) {
               var func = obj.fFunctions.arr[n];
               if (!func || !func._typename || !func.fName) continue;
               var funcpainter = this.FindPainterFor(null, func.fName, func._typename);
               if (funcpainter) funcpainter.UpdateObject(func);
            }
      }

      if (!this.zoom_changed_interactive) this.CheckPadRange();

      this.ScanContent();

      this.histogram_updated = true; // indicate that object updated

      return true;
   }

   JSROOT.THistPainter.prototype.CreateAxisFuncs = function(with_y_axis, with_z_axis) {
      // here functions are defined to convert index to axis value and back
      // introduced to support non-equidistant bins

      this.xmin = this.histo.fXaxis.fXmin;
      this.xmax = this.histo.fXaxis.fXmax;

      if (this.histo.fXaxis.fXbins.length == this.nbinsx+1) {
         this.regularx = false;
         this.GetBinX = function(bin) {
            var indx = Math.round(bin);
            if (indx <= 0) return this.xmin;
            if (indx > this.nbinsx) return this.xmax;
            if (indx==bin) return this.histo.fXaxis.fXbins[indx];
            var indx2 = (bin < indx) ? indx - 1 : indx + 1;
            return this.histo.fXaxis.fXbins[indx] * Math.abs(bin-indx2) + this.histo.fXaxis.fXbins[indx2] * Math.abs(bin-indx);
         };
         this.GetIndexX = function(x,add) {
            for (var k = 1; k < this.histo.fXaxis.fXbins.length; ++k)
               if (x < this.histo.fXaxis.fXbins[k]) return Math.floor(k-1+add);
            return this.nbinsx;
         };
      } else {
         this.regularx = true;
         this.binwidthx = (this.xmax - this.xmin);
         if (this.nbinsx > 0)
            this.binwidthx = this.binwidthx / this.nbinsx;

         this.GetBinX = function(bin) { return this.xmin + bin*this.binwidthx; };
         this.GetIndexX = function(x,add) { return Math.floor((x - this.xmin) / this.binwidthx + add); };
      }

      this.ymin = this.histo.fYaxis.fXmin;
      this.ymax = this.histo.fYaxis.fXmax;

      if (!with_y_axis || (this.nbinsy==0)) return;

      if (this.histo.fYaxis.fXbins.length == this.nbinsy+1) {
         this.regulary = false;
         this.GetBinY = function(bin) {
            var indx = Math.round(bin);
            if (indx <= 0) return this.ymin;
            if (indx > this.nbinsy) return this.ymax;
            if (indx==bin) return this.histo.fYaxis.fXbins[indx];
            var indx2 = (bin < indx) ? indx - 1 : indx + 1;
            return this.histo.fYaxis.fXbins[indx] * Math.abs(bin-indx2) + this.histo.fYaxis.fXbins[indx2] * Math.abs(bin-indx);
         };
         this.GetIndexY = function(y,add) {
            for (var k = 1; k < this.histo.fYaxis.fXbins.length; ++k)
               if (y < this.histo.fYaxis.fXbins[k]) return Math.floor(k-1+add);
            return this.nbinsy;
         };
      } else {
         this.regulary = true;
         this.binwidthy = (this.ymax - this.ymin);
         if (this.nbinsy > 0)
            this.binwidthy = this.binwidthy / this.nbinsy;

         this.GetBinY = function(bin) { return this.ymin+bin*this.binwidthy; };
         this.GetIndexY = function(y,add) { return Math.floor((y - this.ymin) / this.binwidthy + add); };
      }

      if (!with_z_axis || (this.nbinsz==0)) return;

      if (this.histo.fZaxis.fXbins.length == this.nbinsz+1) {
         this.regularz = false;
         this.GetBinZ = function(bin) {
            var indx = Math.round(bin);
            if (indx <= 0) return this.zmin;
            if (indx > this.nbinsz) return this.zmax;
            if (indx==bin) return this.histo.fZaxis.fXbins[indx];
            var indx2 = (bin < indx) ? indx - 1 : indx + 1;
            return this.histo.fZaxis.fXbins[indx] * Math.abs(bin-indx2) + this.histo.fZaxis.fXbins[indx2] * Math.abs(bin-indx);
         };
         this.GetIndexZ = function(z,add) {
            for (var k = 1; k < this.histo.fZaxis.fXbins.length; ++k)
               if (z < this.histo.fZaxis.fXbins[k]) return Math.floor(k-1+add);
            return this.nbinsz;
         };
      } else {
         this.regularz = true;
         this.binwidthz = (this.zmax - this.zmin);
         if (this.nbinsz > 0)
            this.binwidthz = this.binwidthz / this.nbinsz;

         this.GetBinZ = function(bin) { return this.zmin+bin*this.binwidthz; };
         this.GetIndexZ = function(z,add) { return Math.floor((z - this.zmin) / this.binwidthz + add); };
      }
   }

   JSROOT.THistPainter.prototype.CreateXY = function() {
      // here we create x,y objects which maps our physical coordnates into pixels
      // while only first painter really need such object, all others just reuse it
      // following functions are introduced
      //    this.GetBin[X/Y]  return bin coordinate
      //    this.Convert[X/Y]  converts root value in JS date when date scale is used
      //    this.[x,y]  these are d3.scale objects
      //    this.gr[x,y]  converts root scale into graphical value
      //    this.Revert[X/Y]  converts graphical coordinates to root scale value

      if (!this.is_main_painter()) {
         this.x = this.main_painter().x;
         this.y = this.main_painter().y;
         return;
      }

      this.swap_xy = false;
      if (this.options.Bar>=20) this.swap_xy = true;
      this.logx = this.logy = false;

      var w = this.frame_width(), h = this.frame_height(), pad = this.root_pad();

      if (this.histo.fXaxis.fTimeDisplay) {
         this.x_kind = 'time';
         this.timeoffsetx = JSROOT.Painter.getTimeOffset(this.histo.fXaxis);
         this.ConvertX = function(x) { return new Date(this.timeoffsetx + x*1000); };
         this.RevertX = function(grx) { return (this.x.invert(grx) - this.timeoffsetx) / 1000; };
      } else {
         this.x_kind = (this.histo.fXaxis.fLabels==null) ? 'normal' : 'labels';
         this.ConvertX = function(x) { return x; };
         this.RevertX = function(grx) { return this.x.invert(grx); };
      }

      this.scale_xmin = this.xmin;
      this.scale_xmax = this.xmax;
      if (this.zoom_xmin != this.zoom_xmax) {
         this.scale_xmin = this.zoom_xmin;
         this.scale_xmax = this.zoom_xmax;
      }
      if (this.x_kind == 'time') {
         this.x = d3.scaleTime();
      } else
      if (this.swap_xy ? pad.fLogy : pad.fLogx) {
         this.logx = true;

         if (this.scale_xmax <= 0) this.scale_xmax = 0;

         if ((this.scale_xmin <= 0) && (this.nbinsx>0))
            for (var i=0;i<this.nbinsx;++i) {
               this.scale_xmin = Math.max(this.scale_xmin, this.GetBinX(i));
               if (this.scale_xmin>0) break;
            }

         if ((this.scale_xmin <= 0) || (this.scale_xmin >= this.scale_xmax))
            this.scale_xmin = this.scale_xmax * 0.0001;

         this.xmin_log = this.scale_xmin;

         this.x = d3.scaleLog();
      } else {
         this.x = d3.scaleLinear();
      }

      this.x.domain([this.ConvertX(this.scale_xmin), this.ConvertX(this.scale_xmax)])
            .range(this.swap_xy ? [ h, 0 ] : [ 0, w ]);

      if (this.x_kind == 'time') {
         // we emulate scale functionality
         this.grx = function(val) { return this.x(this.ConvertX(val)); }
      } else
      if (this.logx) {
         this.grx = function(val) { return (val < this.scale_xmin) ? (this.swap_xy ? this.x.range()[0]+5 : -5) : this.x(val); }
      } else {
         this.grx = this.x;
      }

      this.scale_ymin = this.ymin;
      this.scale_ymax = this.ymax;
      if (this.zoom_ymin != this.zoom_ymax) {
         this.scale_ymin = this.zoom_ymin;
         this.scale_ymax = this.zoom_ymax;
      }

      if (this.histo.fYaxis.fTimeDisplay) {
         this.y_kind = 'time';
         this.timeoffsety = JSROOT.Painter.getTimeOffset(this.histo.fYaxis);
         this.ConvertY = function(y) { return new Date(this.timeoffsety + y*1000); };
         this.RevertY = function(gry) { return (this.y.invert(gry) - this.timeoffsety) / 1000; };
      } else {
         this.y_kind = ((this.Dimension()==2) && (this.histo.fYaxis.fLabels!=null)) ? 'labels' : 'normal';
         this.ConvertY = function(y) { return y; };
         this.RevertY = function(gry) { return this.y.invert(gry); };
      }

      if (this.swap_xy ? pad.fLogx : pad.fLogy) {
         this.logy = true;
         if (this.scale_ymax <= 0)
            this.scale_ymax = 1;
         else
         if ((this.zoom_ymin === this.zoom_ymax) && (this.Dimension()==1))
            this.scale_ymax*=1.8;

         // this is for 2/3 dim histograms - find first non-negative bin
         if ((this.scale_ymin <= 0) && (this.nbinsy>0) && (this.Dimension()>1))
            for (var i=0;i<this.nbinsy;++i) {
               this.scale_ymin = Math.max(this.scale_ymin, this.GetBinY(i));
               if (this.scale_ymin>0) break;
            }

         if ((this.scale_ymin <= 0) && ('ymin_nz' in this) && (this.ymin_nz > 0) && (this.ymin_nz < 1e-2*this.ymax))
            this.scale_ymin = 0.3*this.ymin_nz;

         if ((this.scale_ymin <= 0) || (this.scale_ymin >= this.scale_ymax))
            this.scale_ymin = 3e-4 * this.scale_ymax;

         this.ymin_log = this.scale_ymin;

         this.y = d3.scaleLog();
      } else
      if (this.y_kind=='time') {
         this.y = d3.scaleTime();
      } else {
         this.y = d3.scaleLinear()
      }

      this.y.domain([ this.ConvertY(this.scale_ymin), this.ConvertY(this.scale_ymax) ])
            .range(this.swap_xy ? [ 0, w ] : [ h, 0 ]);

      if (this.y_kind=='time') {
         // we emulate scale functionality
         this.gry = function(val) { return this.y(this.ConvertY(val)); }
      } else
      if (this.logy) {
         // make protecttion for log
         this.gry = function(val) { return (val < this.scale_ymin) ? (this.swap_xy ? -5 : this.y.range()[0]+5) : this.y(val); }
      } else {
         this.gry = this.y;
      }

      this.SetRootPadRange(pad);
   }

   /** Set selected range back to TPad object */
   JSROOT.THistPainter.prototype.SetRootPadRange = function(pad) {
      if (!pad) return;

      if (this.logx) {
         pad.fUxmin = JSROOT.log10(this.scale_xmin);
         pad.fUxmax = JSROOT.log10(this.scale_xmax);
      } else {
         pad.fUxmin = this.scale_xmin;
         pad.fUxmax = this.scale_xmax;
      }
      if (this.logy) {
         pad.fUymin = JSROOT.log10(this.scale_ymin);
         pad.fUymax = JSROOT.log10(this.scale_ymax);
      } else {
         pad.fUymin = this.scale_ymin;
         pad.fUymax = this.scale_ymax;
      }

      var rx = pad.fUxmax - pad.fUxmin,
          mx = 1 - pad.fLeftMargin - pad.fRightMargin,
          ry = pad.fUymax - pad.fUymin,
          my = 1 - pad.fBottomMargin - pad.fTopMargin;

      pad.fX1 = pad.fUxmin - rx/mx*pad.fLeftMargin;
      pad.fX2 = pad.fUxmax + rx/mx*pad.fRightMargin;
      pad.fY1 = pad.fUymin - ry/my*pad.fBottomMargin;
      pad.fY2 = pad.fUymax + ry/my*pad.fTopMargin;
   }

   JSROOT.THistPainter.prototype.DrawGrids = function() {
      // grid can only be drawn by first painter
      if (!this.is_main_painter()) return;

      var layer = this.svg_frame().select(".grid_layer");

      layer.selectAll(".xgrid").remove();
      layer.selectAll(".ygrid").remove();

      var pad = this.root_pad(), h = this.frame_height(), w = this.frame_width(),
          grid, grid_style = JSROOT.gStyle.fGridStyle, grid_color = "black";

      if (JSROOT.Painter.fGridColor > 0)
         grid_color = JSROOT.Painter.root_colors[JSROOT.Painter.fGridColor];

      if ((grid_style < 0) || (grid_style >= JSROOT.Painter.root_line_styles.length)) grid_style = 11;

      // add a grid on x axis, if the option is set
      if (pad && pad.fGridx && this.x_handle) {
         grid = "";
         for (var n=0;n<this.x_handle.ticks.length;++n)
            if (this.swap_xy)
               grid += "M0,"+this.x_handle.ticks[n]+"h"+w;
            else
               grid += "M"+this.x_handle.ticks[n]+",0v"+h;

         if (grid.length > 0)
          layer.append("svg:path")
               .attr("class", "xgrid")
               .attr("d", grid)
               .style('stroke',grid_color).style("stroke-width",JSROOT.gStyle.fGridWidth)
               .style("stroke-dasharray",JSROOT.Painter.root_line_styles[grid_style]);
      }

      // add a grid on y axis, if the option is set
      if (pad && pad.fGridy && this.y_handle) {
         grid = "";
         for (var n=0;n<this.y_handle.ticks.length;++n)
            if (this.swap_xy)
               grid += "M"+this.y_handle.ticks[n]+",0v"+h;
            else
               grid += "M0,"+this.y_handle.ticks[n]+"h"+w;

         if (grid.length > 0)
          layer.append("svg:path")
               .attr("class", "ygrid")
               .attr("d", grid)
               .style('stroke',grid_color).style("stroke-width",JSROOT.gStyle.fGridWidth)
               .style("stroke-dasharray", JSROOT.Painter.root_line_styles[grid_style]);
      }
   }

   JSROOT.THistPainter.prototype.DrawBins = function() {
      alert("HistPainter.DrawBins not implemented");
   }

   JSROOT.THistPainter.prototype.AxisAsText = function(axis, value) {
      if (axis == "x") {
         if (this.x_kind == 'time')
            value = this.ConvertX(value);

         if (this.x_handle && ('format' in this.x_handle))
            return this.x_handle.format(value);

         return value.toPrecision(4);
      }

      if (axis == "y") {
         if (this.y_kind == 'time')
            value = this.ConvertY(value);

         if (this.y_handle && ('format' in this.y_handle))
            return this.y_handle.format(value);

         return value.toPrecision(4);
      }

      return value.toPrecision(4);
   }

   JSROOT.THistPainter.prototype.DrawAxes = function(shrink_forbidden) {
      // axes can be drawn only for main histogram

      if (!this.is_main_painter()) return;

      var layer = this.svg_frame().select(".axis_layer"),
          w = this.frame_width(),
          h = this.frame_height(),
          pad = this.root_pad();

      this.x_handle = new JSROOT.TAxisPainter(this.histo.fXaxis, true);
      this.x_handle.SetDivId(this.divid, -1);
      this.x_handle.pad_name = this.pad_name;

      this.x_handle.SetAxisConfig("xaxis",
                                  (this.logx && (this.x_kind !== "time")) ? "log" : this.x_kind,
                                  this.x, this.xmin, this.xmax, this.scale_xmin, this.scale_xmax);
      this.x_handle.invert_side = (this.options.AxisPos>=10);

      this.y_handle = new JSROOT.TAxisPainter(this.histo.fYaxis, true);
      this.y_handle.SetDivId(this.divid, -1);
      this.y_handle.pad_name = this.pad_name;

      this.y_handle.SetAxisConfig("yaxis",
                                  (this.logy && this.y_kind !== "time") ? "log" : this.y_kind,
                                  this.y, this.ymin, this.ymax, this.scale_ymin, this.scale_ymax);
      this.y_handle.invert_side = (this.options.AxisPos % 10) === 1;

      var draw_horiz = this.swap_xy ? this.y_handle : this.x_handle,
          draw_vertical = this.swap_xy ? this.x_handle : this.y_handle;

      draw_horiz.DrawAxis(false, layer, w, h, draw_horiz.invert_side ? undefined : "translate(0," + h + ")",
                          false, pad.fTickx ? -h : 0);
      draw_vertical.DrawAxis(true, layer, w, h, draw_vertical.invert_side ? "translate(" + w + ",0)" : undefined,
                             false, pad.fTicky ? w : 0);

      if (shrink_forbidden) return;

      var shrink = 0., ypos = draw_vertical.position;

      if ((-0.2*w < ypos) && (ypos < 0)) {
         shrink = -ypos/w + 0.001;
         this.shrink_frame_left += shrink;
      } else
      if ((ypos>0) && (ypos<0.3*w) && (this.shrink_frame_left > 0) && (ypos/w > this.shrink_frame_left)) {
         shrink = -this.shrink_frame_left;
         this.shrink_frame_left = 0.;
      }

      if (shrink != 0) {
         this.frame_painter().Shrink(shrink, 0);
         this.frame_painter().Redraw();
         this.CreateXY();
         this.DrawAxes(true);
      }
   }

   JSROOT.THistPainter.prototype.ToggleTitle = function(arg) {
      if (!this.is_main_painter()) return false;
      if (arg==='only-check') return !this.histo.TestBit(JSROOT.TH1StatusBits.kNoTitle);
      this.histo.InvertBit(JSROOT.TH1StatusBits.kNoTitle);
      this.DrawTitle();
   }

   JSROOT.THistPainter.prototype.DrawTitle = function() {

      // case when histogram drawn over other histogram (same option)
      if (!this.is_main_painter()) return;

      var tpainter = this.FindPainterFor(null, "title");
      var pavetext = (tpainter !== null) ? tpainter.GetObject() : null;
      if (pavetext === null) pavetext = this.FindInPrimitives("title");
      if ((pavetext !== null) && (pavetext._typename !== "TPaveText")) pavetext = null;

      var draw_title = !this.histo.TestBit(JSROOT.TH1StatusBits.kNoTitle);

      if (pavetext !== null) {
         pavetext.Clear();
         if (draw_title)
            pavetext.AddText(this.histo.fTitle);
         if (tpainter) tpainter.Redraw();
      } else
      if (draw_title && !tpainter && (this.histo.fTitle.length > 0)) {
         pavetext = JSROOT.Create("TPaveText");

         JSROOT.extend(pavetext, { fName: "title", fX1NDC: 0.28, fY1NDC: 0.94, fX2NDC: 0.72, fY2NDC: 0.99 } );
         pavetext.AddText(this.histo.fTitle);

         JSROOT.Painter.drawPaveText(this.divid, pavetext);
      }
   }

   JSROOT.THistPainter.prototype.UpdateStatWebCanvas = function() {
      if (!this.snapid) return;

      var stat = this.FindStat(),
          statpainter = this.FindPainterFor(stat);

      if (statpainter && !statpainter.snapid) statpainter.Redraw();
   }

   JSROOT.THistPainter.prototype.ToggleStat = function(arg) {

      var stat = this.FindStat(), statpainter = null;

      if (!arg) arg = "";

      if (stat == null) {
         if (arg.indexOf('-check')>0) return false;
         // when statbox created first time, one need to draw it
         stat = this.CreateStat();
      } else {
         statpainter = this.FindPainterFor(stat);
      }

      if (arg=='only-check') return statpainter ? statpainter.Enabled : false;

      if (arg=='fitpar-check') return stat ? stat.fOptFit : false;

      if (arg=='fitpar-toggle') {
         if (!stat) return false;
         stat.fOptFit = stat.fOptFit ? 0 : 1111; // for websocket command should be send to server
         if (statpainter) statpainter.Redraw();
         return true;
      }

      if (statpainter) {
         statpainter.Enabled = !statpainter.Enabled;
         // when stat box is drawed, it always can be draw individualy while it
         // should be last for colz RedrawPad is used
         statpainter.Redraw();
         return statpainter.Enabled;
      }

      JSROOT.draw(this.divid, stat, "onpad:" + this.pad_name);

      return true;
   }

   JSROOT.THistPainter.prototype.IsAxisZoomed = function(axis) {
      var obj = this.main_painter() || this;
      return obj['zoom_'+axis+'min'] !== obj['zoom_'+axis+'max'];
   }

   JSROOT.THistPainter.prototype.GetSelectIndex = function(axis, size, add) {
      // be aware - here indexs starts from 0
      var indx = 0, obj = this.main_painter();
      if (!obj) obj = this;
      var nbin = this['nbins'+axis];
      if (!nbin) nbin = 0;
      if (!add) add = 0;

      var func = 'GetIndex' + axis.toUpperCase(),
          min = obj['zoom_' + axis + 'min'],
          max = obj['zoom_' + axis + 'max'];

      if ((min != max) && (func in this)) {
         if (size == "left") {
            indx = this[func](min, add);
         } else {
            indx = this[func](max, add + 0.5);
         }
      } else {
         indx = (size == "left") ? 0 : nbin;
      }

      var taxis; // TAxis object of histogram, where user range can be stored
      if (this.histo) taxis  = this.histo["f" + axis.toUpperCase() + "axis"];
      if (taxis) {
         if ((taxis.fFirst === taxis.fLast) || !taxis.TestBit(JSROOT.EAxisBits.kAxisRange) ||
             ((taxis.fFirst<=1) && (taxis.fLast>=nbin))) taxis = undefined;
      }

      if (size == "left") {
         if (indx < 0) indx = 0;
         if (taxis && (taxis.fFirst>1) && (indx<taxis.fFirst)) indx = taxis.fFirst-1;
      } else {
         if (indx > nbin) indx = nbin;
         if (taxis && (taxis.fLast <= nbin) && (indx>taxis.fLast)) indx = taxis.fLast;
      }

      return indx;
   }

   JSROOT.THistPainter.prototype.FindStat = function() {
      if (this.histo.fFunctions !== null)
         for (var i = 0; i < this.histo.fFunctions.arr.length; ++i) {
            var func = this.histo.fFunctions.arr[i];

            if ((func._typename == 'TPaveStats') &&
                (func.fName == 'stats')) return func;
         }

      return null;
   }

   JSROOT.THistPainter.prototype.CreateStat = function(opt_stat) {

      if (!this.draw_content || !this.is_main_painter()) return null;

      this.create_stats = true;

      var stats = this.FindStat();
      if (stats) return stats;

      var st = JSROOT.gStyle;

      stats = JSROOT.Create('TPaveStats');
      JSROOT.extend(stats, { fName : 'stats',
                             fOptStat: opt_stat || st.fOptStat,
                             fOptFit: st.fOptFit,
                             fBorderSize : 1} );

      stats.fX1NDC = st.fStatX - st.fStatW;
      stats.fY1NDC = st.fStatY - st.fStatH;
      stats.fX2NDC = st.fStatX;
      stats.fY2NDC = st.fStatY;

      stats.fFillColor = st.fStatColor;
      stats.fFillStyle = st.fStatStyle;

      stats.fTextAngle = 0;
      stats.fTextSize = st.fStatFontSize; // 9 ??
      stats.fTextAlign = 12;
      stats.fTextColor = st.fStatTextColor;
      stats.fTextFont = st.fStatFont;

//      st.fStatBorderSize : 1,

      if (this.histo._typename.match(/^TProfile/) || this.histo._typename.match(/^TH2/))
         stats.fY1NDC = 0.67;

      stats.AddText(this.histo.fName);

      if (!this.histo.fFunctions)
         this.histo.fFunctions = JSROOT.Create("TList");

      this.histo.fFunctions.Add(stats,"");

      return stats;
   }

   JSROOT.THistPainter.prototype.AddFunction = function(obj, asfirst) {
      var histo = this.GetObject();
      if (!histo || !obj) return;

      if (histo.fFunctions == null)
         histo.fFunctions = JSROOT.Create("TList");

      if (asfirst)
         histo.fFunctions.AddFirst(obj);
      else
         histo.fFunctions.Add(obj);

   }

   JSROOT.THistPainter.prototype.FindFunction = function(type_name) {
      var funcs = this.GetObject().fFunctions;
      if (funcs === null) return null;

      for (var i = 0; i < funcs.arr.length; ++i)
         if (funcs.arr[i]._typename === type_name) return funcs.arr[i];

      return null;
   }

   JSROOT.THistPainter.prototype.DrawNextFunction = function(indx, callback) {
      // method draws next function from the functions list

      if (this.options.Same || !this.options.Func || !this.histo.fFunctions ||
           (indx >= this.histo.fFunctions.arr.length)) return JSROOT.CallBack(callback);

      var func = this.histo.fFunctions.arr[indx],
          opt = this.histo.fFunctions.opt[indx],
          do_draw = false,
          func_painter = this.FindPainterFor(func);

      // no need to do something if painter for object was already done
      // object will be redraw automatically
      if (func_painter === null) {
         if (func._typename === 'TPaveText' || func._typename === 'TPaveStats') {
            do_draw = !this.histo.TestBit(JSROOT.TH1StatusBits.kNoStats) && (this.options.NoStat!=1);
         } else
         if (func._typename === 'TF1') {
            do_draw = !func.TestBit(JSROOT.BIT(9));
         } else
            do_draw = (func._typename !== "TPaletteAxis");
      }

      if (do_draw)
         return JSROOT.draw(this.divid, func, opt, this.DrawNextFunction.bind(this, indx+1, callback));

      this.DrawNextFunction(indx+1, callback);
   }

   JSROOT.THistPainter.prototype.UnzoomUserRange = function(dox, doy, doz) {

      if (!this.histo) return false;

      var res = false, painter = this;

      function UnzoomTAxis(obj) {
         if (!obj) return false;
         if (!obj.TestBit(JSROOT.EAxisBits.kAxisRange)) return false;
         if (obj.fFirst === obj.fLast) return false;
         if ((obj.fFirst <= 1) && (obj.fLast >= obj.fNbins)) return false;
         obj.InvertBit(JSROOT.EAxisBits.kAxisRange);
         return true;
      }

      function UzoomMinMax(ndim, hist) {
         if (painter.Dimension()!==ndim) return false;
         if ((painter.options.minimum===-1111) && (painter.options.maximum===-1111)) return false;
         if (!painter.draw_content) return false; // if not drawin content, not change min/max
         painter.options.minimum = painter.options.maximum = -1111;
         painter.ScanContent(true); // to reset ymin/ymax
         return true;
      }

      if (dox && UnzoomTAxis(this.histo.fXaxis)) res = true;
      if (doy && (UnzoomTAxis(this.histo.fYaxis) || UzoomMinMax(1, this.histo))) res = true;
      if (doz && (UnzoomTAxis(this.histo.fZaxis) || UzoomMinMax(2, this.histo))) res = true;

      return res;
   }

   JSROOT.THistPainter.prototype.ToggleLog = function(axis) {
      var obj = this.main_painter(), pad = this.root_pad();
      if (!obj) obj = this;
      var curr = pad["fLog" + axis];
      // do not allow log scale for labels
      if (!curr) {
         var kind = this[axis+"_kind"];
         if (this.swap_xy && axis==="x") kind = this["y_kind"]; else
         if (this.swap_xy && axis==="y") kind = this["x_kind"];
         if (kind === "labels") return;
      }
      var pp = this.pad_painter();
      if (pp && pp._websocket) {
         pp._websocket.send("EXEC:SetLog" + axis + (curr ? "(0)" : "(1)"));
      } else {
         pad["fLog" + axis] = curr ? 0 : 1;
         obj.RedrawPad();
      }
   }

   JSROOT.THistPainter.prototype.Zoom = function(xmin, xmax, ymin, ymax, zmin, zmax) {
      // function can be used for zooming into specified range
      // if both limits for each axis 0 (like xmin==xmax==0), axis will be unzoomed

      if (xmin==="x") { xmin = xmax; xmax = ymin; ymin = undefined; } else
      if (xmin==="y") { ymax = ymin; ymin = xmax; xmin = xmax = undefined; } else
      if (xmin==="z") { zmin = xmax; zmax = ymin; xmin = xmax = ymin = undefined; }

      var main = this.main_painter(),
          zoom_x = (xmin !== xmax), zoom_y = (ymin !== ymax), zoom_z = (zmin !== zmax),
          unzoom_x = false, unzoom_y = false, unzoom_z = false;

      if (zoom_x) {
         var cnt = 0, main_xmin = main.xmin;
         if (main.logx && main.xmin_log) main_xmin = main.xmin_log;
         if (xmin <= main_xmin) { xmin = main_xmin; cnt++; }
         if (xmax >= main.xmax) { xmax = main.xmax; cnt++; }
         if (cnt === 2) { zoom_x = false; unzoom_x = true; }
      } else {
         unzoom_x = (xmin === xmax) && (xmin === 0);
      }

      if (zoom_y) {
         var cnt = 0, main_ymin = main.ymin;
         if (main.logy && main.ymin_log) main_ymin = main.ymin_log;
         if (ymin <= main_ymin) { ymin = main_ymin; cnt++; }
         if (ymax >= main.ymax) { ymax = main.ymax; cnt++; }
         if (cnt === 2) { zoom_y = false; unzoom_y = true; }
      } else {
         unzoom_y = (ymin === ymax) && (ymin === 0);
      }

      if (zoom_z) {
         var cnt = 0, main_zmin = main.zmin;
         // if (main.logz && main.ymin_nz && main.Dimension()===2) main_zmin = 0.3*main.ymin_nz;
         if (zmin <= main_zmin) { zmin = main_zmin; cnt++; }
         if (zmax >= main.zmax) { zmax = main.zmax; cnt++; }
         if (cnt === 2) { zoom_z = false; unzoom_z = true; }
      } else {
         unzoom_z = (zmin === zmax) && (zmin === 0);
      }

      var changed = false;

      // first process zooming (if any)
      if (zoom_x || zoom_y || zoom_z)
         main.ForEachPainter(function(obj) {
            if (zoom_x && obj.CanZoomIn("x", xmin, xmax)) {
               main.zoom_xmin = xmin;
               main.zoom_xmax = xmax;
               changed = true;
               zoom_x = false;
            }
            if (zoom_y && obj.CanZoomIn("y", ymin, ymax)) {
               main.zoom_ymin = ymin;
               main.zoom_ymax = ymax;
               changed = true;
               zoom_y = false;
            }
            if (zoom_z && obj.CanZoomIn("z", zmin, zmax)) {
               main.zoom_zmin = zmin;
               main.zoom_zmax = zmax;
               changed = true;
               zoom_z = false;
            }
         });

      // and process unzoom, if any
      if (unzoom_x || unzoom_y || unzoom_z) {
         if (unzoom_x) {
            if (main.zoom_xmin !== main.zoom_xmax) changed = true;
            main.zoom_xmin = main.zoom_xmax = 0;
         }
         if (unzoom_y) {
            if (main.zoom_ymin !== main.zoom_ymax) changed = true;
            main.zoom_ymin = main.zoom_ymax = 0;
         }
         if (unzoom_z) {
            if (main.zoom_zmin !== main.zoom_zmax) changed = true;
            main.zoom_zmin = main.zoom_zmax = 0;
         }

         // first try to unzoom main painter - it could have user range specified
         if (!changed) {
            changed = main.UnzoomUserRange(unzoom_x, unzoom_y, unzoom_z);

            // than try to unzoom all overlapped objects
            var pp = this.pad_painter(true);
            if (pp && pp.painters)
            pp.painters.forEach(function(paint){
               if (paint && (paint!==main) && (typeof paint.UnzoomUserRange == 'function'))
                  if (paint.UnzoomUserRange(unzoom_x, unzoom_y, unzoom_z)) changed = true;
            });
         }
      }

      if (changed) this.RedrawPad();

      return changed;
   }

   JSROOT.THistPainter.prototype.Unzoom = function(dox, doy, doz) {
      if (typeof dox === 'undefined') { dox = true; doy = true; doz = true; } else
      if (typeof dox === 'string') { doz = dox.indexOf("z")>=0; doy = dox.indexOf("y")>=0; dox = dox.indexOf("x")>=0; }

      var last = this.zoom_changed_interactive;

      if (dox || doy || dox) this.zoom_changed_interactive = 2;

      var changed = this.Zoom(dox ? 0 : undefined, dox ? 0 : undefined,
                              doy ? 0 : undefined, doy ? 0 : undefined,
                              doz ? 0 : undefined, doz ? 0 : undefined);

      // if unzooming has no effect, decrease counter
      if ((dox || doy || dox) && !changed)
         this.zoom_changed_interactive = (!isNaN(last) && (last>0)) ? last - 1 : 0;

      return changed;

   }

   JSROOT.THistPainter.prototype.clearInteractiveElements = function() {
      JSROOT.Painter.closeMenu();
      if (this.zoom_rect != null) { this.zoom_rect.remove(); this.zoom_rect = null; }
      this.zoom_kind = 0;

      // enable tooltip in frame painter
      this.SwitchTooltip(true);
   }

   JSROOT.THistPainter.prototype.mouseDoubleClick = function() {
      d3.event.preventDefault();
      var m = d3.mouse(this.svg_frame().node());
      this.clearInteractiveElements();
      var kind = "xyz";
      if ((m[0] < 0) || (m[0] > this.frame_width())) kind = this.swap_xy ? "x" : "y"; else
      if ((m[1] < 0) || (m[1] > this.frame_height())) kind = this.swap_xy ? "y" : "x";
      this.Unzoom(kind);
   }

   JSROOT.THistPainter.prototype.startRectSel = function() {
      // ignore when touch selection is actiavated

      if (this.zoom_kind > 100) return;

      // ignore all events from non-left button
      if ((d3.event.which || d3.event.button) !== 1) return;

      d3.event.preventDefault();

      this.clearInteractiveElements();
      this.zoom_origin = d3.mouse(this.svg_frame().node());

      var w = this.frame_width(), h = this.frame_height();

      this.zoom_curr = [ Math.max(0, Math.min(w, this.zoom_origin[0])),
                         Math.max(0, Math.min(h, this.zoom_origin[1])) ];

      if ((this.zoom_origin[0] < 0) || (this.zoom_origin[0] > w)) {
         this.zoom_kind = 3; // only y
         this.zoom_origin[0] = 0;
         this.zoom_origin[1] = this.zoom_curr[1];
         this.zoom_curr[0] = w;
         this.zoom_curr[1] += 1;
      } else if ((this.zoom_origin[1] < 0) || (this.zoom_origin[1] > h)) {
         this.zoom_kind = 2; // only x
         this.zoom_origin[0] = this.zoom_curr[0];
         this.zoom_origin[1] = 0;
         this.zoom_curr[0] += 1;
         this.zoom_curr[1] = h;
      } else {
         this.zoom_kind = 1; // x and y
         this.zoom_origin[0] = this.zoom_curr[0];
         this.zoom_origin[1] = this.zoom_curr[1];
      }

      d3.select(window).on("mousemove.zoomRect", this.moveRectSel.bind(this))
                       .on("mouseup.zoomRect", this.endRectSel.bind(this), true);

      this.zoom_rect = null;

      // disable tooltips in frame painter
      this.SwitchTooltip(false);

      d3.event.stopPropagation();
   }

   JSROOT.THistPainter.prototype.moveRectSel = function() {

      if ((this.zoom_kind == 0) || (this.zoom_kind > 100)) return;

      d3.event.preventDefault();
      var m = d3.mouse(this.svg_frame().node());

      m[0] = Math.max(0, Math.min(this.frame_width(), m[0]));
      m[1] = Math.max(0, Math.min(this.frame_height(), m[1]));

      switch (this.zoom_kind) {
         case 1: this.zoom_curr[0] = m[0]; this.zoom_curr[1] = m[1]; break;
         case 2: this.zoom_curr[0] = m[0]; break;
         case 3: this.zoom_curr[1] = m[1]; break;
      }

      if (this.zoom_rect===null)
         this.zoom_rect = this.svg_frame()
                              .append("rect")
                              .attr("class", "zoom")
                              .attr("pointer-events","none");

      this.zoom_rect.attr("x", Math.min(this.zoom_origin[0], this.zoom_curr[0]))
                    .attr("y", Math.min(this.zoom_origin[1], this.zoom_curr[1]))
                    .attr("width", Math.abs(this.zoom_curr[0] - this.zoom_origin[0]))
                    .attr("height", Math.abs(this.zoom_curr[1] - this.zoom_origin[1]));
   }

   JSROOT.THistPainter.prototype.endRectSel = function() {
      if ((this.zoom_kind == 0) || (this.zoom_kind > 100)) return;

      d3.event.preventDefault();

      d3.select(window).on("mousemove.zoomRect", null)
                       .on("mouseup.zoomRect", null);

      var m = d3.mouse(this.svg_frame().node());

      m[0] = Math.max(0, Math.min(this.frame_width(), m[0]));
      m[1] = Math.max(0, Math.min(this.frame_height(), m[1]));

      var changed = [true, true];

      switch (this.zoom_kind) {
         case 1: this.zoom_curr[0] = m[0]; this.zoom_curr[1] = m[1]; break;
         case 2: this.zoom_curr[0] = m[0]; changed[1] = false; break; // only X
         case 3: this.zoom_curr[1] = m[1]; changed[0] = false; break; // only Y
      }

      var xmin, xmax, ymin, ymax, isany = false,
          idx = this.swap_xy ? 1 : 0, idy = 1 - idx;

      if (changed[idx] && (Math.abs(this.zoom_curr[idx] - this.zoom_origin[idx]) > 10)) {
         xmin = Math.min(this.RevertX(this.zoom_origin[idx]), this.RevertX(this.zoom_curr[idx]));
         xmax = Math.max(this.RevertX(this.zoom_origin[idx]), this.RevertX(this.zoom_curr[idx]));
         isany = true;
      }

      if (changed[idy] && (Math.abs(this.zoom_curr[idy] - this.zoom_origin[idy]) > 10)) {
         ymin = Math.min(this.RevertY(this.zoom_origin[idy]), this.RevertY(this.zoom_curr[idy]));
         ymax = Math.max(this.RevertY(this.zoom_origin[idy]), this.RevertY(this.zoom_curr[idy]));
         isany = true;
      }

      this.clearInteractiveElements();

      if (isany) {
         this.zoom_changed_interactive = 2;
         this.Zoom(xmin, xmax, ymin, ymax);
      }
   }

   JSROOT.THistPainter.prototype.startTouchZoom = function() {
      // in case when zooming was started, block any other kind of events
      if (this.zoom_kind != 0) {
         d3.event.preventDefault();
         d3.event.stopPropagation();
         return;
      }

      var arr = d3.touches(this.svg_frame().node());
      this.touch_cnt+=1;

      // normally double-touch will be handled
      // touch with single click used for context menu
      if (arr.length == 1) {
         // this is touch with single element

         var now = new Date();
         var diff = now.getTime() - this.last_touch.getTime();
         this.last_touch = now;

         if ((diff < 300) && (this.zoom_curr != null)
               && (Math.abs(this.zoom_curr[0] - arr[0][0]) < 30)
               && (Math.abs(this.zoom_curr[1] - arr[0][1]) < 30)) {

            d3.event.preventDefault();
            d3.event.stopPropagation();

            this.clearInteractiveElements();
            this.Unzoom("xyz");

            this.last_touch = new Date(0);

            this.svg_frame().on("touchcancel", null)
                            .on("touchend", null, true);
         } else
         if (JSROOT.gStyle.ContextMenu) {
            this.zoom_curr = arr[0];
            this.svg_frame().on("touchcancel", this.endTouchSel.bind(this))
                            .on("touchend", this.endTouchSel.bind(this));
            d3.event.preventDefault();
            d3.event.stopPropagation();
         }
      }

      if ((arr.length != 2) || !JSROOT.gStyle.Zooming || !JSROOT.gStyle.ZoomTouch) return;

      d3.event.preventDefault();
      d3.event.stopPropagation();

      this.clearInteractiveElements();

      this.svg_frame().on("touchcancel", null)
                      .on("touchend", null);

      var pnt1 = arr[0], pnt2 = arr[1], w = this.frame_width(), h = this.frame_height();

      this.zoom_curr = [ Math.min(pnt1[0], pnt2[0]), Math.min(pnt1[1], pnt2[1]) ];
      this.zoom_origin = [ Math.max(pnt1[0], pnt2[0]), Math.max(pnt1[1], pnt2[1]) ];

      if ((this.zoom_curr[0] < 0) || (this.zoom_curr[0] > w)) {
         this.zoom_kind = 103; // only y
         this.zoom_curr[0] = 0;
         this.zoom_origin[0] = w;
      } else if ((this.zoom_origin[1] > h) || (this.zoom_origin[1] < 0)) {
         this.zoom_kind = 102; // only x
         this.zoom_curr[1] = 0;
         this.zoom_origin[1] = h;
      } else {
         this.zoom_kind = 101; // x and y
      }

      this.SwitchTooltip(false);

      this.zoom_rect = this.svg_frame().append("rect")
            .attr("class", "zoom")
            .attr("id", "zoomRect")
            .attr("x", this.zoom_curr[0])
            .attr("y", this.zoom_curr[1])
            .attr("width", this.zoom_origin[0] - this.zoom_curr[0])
            .attr("height", this.zoom_origin[1] - this.zoom_curr[1]);

      d3.select(window).on("touchmove.zoomRect", this.moveTouchSel.bind(this))
                       .on("touchcancel.zoomRect", this.endTouchSel.bind(this))
                       .on("touchend.zoomRect", this.endTouchSel.bind(this));
   }

   JSROOT.THistPainter.prototype.moveTouchSel = function() {
      if (this.zoom_kind < 100) return;

      d3.event.preventDefault();

      var arr = d3.touches(this.svg_frame().node());

      if (arr.length != 2)
         return this.clearInteractiveElements();

      var pnt1 = arr[0], pnt2 = arr[1];

      if (this.zoom_kind != 103) {
         this.zoom_curr[0] = Math.min(pnt1[0], pnt2[0]);
         this.zoom_origin[0] = Math.max(pnt1[0], pnt2[0]);
      }
      if (this.zoom_kind != 102) {
         this.zoom_curr[1] = Math.min(pnt1[1], pnt2[1]);
         this.zoom_origin[1] = Math.max(pnt1[1], pnt2[1]);
      }

      this.zoom_rect.attr("x", this.zoom_curr[0])
                     .attr("y", this.zoom_curr[1])
                     .attr("width", this.zoom_origin[0] - this.zoom_curr[0])
                     .attr("height", this.zoom_origin[1] - this.zoom_curr[1]);

      if ((this.zoom_origin[0] - this.zoom_curr[0] > 10)
           || (this.zoom_origin[1] - this.zoom_curr[1] > 10))
         this.SwitchTooltip(false);

      d3.event.stopPropagation();
   }

   JSROOT.THistPainter.prototype.endTouchSel = function() {

      this.svg_frame().on("touchcancel", null)
                      .on("touchend", null);

      if (this.zoom_kind === 0) {
         // special case - single touch can ends up with context menu

         d3.event.preventDefault();

         var now = new Date();

         var diff = now.getTime() - this.last_touch.getTime();

         if ((diff > 500) && (diff<2000) && !this.frame_painter().IsTooltipShown()) {
            this.ShowContextMenu('main', { clientX: this.zoom_curr[0], clientY: this.zoom_curr[1] });
            this.last_touch = new Date(0);
         } else {
            this.clearInteractiveElements();
         }
      }

      if (this.zoom_kind < 100) return;

      d3.event.preventDefault();
      d3.select(window).on("touchmove.zoomRect", null)
                       .on("touchend.zoomRect", null)
                       .on("touchcancel.zoomRect", null);

      var xmin, xmax, ymin, ymax, isany = false,
          xid = this.swap_xy ? 1 : 0, yid = 1 - xid,
          changed = [true, true];
      if (this.zoom_kind === 102) changed[1] = false;
      if (this.zoom_kind === 103) changed[0] = false;

      if (changed[xid] && (Math.abs(this.zoom_curr[xid] - this.zoom_origin[xid]) > 10)) {
         xmin = Math.min(this.RevertX(this.zoom_origin[xid]), this.RevertX(this.zoom_curr[xid]));
         xmax = Math.max(this.RevertX(this.zoom_origin[xid]), this.RevertX(this.zoom_curr[xid]));
         isany = true;
      }

      if (changed[yid] && (Math.abs(this.zoom_curr[yid] - this.zoom_origin[yid]) > 10)) {
         ymin = Math.min(this.RevertY(this.zoom_origin[yid]), this.RevertY(this.zoom_curr[yid]));
         ymax = Math.max(this.RevertY(this.zoom_origin[yid]), this.RevertY(this.zoom_curr[yid]));
         isany = true;
      }

      this.clearInteractiveElements();
      this.last_touch = new Date(0);

      if (isany) {
         this.zoom_changed_interactive = 2;
         this.Zoom(xmin, xmax, ymin, ymax);
      }

      d3.event.stopPropagation();
   }

   JSROOT.THistPainter.prototype.AllowDefaultYZooming = function() {
      // return true if default Y zooming should be enabled
      // it is typically for 2-Dim histograms or
      // when histogram not draw, defined by other painters

      if (this.Dimension()>1) return true;
      if (this.draw_content) return false;

      var pad_painter = this.pad_painter(true);
      if (pad_painter &&  pad_painter.painters)
         for (var k = 0; k < pad_painter.painters.length; ++k) {
            var subpainter = pad_painter.painters[k];
            if ((subpainter!==this) && subpainter.wheel_zoomy!==undefined)
               return subpainter.wheel_zoomy;
         }

      return false;
   }

   JSROOT.THistPainter.prototype.AnalyzeMouseWheelEvent = function(event, item, dmin, ignore) {

      item.min = item.max = undefined;
      item.changed = false;
      if (ignore && item.ignore) return;

      var delta = 0, delta_left = 1, delta_right = 1;

      if ('dleft' in item) { delta_left = item.dleft; delta = 1; }
      if ('dright' in item) { delta_right = item.dright; delta = 1; }

      if ('delta' in item)
         delta = item.delta;
      else
      if (event && event.wheelDelta !== undefined ) {
         // WebKit / Opera / Explorer 9
         delta = -event.wheelDelta;
      } else if (event && event.deltaY !== undefined ) {
         // Firefox
         delta = event.deltaY;
      } else if (event && event.detail !== undefined) {
         delta = event.detail;
      }

      if (delta===0) return;
      delta = (delta<0) ? -0.2 : 0.2;

      delta_left *= delta
      delta_right *= delta;

      var lmin = item.min = this["scale_"+item.name+"min"],
          lmax = item.max = this["scale_"+item.name+"max"],
          gmin = this[item.name+"min"],
          gmax = this[item.name+"max"];

      if ((item.min === item.max) && (delta<0)) {
         item.min = gmin;
         item.max = gmax;
      }

      if (item.min >= item.max) return;

      if ((dmin>0) && (dmin<1)) {
         if (this['log'+item.name]) {
            var factor = (item.min>0) ? JSROOT.log10(item.max/item.min) : 2;
            if (factor>10) factor = 10; else if (factor<0.01) factor = 0.01;
            item.min = item.min / Math.pow(10, factor*delta_left*dmin);
            item.max = item.max * Math.pow(10, factor*delta_right*(1-dmin));
         } else {
            var rx_left = (item.max - item.min),
                rx_right = rx_left;
            if (delta_left>0) rx_left = 1.001 * rx_left / (1-delta_left);
            item.min += -delta_left*dmin*rx_left;

            if (delta_right>0) rx_right = 1.001 * rx_right / (1-delta_right);

            item.max -= -delta_right*(1-dmin)*rx_right;
         }
         if (item.min >= item.max)
            item.min = item.max = undefined;
         else
         if (delta_left !== delta_right) {
            // extra check case when moving left or right
            if (((item.min < gmin) && (lmin===gmin)) ||
                ((item.max > gmax) && (lmax==gmax)))
                   item.min = item.max = undefined;
         }

      } else {
         item.min = item.max = undefined;
      }

      item.changed = ((item.min !== undefined) && (item.max !== undefined));
   }

   JSROOT.THistPainter.prototype.mouseWheel = function() {
      d3.event.stopPropagation();

      d3.event.preventDefault();
      this.clearInteractiveElements();

      var itemx = { name: "x", ignore: false },
          itemy = { name: "y", ignore: !this.AllowDefaultYZooming() },
          cur = d3.mouse(this.svg_frame().node()),
          w = this.frame_width(), h = this.frame_height();

      this.AnalyzeMouseWheelEvent(d3.event, this.swap_xy ? itemy : itemx, cur[0] / w, (cur[1] >=0) && (cur[1] <= h));

      this.AnalyzeMouseWheelEvent(d3.event, this.swap_xy ? itemx : itemy, 1 - cur[1] / h, (cur[0] >= 0) && (cur[0] <= w));

      this.Zoom(itemx.min, itemx.max, itemy.min, itemy.max);

      if (itemx.changed || itemy.changed) this.zoom_changed_interactive = 2;
   }

   JSROOT.THistPainter.prototype.ShowAxisStatus = function(axis_name) {
      // method called normally when mouse enter main object element

      var status_func = this.GetShowStatusFunc();

      if (!status_func) return;

      var taxis = this.histo ? this.histo['f'+axis_name.toUpperCase()+"axis"] : null;

      var hint_name = axis_name, hint_title = "TAxis";

      if (taxis) { hint_name = taxis.fName; hint_title = taxis.fTitle || "histogram TAxis object"; }

      var m = d3.mouse(this.svg_frame().node());

      var id = (axis_name=="x") ? 0 : 1;
      if (this.swap_xy) id = 1-id;

      var axis_value = (axis_name=="x") ? this.RevertX(m[id]) : this.RevertY(m[id]);

      status_func(hint_name, hint_title, axis_name + " : " + this.AxisAsText(axis_name, axis_value),
                  m[0].toFixed(0)+","+ m[1].toFixed(0));
   }

   JSROOT.THistPainter.prototype.AddInteractive = function() {
      // only first painter in list allowed to add interactive functionality to the frame

      if ((!JSROOT.gStyle.Zooming && !JSROOT.gStyle.ContextMenu) || !this.is_main_painter()) return;

      var svg = this.svg_frame();

      if (svg.empty() || svg.property('interactive_set')) return;

      this.AddKeysHandler();

      this.last_touch = new Date(0);
      this.zoom_kind = 0; // 0 - none, 1 - XY, 2 - only X, 3 - only Y, (+100 for touches)
      this.zoom_rect = null;
      this.zoom_origin = null;  // original point where zooming started
      this.zoom_curr = null;    // current point for zomming
      this.touch_cnt = 0;

      if (JSROOT.gStyle.Zooming) {
         if (JSROOT.gStyle.ZoomMouse) {
            svg.on("mousedown", this.startRectSel.bind(this));
            svg.on("dblclick", this.mouseDoubleClick.bind(this));
         }
         if (JSROOT.gStyle.ZoomWheel)
            svg.on("wheel", this.mouseWheel.bind(this));
      }

      if (JSROOT.touches && ((JSROOT.gStyle.Zooming && JSROOT.gStyle.ZoomTouch) || JSROOT.gStyle.ContextMenu))
         svg.on("touchstart", this.startTouchZoom.bind(this));

      if (JSROOT.gStyle.ContextMenu) {
         if (JSROOT.touches) {
            svg.selectAll(".xaxis_container")
               .on("touchstart", this.startTouchMenu.bind(this,"x"));
            svg.selectAll(".yaxis_container")
                .on("touchstart", this.startTouchMenu.bind(this,"y"));
         }
         svg.on("contextmenu", this.ShowContextMenu.bind(this));
         svg.selectAll(".xaxis_container")
             .on("contextmenu", this.ShowContextMenu.bind(this,"x"));
         svg.selectAll(".yaxis_container")
             .on("contextmenu", this.ShowContextMenu.bind(this,"y"));
      }

      svg.selectAll(".xaxis_container")
         .on("mousemove", this.ShowAxisStatus.bind(this,"x"));
      svg.selectAll(".yaxis_container")
         .on("mousemove", this.ShowAxisStatus.bind(this,"y"));

      svg.property('interactive_set', true);
   }

   JSROOT.THistPainter.prototype.AddKeysHandler = function() {
      if (this.keys_handler || !this.is_main_painter() || JSROOT.BatchMode || (typeof window == 'undefined')) return;

      this.keys_handler = this.ProcessKeyPress.bind(this);

      window.addEventListener('keydown', this.keys_handler, false);
   }

   JSROOT.THistPainter.prototype.ProcessKeyPress = function(evnt) {

      var main = this.select_main();
      if (main.empty()) return;
      var isactive = main.attr('frame_active');
      if (isactive && isactive!=='true') return;

      var key = "";
      switch (evnt.keyCode) {
         case 33: key = "PageUp"; break;
         case 34: key = "PageDown"; break;
         case 37: key = "ArrowLeft"; break;
         case 38: key = "ArrowUp"; break;
         case 39: key = "ArrowRight"; break;
         case 40: key = "ArrowDown"; break;
         case 42: key = "PrintScreen"; break;
         case 106: key = "*"; break;
         default: return false;
      }

      if (evnt.shiftKey) key = "Shift " + key;
      if (evnt.altKey) key = "Alt " + key;
      if (evnt.ctrlKey) key = "Ctrl " + key;

      var zoom = { name: "x", dleft: 0, dright: 0 };

      switch (key) {
         case "ArrowLeft":  zoom.dleft = -1; zoom.dright = 1; break;
         case "ArrowRight":  zoom.dleft = 1; zoom.dright = -1; break;
         case "Ctrl ArrowLeft": zoom.dleft = zoom.dright = -1; break;
         case "Ctrl ArrowRight": zoom.dleft = zoom.dright = 1; break;
         case "ArrowUp":  zoom.name = "y"; zoom.dleft = 1; zoom.dright = -1; break;
         case "ArrowDown":  zoom.name = "y"; zoom.dleft = -1; zoom.dright = 1; break;
         case "Ctrl ArrowUp": zoom.name = "y"; zoom.dleft = zoom.dright = 1; break;
         case "Ctrl ArrowDown": zoom.name = "y"; zoom.dleft = zoom.dright = -1; break;
      }

      if (zoom.dleft || zoom.dright) {
         if (!JSROOT.gStyle.Zooming) return false;
         // in 3dmode with orbit control ignore simple arrows
         if (this.mode3d && (key.indexOf("Ctrl")!==0)) return false;
         this.AnalyzeMouseWheelEvent(null, zoom, 0.5);
         this.Zoom(zoom.name, zoom.min, zoom.max);
         if (zoom.changed) this.zoom_changed_interactive = 2;
         evnt.stopPropagation();
         evnt.preventDefault();
      } else {
         var pp = this.pad_painter(true),
             func = pp ? pp.FindButton(key) : "";
         if (func) {
            pp.PadButtonClick(func);
            evnt.stopPropagation();
            evnt.preventDefault();
         }
      }

      return true; // just process any key press
   }

   JSROOT.THistPainter.prototype.ShowContextMenu = function(kind, evnt, obj) {
      // ignore context menu when touches zooming is ongoing
      if (('zoom_kind' in this) && (this.zoom_kind > 100)) return;

      // this is for debug purposes only, when context menu is where, close is and show normal menu
      //if (!evnt && !kind && document.getElementById('root_ctx_menu')) {
      //   var elem = document.getElementById('root_ctx_menu');
      //   elem.parentNode.removeChild(elem);
      //   return;
      //}

      var menu_painter = this, frame_corner = false, fp = null; // object used to show context menu

      if (!evnt) {
         d3.event.preventDefault();
         d3.event.stopPropagation(); // disable main context menu
         evnt = d3.event;

         if (kind === undefined) {
            var ms = d3.mouse(this.svg_frame().node()),
                tch = d3.touches(this.svg_frame().node()),
                pp = this.pad_painter(true),
                pnt = null, sel = null;

            fp = this.frame_painter();

            if (tch.length === 1) pnt = { x: tch[0][0], y: tch[0][1], touch: true }; else
            if (ms.length === 2) pnt = { x: ms[0], y: ms[1], touch: false };

            if ((pnt !== null) && (pp !== null)) {
               pnt.painters = true; // assign painter for every tooltip
               var hints = pp.GetTooltips(pnt), bestdist = 1000;
               for (var n=0;n<hints.length;++n)
                  if (hints[n] && hints[n].menu) {
                     var dist = ('menu_dist' in hints[n]) ? hints[n].menu_dist : 7;
                     if (dist < bestdist) { sel = hints[n].painter; bestdist = dist; }
                  }
            }

            if (sel!==null) menu_painter = sel; else
            if (fp!==null) kind = "frame";

            if (pnt!==null) frame_corner = (pnt.x>0) && (pnt.x<20) && (pnt.y>0) && (pnt.y<20);
         }
      }

      // one need to copy event, while after call back event may be changed
      menu_painter.ctx_menu_evnt = evnt;

      JSROOT.Painter.createMenu(menu_painter, function(menu) {
         var domenu = menu.painter.FillContextMenu(menu, kind, obj);

         // fill frame menu by default - or append frame elements when actiavted in the frame corner
         if (fp && (!domenu || (frame_corner && (kind!=="frame"))))
            domenu = fp.FillContextMenu(menu);

         if (domenu)
            menu.painter.FillObjectExecMenu(menu, function() {
                // suppress any running zomming
                menu.painter.SwitchTooltip(false);
                menu.show(menu.painter.ctx_menu_evnt, menu.painter.SwitchTooltip.bind(menu.painter, true) );
            });

      });  // end menu creation
   }


   JSROOT.THistPainter.prototype.ChangeUserRange = function(arg) {
      var taxis = this.histo['f'+arg+"axis"];
      if (!taxis) return;

      var curr = "[1," + taxis.fNbins+"]";
      if (taxis.TestBit(JSROOT.EAxisBits.kAxisRange))
          curr = "[" +taxis.fFirst+"," + taxis.fLast+"]";

      var res = prompt("Enter user range for axis " + arg + " like [1," + taxis.fNbins + "]", curr);
      if (res==null) return;
      res = JSON.parse(res);

      if (!res || (res.length!=2) || isNaN(res[0]) || isNaN(res[1])) return;
      taxis.fFirst = parseInt(res[0]);
      taxis.fLast = parseInt(res[1]);

      var newflag = (taxis.fFirst < taxis.fLast) && (taxis.fFirst >= 1) && (taxis.fLast<=taxis.fNbins);
      if (newflag != taxis.TestBit(JSROOT.EAxisBits.kAxisRange))
         taxis.InvertBit(JSROOT.EAxisBits.kAxisRange);

      this.Redraw();
   }

   JSROOT.THistPainter.prototype.FillContextMenu = function(menu, kind, obj) {

      // when fill and show context menu, remove all zooming
      this.clearInteractiveElements();

      if ((kind=="x") || (kind=="y") || (kind=="z")) {
         var faxis = this.histo.fXaxis;
         if (kind=="y") faxis = this.histo.fYaxis;  else
         if (kind=="z") faxis = obj ? obj : this.histo.fZaxis;
         menu.add("header: " + kind.toUpperCase() + " axis");
         menu.add("Unzoom", this.Unzoom.bind(this, kind));
         menu.addchk(this.options["Log" + kind], "SetLog"+kind, this.ToggleLog.bind(this, kind) );
         menu.addchk(faxis.TestBit(JSROOT.EAxisBits.kMoreLogLabels), "More log",
               function() { faxis.InvertBit(JSROOT.EAxisBits.kMoreLogLabels); this.RedrawPad(); });
         menu.addchk(faxis.TestBit(JSROOT.EAxisBits.kNoExponent), "No exponent",
               function() { faxis.InvertBit(JSROOT.EAxisBits.kNoExponent); this.RedrawPad(); });

         if ((kind === "z") && (this.options.Zscale > 0))
            if (this.FillPaletteMenu) this.FillPaletteMenu(menu);

         if (faxis != null) {
            menu.add("sub:Labels");
            menu.addchk(faxis.TestBit(JSROOT.EAxisBits.kCenterLabels), "Center",
                  function() { faxis.InvertBit(JSROOT.EAxisBits.kCenterLabels); this.RedrawPad(); });
            this.AddColorMenuEntry(menu, "Color", faxis.fLabelColor,
                  function(arg) { faxis.fLabelColor = parseInt(arg); this.RedrawPad(); });
            this.AddSizeMenuEntry(menu,"Offset", 0, 0.1, 0.01, faxis.fLabelOffset,
                  function(arg) { faxis.fLabelOffset = parseFloat(arg); this.RedrawPad(); } );
            this.AddSizeMenuEntry(menu,"Size", 0.02, 0.11, 0.01, faxis.fLabelSize,
                  function(arg) { faxis.fLabelSize = parseFloat(arg); this.RedrawPad(); } );
            menu.add("endsub:");
            menu.add("sub:Title");
            menu.add("SetTitle", function() {
               var t = prompt("Enter axis title", faxis.fTitle);
               if (t!==null) { faxis.fTitle = t; this.RedrawPad(); }
            });
            menu.addchk(faxis.TestBit(JSROOT.EAxisBits.kCenterTitle), "Center",
                  function() { faxis.InvertBit(JSROOT.EAxisBits.kCenterTitle); this.RedrawPad(); });
            menu.addchk(faxis.TestBit(JSROOT.EAxisBits.kRotateTitle), "Rotate",
                  function() { faxis.InvertBit(JSROOT.EAxisBits.kRotateTitle); this.RedrawPad(); });
            this.AddColorMenuEntry(menu, "Color", faxis.fTitleColor,
                  function(arg) { faxis.fTitleColor = parseInt(arg); this.RedrawPad(); });
            this.AddSizeMenuEntry(menu,"Offset", 0, 3, 0.2, faxis.fTitleOffset,
                                  function(arg) { faxis.fTitleOffset = parseFloat(arg); this.RedrawPad(); } );
            this.AddSizeMenuEntry(menu,"Size", 0.02, 0.11, 0.01, faxis.fTitleSize,
                  function(arg) { faxis.fTitleSize = parseFloat(arg); this.RedrawPad(); } );
            menu.add("endsub:");
         }
         menu.add("sub:Ticks");
         this.AddColorMenuEntry(menu, "Color", faxis.fLineColor,
                     function(arg) { faxis.fLineColor = parseInt(arg); this.RedrawPad(); });
         this.AddColorMenuEntry(menu, "Color", faxis.fAxisColor,
                     function(arg) { faxis.fAxisColor = parseInt(arg); this.RedrawPad(); });
         this.AddSizeMenuEntry(menu,"Size", -0.05, 0.055, 0.01, faxis.fTickLength,
                   function(arg) { faxis.fTickLength = parseFloat(arg); this.RedrawPad(); } );
         menu.add("endsub:");
         return true;
      }

      if (kind == "frame") {
         var fp = this.frame_painter();
         if (fp) return fp.FillContextMenu(menu);
      }

      menu.add("header:"+ this.histo._typename + "::" + this.histo.fName);

      if (this.draw_content) {
         menu.addchk(this.ToggleStat('only-check'), "Show statbox", function() { this.ToggleStat(); });
         if (this.Dimension() == 1) {
            menu.add("User range X", "X", this.ChangeUserRange);
         } else {
            menu.add("sub:User ranges");
            menu.add("X", "X", this.ChangeUserRange);
            menu.add("Y", "Y", this.ChangeUserRange);
            if (this.Dimension() > 2)
               menu.add("Z", "Z", this.ChangeUserRange);
            menu.add("endsub:")
         }

         if (typeof this.FillHistContextMenu == 'function')
            this.FillHistContextMenu(menu);
      }

      if ((this.options.Lego > 0) || (this.options.Surf > 0) || (this.Dimension() === 3)) {
         // menu for 3D drawings

         if (menu.size() > 0)
            menu.add("separator");

         var main = this.main_painter() || this;

         menu.addchk(main.tooltip_allowed, 'Show tooltips', function() {
            main.tooltip_allowed = !main.tooltip_allowed;
         });

         menu.addchk(main.enable_hightlight, 'Hightlight bins', function() {
            main.enable_hightlight = !main.enable_hightlight;
            if (!main.enable_hightlight && main.BinHighlight3D) main.BinHighlight3D(null);
         });

         menu.addchk(main.options.FrontBox, 'Front box', function() {
            main.options.FrontBox = !main.options.FrontBox;
            if (main.Render3D) main.Render3D();
         });
         menu.addchk(main.options.BackBox, 'Back box', function() {
            main.options.BackBox = !main.options.BackBox;
            if (main.Render3D) main.Render3D();
         });

         if (this.draw_content) {
            menu.addchk(!this.options.Zero, 'Suppress zeros', function() {
               this.options.Zero = !this.options.Zero;
               this.RedrawPad();
            });

            if ((this.options.Lego==12) || (this.options.Lego==14)) {
               menu.addchk(this.options.Zscale, "Z scale", function() {
                  this.ToggleColz();
               });
               if (this.FillPaletteMenu) this.FillPaletteMenu(menu);
            }
         }

         if (main.control && typeof main.control.reset === 'function')
            menu.add('Reset camera', function() {
               main.control.reset();
            });
      }

      this.FillAttContextMenu(menu);

      if (this.histogram_updated && this.zoom_changed_interactive)
         menu.add('Let update zoom', function() {
            this.zoom_changed_interactive = 0;
         });

      return true;
   }

   JSROOT.THistPainter.prototype.ButtonClick = function(funcname) {
      if (!this.is_main_painter()) return false;
      switch(funcname) {
         case "ToggleZoom":
            if ((this.zoom_xmin !== this.zoom_xmax) || (this.zoom_ymin !== this.zoom_ymax) || (this.zoom_zmin !== this.zoom_zmax)) {
               this.Unzoom();
               return true;
            }
            if (this.draw_content && (typeof this.AutoZoom === 'function')) {
               this.AutoZoom();
               return true;
            }
            break;
         case "ToggleLogX": this.ToggleLog("x"); break;
         case "ToggleLogY": this.ToggleLog("y"); break;
         case "ToggleLogZ": this.ToggleLog("z"); break;
         case "ToggleStatBox": this.ToggleStat(); return true; break;
      }
      return false;
   }

   JSROOT.THistPainter.prototype.FillToolbar = function() {
      var pp = this.pad_painter(true);
      if (pp===null) return;

      pp.AddButton(JSROOT.ToolbarIcons.auto_zoom, 'Toggle between unzoom and autozoom-in', 'ToggleZoom', "Ctrl *");
      pp.AddButton(JSROOT.ToolbarIcons.arrow_right, "Toggle log x", "ToggleLogX", "PageDown");
      pp.AddButton(JSROOT.ToolbarIcons.arrow_up, "Toggle log y", "ToggleLogY", "PageUp");
      if (this.Dimension() > 1)
         pp.AddButton(JSROOT.ToolbarIcons.arrow_diag, "Toggle log z", "ToggleLogZ");
      if (this.draw_content)
         pp.AddButton(JSROOT.ToolbarIcons.statbox, 'Toggle stat box', "ToggleStatBox");
   }


   // ======= TH1 painter================================================

   JSROOT.TH1Painter = function(histo) {
      JSROOT.THistPainter.call(this, histo);
   }

   JSROOT.TH1Painter.prototype = Object.create(JSROOT.THistPainter.prototype);

   JSROOT.TH1Painter.prototype.ScanContent = function(when_axis_changed) {
      // if when_axis_changed === true specified, content will be scanned after axis zoom changed

      if (!this.nbinsx && when_axis_changed) when_axis_changed = false;

      if (!when_axis_changed) {
         this.nbinsx = this.histo.fXaxis.fNbins;
         this.nbinsy = 0;
         this.CreateAxisFuncs(false);
      }

      var left = this.GetSelectIndex("x", "left"),
          right = this.GetSelectIndex("x", "right");

      if (when_axis_changed) {
         if ((left === this.scan_xleft) && (right === this.scan_xright)) return;
      }

      this.scan_xleft = left;
      this.scan_xright = right;

      var hmin = 0, hmin_nz = 0, hmax = 0, hsum = 0, first = true,
          profile = this.IsTProfile(), value, err;

      for (var i = 0; i < this.nbinsx; ++i) {
         value = this.histo.getBinContent(i + 1);
         hsum += profile ? this.histo.fBinEntries[i + 1] : value;

         if ((i<left) || (i>=right)) continue;

         if (value > 0)
            if ((hmin_nz == 0) || (value<hmin_nz)) hmin_nz = value;
         if (first) {
            hmin = hmax = value;
            first = false;;
         }

         err = (this.options.Error > 0) ? this.histo.getBinError(i + 1) : 0;

         hmin = Math.min(hmin, value - err);
         hmax = Math.max(hmax, value + err);
      }

      // account overflow/underflow bins
      if (profile)
         hsum += this.histo.fBinEntries[0] + this.histo.fBinEntries[this.nbinsx + 1];
      else
         hsum += this.histo.getBinContent(0) + this.histo.getBinContent(this.nbinsx + 1);

      this.stat_entries = hsum;
      if (this.histo.fEntries>1) this.stat_entries = this.histo.fEntries;

      this.hmin = hmin;
      this.hmax = hmax;

      this.ymin_nz = hmin_nz; // value can be used to show optimal log scale

      if ((this.nbinsx == 0) || ((Math.abs(hmin) < 1e-300 && Math.abs(hmax) < 1e-300))) {
         this.draw_content = false;
         hmin = this.ymin;
         hmax = this.ymax;
      } else {
         this.draw_content = true;
      }

      if (this.draw_content) {
         if (hmin >= hmax) {
            if (hmin == 0) { this.ymin = 0; this.ymax = 1; } else
               if (hmin < 0) { this.ymin = 2 * hmin; this.ymax = 0; }
               else { this.ymin = 0; this.ymax = hmin * 2; }
         } else {
            var dy = (hmax - hmin) * 0.05;
            this.ymin = hmin - dy;
            if ((this.ymin < 0) && (hmin >= 0)) this.ymin = 0;
            this.ymax = hmax + dy;
         }
      }

      hmin = hmax = null;
      var set_zoom = false;

      if (this.options.minimum !== -1111) {
         hmin = this.options.minimum;
         if (hmin < this.ymin)
            this.ymin = hmin;
         else
            set_zoom = true;
      }

      if (this.options.maximum !== -1111) {
         hmax = this.options.maximum;
         if (hmax > this.ymax)
            this.ymax = hmax;
         else
            set_zoom = true;
      }

      if (set_zoom && this.draw_content) {
         this.zoom_ymin = (hmin === null) ? this.ymin : hmin;
         this.zoom_ymax = (hmax === null) ? this.ymax : hmax;
      }

      // If no any draw options specified, do not try draw histogram
      if (!this.options.Bar && !this.options.Hist && !this.options.Line &&
          !this.options.Error && !this.options.Same && !this.options.Lego && !this.options.Text) {
         this.draw_content = false;
      }
      if (this.options.Axis > 0) { // Paint histogram axis only
         this.draw_content = false;
      }
   }

   JSROOT.TH1Painter.prototype.CountStat = function(cond) {
      var profile = this.IsTProfile(),
          left = this.GetSelectIndex("x", "left"),
          right = this.GetSelectIndex("x", "right"),
          stat_sumw = 0, stat_sumwx = 0, stat_sumwx2 = 0, stat_sumwy = 0, stat_sumwy2 = 0,
          i, xx = 0, w = 0, xmax = null, wmax = null,
          res = { meanx: 0, meany: 0, rmsx: 0, rmsy: 0, integral: 0, entries: this.stat_entries, xmax:0, wmax:0 };

      for (i = left; i < right; ++i) {
         xx = this.GetBinX(i+0.5);

         if (cond && !cond(xx)) continue;

         if (profile) {
            w = this.histo.fBinEntries[i + 1];
            stat_sumwy += this.histo.fArray[i + 1];
            stat_sumwy2 += this.histo.fSumw2[i + 1];
         } else {
            w = this.histo.getBinContent(i + 1);
         }

         if ((xmax===null) || (w>wmax)) { xmax = xx; wmax = w; }

         stat_sumw += w;
         stat_sumwx += w * xx;
         stat_sumwx2 += w * xx * xx;
      }

      // when no range selection done, use original statistic from histogram
      if (!this.IsAxisZoomed("x") && (this.histo.fTsumw>0)) {
         stat_sumw = this.histo.fTsumw;
         stat_sumwx = this.histo.fTsumwx;
         stat_sumwx2 = this.histo.fTsumwx2;
      }

      res.integral = stat_sumw;

      if (stat_sumw > 0) {
         res.meanx = stat_sumwx / stat_sumw;
         res.meany = stat_sumwy / stat_sumw;
         res.rmsx = Math.sqrt(Math.abs(stat_sumwx2 / stat_sumw - res.meanx * res.meanx));
         res.rmsy = Math.sqrt(Math.abs(stat_sumwy2 / stat_sumw - res.meany * res.meany));
      }

      if (xmax!==null) {
         res.xmax = xmax;
         res.wmax = wmax;
      }

      return res;
   }

   JSROOT.TH1Painter.prototype.FillStatistic = function(stat, dostat, dofit) {
      if (!this.histo) return false;

      var pave = stat.GetObject(),
          data = this.CountStat(),
          print_name = dostat % 10,
          print_entries = Math.floor(dostat / 10) % 10,
          print_mean = Math.floor(dostat / 100) % 10,
          print_rms = Math.floor(dostat / 1000) % 10,
          print_under = Math.floor(dostat / 10000) % 10,
          print_over = Math.floor(dostat / 100000) % 10,
          print_integral = Math.floor(dostat / 1000000) % 10,
          print_skew = Math.floor(dostat / 10000000) % 10,
          print_kurt = Math.floor(dostat / 100000000) % 10;

      if (print_name > 0)
         pave.AddText(this.histo.fName);

      if (this.IsTProfile()) {

         if (print_entries > 0)
            pave.AddText("Entries = " + stat.Format(data.entries,"entries"));

         if (print_mean > 0) {
            pave.AddText("Mean = " + stat.Format(data.meanx));
            pave.AddText("Mean y = " + stat.Format(data.meany));
         }

         if (print_rms > 0) {
            pave.AddText("Std Dev = " + stat.Format(data.rmsx));
            pave.AddText("Std Dev y = " + stat.Format(data.rmsy));
         }

      } else {

         if (print_entries > 0)
            pave.AddText("Entries = " + stat.Format(data.entries,"entries"));

         if (print_mean > 0)
            pave.AddText("Mean = " + stat.Format(data.meanx));

         if (print_rms > 0)
            pave.AddText("Std Dev = " + stat.Format(data.rmsx));

         if (print_under > 0)
            pave.AddText("Underflow = " + stat.Format((this.histo.fArray.length > 0) ? this.histo.fArray[0] : 0,"entries"));

         if (print_over > 0)
            pave.AddText("Overflow = " + stat.Format((this.histo.fArray.length > 0) ? this.histo.fArray[this.histo.fArray.length - 1] : 0,"entries"));

         if (print_integral > 0)
            pave.AddText("Integral = " + stat.Format(data.integral,"entries"));

         if (print_skew > 0)
            pave.AddText("Skew = <not avail>");

         if (print_kurt > 0)
            pave.AddText("Kurt = <not avail>");
      }

      if (dofit!=0) {
         var f1 = this.FindFunction('TF1');
         if (f1!=null) {
            var print_fval    = dofit%10;
            var print_ferrors = Math.floor(dofit/10) % 10;
            var print_fchi2   = Math.floor(dofit/100) % 10;
            var print_fprob   = Math.floor(dofit/1000) % 10;

            if (print_fchi2 > 0)
               pave.AddText("#chi^2 / ndf = " + stat.Format(f1.fChisquare,"fit") + " / " + f1.fNDF);
            if (print_fprob > 0)
               pave.AddText("Prob = "  + (('Math' in JSROOT) ? stat.Format(JSROOT.Math.Prob(f1.fChisquare, f1.fNDF)) : "<not avail>"));
            if (print_fval > 0) {
               for(var n=0;n<f1.fNpar;++n) {
                  var parname = f1.GetParName(n);
                  var parvalue = f1.GetParValue(n);
                  if (parvalue != null) parvalue = stat.Format(Number(parvalue),"fit");
                                 else  parvalue = "<not avail>";
                  var parerr = "";
                  if (f1.fParErrors!=null) {
                     parerr = stat.Format(f1.fParErrors[n],"last");
                     if ((Number(parerr)==0.0) && (f1.fParErrors[n]!=0.0)) parerr = stat.Format(f1.fParErrors[n],"4.2g");
                  }

                  if ((print_ferrors > 0) && (parerr.length > 0))
                     pave.AddText(parname + " = " + parvalue + " #pm " + parerr);
                  else
                     pave.AddText(parname + " = " + parvalue);
               }
            }
         }
      }

      // adjust the size of the stats box with the number of lines
      var nlines = pave.fLines.arr.length,
          stath = nlines * JSROOT.gStyle.StatFontSize;
      if ((stath <= 0) || (JSROOT.gStyle.StatFont % 10 === 3)) {
         stath = 0.25 * nlines * JSROOT.gStyle.StatH;
         pave.fY1NDC = 0.93 - stath;
         pave.fY2NDC = 0.93;
      }

      return true;
   }

   JSROOT.TH1Painter.prototype.DrawBars = function(width, height) {

      this.RecreateDrawG(false, "main_layer");

      var left = this.GetSelectIndex("x", "left", -1),
          right = this.GetSelectIndex("x", "right", 1),
          pmain = this.main_painter(),
          pad = this.root_pad(),
          pthis = this,
          i, x1, x2, grx1, grx2, y, gry1, gry2, w,
          bars = "", barsl = "", barsr = "",
          side = (this.options.Bar > 10) ? this.options.Bar % 10 : 0;

      if (side>4) side = 4;
      gry2 = pmain.swap_xy ? 0 : height;
      if ((this.options.BaseLine !== false) && !isNaN(this.options.BaseLine))
         if (this.options.BaseLine >= pmain.scale_ymin)
            gry2 = Math.round(pmain.gry(this.options.BaseLine));

      for (i = left; i < right; ++i) {
         x1 = this.GetBinX(i);
         x2 = this.GetBinX(i+1);

         if (pmain.logx && (x2 <= 0)) continue;

         grx1 = Math.round(pmain.grx(x1));
         grx2 = Math.round(pmain.grx(x2));

         y = this.histo.getBinContent(i+1);
         if (pmain.logy && (y < pmain.scale_ymin)) continue;
         gry1 = Math.round(pmain.gry(y));

         w = grx2 - grx1;
         grx1 += Math.round(this.histo.fBarOffset/1000*w);
         w = Math.round(this.histo.fBarWidth/1000*w);

         if (pmain.swap_xy)
            bars += "M"+gry2+","+grx1 + "h"+(gry1-gry2) + "v"+w + "h"+(gry2-gry1) + "z";
         else
            bars += "M"+grx1+","+gry1 + "h"+w + "v"+(gry2-gry1) + "h"+(-w)+ "z";

         if (side > 0) {
            grx2 = grx1 + w;
            w = Math.round(w * side / 10);
            if (pmain.swap_xy) {
               barsl += "M"+gry2+","+grx1 + "h"+(gry1-gry2) + "v" + w + "h"+(gry2-gry1) + "z";
               barsr += "M"+gry2+","+grx2 + "h"+(gry1-gry2) + "v" + (-w) + "h"+(gry2-gry1) + "z";
            } else {
               barsl += "M"+grx1+","+gry1 + "h"+w + "v"+(gry2-gry1) + "h"+(-w)+ "z";
               barsr += "M"+grx2+","+gry1 + "h"+(-w) + "v"+(gry2-gry1) + "h"+w + "z";
            }
         }
      }

      if (bars.length > 0)
         this.draw_g.append("svg:path")
                    .attr("d", bars)
                    .call(this.fillatt.func);

      if (barsl.length > 0)
         this.draw_g.append("svg:path")
               .attr("d", barsl)
               .call(this.fillatt.func)
               .style("fill", d3.rgb(this.fillatt.color).brighter(0.5).toString());

      if (barsr.length > 0)
         this.draw_g.append("svg:path")
               .attr("d", barsr)
               .call(this.fillatt.func)
               .style("fill", d3.rgb(this.fillatt.color).darker(0.5).toString());
   }

   JSROOT.TH1Painter.prototype.DrawFilledErrors = function(width, height) {
      this.RecreateDrawG(false, "main_layer");

      var left = this.GetSelectIndex("x", "left", -1),
          right = this.GetSelectIndex("x", "right", 1),
          pmain = this.main_painter(),
          i, x, grx, y, yerr, gry1, gry2,
          bins1 = [], bins2 = [];

      for (i = left; i < right; ++i) {
         x = this.GetBinX(i+0.5);
         if (pmain.logx && (x <= 0)) continue;
         grx = Math.round(pmain.grx(x));

         y = this.histo.getBinContent(i+1);
         yerr = this.histo.getBinError(i+1);
         if (pmain.logy && (y-yerr < pmain.scale_ymin)) continue;

         gry1 = Math.round(pmain.gry(y + yerr));
         gry2 = Math.round(pmain.gry(y - yerr));

         bins1.push({grx:grx, gry: gry1});
         bins2.unshift({grx:grx, gry: gry2});
      }

      var kind = (this.options.Error == 14) ? "bezier" : "line";

      var path1 = JSROOT.Painter.BuildSvgPath(kind, bins1),
          path2 = JSROOT.Painter.BuildSvgPath("L"+kind, bins2);

      this.draw_g.append("svg:path")
                 .attr("d", path1.path + path2.path + "Z")
                 .style("stroke", "none")
                 .call(this.fillatt.func);
   }

   JSROOT.TH1Painter.prototype.DrawBins = function() {
      // new method, create svg:path expression ourself directly from histogram
      // all points will be used, compress expression when too large

      this.CheckHistDrawAttributes();

      var width = this.frame_width(), height = this.frame_height();

      if (!this.draw_content || (width<=0) || (height<=0))
         return this.RemoveDrawG();

      if (this.options.Bar > 0)
         return this.DrawBars(width, height);

      if ((this.options.Error == 13) || (this.options.Error == 14))
         return this.DrawFilledErrors(width, height);

      this.RecreateDrawG(false, "main_layer");

      var left = this.GetSelectIndex("x", "left", -1),
          right = this.GetSelectIndex("x", "right", 2),
          pmain = this.main_painter(),
          pad = this.root_pad(),
          pthis = this,
          res = "", lastbin = false,
          startx, currx, curry, x, grx, y, gry, curry_min, curry_max, prevy, prevx, i, besti,
          exclude_zero = !this.options.Zero,
          show_errors = (this.options.Error > 0),
          show_markers = (this.options.Mark > 0),
          show_line = (this.options.Line > 0),
          show_text = (this.options.Text > 0),
          path_fill = null, path_err = null, path_marker = null, path_line = null,
          endx = "", endy = "", dend = 0, my, yerr1, yerr2, bincont, binerr, mx1, mx2, midx,
          mpath = "", text_col, text_angle, text_size;

      if (show_errors && !show_markers && (this.histo.fMarkerStyle > 1))
         show_markers = true;

      if (this.options.Error == 12) {
         if (this.fillatt.color=='none') show_markers = true;
                                    else path_fill = "";
      } else
      if (this.options.Error > 0) path_err = "";

      if (show_line) path_line = "";

      if (show_markers) {
         // draw markers also when e2 option was specified
         if (!this.markeratt)
            this.markeratt = JSROOT.Painter.createAttMarker(this.histo, this.options.Mark - 20);
         if (this.markeratt.size > 0) {
            // simply use relative move from point, can optimize in the future
            path_marker = "";
            this.markeratt.reset_pos();
         } else {
            show_markers = false;
         }
      }

      if (show_text) {
         text_col = JSROOT.Painter.root_colors[this.histo.fMarkerColor];
         text_angle = (this.options.Text>1000) ? this.options.Text % 1000 : 0;
         text_size = 20;

         if ((this.histo.fMarkerSize!==1) && (text_angle!==0))
            text_size = 0.02*height*this.histo.fMarkerSize;

         if ((text_angle === 0) && (this.options.Text<1000)) {
             var space = width / (right - left + 1);
             if (space < 3 * text_size) {
                text_angle = 90;
                text_size = Math.round(space*0.7);
             }
         }

         this.StartTextDrawing(42, text_size, this.draw_g, text_size);
      }

      // if there are too many points, exclude many vertical drawings at the same X position
      // instead define min and max value and made min-max drawing
      var use_minmax = ((right-left) > 3*width);

      if (this.options.Error == 11) {
         var lw = this.lineatt.width + JSROOT.gStyle.fEndErrorSize;
         endx = "m0," + lw + "v-" + 2*lw + "m0," + lw;
         endy = "m" + lw + ",0h-" + 2*lw + "m" + lw + ",0";
         dend = Math.floor((this.lineatt.width-1)/2);
      }

      var draw_markers = show_errors || show_markers;

      if (draw_markers || show_text || show_line) use_minmax = true;

      for (i = left; i <= right; ++i) {

         x = this.GetBinX(i);

         if (this.logx && (x <= 0)) continue;

         grx = Math.round(pmain.grx(x));

         lastbin = (i === right);

         if (lastbin && (left<right)) {
            gry = curry;
         } else {
            y = this.histo.getBinContent(i+1);
            gry = Math.round(pmain.gry(y));
         }

         if (res.length === 0) {
            besti = i;
            prevx = startx = currx = grx;
            prevy = curry_min = curry_max = curry = gry;
            res = "M"+currx+","+curry;
         } else
         if (use_minmax) {
            if ((grx === currx) && !lastbin) {
               if (gry < curry_min) besti = i;
               curry_min = Math.min(curry_min, gry);
               curry_max = Math.max(curry_max, gry);
               curry = gry;
            } else {

               if (draw_markers || show_text || show_line) {
                  bincont = this.histo.getBinContent(besti+1);
                  if (!exclude_zero || (bincont!==0)) {
                     mx1 = Math.round(pmain.grx(this.GetBinX(besti)));
                     mx2 = Math.round(pmain.grx(this.GetBinX(besti+1)));
                     midx = Math.round((mx1+mx2)/2);
                     my = Math.round(pmain.gry(bincont));
                     yerr1 = yerr2 = 20;
                     if (show_errors) {
                        binerr = this.histo.getBinError(besti+1);
                        yerr1 = Math.round(my - pmain.gry(bincont + binerr)); // up
                        yerr2 = Math.round(pmain.gry(bincont - binerr) - my); // down
                     }

                     if (show_text) {
                        var cont = bincont;
                        if ((this.options.Text>=2000) && (this.options.Text < 3000) &&
                             this.IsTProfile() && this.histo.fBinEntries)
                           cont = this.histo.fBinEntries[besti+1];

                        var posx = Math.round(mx1 + (mx2-mx1)*0.1),
                            posy = Math.round(my-2-text_size),
                            sizex = Math.round((mx2-mx1)*0.8),
                            sizey = text_size,
                            lbl = Math.round(cont),
                            talign = 22;

                        if (lbl === cont)
                           lbl = cont.toString();
                        else
                           lbl = JSROOT.FFormat(cont, JSROOT.gStyle.fPaintTextFormat);

                        if (text_angle!==0) {
                           posx = midx;
                           posy = Math.round(my - 2 - text_size/5);
                           sizex = 0;
                           sizey = text_angle-360;
                           talign = 12;
                        }

                        if (cont!==0)
                           this.DrawText(talign, posx, posy, sizex, sizey, lbl, text_col, 0);
                     }

                     if (show_line && (path_line !== null))
                        path_line += ((path_line.length===0) ? "M" : "L") + midx + "," + my;

                     if (draw_markers) {
                        if ((my >= -yerr1) && (my <= height + yerr2)) {
                           if (path_fill !== null)
                              path_fill += "M" + mx1 +","+(my-yerr1) +
                                           "h" + (mx2-mx1) + "v" + (yerr1+yerr2+1) + "h-" + (mx2-mx1) + "z";
                           if (path_marker !== null)
                              path_marker += this.markeratt.create(midx, my);
                           if (path_err !== null) {
                              if (this.options.errorX > 0) {
                                 var mmx1 = Math.round(midx - (mx2-mx1)*this.options.errorX),
                                     mmx2 = Math.round(midx + (mx2-mx1)*this.options.errorX);
                                 path_err += "M" + (mmx1+dend) +","+ my + endx + "h" + (mmx2-mmx1-2*dend) + endx;
                              }
                              path_err += "M" + midx +"," + (my-yerr1+dend) + endy + "v" + (yerr1+yerr2-2*dend) + endy;
                           }
                        }
                     }
                  }
               }

               // when several points as same X differs, need complete logic
               if (!draw_markers && ((curry_min !== curry_max) || (prevy !== curry_min))) {

                  if (prevx !== currx)
                     res += "h"+(currx-prevx);

                  if (curry === curry_min) {
                     if (curry_max !== prevy)
                        res += "v" + (curry_max - prevy);
                     if (curry_min !== curry_max)
                        res += "v" + (curry_min - curry_max);
                  } else {
                     if (curry_min !== prevy)
                        res += "v" + (curry_min - prevy);
                     if (curry_max !== curry_min)
                        res += "v" + (curry_max - curry_min);
                     if (curry !== curry_max)
                       res += "v" + (curry - curry_max);
                  }

                  prevx = currx;
                  prevy = curry;
               }

               if (lastbin && (prevx !== grx))
                  res += "h"+(grx-prevx);

               besti = i;
               curry_min = curry_max = curry = gry;
               currx = grx;
            }
         } else
         if ((gry !== curry) || lastbin) {
            if (grx !== currx) res += "h"+(grx-currx);
            if (gry !== curry) res += "v"+(gry-curry);
            curry = gry;
            currx = grx;
         }
      }

      var close_path = "";

      if (!this.fillatt.empty()) {
         var h0 = (height+3);
         if ((this.hmin>=0) && (pmain.gry(0) < height)) h0 = Math.round(pmain.gry(0));
         close_path = "L"+currx+","+h0 + "L"+startx+","+h0 + "Z";
         if (res.length>0) res += close_path;
      }

      if (draw_markers || show_line) {
         if ((path_fill !== null) && (path_fill.length > 0))
            this.draw_g.append("svg:path")
                       .attr("d", path_fill)
                       .call(this.fillatt.func);

         if ((path_err !== null) && (path_err.length > 0))
               this.draw_g.append("svg:path")
                   .attr("d", path_err)
                   .call(this.lineatt.func);

         if ((path_line !== null) && (path_line.length > 0)) {
            if (!this.fillatt.empty())
               this.draw_g.append("svg:path")
                     .attr("d", this.options.Line===2 ? (path_line + close_path) : res)
                     .attr("stroke", "none")
                     .call(this.fillatt.func);

            this.draw_g.append("svg:path")
                   .attr("d", path_line)
                   .attr("fill", "none")
                   .call(this.lineatt.func);
         }

         if ((path_marker !== null) && (path_marker.length > 0))
            this.draw_g.append("svg:path")
                .attr("d", path_marker)
                .call(this.markeratt.func);

      } else
      if ((res.length > 0) && (this.options.Hist>0)) {
         this.draw_g.append("svg:path")
                    .attr("d", res)
                    .style("stroke-linejoin","miter")
                    .call(this.lineatt.func)
                    .call(this.fillatt.func);
      }

      if (show_text)
         this.FinishTextDrawing(this.draw_g);

   }

   JSROOT.TH1Painter.prototype.GetBinTips = function(bin) {
      var tips = [],
          name = this.GetTipName(),
          pmain = this.main_painter(),
          histo = this.GetObject(),
          x1 = this.GetBinX(bin),
          x2 = this.GetBinX(bin+1),
          cont = histo.getBinContent(bin+1);

      if (name.length>0) tips.push(name);

      if ((this.options.Error > 0) || (this.options.Mark > 0)) {
         tips.push("x = " + pmain.AxisAsText("x", (x1+x2)/2));
         tips.push("y = " + pmain.AxisAsText("y", cont));
         if (this.options.Error > 0) {
            tips.push("error x = " + ((x2 - x1) / 2).toPrecision(4));
            tips.push("error y = " + this.histo.getBinError(bin + 1).toPrecision(4));
         }
      } else {
         tips.push("bin = " + (bin+1));

         if (pmain.x_kind === 'labels')
            tips.push("x = " + pmain.AxisAsText("x", x1));
         else
         if (pmain.x_kind === 'time')
            tips.push("x = " + pmain.AxisAsText("x", (x1+x2)/2));
         else
            tips.push("x = [" + pmain.AxisAsText("x", x1) + ", " + pmain.AxisAsText("x", x2) + ")");

         if (histo['$baseh']) cont -= histo['$baseh'].getBinContent(bin+1);

         if (cont === Math.round(cont))
            tips.push("entries = " + cont);
         else
            tips.push("entries = " + JSROOT.FFormat(cont, JSROOT.gStyle.fStatFormat));
      }

      return tips;
   }

   JSROOT.TH1Painter.prototype.ProcessTooltip = function(pnt) {
      if ((pnt === null) || !this.draw_content || (this.options.Lego > 0) || (this.options.Surf > 0)) {
         if (this.draw_g !== null)
            this.draw_g.select(".tooltip_bin").remove();
         this.ProvideUserTooltip(null);
         return null;
      }

      var width = this.frame_width(),
          height = this.frame_height(),
          pmain = this.main_painter(),
          pad = this.root_pad(),
          painter = this,
          findbin = null, show_rect = true,
          grx1, midx, grx2, gry1, midy, gry2, gapx = 2,
          left = this.GetSelectIndex("x", "left", -1),
          right = this.GetSelectIndex("x", "right", 2),
          l = left, r = right;

      function GetBinGrX(i) {
         var xx = painter.GetBinX(i);
         return (pmain.logx && (xx<=0)) ? null : pmain.grx(xx);
      }

      function GetBinGrY(i) {
         var yy = painter.histo.getBinContent(i + 1);
         if (pmain.logy && (yy < painter.scale_ymin))
            return pmain.swap_xy ? -1000 : 10*height;
         return Math.round(pmain.gry(yy));
      }

      var pnt_x = pmain.swap_xy ? pnt.y : pnt.x,
          pnt_y = pmain.swap_xy ? pnt.x : pnt.y;

      while (l < r-1) {
         var m = Math.round((l+r)*0.5);

         var xx = GetBinGrX(m);
         if ((xx === null) || (xx < pnt_x - 0.5)) {
            if (pmain.swap_xy) r = m; else l = m;
         } else
         if (xx > pnt_x + 0.5) {
            if (pmain.swap_xy) l = m; else r = m;
         } else { l++; r--; }
      }

      findbin = r = l;
      grx1 = GetBinGrX(findbin);

      if (pmain.swap_xy) {
         while ((l>left) && (GetBinGrX(l-1) < grx1 + 2)) --l;
         while ((r<right) && (GetBinGrX(r+1) > grx1 - 2)) ++r;
      } else {
         while ((l>left) && (GetBinGrX(l-1) > grx1 - 2)) --l;
         while ((r<right) && (GetBinGrX(r+1) < grx1 + 2)) ++r;
      }

      if (l < r) {
         // many points can be assigned with the same cursor position
         // first try point around mouse y
         var best = height;
         for (var m=l;m<=r;m++) {
            var dist = Math.abs(GetBinGrY(m) - pnt_y);
            if (dist < best) { best = dist; findbin = m; }
         }

         // if best distance still too far from mouse position, just take from between
         if (best > height/10)
            findbin = Math.round(l + (r-l) / height * pnt_y);

         grx1 = GetBinGrX(findbin);
      }

      grx1 = Math.round(grx1);
      grx2 = Math.round(GetBinGrX(findbin+1));

      if (this.options.Bar > 0) {
         var w = grx2 - grx1;
         grx1 += Math.round(this.histo.fBarOffset/1000*w);
         grx2 = grx1 + Math.round(this.histo.fBarWidth/1000*w);
      }

      if (grx1 > grx2) { var d = grx1; grx1 = grx2; grx2 = d; }

      midx = Math.round((grx1+grx2)/2);

      midy = gry1 = gry2 = GetBinGrY(findbin);

      if (this.options.Bar > 0) {
         show_rect = true;

         gapx = 0;

         gry1 = Math.round(pmain.gry(((this.options.BaseLine!==false) && (this.options.BaseLine > pmain.scale_ymin)) ? this.options.BaseLine : pmain.scale_ymin));

         if (gry1 > gry2) { var d = gry1; gry1 = gry2; gry2 = d; }

         if (!pnt.touch && (pnt.nproc === 1))
            if ((pnt_y<gry1) || (pnt_y>gry2)) findbin = null;
      } else
      if ((this.options.Error > 0) || (this.options.Mark > 0) || (this.options.Line > 0))  {

         show_rect = true;

         var msize = 3;
         if (this.markeratt) msize = Math.max(msize, 2+Math.round(this.markeratt.size * 4));

         if (this.options.Error > 0) {
            var cont = this.histo.getBinContent(findbin+1),
                binerr = this.histo.getBinError(findbin+1);

            gry1 = Math.round(pmain.gry(cont + binerr)); // up
            gry2 = Math.round(pmain.gry(cont - binerr)); // down

            if ((cont==0) && this.IsTProfile()) findbin = null;

            var dx = (grx2-grx1)*this.options.errorX;
            grx1 = Math.round(midx - dx);
            grx2 = Math.round(midx + dx);
         }

         // show at least 6 pixels as tooltip rect
         if (grx2 - grx1 < 2*msize) { grx1 = midx-msize; grx2 = midx+msize; }

         gry1 = Math.min(gry1, midy - msize);
         gry2 = Math.max(gry2, midy + msize);

         if (!pnt.touch && (pnt.nproc === 1))
            if ((pnt_y<gry1) || (pnt_y>gry2)) findbin = null;

      } else {

         // if histogram alone, use old-style with rects
         // if there are too many points at pixel, use circle
         show_rect = (pnt.nproc === 1) && (right-left < width);

         if (show_rect) {
            // for mouse events mouse pointer should be under the curve
            if ((pnt.y < gry1) && !pnt.touch) findbin = null;

            gry2 = height;

            if ((this.fillatt.color !== 'none') && (this.hmin>=0)) {
               gry2 = Math.round(pmain.gry(0));
               if ((gry2 > height) || (gry2 <= gry1)) gry2 = height;
            }
         }
      }

      if (findbin!==null) {
         // if bin on boundary found, check that x position is ok
         if ((findbin === left) && (grx1 > pnt_x + gapx))  findbin = null; else
         if ((findbin === right-1) && (grx2 < pnt_x - gapx)) findbin = null; else
         // if bars option used check that bar is not match
         if ((pnt_x < grx1 - gapx) || (pnt_x > grx2 + gapx)) findbin = null; else
         // exclude empty bin if empty bins suppressed
         if (!this.options.Zero && (this.histo.getBinContent(findbin+1)===0)) findbin = null;
      }

      var ttrect = this.draw_g.select(".tooltip_bin");

      if ((findbin === null) || ((gry2 <= 0) || (gry1 >= height))) {
         ttrect.remove();
         this.ProvideUserTooltip(null);
         return null;
      }

      var res = { name: this.histo.fName, title: this.histo.fTitle,
                  x: midx, y: midy,
                  color1: this.lineatt ? this.lineatt.color : 'green',
                  color2: this.fillatt ? this.fillatt.color : 'blue',
                  lines: this.GetBinTips(findbin) };

      if (pnt.disabled) {
         // case when tooltip should not highlight bin

         ttrect.remove();
         res.changed = true;
      } else
      if (show_rect) {

         if (ttrect.empty())
            ttrect = this.draw_g.append("svg:rect")
                                .attr("class","tooltip_bin h1bin")
                                .style("pointer-events","none");

         res.changed = ttrect.property("current_bin") !== findbin;

         if (res.changed)
            ttrect.attr("x", pmain.swap_xy ? gry1 : grx1)
                  .attr("width", pmain.swap_xy ? gry2-gry1 : grx2-grx1)
                  .attr("y", pmain.swap_xy ? grx1 : gry1)
                  .attr("height", pmain.swap_xy ? grx2-grx1 : gry2-gry1)
                  .style("opacity", "0.3")
                  .property("current_bin", findbin);

         res.exact = (Math.abs(midy - pnt_y) <= 5) || ((pnt_y>=gry1) && (pnt_y<=gry2));

         res.menu = true; // one could show context menu
         // distance to middle point, use to decide which menu to activate
         res.menu_dist = Math.sqrt((midx-pnt_x)*(midx-pnt_x) + (midy-pnt_y)*(midy-pnt_y));

      } else {
         var radius = this.lineatt.width + 3;

         if (ttrect.empty())
            ttrect = this.draw_g.append("svg:circle")
                                .attr("class","tooltip_bin")
                                .style("pointer-events","none")
                                .attr("r", radius)
                                .call(this.lineatt.func)
                                .call(this.fillatt.func);

         res.exact = (Math.abs(midx - pnt.x) <= radius) && (Math.abs(midy - pnt.y) <= radius);

         res.menu = res.exact; // show menu only when mouse pointer exactly over the histogram
         res.menu_dist = Math.sqrt((midx-pnt.x)*(midx-pnt.x) + (midy-pnt.y)*(midy-pnt.y));

         res.changed = ttrect.property("current_bin") !== findbin;

         if (res.changed)
            ttrect.attr("cx", midx)
                  .attr("cy", midy)
                  .property("current_bin", findbin);
      }

      if (this.IsUserTooltipCallback() && res.changed) {
         this.ProvideUserTooltip({ obj: this.histo,  name: this.histo.fName,
                                   bin: findbin, cont: this.histo.getBinContent(findbin+1),
                                   grx: midx, gry: midy });
      }

      return res;
   }


   JSROOT.TH1Painter.prototype.FillHistContextMenu = function(menu) {

      menu.add("Auto zoom-in", this.AutoZoom);

      var sett = JSROOT.getDrawSettings("ROOT." + this.GetObject()._typename, 'nosame');

      menu.addDrawMenu("Draw with", sett.opts, function(arg) {
         if (arg==='inspect')
            return JSROOT.draw(this.divid, this.GetObject(), arg);

         this.options = this.DecodeOptions(arg, true);

         // redraw all objects
         this.RedrawPad();
      });
   }

   JSROOT.TH1Painter.prototype.AutoZoom = function() {
      var left = this.GetSelectIndex("x", "left", -1),
          right = this.GetSelectIndex("x", "right", 1),
          dist = right - left;

      if (dist == 0) return;

      // first find minimum
      var min = this.histo.getBinContent(left + 1);
      for (var indx = left; indx < right; ++indx)
         min = Math.min(min, this.histo.getBinContent(indx+1));
      if (min > 0) return; // if all points positive, no chance for autoscale

      while ((left < right) && (this.histo.getBinContent(left+1) <= min)) ++left;
      while ((left < right) && (this.histo.getBinContent(right) <= min)) --right;

      // if singular bin
      if ((left === right-1) && (left > 2) && (right < this.nbinsx-2)) {
         --left; ++right;
      }

      if ((right - left < dist) && (left < right))
         this.Zoom(this.GetBinX(left), this.GetBinX(right));
   }

   JSROOT.TH1Painter.prototype.CanZoomIn = function(axis,min,max) {
      if ((axis=="x") && (this.GetIndexX(max,0.5) - this.GetIndexX(min,0) > 1)) return true;

      if ((axis=="y") && (Math.abs(max-min) > Math.abs(this.ymax-this.ymin)*1e-6)) return true;

      // check if it makes sense to zoom inside specified axis range
      return false;
   }

   JSROOT.TH1Painter.prototype.CallDrawFunc = function(callback, resize) {
      var is3d = (this.options.Lego > 0) ? true : false,
          main = this.main_painter();

      if ((main !== this) && (main.mode3d !== is3d)) {
         // that to do with that case
         is3d = main.mode3d;
         this.options.Lego = main.options.Lego;
      }

      var funcname = is3d ? "Draw3D" : "Draw2D";

      this[funcname](callback, resize);
   }


   JSROOT.TH1Painter.prototype.Draw2D = function(call_back) {
      if (typeof this.Create3DScene === 'function')
         this.Create3DScene(-1);

      this.mode3d = false;

      this.ScanContent(true);

      this.CreateXY();

      if (typeof this.DrawColorPalette === 'function')
         this.DrawColorPalette(false);

      this.DrawAxes();
      this.DrawGrids();
      this.DrawBins();
      this.DrawTitle();
      this.UpdateStatWebCanvas();
      this.AddInteractive();
      JSROOT.CallBack(call_back);
   }

   JSROOT.TH1Painter.prototype.Draw3D = function(call_back) {
      this.mode3d = true;
      JSROOT.AssertPrerequisites('more2d;3d', function() {
         this.Create3DScene = JSROOT.Painter.HPainter_Create3DScene;
         this.PrepareColorDraw = JSROOT.TH2Painter.prototype.PrepareColorDraw;
         this.Draw3D = JSROOT.Painter.TH1Painter_Draw3D;
         this.Draw3D(call_back);
      }.bind(this));
   }

   JSROOT.THistPainter.prototype.Get3DToolTip = function(indx) {
      var tip = { bin: indx, name: this.GetObject().fName, title: this.GetObject().fTitle };
      switch (this.Dimension()) {
         case 1:
            tip.ix = indx; tip.iy = 1;
            tip.value = this.histo.getBinContent(tip.ix);
            tip.error = this.histo.getBinError(indx);
            tip.lines = this.GetBinTips(indx-1);
            break;
         case 2:
            tip.ix = indx % (this.nbinsx + 2);
            tip.iy = (indx - tip.ix) / (this.nbinsx + 2);
            tip.value = this.histo.getBinContent(tip.ix, tip.iy);
            tip.error = this.histo.getBinError(indx);
            tip.lines = this.GetBinTips(tip.ix-1, tip.iy-1);
            break;
         case 3:
            tip.ix = indx % (this.nbinsx+2);
            tip.iy = ((indx - tip.ix) / (this.nbinsx+2)) % (this.nbinsy+2);
            tip.iz = (indx - tip.ix - tip.iy * (this.nbinsx+2)) / (this.nbinsx+2) / (this.nbinsy+2);
            tip.value = this.GetObject().getBinContent(tip.ix, tip.iy, tip.iz);
            tip.error = this.histo.getBinError(indx);
            tip.lines = this.GetBinTips(tip.ix-1, tip.iy-1, tip.iz-1);
            break;
      }

      return tip;
   }


   JSROOT.TH1Painter.prototype.Redraw = function(resize) {
      this.CallDrawFunc(null, resize);
   }

   JSROOT.Painter.drawHistogram1D = function(divid, histo, opt) {
      // create painter and add it to canvas
      var painter = new JSROOT.TH1Painter(histo);

      painter.SetDivId(divid, 1);

      // here we deciding how histogram will look like and how will be shown
      painter.options = painter.DecodeOptions(opt);

      if (!painter.options.Lego) painter.CheckPadRange();

      painter.ScanContent();

      if (JSROOT.gStyle.AutoStat && (painter.create_canvas || histo.$snapid))
         painter.CreateStat(histo.$custom_stat);

      painter.CallDrawFunc(function() {
         painter.DrawNextFunction(0, function() {

            if (painter.options.Lego === 0) {
               if (painter.options.AutoZoom) painter.AutoZoom();
            }

            painter.FillToolbar();
            painter.DrawingReady();
         });
      });

      return painter;
   }

   // =====================================================================================

   JSROOT.Painter.drawText = function(divid, text) {
      var painter = new JSROOT.TObjectPainter(text);
      painter.SetDivId(divid, 2);

      painter.Redraw = function() {
         var text = this.GetObject(),
             w = this.pad_width(), h = this.pad_height(),
             pos_x = text.fX, pos_y = text.fY,
             tcolor = JSROOT.Painter.root_colors[text.fTextColor],
             use_pad = true, latex_kind = 0, fact = 1.;

         if (text.TestBit(JSROOT.BIT(14))) {
            // NDC coordiantes
            pos_x = pos_x * w;
            pos_y = (1 - pos_y) * h;
         } else
         if (this.main_painter() !== null) {
            w = this.frame_width(); h = this.frame_height(); use_pad = false;
            pos_x = this.main_painter().grx(pos_x);
            pos_y = this.main_painter().gry(pos_y);
         } else
         if (this.root_pad() !== null) {
            pos_x = this.ConvertToNDC("x", pos_x) * w;
            pos_y = (1 - this.ConvertToNDC("y", pos_y)) * h;
         } else {
            text.fTextAlign = 22;
            pos_x = w/2;
            pos_y = h/2;
            if (text.fTextSize === 0) text.fTextSize = 0.05;
            if (text.fTextColor === 0) text.fTextColor = 1;
         }

         this.RecreateDrawG(use_pad, use_pad ? "text_layer" : "upper_layer");

         if (text._typename == 'TLatex') { latex_kind = 1; fact = 0.9; } else
         if (text._typename == 'TMathText') { latex_kind = 2; fact = 0.8; }

         this.StartTextDrawing(text.fTextFont, Math.round(text.fTextSize*Math.min(w,h)*fact));

         this.DrawText(text.fTextAlign, Math.round(pos_x), Math.round(pos_y), 0, 0, text.fTitle, tcolor, latex_kind);

         this.FinishTextDrawing();
      }

      painter.Redraw();
      return painter.DrawingReady();
   }

   // ================= painter of raw text ========================================


   JSROOT.Painter.drawRawText = function(divid, txt, opt) {

      var painter = new JSROOT.TBasePainter();
      painter.txt = txt;
      painter.SetDivId(divid);

      painter.RedrawObject = function(obj) {
         this.txt = obj;
         this.Draw();
         return true;
      }

      painter.Draw = function() {
         var txt = this.txt.value;
         if (typeof txt != 'string') txt = "<undefined>";

         var mathjax = this.txt.mathjax || (JSROOT.gStyle.MathJax>1);

         if (!mathjax && !('as_is' in this.txt)) {
            var arr = txt.split("\n"); txt = "";
            for (var i = 0; i < arr.length; ++i)
               txt += "<pre>" + arr[i] + "</pre>";
         }

         var frame = this.select_main(),
              main = frame.select("div");
         if (main.empty())
            main = frame.append("div").style('max-width','100%').style('max-height','100%').style('overflow','auto');
         main.html(txt);

         // (re) set painter to first child element
         this.SetDivId(this.divid);

         if (mathjax)
            JSROOT.AssertPrerequisites('mathjax', function() {
               MathJax.Hub.Typeset(frame.node());
            });
      }

      painter.Draw();
      return painter.DrawingReady();
   }

   // ===================== hierarchy scanning functions ==================================

   JSROOT.Painter.FolderHierarchy = function(item, obj) {

      if ((obj==null) || !('fFolders' in obj) || (obj.fFolders==null)) return false;

      if (obj.fFolders.arr.length===0) { item._more = false; return true; }

      item._childs = [];

      for ( var i = 0; i < obj.fFolders.arr.length; ++i) {
         var chld = obj.fFolders.arr[i];
         item._childs.push( {
            _name : chld.fName,
            _kind : "ROOT." + chld._typename,
            _obj : chld
         });
      }
      return true;
   }

   JSROOT.Painter.TaskHierarchy = function(item, obj) {
      // function can be used for different derived classes
      // we show not only child tasks, but all complex data members

      if ((obj==null) || !('fTasks' in obj) || (obj.fTasks==null)) return false;

      JSROOT.Painter.ObjectHierarchy(item, obj, { exclude: ['fTasks', 'fName'] } );

      if ((obj.fTasks.arr.length===0) && (item._childs.length==0)) { item._more = false; return true; }

      // item._childs = [];

      for ( var i = 0; i < obj.fTasks.arr.length; ++i) {
         var chld = obj.fTasks.arr[i];
         item._childs.push( {
            _name : chld.fName,
            _kind : "ROOT." + chld._typename,
            _obj : chld
         });
      }
      return true;
   }

   JSROOT.Painter.ListHierarchy = function(folder, lst) {
      if (!JSROOT.IsRootCollection(lst)) return false;

      if ((lst.arr === undefined) || (lst.arr.length === 0)) {
         folder._more = false;
         return true;
      }

      var do_context = false, prnt = folder;
      while (prnt) {
         if (prnt._do_context) do_context = true;
         prnt = prnt._parent;
      }

      // if list has objects with similar names, create cycle number for them
      var ismap = (lst._typename == 'TMap'), names = [], cnt = [], cycle = [];

      for (var i = 0; i < lst.arr.length; ++i) {
         var obj = ismap ? lst.arr[i].first : lst.arr[i];
         if (!obj) continue; // for such objects index will be used as name
         var objname = obj.fName || obj.name;
         if (!objname) continue;
         var indx = names.indexOf(objname);
         if (indx>=0) {
            cnt[indx]++;
         } else {
            cnt[names.length] = cycle[names.length] = 1;
            names.push(objname);
         }
      }

      folder._childs = [];
      for ( var i = 0; i < lst.arr.length; ++i) {
         var obj = ismap ? lst.arr[i].first : lst.arr[i];

         var item;

         if (!obj || !obj._typename) {
            item = {
               _name: i.toString(),
               _kind: "ROOT.NULL",
               _title: "NULL",
               _value: "null",
               _obj: null
            }
         } else {
           item = {
             _name: obj.fName || obj.name,
             _kind: "ROOT." + obj._typename,
             _title: (obj.fTitle || "") + " type:"  +  obj._typename,
             _obj: obj
           };

           switch(obj._typename) {
              case 'TColor': item._value = JSROOT.Painter.MakeColorRGB(obj); break;
              case 'TText': item._value = obj.fTitle; break;
              case 'TLatex': item._value = obj.fTitle; break;
              case 'TObjString': item._value = obj.fString; break;
              default: if (lst.opt && lst.opt[i] && lst.opt[i].length) item._value = lst.opt[i];
           }

           if (do_context && JSROOT.canDraw(obj._typename)) item._direct_context = true;

           // if name is integer value, it should match array index
           if (!item._name || (!isNaN(parseInt(item._name)) && (parseInt(item._name)!==i))
               || (lst.arr.indexOf(obj)<i)) {
              item._name = i.toString();
           } else {
              // if there are several such names, add cycle number to the item name
              var indx = names.indexOf(obj.fName);
              if ((indx>=0) && (cnt[indx]>1)) {
                 item._cycle = cycle[indx]++;
                 item._keyname = item._name;
                 item._name = item._keyname + ";" + item._cycle;
              }
           }
         }

         folder._childs.push(item);
      }
      return true;
   }

   JSROOT.Painter.KeysHierarchy = function(folder, keys, file, dirname) {

      if (keys === undefined) return false;

      folder._childs = [];

      for (var i = 0; i < keys.length; ++i) {
         var key = keys[i];

         var item = {
            _name : key.fName + ";" + key.fCycle,
            _cycle : key.fCycle,
            _kind : "ROOT." + key.fClassName,
            _title : key.fTitle,
            _keyname : key.fName,
            _readobj : null,
            _parent : folder
         };

         if (key.fObjlen > 1e5) item._title += ' (size: ' + (key.fObjlen/1e6).toFixed(1) + 'MB)';

         if ('fRealName' in key)
            item._realname = key.fRealName + ";" + key.fCycle;

         if (key.fClassName == 'TDirectory' || key.fClassName == 'TDirectoryFile') {
            var dir = null;
            if ((dirname!=null) && (file!=null)) dir = file.GetDir(dirname + key.fName);
            if (dir == null) {
               item._more = true;
               item._expand = function(node, obj) {
                  // one can get expand call from child objects - ignore them
                  return JSROOT.Painter.KeysHierarchy(node, obj.fKeys);
               }
            } else {
               // remove cycle number - we have already directory
               item._name = key.fName;
               JSROOT.Painter.KeysHierarchy(item, dir.fKeys, file, dirname + key.fName + "/");
            }
         } else
         if ((key.fClassName == 'TList') && (key.fName == 'StreamerInfo')) {
            item._name = 'StreamerInfo';
            item._kind = "ROOT.TStreamerInfoList";
            item._title = "List of streamer infos for binary I/O";
            item._readobj = file.fStreamerInfos;
         }

         folder._childs.push(item);
      }

      return true;
   }

   JSROOT.Painter.ObjectHierarchy = function(top, obj, args) {
      if (!top || (obj===null)) return false;

      top._childs = [];

      var proto = Object.prototype.toString.apply(obj);

      if (proto === '[object DataView]') {

         var item = {
             _parent: top,
             _name: 'size',
             _value: obj.byteLength.toString(),
             _vclass: 'h_value_num'
         };

         top._childs.push(item);
         var namelen = (obj.byteLength < 10) ? 1 : JSROOT.log10(obj.byteLength);

         for (var k=0;k<obj.byteLength;++k) {
            if (k % 16 === 0) {
               item = {
                 _parent: top,
                 _name: k.toString(),
                 _value: "",
                 _vclass: 'h_value_num'
               };
               while (item._name.length < namelen) item._name = "0" + item._name;
               top._childs.push(item);
            }

            var val = obj.getUint8(k).toString(16);
            while (val.length<2) val = "0"+val;
            if (item._value.length>0)
               item._value += (k%4===0) ? " | " : " ";

            item._value += val;
         }
         return true;
      }

      // check nosimple property in all parents
      var nosimple = true, do_context = false, prnt = top;
      while (prnt) {
         if (prnt._do_context) do_context = true;
         if ('_nosimple' in prnt) { nosimple = prnt._nosimple; break; }
         prnt = prnt._parent;
      }

      var isarray = (proto.lastIndexOf('Array]') == proto.length-6) && (proto.indexOf('[object')==0) && !isNaN(obj.length),
          compress = isarray && (obj.length > JSROOT.gStyle.HierarchyLimit),  arrcompress = false;

      if (isarray && (top._name==="Object") && !top._parent) top._name = "Array";

      if (compress) {
         arrcompress = true;
         for (var k=0;k<obj.length;++k) {
            var typ = typeof obj[k];
            if ((typ === 'number') || (typ === 'boolean') || (typ=='string' && (obj[k].length<16))) continue;
            arrcompress = false; break;
         }
      }

      if (!('_obj' in top))
         top._obj = obj;
      else
      if (top._obj !== obj) alert('object missmatch');

      if (!top._title) {
         if (obj._typename)
            top._title = "ROOT." + obj._typename;
         else
         if (isarray) top._title = "Array len: " + obj.length;
      }

      if (arrcompress) {
         for (var k=0;k<obj.length;) {

            var nextk = Math.min(k+10,obj.length), allsame = true, prevk = k;

            while (allsame) {
               allsame = true;
               for (var d=prevk;d<nextk;++d)
                  if (obj[k]!==obj[d]) allsame = false;

               if (allsame) {
                  if (nextk===obj.length) break;
                  prevk = nextk;
                  nextk = Math.min(nextk+10,obj.length);
               } else
               if (prevk !== k) {
                  // last block with similar
                  nextk = prevk;
                  allsame = true;
                  break;
               }
            }

            var item = { _parent: top, _name: k+".."+(nextk-1), _vclass: 'h_value_num' };

            if (allsame) {
               item._value = obj[k].toString();
            } else {
               item._value = "";
               for (var d=k;d<nextk;++d)
                  item._value += ((d===k) ? "[ " : ", ") + obj[d].toString();
               item._value += " ]";
            }

            top._childs.push(item);

            k = nextk;
         }
         return true;
      }

      var lastitem, lastkey, lastfield, cnt;

      for (var key in obj) {
         if ((key == '_typename') || (key[0]=='$')) continue;
         var fld = obj[key];
         if (typeof fld == 'function') continue;
         if (args && args.exclude && (args.exclude.indexOf(key)>=0)) continue;

         if (compress && lastitem) {
            if (lastfield===fld) { ++cnt; lastkey = key; continue; }
            if (cnt>0) lastitem._name += ".." + lastkey;
         }

         var item = { _parent: top, _name: key };

         if (compress) { lastitem = item;  lastkey = key; lastfield = fld; cnt = 0; }

         if (fld === null) {
            item._value = item._title = "null";
            if (!nosimple) top._childs.push(item);
            continue;
         }

         var simple = false;

         if (typeof fld == 'object') {

            proto = Object.prototype.toString.apply(fld);

            if ((proto.lastIndexOf('Array]') == proto.length-6) && (proto.indexOf('[object')==0)) {
               item._title = "array len=" + fld.length;
               simple = (proto != '[object Array]');
               if (fld.length === 0) {
                  item._value = "[ ]";
                  item._more = false; // hpainter will not try to expand again
               } else {
                  item._value = "[...]";
                  item._more = true;
                  item._expand = JSROOT.Painter.ObjectHierarchy;
                  item._obj = fld;
               }
            } else
            if (proto === "[object DataView]") {
               item._title = 'DataView len=' + fld.byteLength;
               item._value = "[...]";
               item._more = true;
               item._expand = JSROOT.Painter.ObjectHierarchy;
               item._obj = fld;
            }  else
            if (proto === "[object Date]") {
               item._more = false;
               item._title = 'Date';
               item._value = fld.toString();
               item._vclass = 'h_value_num';
            } else {

               if (fld.$kind || fld._typename)
                  item._kind = item._title = "ROOT." + (fld.$kind || fld._typename);

               if (fld._typename) {
                  item._title = fld._typename;
                  if (do_context && JSROOT.canDraw(fld._typename)) item._direct_context = true;
               }

               // check if object already shown in hierarchy (circular dependency)
               var curr = top, inparent = false;
               while (curr && !inparent) {
                  inparent = (curr._obj === fld);
                  curr = curr._parent;
               }

               if (inparent) {
                  item._value = "{ prnt }";
                  simple = true;
               } else {
                  item._obj = fld;
                  item._more = false;

                  switch(fld._typename) {
                     case 'TColor': item._value = JSROOT.Painter.MakeColorRGB(fld); break;
                     case 'TText': item._value = fld.fTitle; break;
                     case 'TLatex': item._value = fld.fTitle; break;
                     case 'TObjString': item._value = fld.fString; break;
                     default:
                        if (JSROOT.IsRootCollection(fld) && (typeof fld.arr === "object")) {
                           item._value = fld.arr.length ? "[...]" : "[]";
                           item._title += ", size:"  + fld.arr.length;
                           if (fld.arr.length>0) item._more = true;
                        } else {
                           item._more = true;
                           item._value = "{ }";
                        }
                  }
               }
            }
         } else
         if ((typeof fld === 'number') || (typeof fld === 'boolean')) {
            simple = true;
            if (key == 'fBits')
               item._value = "0x" + fld.toString(16);
            else
               item._value = fld.toString();
            item._vclass = 'h_value_num';
         } else
         if (typeof fld === 'string') {
            simple = true;
            item._value = '&quot;' + fld.replace(/\&/g, '&amp;').replace(/\"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;') + '&quot;';
            item._vclass = 'h_value_str';
         } else
         if (typeof fld === 'undefined') {
            simple = true;
            item._value = "undefined";
            item._vclass = 'h_value_num';
         } else {
            simple = true;
            alert('miss ' + key + '  ' + typeof fld);
         }

         if (!simple || !nosimple)
            top._childs.push(item);
      }

      if (compress && lastitem && (cnt>0)) lastitem._name += ".." + lastkey;

      return true;
   }

   // =========== painter of hierarchical structures =================================

   JSROOT.hpainter = null; // global pointer

   JSROOT.HierarchyPainter = function(name, frameid, backgr) {
      JSROOT.TBasePainter.call(this);
      this.name = name;
      this.h = null; // hierarchy
      this.with_icons = true;
      this.background = backgr;
      this.files_monitoring = (frameid == null); // by default files monitored when nobrowser option specified
      this.nobrowser = (frameid === null);
      if (!this.nobrowser) this.SetDivId(frameid); // this is required to be able cleanup painter

      // remember only very first instance
      if (!JSROOT.hpainter)
         JSROOT.hpainter = this;
   }

   JSROOT.HierarchyPainter.prototype = Object.create(JSROOT.TBasePainter.prototype);

   JSROOT.HierarchyPainter.prototype.Cleanup = function() {
      // clear drawing and browser
      this.clear(true);

      JSROOT.TBasePainter.prototype.Cleanup.call(this);

      if (JSROOT.hpainter === this)
         JSROOT.hpainter = null;
   }

   JSROOT.HierarchyPainter.prototype.FileHierarchy = function(file) {
      var painter = this;

      var folder = {
         _name : file.fFileName,
         _title : (file.fTitle ? (file.fTitle + ", path ") : "")  + file.fFullURL,
         _kind : "ROOT.TFile",
         _file : file,
         _fullurl : file.fFullURL,
         _localfile : file.fLocalFile,
         _had_direct_read : false,
         // this is central get method, item or itemname can be used
         _get : function(item, itemname, callback) {

            var fff = this; // file item

            if (item && item._readobj)
               return JSROOT.CallBack(callback, item, item._readobj);

            if (item!=null) itemname = painter.itemFullName(item, fff);

            function ReadFileObject(file) {
               if (fff._file==null) fff._file = file;

               if (file == null) return JSROOT.CallBack(callback, item, null);

               file.ReadObject(itemname, function(obj) {

                  // if object was read even when item didnot exist try to reconstruct new hierarchy
                  if ((item==null) && (obj!=null)) {
                     // first try to found last read directory
                     var d = painter.Find({name:itemname, top:fff, last_exists:true, check_keys:true });
                     if ((d!=null) && ('last' in d) && (d.last!=fff)) {
                        // reconstruct only subdir hierarchy
                        var dir = file.GetDir(painter.itemFullName(d.last, fff));
                        if (dir) {
                           d.last._name = d.last._keyname;
                           var dirname = painter.itemFullName(d.last, fff);
                           JSROOT.Painter.KeysHierarchy(d.last, dir.fKeys, file, dirname + "/");
                        }
                     } else {
                        // reconstruct full file hierarchy
                        JSROOT.Painter.KeysHierarchy(fff, file.fKeys, file, "");
                     }
                     item = painter.Find({name:itemname, top: fff});
                  }

                  if (item!=null) {
                     item._readobj = obj;
                     // remove cycle number for objects supporting expand
                     if ('_expand' in item) item._name = item._keyname;
                  }

                  JSROOT.CallBack(callback, item, obj);
               });
            }

            if (fff._file) ReadFileObject(fff._file); else
            if (fff._localfile) new JSROOT.TLocalFile(fff._localfile, ReadFileObject); else
            if (fff._fullurl) new JSROOT.TFile(fff._fullurl, ReadFileObject);
         }
      };

      JSROOT.Painter.KeysHierarchy(folder, file.fKeys, file, "");

      return folder;
   }

   JSROOT.HierarchyPainter.prototype.ForEach = function(callback, top) {

      if (top==null) top = this.h;
      if ((top==null) || (typeof callback != 'function')) return;
      function each_item(item) {
         callback(item);
         if ('_childs' in item)
            for (var n = 0; n < item._childs.length; ++n) {
               item._childs[n]._parent = item;
               each_item(item._childs[n]);
            }
      }

      each_item(top);
   }

   JSROOT.HierarchyPainter.prototype.Find = function(arg) {
      // search item in the hierarchy
      // One could specify simply item name or object with following arguments
      //   name:  item to search
      //   force: specified elements will be created when not exists
      //   last_exists: when specified last parent element will be returned
      //   check_keys: check TFile keys with cycle suffix
      //   top:   element to start search from

      function find_in_hierarchy(top, fullname) {

         if (!fullname || (fullname.length == 0) || !top) return top;

         var pos = fullname.length;

         if (!top._parent && (top._kind !== 'TopFolder') && (fullname.indexOf(top._name)===0)) {
            // it is allowed to provide item name, which includes top-parent like file.root/folder/item
            // but one could skip top-item name, if there are no other items
            if (fullname === top._name) return top;

            var len = top._name.length;
            if (fullname[len] == "/") {
               fullname = fullname.substr(len+1);
               pos = fullname.length;
            }
         }

         function process_child(child, ignore_prnt) {
            // set parent pointer when searching child
            if (!ignore_prnt) child._parent = top;

            if ((pos >= fullname.length-1) || (pos < 0)) return child;

            return find_in_hierarchy(child, fullname.substr(pos + 1));
         }

         while (pos > 0) {
            // we try to find element with slashes inside - start from full name
            var localname = (pos >= fullname.length) ? fullname : fullname.substr(0, pos);

            if (top._childs) {
               // first try to find direct matched item
               for (var i = 0; i < top._childs.length; ++i)
                  if (top._childs[i]._name == localname)
                     return process_child(top._childs[i]);

               // if first child online, check its elements
               if ((top._kind === 'TopFolder') && (top._childs[0]._online!==undefined))
                  for (var i = 0; i < top._childs[0]._childs.length; ++i)
                     if (top._childs[0]._childs[i]._name == localname)
                        return process_child(top._childs[0]._childs[i], true);

               // if allowed, try to found item with key
               if (arg.check_keys) {
                  var newest = null;
                  for (var i = 0; i < top._childs.length; ++i) {
                    if (top._childs[i]._keyname === localname) {
                       if (!newest || (newest._cycle < top._childs[i]._cycle)) newest = top._childs[i];
                    }
                  }
                  if (newest) return process_child(newest);
               }

               var allow_index = arg.allow_index;
               if ((localname[0] === '[') && (localname[localname.length-1] === ']') &&
                   !isNaN(parseInt(localname.substr(1,localname.length-2)))) {
                  allow_index = true;
                  localname = localname.substr(1,localname.length-2);
               }

               // when search for the elements it could be allowed to check index
               if (allow_index) {
                  var indx = parseInt(localname);
                  if (!isNaN(indx) && (indx>=0) && (indx<top._childs.length))
                     return process_child(top._childs[indx]);
               }
            }

            pos = fullname.lastIndexOf("/", pos - 1);
         }

         if (arg.force) {
             // if didnot found element with given name we just generate it
             if (top._childs === undefined) top._childs = [];
             pos = fullname.indexOf("/");
             var child = { _name: ((pos < 0) ? fullname : fullname.substr(0, pos)) };
             top._childs.push(child);
             return process_child(child);
         }

         return (arg.last_exists && top) ? { last: top, rest: fullname } : null;
      }

      var top = this.h, itemname = "";

      if (arg === null) return null; else
      if (typeof arg == 'string') { itemname = arg; arg = {}; } else
      if (typeof arg == 'object') { itemname = arg.name; if ('top' in arg) top = arg.top; } else
         return null;

      if (itemname === "__top_folder__") return top;

      return find_in_hierarchy(top, itemname);
   }

   JSROOT.HierarchyPainter.prototype.itemFullName = function(node, uptoparent, compact) {

      if (node && node._kind ==='TopFolder') return "__top_folder__";

      var res = "";

      while (node) {
         // online items never includes top-level folder
         if ((node._online!==undefined) && !uptoparent) return res;

         if ((node === uptoparent) || (node._kind==='TopFolder')) break;
         if (compact && !node._parent) break; // in compact form top-parent is not included
         if (res.length > 0) res = "/" + res;
         res = node._name + res;
         node = node._parent;
      }

      return res;
   }

   JSROOT.HierarchyPainter.prototype.ExecuteCommand = function(itemname, callback) {
      // execute item marked as 'Command'
      // If command requires additional arguments, they could be specified as extra arguments
      // Or they will be requested interactive

      var hitem = this.Find(itemname);
      var url = this.GetOnlineItemUrl(hitem) + "/cmd.json";
      var pthis = this;
      var d3node = d3.select((typeof callback == 'function') ? undefined : callback);

      if ('_numargs' in hitem)
         for (var n = 0; n < hitem._numargs; ++n) {
            var argname = "arg" + (n+1);
            var argvalue = null;
            if (n+2<arguments.length) argvalue = arguments[n+2];
            if ((argvalue==null) && (typeof callback == 'object'))
               argvalue = prompt("Input argument " + argname + " for command " + hitem._name,"");
            if (argvalue==null) return;
            url += ((n==0) ? "?" : "&") + argname + "=" + argvalue;
         }

      if (!d3node.empty()) {
         d3node.style('background','yellow');
         if (hitem && hitem._title) d3node.attr('title', "Executing " + hitem._title);
      }

      JSROOT.NewHttpRequest(url, 'text', function(res) {
         if (typeof callback == 'function') return callback(res);
         if (d3node.empty()) return;
         var col = ((res!=null) && (res!='false')) ? 'green' : 'red';
         if (hitem && hitem._title) d3node.attr('title', hitem._title + " lastres=" + res);
         d3node.style('background', col);
         setTimeout(function() { d3node.style('background', ''); }, 2000);
         if ((col == 'green') && ('_hreload' in hitem)) pthis.reload();
         if ((col == 'green') && ('_update_item' in hitem)) pthis.updateItems(hitem._update_item.split(";"));
      }).send();
   }

   JSROOT.HierarchyPainter.prototype.RefreshHtml = function(callback) {
      if (!this.divid) return JSROOT.CallBack(callback);
      var hpainter = this;
      JSROOT.AssertPrerequisites('jq2d', function() {
          hpainter.RefreshHtml(callback);
      });
   }

   JSROOT.HierarchyPainter.prototype.get = function(arg, call_back, options) {
      // get object item with specified name
      // depending from provided option, same item can generate different object types

      if (arg===null) return JSROOT.CallBack(call_back, null, null);

      var itemname, item, hpainter = this;

      if (typeof arg === 'string') {
         itemname = arg;
      } else
      if (typeof arg === 'object') {
         if ((arg._parent!==undefined) && (arg._name!==undefined) && (arg._kind!==undefined)) item = arg; else
         if (arg.name!==undefined) itemname = arg.name; else
         if (arg.arg!==undefined) itemname = arg.arg; else
         if (arg.item!==undefined) item = arg.item;
      }

      if (item) itemname = this.itemFullName(item);
           else item = this.Find( { name: itemname, allow_index: true, check_keys: true } );

      // if item not found, try to find nearest parent which could allow us to get inside
      var d = (item!=null) ? null : this.Find({ name: itemname, last_exists: true, check_keys: true, allow_index: true });

      // if item not found, try to expand hierarchy central function
      // implements not process get in central method of hierarchy item (if exists)
      // if last_parent found, try to expand it
      if ((d !== null) && ('last' in d) && (d.last !== null)) {
         var parentname = this.itemFullName(d.last);

         // this is indication that expand does not give us better path to searched item
         if ((typeof arg == 'object') && ('rest' in arg))
            if ((arg.rest == d.rest) || (arg.rest.length <= d.rest.length))
               return JSROOT.CallBack(call_back);

         return this.expand(parentname, function(res) {
            if (!res) JSROOT.CallBack(call_back);
            var newparentname = hpainter.itemFullName(d.last);
            if (newparentname.length>0) newparentname+="/";
            hpainter.get( { name: newparentname + d.rest, rest: d.rest }, call_back, options);
         }, null, true);
      }

      if ((item !== null) && (typeof item._obj == 'object'))
         return JSROOT.CallBack(call_back, item, item._obj);

      // normally search _get method in the parent items
      var curr = item;
      while (curr != null) {
         if (('_get' in curr) && (typeof curr._get == 'function'))
            return curr._get(item, null, call_back, options);
         curr = ('_parent' in curr) ? curr._parent : null;
      }

      JSROOT.CallBack(call_back, item, null);
   }

   JSROOT.HierarchyPainter.prototype.draw = function(divid, obj, drawopt) {
      // just envelope, one should be able to redefine it for sub-classes
      return JSROOT.draw(divid, obj, drawopt);
   }

   JSROOT.HierarchyPainter.prototype.redraw = function(divid, obj, drawopt) {
      // just envelope, one should be able to redefine it for sub-classes
      return JSROOT.redraw(divid, obj, drawopt);
   }

   JSROOT.HierarchyPainter.prototype.player = function(itemname, option, call_back) {
      var item = this.Find(itemname);

      if (!item || !('_player' in item)) return JSROOT.CallBack(call_back, null);

      var hpainter = this;

      var prereq = ('_prereq' in item) ? item['_prereq'] : '';

      JSROOT.AssertPrerequisites(prereq, function() {

         var player_func = JSROOT.findFunction(item._player);
         if (player_func == null) return JSROOT.CallBack(call_back, null);

         hpainter.CreateDisplay(function(mdi) {
            var res = null;
            if (mdi) res = player_func(hpainter, itemname, option);
            JSROOT.CallBack(call_back, res);
         });
      });
   }

   JSROOT.HierarchyPainter.prototype.canDisplay = function(item, drawopt) {
      if (!item) return false;
      if ('_player' in item) return true;
      if (item._can_draw === true) return true;
      if (drawopt == 'inspect') return true;
      var handle = JSROOT.getDrawHandle(item._kind, drawopt);
      return handle && (('func' in handle) || ('draw_field' in handle));
   }

   JSROOT.HierarchyPainter.prototype.isItemDisplayed = function(itemname) {
      var mdi = this.GetDisplay();
      if (!mdi) return false;

      return mdi.FindFrame(itemname) !== null;
   }

   JSROOT.HierarchyPainter.prototype.display = function(itemname, drawopt, call_back) {
      var h = this,
          painter = null,
          updating = false,
          item = null,
          display_itemname = itemname,
          frame_name = itemname,
          marker = "::_display_on_frame_::",
          p = drawopt ? drawopt.indexOf(marker) : -1;

      if (p>=0) {
         frame_name = drawopt.substr(p + marker.length);
         drawopt = drawopt.substr(0, p);
      }

      function display_callback(respainter) {
         if (!updating) JSROOT.progress();

         if (respainter && (typeof respainter === 'object') && (typeof respainter.SetItemName === 'function')) {
            respainter.SetItemName(display_itemname, updating ? null : drawopt, h); // mark painter as created from hierarchy
            if (item && !item._painter) item._painter = respainter;
         }
         JSROOT.CallBack(call_back, respainter || painter, display_itemname);
      }

      h.CreateDisplay(function(mdi) {

         if (!mdi) return display_callback();

         item = h.Find(display_itemname);

         if (item && ('_player' in item))
            return h.player(display_itemname, drawopt, display_callback);

         updating = (typeof(drawopt)=='string') && (drawopt.indexOf("update:")==0);

         if (updating) {
            drawopt = drawopt.substr(7);
            if (!item || item._doing_update) return display_callback();
            item._doing_update = true;
         }

         if (item && !h.canDisplay(item, drawopt)) return display_callback();

         var divid = "";
         if ((typeof(drawopt)=='string') && (drawopt.indexOf("divid:")>=0)) {
            var pos = drawopt.indexOf("divid:");
            divid = drawopt.slice(pos+6);
            drawopt = drawopt.slice(0, pos);
         }

         if (!updating) JSROOT.progress("Loading " + display_itemname);

         h.get(display_itemname, function(resitem, obj) {

            if (!updating) JSROOT.progress();

            if (!item) item = resitem;

            if (updating && item) delete item._doing_update;
            if (!obj) return display_callback();

            if (!updating) JSROOT.progress("Drawing " + display_itemname);

            if (divid.length > 0)
               return (updating ? JSROOT.redraw : JSROOT.draw)(divid, obj, drawopt, display_callback);

            mdi.ForEachPainter(function(p, frame) {
               if (p.GetItemName() != display_itemname) return;
               // verify that object was drawn with same option as specified now (if any)
               if (!updating && (drawopt!=null) && (p.GetItemDrawOpt()!=drawopt)) return;
               mdi.ActivateFrame(frame);

               var handle = null;
               if (obj._typename) handle = JSROOT.getDrawHandle("ROOT." + obj._typename);
               if (handle && handle.draw_field && obj[handle.draw_field])
                  obj = obj[handle.draw_field];

               if (p.RedrawObject(obj)) painter = p;
            });

            if (painter) return display_callback();

            if (updating) {
               JSROOT.console("something went wrong - did not found painter when doing update of " + display_itemname);
               return display_callback();
            }

            var frame = mdi.FindFrame(frame_name, true);
            d3.select(frame).html("");
            mdi.ActivateFrame(frame);

            JSROOT.draw(d3.select(frame).attr("id"), obj, drawopt, display_callback);

            if (JSROOT.gStyle.DragAndDrop)
               h.enable_dropping(frame, display_itemname);

         }, drawopt);
      });
   }

   JSROOT.HierarchyPainter.prototype.enable_dragging = function(element, itemname) {
      // here is not defined - implemented with jquery
   }

   JSROOT.HierarchyPainter.prototype.enable_dropping = function(frame, itemname) {
      // here is not defined - implemented with jquery
   }

   JSROOT.HierarchyPainter.prototype.dropitem = function(itemname, divid, opt, call_back) {
      var h = this;

      if (opt && typeof opt === 'function') { call_back = opt; opt = ""; }
      if (opt===undefined) opt = "";

      function drop_callback(drop_painter) {
         if (drop_painter && (typeof drop_painter === 'object')) drop_painter.SetItemName(itemname, null, h);
         JSROOT.CallBack(call_back);
      }

      h.get(itemname, function(item, obj) {
         if (!obj) return JSROOT.CallBack(call_back);

         var dummy = new JSROOT.TObjectPainter();
         dummy.SetDivId(divid, -1);
         var main_painter = dummy.main_painter(true);

         if (main_painter && (typeof main_painter.PerformDrop === 'function'))
            return main_painter.PerformDrop(obj, itemname, item, opt, drop_callback);

         if (main_painter && main_painter.accept_drops)
            return JSROOT.draw(divid, obj, "same " + opt, drop_callback);

         h.CleanupFrame(divid);
         return JSROOT.draw(divid, obj, opt, drop_callback);
      });

      return true;
   }

   JSROOT.HierarchyPainter.prototype.updateItems = function(items) {
      // argument is item name or array of string with items name
      // only already drawn items will be update with same draw option

      if ((this.disp == null) || (items==null)) return;

      var draw_items = [], draw_options = [];

      this.disp.ForEachPainter(function(p) {
         var itemname = p.GetItemName();
         if ((itemname==null) || (draw_items.indexOf(itemname)>=0)) return;
         if (typeof items == 'array') {
            if (items.indexOf(itemname) < 0) return;
         } else {
            if (items != itemname) return;
         }
         draw_items.push(itemname);
         draw_options.push("update:" + p.GetItemDrawOpt());
      }, true); // only visible panels are considered

      if (draw_items.length > 0)
         this.displayAll(draw_items, draw_options);
   }


   JSROOT.HierarchyPainter.prototype.updateAll = function(only_auto_items, only_items) {
      // method can be used to fetch new objects and update all existing drawings
      // if only_auto_items specified, only automatic items will be updated

      if (this.disp == null) return;

      if (only_auto_items === "monitoring") only_auto_items = !this._monitoring_on;

      var allitems = [], options = [], hpainter = this;

      // first collect items
      this.disp.ForEachPainter(function(p) {
         var itemname = p.GetItemName(),
             drawopt = p.GetItemDrawOpt();
         if ((itemname==null) || (allitems.indexOf(itemname)>=0)) return;

         var item = hpainter.Find(itemname), forced = false;
         if (!item || ('_not_monitor' in item) || ('_player' in item)) return;

         if ('_always_monitor' in item) {
            forced = true;
         } else {
            var handle = JSROOT.getDrawHandle(item._kind);
            if (handle && ('monitor' in handle)) {
               if ((handle.monitor===false) || (handle.monitor=='never')) return;
               if (handle.monitor==='always') forced = true;
            }
         }

         if (forced || !only_auto_items) {
            allitems.push(itemname);
            options.push("update:" + drawopt);
         }
      }, true); // only visible panels are considered

      var painter = this;

      // force all files to read again (normally in non-browser mode)
      if (this.files_monitoring && !only_auto_items)
         this.ForEachRootFile(function(item) {
            painter.ForEach(function(fitem) { delete fitem._readobj; }, item);
            delete item._file;
         });

      if (allitems.length > 0)
         this.displayAll(allitems, options);
   }

   JSROOT.HierarchyPainter.prototype.displayAll = function(items, options, call_back) {

      if ((items == null) || (items.length == 0)) return JSROOT.CallBack(call_back);

      var h = this;

      if (!options) options = [];
      while (options.length < items.length)
         options.push("");

      if ((options.length == 1) && (options[0] == "iotest")) {
         h.clear();
         d3.select("#" + h.disp_frameid).html("<h2>Start I/O test</h2>")

         var tm0 = new Date();
         return h.get(items[0], function(item, obj) {
            var tm1 = new Date();
            d3.select("#" + h.disp_frameid).append("h2").html("Item " + items[0] + " reading time = " + (tm1.getTime() - tm0.getTime()) + "ms");
            return JSROOT.CallBack(call_back);
         });
      }

      var dropitems = new Array(items.length), dropopts = new Array(items.length);

      // First of all check that items are exists, look for cycle extension and plus sign
      for (var i = 0; i < items.length; ++i) {
         dropitems[i] = dropopts[i] = null;

         var item = items[i], can_split = true;

         if (item && (item.length>1) && (item[0]=='\'') && (item[item.length-1]=='\'')) {
            items[i] = item.substr(1, item.length-2);
            can_split = false;
         }

         var elem = h.Find({ name: items[i], check_keys: true });
         if (elem) { items[i] = h.itemFullName(elem); continue; }

         if (can_split && (items[i][0]=='[') && (items[i][items[i].length-1]==']')) {
            dropitems[i] = JSROOT.ParseAsArray(items[i]);
            items[i] = dropitems[i].shift();
         } else
         if (can_split && (items[i].indexOf("+") > 0)) {
            dropitems[i] = items[i].split("+");
            items[i] = dropitems[i].shift();
         }

         if (dropitems[i] && dropitems[i].length > 0) {
            // allow to specify _same_ item in different file
            for (var j = 0; j < dropitems[i].length; ++j) {
               var pos = dropitems[i][j].indexOf("_same_");
               if ((pos>0) && (h.Find(dropitems[i][j])==null))
                  dropitems[i][j] = dropitems[i][j].substr(0,pos) + items[i].substr(pos);

               elem = h.Find({ name: dropitems[i][j], check_keys: true });
               if (elem) dropitems[i][j] = h.itemFullName(elem);
            }

            if ((options[i][0] == "[") && (options[i][options[i].length-1] == "]")) {
               dropopts[i] = JSROOT.ParseAsArray(options[i]);
               options[i] = dropopts[i].shift();
            } else
            if (options[i].indexOf("+") > 0) {
               dropopts[i] = options[i].split("+");
               options[i] = dropopts[i].shift();
            } else {
               dropopts[i] = [];
            }

            while (dropopts[i].length < dropitems[i].length) dropopts[i].push("");
         }

         // also check if subsequent items has _same_, than use name from first item
         var pos = items[i].indexOf("_same_");
         if ((pos>0) && !h.Find(items[i]) && (i>0))
            items[i] = items[i].substr(0,pos) + items[0].substr(pos);

         elem = h.Find({ name: items[i], check_keys: true });
         if (elem) items[i] = h.itemFullName(elem);
      }

      // now check that items can be displayed
      for (var n = items.length-1; n>=0; --n) {
         var hitem = h.Find(items[n]);
         if (!hitem || h.canDisplay(hitem, options[n])) continue;
         // try to expand specified item
         h.expand(items[n], null, null, true);
         items.splice(n, 1);
         options.splice(n, 1);
         dropitems.splice(n, 1);
      }

      if (items.length == 0) return JSROOT.CallBack(call_back);

      var frame_names = new Array(items.length), items_wait = new Array(items.length);
      for (var n=0; n < items.length;++n) {
         items_wait[n] = 0;
         var fname = items[n], k = 0;
         if (items.indexOf(fname) < n) items_wait[n] = true; // if same item specified, one should wait first drawing before start next

         while (frame_names.indexOf(fname)>=0)
            fname = items[n] + "_" + k++;
         frame_names[n] = fname;
      }

      // now check if several same items present - select only one for the drawing
      // if draw option includes 'main', such item will be drawn first
      for (var n=0; n<items.length;++n) {
         if (items_wait[n] !== 0) continue;
         var found_main = n;
         for (var k=0; k<items.length;++k)
            if ((items[n]===items[k]) && (options[k].indexOf('main')>=0)) found_main = k;
         for (var k=0; k<items.length;++k)
            if (items[n]===items[k]) items_wait[k] = (found_main != k);
      }

      h.CreateDisplay(function(mdi) {
         if (!mdi) return JSROOT.CallBack(call_back);

         // Than create empty frames for each item
         for (var i = 0; i < items.length; ++i)
            if (options[i].indexOf('update:')!==0) {
               mdi.CreateFrame(frame_names[i]);
               options[i] += "::_display_on_frame_::"+frame_names[i];
            }

         function DropNextItem(indx, painter) {
            if (painter && dropitems[indx] && (dropitems[indx].length>0))
               return h.dropitem(dropitems[indx].shift(), painter.divid, dropopts[indx].shift(), DropNextItem.bind(h, indx, painter));

            dropitems[indx] = null; // mark that all drop items are processed
            items[indx] = null; // mark item as ready

            var isany = false;

            for (var cnt = 0; cnt < items.length; ++cnt) {
               if (dropitems[cnt]) isany = true;
               if (items[cnt]===null) continue; // ignore completed item
               isany = true;
               if (items_wait[cnt] && items.indexOf(items[cnt])===cnt) {
                  items_wait[cnt] = false;
                  h.display(items[cnt], options[cnt], DropNextItem.bind(h,cnt));
               }
            }

            // only when items drawn and all sub-items dropped, one could perform call-back
            if (!isany && call_back) {
               JSROOT.CallBack(call_back);
               call_back = null;
            }
         }

         // We start display of all items parallel, but only if they are not the same
         for (var i = 0; i < items.length; ++i)
            if (!items_wait[i])
               h.display(items[i], options[i], DropNextItem.bind(h,i));
      });
   }

   JSROOT.HierarchyPainter.prototype.reload = function() {
      var hpainter = this;
      if ('_online' in this.h)
         this.OpenOnline(this.h._online, function() {
            hpainter.RefreshHtml();
         });
   }

   JSROOT.HierarchyPainter.prototype.UpdateTreeNode = function() {
      // dummy function, will be redefined when jquery part loaded
   }

   JSROOT.HierarchyPainter.prototype.actiavte = function(items, force) {
      // activate (select) specified item
      // if force specified, all required sub-levels will be opened

      if (typeof items == 'string') items = [ items ];

      var active = [],  // array of elements to activate
          painter = this, // painter itself
          update = []; // array of elements to update
      this.ForEach(function(item) { if (item._background) { active.push(item); delete item._background; } });

      function mark_active() {
         if (typeof painter.UpdateBackground !== 'function') return;

         for (var n=update.length-1;n>=0;--n)
            painter.UpdateTreeNode(update[n]);

         for (var n=0;n<active.length;++n)
            painter.UpdateBackground(active[n], force);
      }

      function find_next(itemname, prev_found) {
         if (itemname === undefined) {
            // extract next element
            if (items.length == 0) return mark_active();
            itemname = items.shift();
         }

         var hitem = painter.Find(itemname);

         if (!hitem) {
            var d = painter.Find({ name: itemname, last_exists: true, check_keys: true, allow_index: true });
            if (!d || !d.last) return find_next();
            d.now_found = painter.itemFullName(d.last);

            if (force) {

               // if after last expand no better solution found - skip it
               if ((prev_found!==undefined) && (d.now_found === prev_found)) return find_next();

               return painter.expand(d.now_found, function(res) {
                  if (!res) return find_next();
                  var newname = painter.itemFullName(d.last);
                  if (newname.length>0) newname+="/";
                  find_next(newname + d.rest, d.now_found);
               });
            }
            hitem = d.last;
         }

         if (hitem) {
            // check that item is visible (opened), otherwise should enable parent

            var prnt = hitem._parent;
            while (prnt) {
               if (!prnt._isopen) {
                  if (force) {
                     prnt._isopen = true;
                     if (update.indexOf(prnt)<0) update.push(prnt);
                  } else {
                     hitem = prnt; break;
                  }
               }
               prnt = prnt._parent;
            }

            hitem._background = 'grey';
            if (active.indexOf(hitem)<0) active.push(hitem);
         }

         find_next();
      }

      if (force) {
         if (!this.browser_kind) return this.CreateBrowser('float', true, find_next);
         if (!this.browser_visible) this.ToggleBrowserVisisbility();
      }

      // use recursion
      find_next();
   }

   JSROOT.HierarchyPainter.prototype.expand = function(itemname, call_back, d3cont, silent) {
      var hpainter = this, hitem = this.Find(itemname);

      if (!hitem && d3cont) return JSROOT.CallBack(call_back);

      function DoExpandItem(_item, _obj, _name) {
         if (!_name) _name = hpainter.itemFullName(_item);

         var handle = _item._expand ? null : JSROOT.getDrawHandle(_item._kind, "::expand");

         if (_obj && handle && handle.expand_item) {
            _obj = _obj[handle.expand_item]; // just take specified field from the object
            if (_obj && _obj._typename)
               handle = JSROOT.getDrawHandle("ROOT."+_obj._typename, "::expand");
         }

         if (handle && handle.expand) {
            JSROOT.AssertPrerequisites(handle.prereq, function() {
               _item._expand = JSROOT.findFunction(handle.expand);
               if (_item._expand) return DoExpandItem(_item, _obj, _name);
               JSROOT.CallBack(call_back);
            });
            return true;
         }

         // try to use expand function
         if (_obj && _item && (typeof _item._expand === 'function')) {
            if (_item._expand(_item, _obj)) {
               _item._isopen = true;
               if (_item._parent && !_item._parent._isopen) {
                  _item._parent._isopen = true; // also show parent
                  if (!silent) hpainter.UpdateTreeNode(_item._parent);
               } else {
                  if (!silent) hpainter.UpdateTreeNode(_item, d3cont);
               }
               JSROOT.CallBack(call_back, _item);
               return true;
            }
         }

         if (_obj && JSROOT.Painter.ObjectHierarchy(_item, _obj)) {
            _item._isopen = true;
            if (_item._parent && !_item._parent._isopen) {
               _item._parent._isopen = true; // also show parent
               if (!silent) hpainter.UpdateTreeNode(_item._parent);
            } else {
               if (!silent) hpainter.UpdateTreeNode(_item, d3cont);
            }
            JSROOT.CallBack(call_back, _item);
            return true;
         }

         return false;
      }

      if (hitem) {
         // item marked as it cannot be expanded, also top item cannot be changed
         if ((hitem._more === false) || (!hitem._parent && hitem._childs)) return JSROOT.CallBack(call_back);

         if (hitem._childs && hitem._isopen) {
            hitem._isopen = false;
            if (!silent) hpainter.UpdateTreeNode(hitem, d3cont);
            return JSROOT.CallBack(call_back);
         }

         if (hitem._obj && DoExpandItem(hitem, hitem._obj, itemname)) return;
      }

      JSROOT.progress("Loading " + itemname);

      this.get(itemname, function(item, obj) {

         JSROOT.progress();

         if (obj && DoExpandItem(item, obj)) return;

         JSROOT.CallBack(call_back);
      }, "hierarchy_expand" ); // indicate that we getting element for expand, can handle it differently

   }

   JSROOT.HierarchyPainter.prototype.GetTopOnlineItem = function(item) {
      if (item!=null) {
         while ((item!=null) && (!('_online' in item))) item = item._parent;
         return item;
      }

      if (this.h==null) return null;
      if ('_online' in this.h) return this.h;
      if ((this.h._childs!=null) && ('_online' in this.h._childs[0])) return this.h._childs[0];
      return null;
   }


   JSROOT.HierarchyPainter.prototype.ForEachJsonFile = function(call_back) {
      if (this.h==null) return;
      if ('_jsonfile' in this.h)
         return JSROOT.CallBack(call_back, this.h);

      if (this.h._childs!=null)
         for (var n = 0; n < this.h._childs.length; ++n) {
            var item = this.h._childs[n];
            if ('_jsonfile' in item) JSROOT.CallBack(call_back, item);
         }
   }

   JSROOT.HierarchyPainter.prototype.OpenJsonFile = function(filepath, call_back) {
      var isfileopened = false;
      this.ForEachJsonFile(function(item) { if (item._jsonfile==filepath) isfileopened = true; });
      if (isfileopened) return JSROOT.CallBack(call_back);

      var pthis = this;
      JSROOT.NewHttpRequest(filepath, 'object', function(res) {
         if (!res) return JSROOT.CallBack(call_back);
         var h1 = { _jsonfile: filepath, _kind: "ROOT." + res._typename, _jsontmp: res, _name: filepath.split("/").pop() };
         if (res.fTitle) h1._title = res.fTitle;
         h1._get = function(item,itemname,callback) {
            if (item._jsontmp)
               return JSROOT.CallBack(callback, item, item._jsontmp);
            JSROOT.NewHttpRequest(item._jsonfile, 'object', function(res) {
               item._jsontmp = res;
               JSROOT.CallBack(callback, item, item._jsontmp);
            }).send();
         }
         if (pthis.h == null) pthis.h = h1; else
         if (pthis.h._kind == 'TopFolder') pthis.h._childs.push(h1); else {
            var h0 = pthis.h, topname = ('_jsonfile' in h0) ? "Files" : "Items";
            pthis.h = { _name: topname, _kind: 'TopFolder', _childs : [h0, h1] };
         }

         pthis.RefreshHtml(call_back);
      }).send(null);
   }

   JSROOT.HierarchyPainter.prototype.ForEachRootFile = function(call_back) {
      if (this.h==null) return;
      if ((this.h._kind == "ROOT.TFile") && (this.h._file!=null))
         return JSROOT.CallBack(call_back, this.h);

      if (this.h._childs != null)
         for (var n = 0; n < this.h._childs.length; ++n) {
            var item = this.h._childs[n];
            if ((item._kind == 'ROOT.TFile') && ('_fullurl' in item))
               JSROOT.CallBack(call_back, item);
         }
   }

   JSROOT.HierarchyPainter.prototype.OpenRootFile = function(filepath, call_back) {
      // first check that file with such URL already opened

      var isfileopened = false;
      this.ForEachRootFile(function(item) { if (item._fullurl===filepath) isfileopened = true; });
      if (isfileopened) return JSROOT.CallBack(call_back);

      var pthis = this;

      JSROOT.progress("Opening " + filepath + " ...");
      JSROOT.OpenFile(filepath, function(file) {
         JSROOT.progress();
         if (!file) {
            // make CORS warning
            if (!d3.select("#gui_fileCORS").style("background","red").empty())
               setTimeout(function() { d3.select("#gui_fileCORS").style("background",''); }, 5000);
            return JSROOT.CallBack(call_back, false);
         }

         var h1 = pthis.FileHierarchy(file);
         h1._isopen = true;
         if (pthis.h == null) {
            pthis.h = h1;
            if (pthis._topname) h1._name = pthis._topname;
         } else
         if (pthis.h._kind == 'TopFolder') {
            pthis.h._childs.push(h1);
         }  else {
            var h0 = pthis.h, topname = (h0._kind == "ROOT.TFile") ? "Files" : "Items";
            pthis.h = { _name: topname, _kind: 'TopFolder', _childs : [h0, h1], _isopen: true };
         }

         pthis.RefreshHtml(call_back);
      });
   }

   JSROOT.HierarchyPainter.prototype.ApplyStyle = function(style, call_back) {
      if (!style)
         return JSROOT.CallBack(call_back);

      if (typeof style === 'object') {
         if (style._typename === "TStyle")
            JSROOT.extend(JSROOT.gStyle, style);
         return JSROOT.CallBack(call_back);
      }

      if (typeof style === 'string') {

         var hpainter = this,
             item = this.Find( { name: style, allow_index: true, check_keys: true } );

         if (item!==null)
            return this.get(item, function(item2, obj) { hpainter.ApplyStyle(obj, call_back); });

         if (style.indexOf('.json') > 0)
            return JSROOT.NewHttpRequest(style, 'object', function(res) {
               hpainter.ApplyStyle(res, call_back);
            }).send(null);
      }

      return JSROOT.CallBack(call_back);
   }

   JSROOT.HierarchyPainter.prototype.GetFileProp = function(itemname) {
      var item = this.Find(itemname);
      if (item == null) return null;

      var subname = item._name;
      while (item._parent) {
         item = item._parent;
         if ('_file' in item)
            return { kind: "file", fileurl: item._file.fURL, itemname: subname, localfile: !!item._file.fLocalFile };

         if ('_jsonfile' in item)
            return { kind: "json", fileurl: item._jsonfile, itemname: subname };

         subname = item._name + "/" + subname;
      }

      return null;
   }

   JSROOT.MarkAsStreamerInfo = function(h,item,obj) {
      // this function used on THttpServer to mark streamer infos list
      // as fictional TStreamerInfoList class, which has special draw function
      if (obj && (obj._typename=='TList'))
         obj._typename = 'TStreamerInfoList';
   }

   JSROOT.HierarchyPainter.prototype.GetOnlineItemUrl = function(item) {
      // returns URL, which could be used to request item from the online server
      if (typeof item == "string") item = this.Find(item);
      var prnt = item;
      while (prnt && (prnt._online===undefined)) prnt = prnt._parent;
      return prnt ? (prnt._online + this.itemFullName(item, prnt)) : null;
   }

   JSROOT.HierarchyPainter.prototype.isOnlineItem = function(item) {
      return this.GetOnlineItemUrl(item)!==null;
   }

   JSROOT.HierarchyPainter.prototype.GetOnlineItem = function(item, itemname, callback, option) {
      // method used to request object from the http server

      var url = itemname, h_get = false, req = "", req_kind = "object", pthis = this, draw_handle = null;

      if (option === 'hierarchy_expand') { h_get = true; option = undefined; }

      if (item != null) {
         url = this.GetOnlineItemUrl(item);
         var func = null;
         if ('_kind' in item) draw_handle = JSROOT.getDrawHandle(item._kind);

         if (h_get) {
            req = 'h.json?compact=3';
            item._expand = JSROOT.Painter.OnlineHierarchy; // use proper expand function
         } else
         if ('_make_request' in item) {
            func = JSROOT.findFunction(item._make_request);
         } else
         if ((draw_handle!=null) && ('make_request' in draw_handle)) {
            func = draw_handle.make_request;
         }

         if (typeof func == 'function') {
            // ask to make request
            var dreq = func(pthis, item, url, option);
            // result can be simple string or object with req and kind fields
            if (dreq!=null)
               if (typeof dreq == 'string') req = dreq; else {
                  if ('req' in dreq) req = dreq.req;
                  if ('kind' in dreq) req_kind = dreq.kind;
               }
         }

         if ((req.length==0) && (item._kind.indexOf("ROOT.")!=0))
           req = 'item.json.gz?compact=3';
      }

      if ((itemname==null) && (item!=null) && ('_cached_draw_object' in this) && (req.length == 0)) {
         // special handling for drawGUI when cashed
         var obj = this._cached_draw_object;
         delete this._cached_draw_object;
         return JSROOT.CallBack(callback, item, obj);
      }

      if (req.length == 0) req = 'root.json.gz?compact=23';

      if (url.length > 0) url += "/";
      url += req;

      var itemreq = JSROOT.NewHttpRequest(url, req_kind, function(obj) {

         var func = null;

         if (!h_get && (item!=null) && ('_after_request' in item)) {
            func = JSROOT.findFunction(item._after_request);
         } else
         if ((draw_handle!=null) && ('after_request' in draw_handle))
            func = draw_handle.after_request;

         if (typeof func == 'function') {
            var res = func(pthis, item, obj, option, itemreq);
            if ((res!=null) && (typeof res == "object")) obj = res;
         }

         JSROOT.CallBack(callback, item, obj);
      });

      itemreq.send(null);
   }

   JSROOT.Painter.OnlineHierarchy = function(node, obj) {
      // central function for expand of all online items

      if ((obj != null) && (node != null) && ('_childs' in obj)) {

         for (var n=0;n<obj._childs.length;++n)
            if (obj._childs[n]._more || obj._childs[n]._childs)
               obj._childs[n]._expand = JSROOT.Painter.OnlineHierarchy;

         node._childs = obj._childs;
         obj._childs = null;
         return true;
      }

      return false;
   }

   JSROOT.HierarchyPainter.prototype.OpenOnline = function(server_address, user_callback) {
      var painter = this;

      function AdoptHierarchy(result) {
         painter.h = result;
         if (painter.h == null) return;

         if (('_title' in painter.h) && (painter.h._title!='')) document.title = painter.h._title;

         result._isopen = true;

         // mark top hierarchy as online data and
         painter.h._online = server_address;

         painter.h._get = function(item, itemname, callback, option) {
            painter.GetOnlineItem(item, itemname, callback, option);
         }

         painter.h._expand = JSROOT.Painter.OnlineHierarchy;

         var scripts = "", modules = "";
         painter.ForEach(function(item) {
            if ('_childs' in item) item._expand = JSROOT.Painter.OnlineHierarchy;

            if ('_autoload' in item) {
               var arr = item._autoload.split(";");
               for (var n = 0; n < arr.length; ++n)
                  if ((arr[n].length>3) &&
                      ((arr[n].lastIndexOf(".js")==arr[n].length-3) ||
                      (arr[n].lastIndexOf(".css")==arr[n].length-4))) {
                     if (scripts.indexOf(arr[n])<0) scripts+=arr[n]+";";
                  } else {
                     if (modules.indexOf(arr[n])<0) modules+=arr[n]+";";
                  }
            }
         });

         if (scripts.length > 0) scripts = "user:" + scripts;

         // use AssertPrerequisites, while it protect us from race conditions
         JSROOT.AssertPrerequisites(modules + scripts, function() {

            painter.ForEach(function(item) {
               if (!('_drawfunc' in item) || !('_kind' in item)) return;
               var typename = "kind:" + item._kind;
               if (item._kind.indexOf('ROOT.')==0) typename = item._kind.slice(5);
               var drawopt = item._drawopt;
               if (!JSROOT.canDraw(typename) || (drawopt!=null))
                  JSROOT.addDrawFunc({ name: typename, func: item._drawfunc, script: item._drawscript, opt: drawopt });
            });

            JSROOT.CallBack(user_callback, painter);
         });
      }

      if (!server_address) server_address = "";

      if (typeof server_address == 'object') {
         var h = server_address;
         server_address = "";
         return AdoptHierarchy(h);
      }

      JSROOT.NewHttpRequest(server_address + "h.json?compact=3", 'object', AdoptHierarchy).send(null);
   }

   JSROOT.HierarchyPainter.prototype.GetOnlineProp = function(itemname) {
      var item = this.Find(itemname);
      if (!item) return null;

      var subname = item._name;
      while (item._parent != null) {
         item = item._parent;

         if ('_online' in item) {
            return {
               server : item._online,
               itemname : subname
            };
         }
         subname = item._name + "/" + subname;
      }

      return null;
   }

   JSROOT.HierarchyPainter.prototype.FillOnlineMenu = function(menu, onlineprop, itemname) {

      var painter = this,
          node = this.Find(itemname),
          sett = JSROOT.getDrawSettings(node._kind, 'nosame;noinspect'),
          handle = JSROOT.getDrawHandle(node._kind),
          root_type = ('_kind' in node) ? node._kind.indexOf("ROOT.") == 0 : false;

      if (sett.opts) {
         sett.opts.push('inspect');
         menu.addDrawMenu("Draw", sett.opts, function(arg) { painter.display(itemname, arg); });
      }

      if (!node._childs && (node._more || root_type || sett.expand))
         menu.add("Expand", function() { painter.expand(itemname); });

      if (handle && ('execute' in handle))
         menu.add("Execute", function() { painter.ExecuteCommand(itemname, menu.tree_node); });

      var drawurl = onlineprop.server + onlineprop.itemname + "/draw.htm";
      var separ = "?";
      if (this.IsMonitoring()) {
         drawurl += separ + "monitoring=" + this.MonitoringInterval();
         separ = "&";
      }

      if (sett.opts)
         menu.addDrawMenu("Draw in new window", sett.opts, function(arg) { window.open(drawurl+separ+"opt=" +arg); });

      if (sett.opts && (sett.opts.length > 0) && root_type)
         menu.addDrawMenu("Draw as png", sett.opts, function(arg) {
            window.open(onlineprop.server + onlineprop.itemname + "/root.png?w=400&h=300&opt=" + arg);
         });

      if ('_player' in node)
         menu.add("Player", function() { painter.player(itemname); });
   }

   JSROOT.HierarchyPainter.prototype.Adopt = function(h) {
      this.h = h;
      this.RefreshHtml();
   }

   JSROOT.HierarchyPainter.prototype.SetMonitoring = function(interval, flag) {

      if (interval!==undefined) {
         this._monitoring_on = false;
         this._monitoring_interval = 3000;

         interval = !interval ? 0 : parseInt(interval);

         if (!isNaN(interval) && (interval>0)) {
            this._monitoring_on = true;
            this._monitoring_interval = Math.max(100,interval);
         }
      }

      if (flag !== undefined)
         this._monitoring_on = flag;

      // first clear old handle
      if (this._monitoring_handle) clearInterval(this._monitoring_handle);

      // now set new interval (if necessary)
      this._monitoring_handle = setInterval(this.updateAll.bind(this, "monitoring"),  this._monitoring_interval);
   }

   JSROOT.HierarchyPainter.prototype.MonitoringInterval = function(val) {
      // returns interval
      return ('_monitoring_interval' in this) ? this._monitoring_interval : 3000;
   }

   JSROOT.HierarchyPainter.prototype.EnableMonitoring = function(on) {
      this._monitoring_on = on;
   }

   JSROOT.HierarchyPainter.prototype.IsMonitoring = function() {
      return this._monitoring_on;
   }

   JSROOT.HierarchyPainter.prototype.SetDisplay = function(layout, frameid) {

      if ((frameid==null) && (typeof layout == 'object')) {
         this.disp = layout;
         this.disp_kind = 'custom';
         this.disp_frameid = null;
      } else {
         this.disp_kind = layout;
         this.disp_frameid = frameid;
      }

      if (!this.register_resize) {
         this.register_resize = true;
         JSROOT.RegisterForResize(this);
      }
   }

   JSROOT.HierarchyPainter.prototype.GetLayout = function() {
      return this.disp_kind;
   }

   JSROOT.HierarchyPainter.prototype.ClearPainter = function(obj_painter) {
      this.ForEach(function(item) {
         if (item._painter === obj_painter) delete item._painter;
      });
   }

   JSROOT.HierarchyPainter.prototype.clear = function(withbrowser) {
      if (this.disp) {
         this.disp.Reset();
         delete this.disp;
      }

      var plainarr = [];

      this.ForEach(function(item) {
         delete item._painter; // remove reference on the painter
         // when only display cleared, try to clear all browser items
         if (!withbrowser && (typeof item.clear=='function')) item.clear();
         if (withbrowser) plainarr.push(item);
      });

      if (withbrowser) {

         if (this._monitoring_handle) {
            clearInterval(this._monitoring_handle);
            delete this._monitoring_handle;
         }

         // simplify work for javascript and delete all (ok, most of) cross-references
         this.select_main().html("");
         plainarr.forEach(function(d) { delete d._parent; delete d._childs; delete d._obj; delete d._d3cont; });
         delete this.h;
      }
   }

   JSROOT.HierarchyPainter.prototype.GetDisplay = function() {
      return ('disp' in this) ? this.disp : null;
   }

   JSROOT.HierarchyPainter.prototype.CleanupFrame = function(divid) {
      // hook to perform extra actions when frame is cleaned

      var lst = JSROOT.cleanup(divid);

      // we remove all painters references from items
      if (lst && (lst.length>0))
         this.ForEach(function(item) {
            if (item._painter && lst.indexOf(item._painter)>=0) delete item._painter;
         });
   }

   JSROOT.HierarchyPainter.prototype.CreateDisplay = function(callback) {

      if ('disp' in this) {
         if ((this.disp.NumDraw() > 0) || (this.disp_kind == "custom")) return JSROOT.CallBack(callback, this.disp);
         this.disp.Reset();
         delete this.disp;
      }

      // check that we can found frame where drawing should be done
      if (document.getElementById(this.disp_frameid) == null)
         return JSROOT.CallBack(callback, null);

      if ((this.disp_kind == "simple") ||
          (this.disp_kind.indexOf("grid") == 0) && (this.disp_kind.indexOf("gridi") < 0))
           this.disp = new JSROOT.GridDisplay(this.disp_frameid, this.disp_kind);
      else
         return JSROOT.AssertPrerequisites('jq2d', this.CreateDisplay.bind(this,callback));

      if (this.disp)
         this.disp.CleanupFrame = this.CleanupFrame.bind(this);

      JSROOT.CallBack(callback, this.disp);
   }

   JSROOT.HierarchyPainter.prototype.updateOnOtherFrames = function(painter, obj) {
      // function should update object drawings for other painters
      var mdi = this.disp, handle = null, isany = false;
      if (!mdi) return false;

      if (obj._typename) handle = JSROOT.getDrawHandle("ROOT." + obj._typename);
      if (handle && handle.draw_field && obj[handle.draw_field])
         obj = obj[handle.draw_field];

      mdi.ForEachPainter(function(p, frame) {
         if ((p===painter) || (p.GetItemName() != painter.GetItemName())) return;
         mdi.ActivateFrame(frame);
         if (p.RedrawObject(obj)) isany = true;
      });
      return isany;
   }

   JSROOT.HierarchyPainter.prototype.CheckResize = function(size) {
      if (this.disp) this.disp.CheckMDIResize(null, size);
   }

   JSROOT.HierarchyPainter.prototype.StartGUI = function(gui_div, gui_call_back, url) {

      function GetOption(opt) {
         var res = JSROOT.GetUrlOption(opt, url);
         if ((res===null) && gui_div && !gui_div.empty() && gui_div.node().hasAttribute(opt)) res = gui_div.attr(opt);
         return res;
      }

      function GetOptionAsArray(opt) {
         var res = JSROOT.GetUrlOptionAsArray(opt, url);
         if (res.length>0 || !gui_div || gui_div.empty()) return res;
         while (opt.length>0) {
            var separ = opt.indexOf(";");
            var part = separ>0 ? opt.substr(0, separ) : opt;
            if (separ>0) opt = opt.substr(separ+1); else opt = "";

            var canarray = true;
            if (part[0]=='#') { part = part.substr(1); canarray = false; }
            if (part==='files') continue; // special case for normal UI

            if (!gui_div.node().hasAttribute(part)) continue;

            var val = gui_div.attr(part);

            if (canarray) res = res.concat(JSROOT.ParseAsArray(val));
            else if (val!==null) res.push(val);
         }
         return res;
      }

      var hpainter = this,
          prereq = GetOption('prereq') || "",
          filesdir = JSROOT.GetUrlOption("path", url) || "", // path used in normal gui
          filesarr = GetOptionAsArray("#file;files"),
          localfile = GetOption("localfile"),
          jsonarr = GetOptionAsArray("#json;jsons"),
          expanditems = GetOptionAsArray("expand"),
          itemsarr = GetOptionAsArray("#item;items"),
          optionsarr = GetOptionAsArray("#opt;opts"),
          monitor = GetOption("monitoring"),
          layout = GetOption("layout"),
          style = GetOptionAsArray("#style"),
          status = GetOption("status"),
          browser_kind = GetOption("browser"),
          title = GetOption("title");

      if (GetOption("float")!==null) browser_kind='float'; else
      if (GetOption("fix")!==null) browser_kind='fix';

      this.no_select = GetOption("noselect");

      if (GetOption('files_monitoring')!==null) this.files_monitoring = true;

      if (title) document.title = title;

      var load = GetOption("load");
      if (load) prereq += ";io;2d;load:" + load;

      if (expanditems.length==0 && (GetOption("expand")==="")) expanditems.push("");

      if (filesdir) {
         for (var i=0;i<filesarr.length;++i) filesarr[i] = filesdir + filesarr[i];
         for (var i=0;i<jsonarr.length;++i) jsonarr[i] = filesdir + jsonarr[i];
      }

      if ((itemsarr.length==0) && GetOption("item")==="") itemsarr.push("");

      if ((jsonarr.length==1) && (itemsarr.length==0) && (expanditems.length==0)) itemsarr.push("");

      if (!this.disp_kind) {
         if ((typeof layout == "string") && (layout.length>0))
            this.disp_kind = layout;
         else
         switch (itemsarr.length) {
           case 0:
           case 1: this.disp_kind = 'simple'; break;
           case 2: this.disp_kind = 'vert2'; break;
           case 3: this.disp_kind = 'vert21'; break;
           case 4: this.disp_kind = 'vert22'; break;
           case 5: this.disp_kind = 'vert32'; break;
           case 6: this.disp_kind = 'vert222'; break;
           case 7: this.disp_kind = 'vert322'; break;
           case 8: this.disp_kind = 'vert332'; break;
           case 9: this.disp_kind = 'vert333'; break;
           default: this.disp_kind = 'flex';
         }
      }

      if (status==="no") status = null; else
      if (status==="off") { this.status_disabled = true; status = null; } else
      if ((status!==null) && (status!=='on')) { status = parseInt(status); if (isNaN(status) || (status<5)) status = 'on'; }
      if (this.no_select==="") this.no_select = true;

      if (!browser_kind) browser_kind = "fix"; else
      if (browser_kind==="no") browser_kind = ""; else
      if (browser_kind==="off") { browser_kind = ""; status = null; this.exclude_browser = true; }
      if (GetOption("nofloat")!==null) this.float_browser_disabled = true;

      if (this.start_without_browser) browser_kind = "";

      if (status || browser_kind) prereg = "jq2d;" + prereq;

      this._topname = GetOption("topname");

      if (gui_div)
         this.PrepareGuiDiv(gui_div, this.disp_kind);

      function OpenAllFiles(res) {
         if (browser_kind) { hpainter.CreateBrowser(browser_kind); browser_kind = ""; }
         if (status) { hpainter.CreateStatusLine(status,"toggle"); status = null; }
         if (jsonarr.length>0)
            hpainter.OpenJsonFile(jsonarr.shift(), OpenAllFiles);
         else if (filesarr.length>0)
            hpainter.OpenRootFile(filesarr.shift(), OpenAllFiles);
         else if ((localfile!==null) && (typeof hpainter.SelectLocalFile == 'function')) {
            localfile = null; hpainter.SelectLocalFile(OpenAllFiles);
         } else if (expanditems.length>0)
            hpainter.expand(expanditems.shift(), OpenAllFiles);
         else if (style.length>0)
            hpainter.ApplyStyle(style.shift(), OpenAllFiles);
         else
            hpainter.displayAll(itemsarr, optionsarr, function() {
               hpainter.RefreshHtml();
               hpainter.SetMonitoring(monitor);
               JSROOT.CallBack(gui_call_back);
           });
      }

      function AfterOnlineOpened() {
         // check if server enables monitoring

         if (('_monitoring' in hpainter.h) && !monitor)
            monitor = hpainter.h._monitoring;

         if (('_layout' in hpainter.h) && (layout==null))
            hpainter.disp_kind = hpainter.h._layout;

         if (('_loadfile' in hpainter.h) && (filesarr.length==0))
            filesarr = JSROOT.ParseAsArray(hpainter.h._loadfile);

         if (('_drawitem' in hpainter.h) && (itemsarr.length==0)) {
            itemsarr = JSROOT.ParseAsArray(hpainter.h._drawitem);
            optionsarr = JSROOT.ParseAsArray(hpainter.h._drawopt);
         }

         OpenAllFiles();
      }

      var h0 = null;
      if (this.is_online) {
         if (typeof GetCachedHierarchy == 'function') h0 = GetCachedHierarchy();
         if (typeof h0 !== 'object') h0 = "";
      }

      if (h0!==null) hpainter.OpenOnline(h0, AfterOnlineOpened);
      else if (prereq.length>0) JSROOT.AssertPrerequisites(prereq, OpenAllFiles);
      else OpenAllFiles();
   }

   JSROOT.HierarchyPainter.prototype.PrepareGuiDiv = function(myDiv, layout) {
      this.gui_div = myDiv.attr('id');

      myDiv.append("div").attr("id",this.gui_div + "_drawing")
                         .classed("jsroot_draw_area", true)
                         .style('position',"absolute").style('left',0).style('top',0).style('bottom',0).style('right',0);

      if (!this.exclude_browser) {
         var br = myDiv.append("div").classed("jsroot_browser", true);

         var btns = br.append("div").classed("jsroot_browser_btns", true)
                                    .classed("jsroot", true);

         btns.style('position',"absolute").style("left","7px").style("top","7px");
         if (JSROOT.touches) btns.style('opacity','0.2'); // on touch devices should be always visible

         JSROOT.ToolbarIcons.CreateSVG(btns, JSROOT.ToolbarIcons.diamand, 15, "toggle fix-pos browser")
                            .style("margin","3px").on("click", this.CreateBrowser.bind(this, "fix", true));

         if (!this.float_browser_disabled)
            JSROOT.ToolbarIcons.CreateSVG(btns, JSROOT.ToolbarIcons.circle, 15, "toggle float browser")
                               .style("margin","3px").on("click", this.CreateBrowser.bind(this, "float", true));

         if (!this.status_disabled)
            JSROOT.ToolbarIcons.CreateSVG(btns, JSROOT.ToolbarIcons.three_circles, 15, "toggle status line")
                               .style("margin","3px").on("click", this.CreateStatusLine.bind(this, 'on', "toggle"));
      }

      this.SetDisplay(layout, this.gui_div + "_drawing");
   }

   JSROOT.HierarchyPainter.prototype.CreateStatusLine = function(height, mode) {
      if (!this.gui_div) return;

      var hpainter = this;
      JSROOT.AssertPrerequisites('jq2d', function() {
          hpainter.CreateStatusLine(height, mode);
      });
   }

   JSROOT.HierarchyPainter.prototype.CreateBrowser = function(browser_kind, update_html, call_back) {
      if (!this.gui_div) return;

      var hpainter = this;
      JSROOT.AssertPrerequisites('jq2d', function() {
          hpainter.CreateBrowser(browser_kind, update_html, call_back);
      });
   }

   JSROOT.BuildNobrowserGUI = function() {
      var myDiv = d3.select('#simpleGUI'),
          online = false, drawing = false;

      if (myDiv.empty()) {
         online = true;
         myDiv = d3.select('#onlineGUI');
         if (myDiv.empty()) { myDiv = d3.select('#drawGUI'); drawing = true; }
         if (myDiv.empty()) return alert('no div for simple nobrowser gui found');
      }

      if (myDiv.attr("ignoreurl") === "true")
         JSROOT.gStyle.IgnoreUrlOptions = true;

      JSROOT.Painter.readStyleFromURL();

      d3.select('html').style('height','100%');
      d3.select('body').style('min-height','100%').style('margin',0).style('overflow',"hidden");

      myDiv.style('position',"absolute").style('left',0).style('top',0).style('bottom',0).style('right',0).style('padding',1);


      if (drawing && ((JSROOT.GetUrlOption("webcanvas")!==null) || (JSROOT.GetUrlOption("longpollcanvas")!==null))) {

         console.log('Start web painter directly');

         var painter = new JSROOT.TPadPainter(null, true);

         painter.SetDivId(myDiv.attr("id"), -1); // just assign id, nothing else is happens

         painter.OpenWebsocket(JSROOT.GetUrlOption("longpollcanvas")!==null); // when connection activated, ROOT must send new instance of the canvas

         JSROOT.RegisterForResize(painter);

         return;
      }


      var hpainter = new JSROOT.HierarchyPainter('root', null);

      hpainter.is_online = online;
      if (drawing) hpainter.exclude_browser = true;

      hpainter.start_without_browser = true; // indicate that browser not required at the beginning

      hpainter.StartGUI(myDiv, function() {
         if (!drawing) return;

         var func = JSROOT.findFunction('GetCachedObject');
         var obj = (typeof func == 'function') ? JSROOT.JSONR_unref(func()) : null;
         if (obj) hpainter._cached_draw_object = obj;
         var opt = JSROOT.GetUrlOption("opt") || "";

         if (JSROOT.GetUrlOption("websocket")!==null) opt+=";websocket";

         hpainter.display("", opt);
      });
   }

   JSROOT.Painter.drawStreamerInfo = function(divid, lst) {
      var painter = new JSROOT.HierarchyPainter('sinfo', divid, 'white');

      painter.h = { _name : "StreamerInfo", _childs : [] };

      for ( var i = 0; i < lst.arr.length; ++i) {
         var entry = lst.arr[i]

         if (entry._typename == "TList") continue;

         if (typeof (entry.fName) == 'undefined') {
            JSROOT.console("strange element in StreamerInfo with type " + entry._typename);
            continue;
         }

         var item = {
            _name : entry.fName + ";" + entry.fClassVersion,
            _kind : "class " + entry.fName,
            _title : "class:" + entry.fName + ' version:' + entry.fClassVersion + ' checksum:' + entry.fCheckSum,
            _icon: "img_class",
            _childs : []
         };

         if (entry.fTitle != '') item._title += '  ' + entry.fTitle;

         painter.h._childs.push(item);

         if (typeof entry.fElements == 'undefined') continue;
         for ( var l = 0; l < entry.fElements.arr.length; ++l) {
            var elem = entry.fElements.arr[l];
            if (!elem || !elem.fName) continue;
            var info = elem.fTypeName + " " + elem.fName,
                title = elem.fTypeName + " type:" + elem.fType;
            if (elem.fArrayDim===1)
               info += "[" + elem.fArrayLength + "]";
            else
               for (var dim=0;dim<elem.fArrayDim;++dim)
                  info+="[" + elem.fMaxIndex[dim] + "]";
            if (elem.fBaseVersion===4294967295) info += ":-1"; else
            if (elem.fBaseVersion!==undefined) info += ":" + elem.fBaseVersion;
            info += ";";
            if (elem.fTitle != '') info += " // " + elem.fTitle;

            item._childs.push({ _name : info, _title: title, _kind: elem.fTypeName, _icon: (elem.fTypeName == 'BASE') ? "img_class" : "img_member" });
         }
         if (item._childs.length == 0) delete item._childs;
      }

      // painter.select_main().style('overflow','auto');

      painter.RefreshHtml(function() {
         painter.SetDivId(divid);
         painter.DrawingReady();
      });

      return painter;
   }

   JSROOT.Painter.drawInspector = function(divid, obj) {

      JSROOT.cleanup(divid);

      var painter = new JSROOT.HierarchyPainter('inspector', divid, 'white');
      painter.default_by_click = "expand"; // that painter tries to do by default
      painter.with_icons = false;
      painter.h = { _name: "Object", _title: "", _click_action: "expand", _nosimple: false, _do_context: true };
      if ((typeof obj.fTitle === 'string') && (obj.fTitle.length>0))
         painter.h._title = obj.fTitle;

      if (obj._typename)
         painter.h._title += "  type:" + obj._typename;

      if ((typeof obj.fName === 'string') && (obj.fName.length>0))
         painter.h._name = obj.fName;

      // painter.select_main().style('overflow','auto');

      painter.fill_context = function(menu, hitem) {
         var sett = JSROOT.getDrawSettings(hitem._kind, 'nosame');
         if (sett.opts)
            menu.addDrawMenu("nosub:Draw", sett.opts, function(arg) {
               if (!hitem || !hitem._obj) return;
               var obj = hitem._obj, divid = this.divid; // need to remember while many references will be removed (inluding _obj)
               JSROOT.cleanup(divid);
               JSROOT.draw(divid, obj, arg);
            });
      }

      if (JSROOT.IsRootCollection(obj)) {
         painter.h._name = obj.name || obj._typename;
         JSROOT.Painter.ListHierarchy(painter.h, obj);
      } else {
         JSROOT.Painter.ObjectHierarchy(painter.h, obj);
      }
      painter.RefreshHtml(function() {
         painter.SetDivId(divid);
         painter.DrawingReady();
      });

      return painter;
   }

   // ================================================================

   // JSROOT.MDIDisplay - class to manage multiple document interface for drawings

   JSROOT.MDIDisplay = function(frameid) {
      JSROOT.TBasePainter.call(this);
      this.frameid = frameid;
      this.SetDivId(frameid);
      this.select_main().property('mdi', this);
      this.CleanupFrame = JSROOT.cleanup; // use standard cleanup function by default
      this.active_frame_title = ""; // keep title of active frame
   }

   JSROOT.MDIDisplay.prototype = Object.create(JSROOT.TBasePainter.prototype);

   JSROOT.MDIDisplay.prototype.BeforeCreateFrame = function(title) {

      this.active_frame_title = title;
   }

   JSROOT.MDIDisplay.prototype.ForEachFrame = function(userfunc, only_visible) {
      // method dedicated to iterate over existing panels
      // provided userfunc is called with arguemnts (frame)

      console.warn("ForEachFrame not implemented in MDIDisplay");
   }

   JSROOT.MDIDisplay.prototype.ForEachPainter = function(userfunc, only_visible) {
      // method dedicated to iterate over existing panles
      // provided userfunc is called with arguemnts (painter, frame)

      this.ForEachFrame(function(frame) {
         var dummy = new JSROOT.TObjectPainter();
         dummy.SetDivId(frame, -1);
         dummy.ForEachPainter(function(painter) { userfunc(painter, frame); });
      }, only_visible);
   }

   JSROOT.MDIDisplay.prototype.NumDraw = function() {
      var cnt = 0;
      this.ForEachFrame(function() { ++cnt; });
      return cnt;
   }

   JSROOT.MDIDisplay.prototype.FindFrame = function(searchtitle, force) {
      var found_frame = null;

      this.ForEachFrame(function(frame) {
         if (d3.select(frame).attr('frame_title') == searchtitle)
            found_frame = frame;
      });

      if ((found_frame == null) && force)
         found_frame = this.CreateFrame(searchtitle);

      return found_frame;
   }

   JSROOT.MDIDisplay.prototype.ActivateFrame = function(frame) {
      this.active_frame_title = d3.select(frame).attr('frame_title');
   }

   JSROOT.MDIDisplay.prototype.GetActiveFrame = function() {
      return this.FindFrame(this.active_frame_title);
   }

   JSROOT.MDIDisplay.prototype.CheckMDIResize = function(only_frame_id, size) {
      // perform resize for each frame
      var resized_frame = null;

      this.ForEachPainter(function(painter, frame) {

         if (only_frame_id && (d3.select(frame).attr('id') != only_frame_id)) return;

         if ((painter.GetItemName()!==null) && (typeof painter.CheckResize == 'function')) {
            // do not call resize for many painters on the same frame
            if (resized_frame === frame) return;
            painter.CheckResize(size);
            resized_frame = frame;
         }
      });
   }

   JSROOT.MDIDisplay.prototype.Reset = function() {

      this.active_frame_title = "";

      this.ForEachFrame(this.CleanupFrame);

      this.select_main().html("").property('mdi', null);
   }

   JSROOT.MDIDisplay.prototype.Draw = function(title, obj, drawopt) {
      // draw object with specified options
      if (!obj) return;

      if (!JSROOT.canDraw(obj._typename, drawopt)) return;

      var frame = this.FindFrame(title, true);

      this.ActivateFrame(frame);

      return JSROOT.redraw(frame, obj, drawopt);
   }


   // ==================================================

   JSROOT.CustomDisplay = function() {
      JSROOT.MDIDisplay.call(this, "dummy");
      this.frames = {}; // array of configured frames
   }

   JSROOT.CustomDisplay.prototype = Object.create(JSROOT.MDIDisplay.prototype);

   JSROOT.CustomDisplay.prototype.AddFrame = function(divid, itemname) {
      if (!(divid in this.frames)) this.frames[divid] = "";

      this.frames[divid] += (itemname + ";");
   }

   JSROOT.CustomDisplay.prototype.ForEachFrame = function(userfunc,  only_visible) {
      var ks = Object.keys(this.frames);
      for (var k = 0; k < ks.length; ++k) {
         var node = d3.select("#"+ks[k]);
         if (!node.empty())
            JSROOT.CallBack(userfunc, node.node());
      }
   }

   JSROOT.CustomDisplay.prototype.CreateFrame = function(title) {

      this.BeforeCreateFrame(title);

      var ks = Object.keys(this.frames);
      for (var k = 0; k < ks.length; ++k) {
         var items = this.frames[ks[k]];
         if (items.indexOf(title+";")>=0)
            return d3.select("#"+ks[k]).node();
      }
      return null;
   }

   JSROOT.CustomDisplay.prototype.Reset = function() {
      JSROOT.MDIDisplay.prototype.Reset.call(this);
      this.ForEachFrame(function(frame) {
         d3.select(frame).html("");
      });
   }

   // ================================================

   JSROOT.GridDisplay = function(frameid, kind, kind2) {
      // following kinds are supported
      //  vertical or horizontal - only first letter matters, defines basic orientation
      //   'x' in the name disable interactive separators
      //   v4 or h4 - 4 equal elements in specified direction
      //   v231 -  created 3 vertical elements, first divided on 2, second on 3 and third on 1 part
      //   v23_52 - create two vertical elements with 2 and 3 subitems, size ratio 5:2
      //   gridNxM - normal grid layout without interactive separators
      //   gridiNxM - grid layout with interactive separators
      //   simple - no layout, full frame used for object drawings

      JSROOT.MDIDisplay.call(this, frameid);

      this.framecnt = 0;
      this.getcnt = 0;
      this.groups = [];
      this.vertical = kind && (kind[0] == 'v');
      this.use_separarators = !kind || (kind.indexOf("x")<0);
      this.simple_layout = false;

      this.select_main().style('overflow','hidden');

      if (kind === "simple") {
         this.simple_layout = true;
         this.use_separarators = false;
         this.framecnt = 1;
         return;
      }

      var num = 2, arr = undefined, sizes = undefined;

      if ((kind.indexOf("grid") == 0) || kind2) {
         if (kind2) kind = kind + "x" + kind2;
               else kind = kind.substr(4).trim();
         this.use_separarators = false;
         if (kind[0]==="i") {
            this.use_separarators = true;
            kind = kind.substr(1);
         }

         var separ = kind.indexOf("x"), sizex = 3, sizey = 3;

         if (separ > 0) {
            sizey = parseInt(kind.substr(separ + 1));
            sizex = parseInt(kind.substr(0, separ));
         } else {
            sizex = sizey = parseInt(kind);
         }

         if (isNaN(sizex)) sizex = 3;
         if (isNaN(sizey)) sizey = 3;

         if (sizey>1) {
            this.vertical = true;
            num = sizey;
            if (sizex>1) {
               arr = new Array(num);
               for (var k=0;k<num;++k) arr[k] = sizex;
            }
         } else
         if (sizex > 1) {
            this.vertical = false;
            num = sizex;
         } else {
            this.simple_layout = true;
            this.use_separarators = false;
            this.framecnt = 1;
            return;
         }
         kind = "";
      }

      if (kind && kind.indexOf("_")>0) {
         var arg = parseInt(kind.substr(kind.indexOf("_")+1), 10);
         if (!isNaN(arg) && (arg>10)) {
            kind = kind.substr(0, kind.indexOf("_"));
            sizes = [];
            while (arg>0) {
               sizes.unshift(Math.max(arg % 10, 1));
               arg = Math.round((arg-sizes[0])/10);
               if (sizes[0]===0) sizes[0]=1;
            }
         }
      }

      kind = kind ? parseInt(kind.replace( /^\D+/g, ''), 10) : 0;
      if (kind && (kind>1)) {
         if (kind<10) {
            num = kind;
         } else {
            arr = [];
            while (kind>0) {
               arr.unshift(kind % 10);
               kind = Math.round((kind-arr[0])/10);
               if (arr[0]==0) arr[0]=1;
            }
            num = arr.length;
         }
      }

      if (sizes && (sizes.length!==num)) sizes = undefined;

      if (!this.simple_layout)
         this.CreateGroup(this, this.select_main(), num, arr, sizes);
   }

   JSROOT.GridDisplay.prototype = Object.create(JSROOT.MDIDisplay.prototype);

   JSROOT.GridDisplay.prototype.CreateGroup = function(handle, main, num, childs, sizes) {
      if (!sizes) sizes = new Array(num);
      var sum1 = 0, sum2 = 0;
      for (var n=0;n<num;++n) sum1 += (sizes[n] || 1);
      for (var n=0;n<num;++n) {
         sizes[n] = Math.round(100 * (sizes[n] || 1) / sum1);
         sum2 += sizes[n];
         if (n==num-1) sizes[n] += (100-sum2); // make 100%
      }

      for (var cnt = 0; cnt<num; ++cnt) {
         var group = { id: cnt, drawid: -1, position: 0, size: sizes[cnt] };
         if (cnt>0) group.position = handle.groups[cnt-1].position + handle.groups[cnt-1].size;
         group.position0 = group.position;

         if (!childs || !childs[cnt] || childs[cnt]<2) group.drawid = this.framecnt++;

         handle.groups.push(group);

         var elem = main.append("div").attr('groupid', group.id);

         if (handle.vertical)
            elem.style('float', 'bottom').style('height',group.size+'%').style('width','100%');
         else
            elem.style('float', 'left').style('width',group.size+'%').style('height','100%');

         if (group.drawid>=0) {
            elem.classed('jsroot_newgrid', true);
            if (typeof this.frameid === 'string')
               elem.attr('id', this.frameid + "_" + group.drawid);
         } else {
            elem.style('display','flex').style('flex-direction', handle.vertical ? "row" : "column");
         }

         if (childs && (childs[cnt]>1)) {
            group.vertical = !handle.vertical;
            group.groups = [];
            elem.style('overflow','hidden');
            this.CreateGroup(group, elem, childs[cnt]);
         }
      }

      if (this.use_separarators && this.CreateSeparator)
         for (var cnt=1;cnt<num;++cnt)
            this.CreateSeparator(handle, main, handle.groups[cnt]);
   }

   JSROOT.GridDisplay.prototype.ForEachFrame = function(userfunc,  only_visible) {
      var main = this.select_main();

      if (this.simple_layout)
         userfunc(main.node());
      else
      main.selectAll('.jsroot_newgrid').each(function() {
         userfunc(d3.select(this).node());
      });
   }

   JSROOT.GridDisplay.prototype.GetActiveFrame = function() {
      if (this.simple_layout) return this.select_main().node();

      var found = JSROOT.MDIDisplay.prototype.GetActiveFrame.call(this);
      if (found) return found;

      this.ForEachFrame(function(frame) {
         if (!found) found = frame;
      }, true);

      return found;
   }

   JSROOT.GridDisplay.prototype.ActivateFrame = function(frame) {
      this.active_frame_title = d3.select(frame).attr('frame_title');
   }

   JSROOT.GridDisplay.prototype.GetFrame = function(id) {
      var main = this.select_main();
      if (this.simple_layout) return main.node();
      var res = null;
      main.selectAll('.jsroot_newgrid').each(function() {
         if (id-- === 0) res = this;
      });
      return res;
   }

   JSROOT.GridDisplay.prototype.NumGridFrames = function() {
      return this.framecnt;
   }

   JSROOT.GridDisplay.prototype.CreateFrame = function(title) {
      this.BeforeCreateFrame(title);

      var frame = this.GetFrame(this.getcnt);
      if (!this.simple_layout && this.framecnt)
         this.getcnt = (this.getcnt+1) % this.framecnt;

      d3.select(frame).attr('frame_title', title);

      JSROOT.cleanup(frame);

      return frame;
   }

   // =========================================================================

   JSROOT.RegisterForResize = function(handle, delay) {
      // function used to react on browser window resize event
      // While many resize events could come in short time,
      // resize will be handled with delay after last resize event
      // handle can be function or object with CheckResize function
      // one could specify delay after which resize event will be handled

      if (!handle) return;

      var myInterval = null, myDelay = delay ? delay : 300;

      if (myDelay < 20) myDelay = 20;

      function ResizeTimer() {
         myInterval = null;

         document.body.style.cursor = 'wait';
         if (typeof handle == 'function') handle(); else
         if ((typeof handle == 'object') && (typeof handle.CheckResize == 'function')) handle.CheckResize(); else
         if (typeof handle == 'string') {
            var node = d3.select('#'+handle);
            if (!node.empty()) {
               var mdi = node.property('mdi');
               if (mdi) {
                  mdi.CheckMDIResize();
               } else {
                  JSROOT.resize(node.node());
               }
            }
         }
         document.body.style.cursor = 'auto';
      }

      function ProcessResize() {
         if (myInterval !== null) clearTimeout(myInterval);
         myInterval = setTimeout(ResizeTimer, myDelay);
      }

      window.addEventListener('resize', ProcessResize);
   }

   JSROOT.addDrawFunc({ name: "TCanvas", icon: "img_canvas", func: JSROOT.Painter.drawCanvas, opt: ";grid;gridx;gridy;tick;tickx;ticky;log;logx;logy;logz", expand_item: "fPrimitives" });
   JSROOT.addDrawFunc({ name: "TPad", icon: "img_canvas", func: JSROOT.Painter.drawPad, opt: ";grid;gridx;gridy;tick;tickx;ticky;log;logx;logy;logz", expand_item: "fPrimitives" });
   JSROOT.addDrawFunc({ name: "TSlider", icon: "img_canvas", func: JSROOT.Painter.drawPad });
   JSROOT.addDrawFunc({ name: "TFrame", icon: "img_frame", func: JSROOT.Painter.drawFrame });
   JSROOT.addDrawFunc({ name: "TPaveText", icon: "img_pavetext", func: JSROOT.Painter.drawPaveText });
   JSROOT.addDrawFunc({ name: "TPaveStats", icon: "img_pavetext", func: JSROOT.Painter.drawPaveText });
   JSROOT.addDrawFunc({ name: "TPaveLabel", icon: "img_pavelabel", func: JSROOT.Painter.drawPaveText });
   JSROOT.addDrawFunc({ name: "TLatex", icon: "img_text", func: JSROOT.Painter.drawText });
   JSROOT.addDrawFunc({ name: "TMathText", icon: "img_text", func: JSROOT.Painter.drawText });
   JSROOT.addDrawFunc({ name: "TText", icon: "img_text", func: JSROOT.Painter.drawText });
   JSROOT.addDrawFunc({ name: /^TH1/, icon: "img_histo1d", func: JSROOT.Painter.drawHistogram1D, opt:";hist;P;P0;E;E1;E2;E3;E4;E1X0;L;LF2;B;B1;TEXT;LEGO;same", ctrl: "l" });
   JSROOT.addDrawFunc({ name: "TProfile", icon: "img_profile", func: JSROOT.Painter.drawHistogram1D, opt:";E0;E1;E2;p;hist"});
   JSROOT.addDrawFunc({ name: "TH2Poly", icon: "img_histo2d", prereq: "more2d", func: "JSROOT.Painter.drawHistogram2D", opt:";COL;COL0;COLZ;LCOL;LCOL0;LCOLZ;LEGO;same", expand_item: "fBins", theonly: true });
   JSROOT.addDrawFunc({ name: "TH2PolyBin", icon: "img_histo2d", draw_field: "fPoly" });
   JSROOT.addDrawFunc({ name: /^TH2/, icon: "img_histo2d", prereq: "more2d", func: "JSROOT.Painter.drawHistogram2D", opt:";COL;COLZ;COL0;COL1;COL0Z;COL1Z;BOX;BOX1;SCAT;TEXT;CONT;CONT1;CONT2;CONT3;CONT4;ARR;SURF;SURF1;SURF2;SURF4;SURF6;E;LEGO;LEGO0;LEGO1;LEGO2;LEGO3;LEGO4;same", ctrl: "colz" });
   JSROOT.addDrawFunc({ name: "TProfile2D", sameas: "TH2" });
   JSROOT.addDrawFunc({ name: /^TH3/, icon: 'img_histo3d', prereq: "3d", func: "JSROOT.Painter.drawHistogram3D", opt:";SCAT;BOX;BOX2;BOX3;GLBOX1;GLBOX2;GLCOL" });
   JSROOT.addDrawFunc({ name: "THStack", icon: "img_histo1d", prereq: "more2d", func: "JSROOT.Painter.drawHStack", expand_item: "fHists" });
   JSROOT.addDrawFunc({ name: "TPolyMarker3D", icon: 'img_histo3d', prereq: "3d", func: "JSROOT.Painter.drawPolyMarker3D" });
   JSROOT.addDrawFunc({ name: "TGraphPolargram" }); // just dummy entry to avoid drawing of this object
   JSROOT.addDrawFunc({ name: "TGraph2D", icon:"img_graph", prereq: "more2d;3d", func: "JSROOT.Painter.drawGraph2D", opt:";P;PCOL"});
   JSROOT.addDrawFunc({ name: "TGraph2DErrors", icon:"img_graph", prereq: "more2d;3d", func: "JSROOT.Painter.drawGraph2D", opt:";P;PCOL;ERR"});
   JSROOT.addDrawFunc({ name: /^TGraph/, icon:"img_graph", prereq: "more2d", func: "JSROOT.Painter.drawGraph", opt:";L;P"});
   JSROOT.addDrawFunc({ name: "TCutG", sameas: "TGraph" });
   JSROOT.addDrawFunc({ name: /^RooHist/, sameas: "TGraph" });
   JSROOT.addDrawFunc({ name: /^RooCurve/, sameas: "TGraph" });
   JSROOT.addDrawFunc({ name: "RooPlot", icon: "img_canvas", prereq: "more2d", func: "JSROOT.Painter.drawRooPlot" });
   JSROOT.addDrawFunc({ name: "TMultiGraph", icon: "img_mgraph", prereq: "more2d", func: "JSROOT.Painter.drawMultiGraph", expand_item: "fGraphs" });
   JSROOT.addDrawFunc({ name: "TStreamerInfoList", icon: 'img_question', func: JSROOT.Painter.drawStreamerInfo });
   JSROOT.addDrawFunc({ name: "TPaletteAxis", icon: "img_colz", prereq: "more2d", func: "JSROOT.Painter.drawPaletteAxis" });
   JSROOT.addDrawFunc({ name: "TWebPainting", icon: "img_graph", prereq: "more2d", func: "JSROOT.Painter.drawWebPainting" });
   JSROOT.addDrawFunc({ name: "kind:Text", icon: "img_text", func: JSROOT.Painter.drawRawText });
   JSROOT.addDrawFunc({ name: "TF1", icon: "img_tf1", prereq: "math;more2d", func: "JSROOT.Painter.drawFunction" });
   JSROOT.addDrawFunc({ name: "TF2", icon: "img_tf2", prereq: "math;more2d", func: "JSROOT.Painter.drawTF2" });
   JSROOT.addDrawFunc({ name: "TEllipse", icon: 'img_graph', prereq: "more2d", func: "JSROOT.Painter.drawEllipse" });
   JSROOT.addDrawFunc({ name: "TLine", icon: 'img_graph', prereq: "more2d", func: "JSROOT.Painter.drawLine" });
   JSROOT.addDrawFunc({ name: "TArrow", icon: 'img_graph', prereq: "more2d", func: "JSROOT.Painter.drawArrow" });
   JSROOT.addDrawFunc({ name: "TPolyLine", icon: 'img_graph', prereq: "more2d", func: "JSROOT.Painter.drawPolyLine" });
   JSROOT.addDrawFunc({ name: "TGaxis", icon: "img_graph", func: JSROOT.drawGaxis });
   JSROOT.addDrawFunc({ name: "TLegend", icon: "img_pavelabel", prereq: "more2d", func: "JSROOT.Painter.drawLegend" });
   JSROOT.addDrawFunc({ name: "TBox", icon: 'img_graph', prereq: "more2d", func: "JSROOT.Painter.drawBox" });
   JSROOT.addDrawFunc({ name: "TWbox", icon: 'img_graph', prereq: "more2d", func: "JSROOT.Painter.drawBox" });
   JSROOT.addDrawFunc({ name: "TSliderBox", icon: 'img_graph', prereq: "more2d", func: "JSROOT.Painter.drawBox" });
   JSROOT.addDrawFunc({ name: "TMarker", icon: 'img_graph', prereq: "more2d", func: "JSROOT.Painter.drawMarker" });
   JSROOT.addDrawFunc({ name: "TGeoVolume", icon: 'img_histo3d', prereq: "geom", func: "JSROOT.Painter.drawGeoObject", expand: "JSROOT.GEO.expandObject", opt:";more;all;count;projx;projz;dflt", ctrl: "dflt" });
   JSROOT.addDrawFunc({ name: "TEveGeoShapeExtract", icon: 'img_histo3d', prereq: "geom", func: "JSROOT.Painter.drawGeoObject", expand: "JSROOT.GEO.expandObject", opt: ";more;all;count;projx;projz;dflt", ctrl: "dflt"  });
   JSROOT.addDrawFunc({ name: "TGeoManager", icon: 'img_histo3d', prereq: "geom", expand: "JSROOT.GEO.expandObject", func: "JSROOT.Painter.drawGeoObject", opt: ";more;all;count;projx;projz;dflt", dflt: "expand", ctrl: "dflt" });
   JSROOT.addDrawFunc({ name: /^TGeo/, icon: 'img_histo3d', prereq: "geom", func: "JSROOT.Painter.drawGeoObject", opt: ";more;all;axis;compa;count;projx;projz;dflt", ctrl: "dflt" });
   // these are not draw functions, but provide extra info about correspondent classes
   JSROOT.addDrawFunc({ name: "kind:Command", icon: "img_execute", execute: true });
   JSROOT.addDrawFunc({ name: "TFolder", icon: "img_folder", icon2: "img_folderopen", noinspect: true, expand: JSROOT.Painter.FolderHierarchy });
   JSROOT.addDrawFunc({ name: "TTask", icon: "img_task", expand: JSROOT.Painter.TaskHierarchy, for_derived: true });
   JSROOT.addDrawFunc({ name: "TTree", icon: "img_tree", prereq: "tree", expand: 'JSROOT.Painter.TreeHierarchy', func: 'JSROOT.Painter.drawTree', dflt: "expand", opt: "player;testio", shift: "inspect" });
   JSROOT.addDrawFunc({ name: "TNtuple", icon: "img_tree", prereq: "tree", expand: 'JSROOT.Painter.TreeHierarchy', func: 'JSROOT.Painter.drawTree', dflt: "expand", opt: "player;testio", shift: "inspect" });
   JSROOT.addDrawFunc({ name: "TNtupleD", icon: "img_tree", prereq: "tree", expand: 'JSROOT.Painter.TreeHierarchy', func: 'JSROOT.Painter.drawTree', dflt: "expand", opt: "player;testio", shift: "inspect" });
   JSROOT.addDrawFunc({ name: "TBranchFunc", icon: "img_leaf_method", prereq: "tree", func: 'JSROOT.Painter.drawTree', opt: ";dump", noinspect: true });
   JSROOT.addDrawFunc({ name: /^TBranch/, icon: "img_branch", prereq: "tree", func: 'JSROOT.Painter.drawTree', dflt: "expand", opt: ";dump", ctrl: "dump", shift: "inspect", ignore_online: true });
   JSROOT.addDrawFunc({ name: /^TLeaf/, icon: "img_leaf", prereq: "tree", noexpand: true, func: 'JSROOT.Painter.drawTree', opt: ";dump", ctrl: "dump", ignore_online: true });
   JSROOT.addDrawFunc({ name: "TList", icon: "img_list", expand: JSROOT.Painter.ListHierarchy, dflt: "expand" });
   JSROOT.addDrawFunc({ name: "THashList", sameas: "TList" });
   JSROOT.addDrawFunc({ name: "TObjArray", sameas: "TList" });
   JSROOT.addDrawFunc({ name: "TClonesArray", sameas: "TList" });
   JSROOT.addDrawFunc({ name: "TMap", sameas: "TList" });
   JSROOT.addDrawFunc({ name: "TColor", icon: "img_color" });
   JSROOT.addDrawFunc({ name: "TFile", icon: "img_file", noinspect:true });
   JSROOT.addDrawFunc({ name: "TMemFile", icon: "img_file", noinspect:true });
   JSROOT.addDrawFunc({ name: "TStyle", icon: "img_question", noexpand:true });
   JSROOT.addDrawFunc({ name: "Session", icon: "img_globe" });
   JSROOT.addDrawFunc({ name: "kind:TopFolder", icon: "img_base" });
   JSROOT.addDrawFunc({ name: "kind:Folder", icon: "img_folder", icon2: "img_folderopen", noinspect:true });

   JSROOT.getDrawHandle = function(kind, selector) {
      // return draw handle for specified item kind
      // kind could be ROOT.TH1I for ROOT classes or just
      // kind string like "Command" or "Text"
      // selector can be used to search for draw handle with specified option (string)
      // or just sequence id

      if (typeof kind != 'string') return null;
      if (selector === "") selector = null;

      var first = null;

      if ((selector === null) && (kind in JSROOT.DrawFuncs.cache))
         return JSROOT.DrawFuncs.cache[kind];

      var search = (kind.indexOf("ROOT.")==0) ? kind.substr(5) : "kind:"+kind;

      var counter = 0;
      for (var i=0; i < JSROOT.DrawFuncs.lst.length; ++i) {
         var h = JSROOT.DrawFuncs.lst[i];
         if (typeof h.name == "string") {
            if (h.name != search) continue;
         } else {
            if (!search.match(h.name)) continue;
         }

         if (h.sameas !== undefined)
            return JSROOT.getDrawHandle("ROOT."+h.sameas, selector);

         if (selector==null) {
            // store found handle in cache, can reuse later
            if (!(kind in JSROOT.DrawFuncs.cache)) JSROOT.DrawFuncs.cache[kind] = h;
            return h;
         } else
         if (typeof selector == 'string') {
            if (!first) first = h;
            // if drawoption specified, check it present in the list

            if (selector == "::expand") {
               if (('expand' in h) || ('expand_item' in h)) return h;
            } else
            if ('opt' in h) {
               var opts = h.opt.split(';');
               for (var j=0; j < opts.length; ++j) opts[j] = opts[j].toLowerCase();
               if (opts.indexOf(selector.toLowerCase())>=0) return h;
            }
         } else {
            if (selector === counter) return h;
         }
         ++counter;
      }

      return first;
   }

   JSROOT.addStreamerInfos = function(lst) {
      if (lst === null) return;

      function CheckBaseClasses(si, lvl) {
         if (si.fElements == null) return null;
         if (lvl>10) return null; // protect against recursion

         for (var j=0; j<si.fElements.arr.length; ++j) {
            // extract streamer info for each class member
            var element = si.fElements.arr[j];
            if (element.fTypeName !== 'BASE') continue;

            var handle = JSROOT.getDrawHandle("ROOT." + element.fName);
            if (handle && !handle.for_derived) handle = null;

            // now try find that base class of base in the list
            if (handle === null)
               for (var k=0;k<lst.arr.length; ++k)
                  if (lst.arr[k].fName === element.fName) {
                     handle = CheckBaseClasses(lst.arr[k], lvl+1);
                     break;
                  }

            if (handle && handle.for_derived) return handle;
         }
         return null;
      }

      for (var n=0;n<lst.arr.length;++n) {
         var si = lst.arr[n];
         if (JSROOT.getDrawHandle("ROOT." + si.fName) !== null) continue;

         var handle = CheckBaseClasses(si, 0);

         if (!handle) continue;

         var newhandle = JSROOT.extend({}, handle);
         // delete newhandle.for_derived; // should we disable?
         newhandle.name = si.fName;
         JSROOT.DrawFuncs.lst.push(newhandle);
      }
   }

   JSROOT.getDrawSettings = function(kind, selector) {
      var res = { opts: null, inspect: false, expand: false, draw: false, handle: null };
      if (typeof kind != 'string') return res;
      var allopts = null, isany = false, noinspect = false, canexpand = false;
      if (typeof selector !== 'string') selector = "";

      for (var cnt=0;cnt<1000;++cnt) {
         var h = JSROOT.getDrawHandle(kind, cnt);
         if (!h) break;
         if (!res.handle) res.handle = h;
         if (h.noinspect) noinspect = true;
         if (h.expand || h.expand_item || h.can_expand) canexpand = true;
         if (!('func' in h)) break;
         isany = true;
         if (! ('opt' in h)) continue;
         var opts = h.opt.split(';');
         for (var i = 0; i < opts.length; ++i) {
            opts[i] = opts[i].toLowerCase();
            if ((selector.indexOf('nosame')>=0) && (opts[i].indexOf('same')==0)) continue;

            if (res.opts===null) res.opts = [];
            if (res.opts.indexOf(opts[i])<0) res.opts.push(opts[i]);
         }
         if (h.theonly) break;
      }

      if (selector.indexOf('noinspect')>=0) noinspect = true;

      if (isany && (res.opts===null)) res.opts = [""];

      // if no any handle found, let inspect ROOT-based objects
      if (!isany && (kind.indexOf("ROOT.")==0) && !noinspect) res.opts = [];

      if (!noinspect && res.opts)
         res.opts.push("inspect");

      res.inspect = !noinspect;
      res.expand = canexpand;
      res.draw = res.opts && (res.opts.length>0);

      return res;
   }

   // returns array with supported draw options for the specified class
   JSROOT.getDrawOptions = function(kind, selector) {
      return JSROOT.getDrawSettings(kind).opts;
   }

   JSROOT.canDraw = function(classname) {
      return JSROOT.getDrawSettings("ROOT." + classname).opts !== null;
   }

   /** @fn JSROOT.draw(divid, obj, opt, callback)
    * Draw object in specified HTML element with given draw options  */
   JSROOT.draw = function(divid, obj, opt, callback) {

      function completeDraw(painter) {
         if (painter && callback && (typeof painter.WhenReady == 'function'))
            painter.WhenReady(callback);
         else
            JSROOT.CallBack(callback, painter);
         return painter;
      }

      if ((obj===null) || (typeof obj !== 'object')) return completeDraw(null);

      if (opt == 'inspect')
         return completeDraw(JSROOT.Painter.drawInspector(divid, obj));

      var handle = null, painter = null;
      if ('_typename' in obj) handle = JSROOT.getDrawHandle("ROOT." + obj._typename, opt);
      else if ('_kind' in obj) handle = JSROOT.getDrawHandle(obj._kind, opt);

      if (!handle) return completeDraw(null);

      if (handle.draw_field && obj[handle.draw_field])
         return JSROOT.draw(divid, obj[handle.draw_field], opt, callback);

      if (!handle.func) return completeDraw(null);

      function performDraw() {
         if (!painter && ('painter_kind' in handle))
            painter = (handle.painter_kind == "base") ? new JSROOT.TBasePainter() : new JSROOT.TObjectPainter(obj);

         if (!painter)
            painter = handle.func(divid, obj, opt);
         else
            painter = handle.func.bind(painter)(divid, obj, opt, painter);

         return completeDraw(painter);
      }

      if (typeof handle.func == 'function') return performDraw();

      var funcname = "", prereq = "";
      if (typeof handle.func == 'object') {
         if ('func' in handle.func) funcname = handle.func.func;
         if ('script' in handle.func) prereq = "user:" + handle.func.script;
      } else
      if (typeof handle.func == 'string') {
         funcname = handle.func;
         if (('prereq' in handle) && (typeof handle.prereq == 'string')) prereq = handle.prereq;
         if (('script' in handle) && (typeof handle.script == 'string')) prereq += ";user:" + handle.script;
      }

      if (funcname.length === 0) return completeDraw(null);

      // special handling for painters, which should be loaded via extra scripts
      // such painter get extra last argument - pointer on dummy painter object
      if ((handle.painter_kind === undefined) && (prereq.length > 0))
         handle.painter_kind = (funcname.indexOf("JSROOT.Painter")==0) ? "object" : "base";

      // try to find function without prerequisisties
      var func = JSROOT.findFunction(funcname);
      if (func) {
          handle.func = func; // remember function once it is found
          return performDraw();
      }

      if (prereq.length === 0) return completeDraw(null);

      painter = (handle.painter_kind == "base") ? new JSROOT.TBasePainter() : new JSROOT.TObjectPainter(obj);

      JSROOT.AssertPrerequisites(prereq, function() {
         var func = JSROOT.findFunction(funcname);
         if (!func) {
            alert('Fail to find function ' + funcname + ' after loading ' + prereq);
            return completeDraw(null);
         }

         handle.func = func; // remember function once it found

         if (performDraw() !== painter)
            alert('Painter function ' + funcname + ' do not follow rules of dynamicaly loaded painters');
      });

      return painter;
   }

   /** @fn JSROOT.redraw(divid, obj, opt)
    * Redraw object in specified HTML element with given draw options
    * If drawing was not exists, it will be performed with JSROOT.draw.
    * If drawing was already done, that content will be updated */

   JSROOT.redraw = function(divid, obj, opt, callback) {
      if (!obj) return JSROOT.CallBack(callback, null);

      var dummy = new JSROOT.TObjectPainter();
      dummy.SetDivId(divid, -1);
      var can_painter = dummy.pad_painter();

      var handle = null;
      if (obj._typename) handle = JSROOT.getDrawHandle("ROOT." + obj._typename);
      if (handle && handle.draw_field && obj[handle.draw_field])
         obj = obj[handle.draw_field];

      if (can_painter) {
         if (obj._typename === "TCanvas") {
            can_painter.RedrawObject(obj);
            JSROOT.CallBack(callback, can_painter);
            return can_painter;
         }

         for (var i = 0; i < can_painter.painters.length; ++i) {
            var painter = can_painter.painters[i];
            if (painter.MatchObjectType(obj._typename))
               if (painter.UpdateObject(obj)) {
                  can_painter.RedrawPad();
                  JSROOT.CallBack(callback, painter);
                  return painter;
               }
         }
      }

      if (can_painter)
         JSROOT.console("Cannot find painter to update object of type " + obj._typename);

      JSROOT.cleanup(divid);

      return JSROOT.draw(divid, obj, opt, callback);
   }

   /** @fn JSROOT.MakeSVG(args, callback)
    * Create SVG for specified args.object and args.option
    * One could provide args.width and args.height as size options.
    * As callback arguemnt one gets SVG code */
   JSROOT.MakeSVG = function(args, callback) {

      if (!args) args = {};

      if (!args.object) return JSROOT.CallBack(callback, null);

      if (!args.width) args.width = 1200;
      if (!args.height) args.height = 800;

      function build(main) {

         main.attr("width", args.width).attr("height", args.height);

         main.style("width", args.width+"px").style("height", args.height+"px");

         JSROOT.svg_workaround = undefined;

         JSROOT.draw(main.node(), args.object, args.option || "", function(painter) {

            main.select('svg').attr("xmlns", "http://www.w3.org/2000/svg")
                              .attr("width", args.width)
                              .attr("height", args.height)
                              .attr("style", "").attr("style", null)
                              .attr("class", null).attr("x", null).attr("y", null);

            var svg = main.html();

            if (JSROOT.svg_workaround) {
               for (var k=0;k<JSROOT.svg_workaround.length;++k)
                 svg = svg.replace('<path jsroot_svg_workaround="' + k + '"></path>', JSROOT.svg_workaround[k]);
               JSROOT.svg_workaround = undefined;
            }

            svg = svg.replace(/url\(\&quot\;\#(\w+)\&quot\;\)/g,"url(#$1)");

            main.remove();

            JSROOT.CallBack(callback, svg);
         });
      }

      if (!JSROOT.nodejs) {
         build(d3.select(window.document).append("div").style("visible", "hidden"));
      } else
      if (JSROOT.nodejs_document) {
         build(JSROOT.nodejs_window.d3.select('body').append('div'));
      } else {
         var jsdom = require('jsdom');
         jsdom.env({
            html:'',
            features:{ QuerySelector:true }, //you need query selector for D3 to work
            done:function(errors, window) {

               window.d3 = d3.select(window.document); //get d3 into the dom
               JSROOT.nodejs_window = window;
               JSROOT.nodejs_document = window.document; // used with three.js

               build(window.d3.select('body').append('div'));
            }});
      }
   }

   // Check resize of drawn element
   // As first argument divid one should use same argment as for the drawing
   // As second argument, one could specify "true" value to force redrawing of
   // the element even after minimal resize of the element
   // Or one just supply object with exact sizes like { width:300, height:200, force:true };

   JSROOT.resize = function(divid, arg) {
      if (arg === true) arg = { force: true }; else
      if (typeof arg !== 'object') arg = null;
      var dummy = new JSROOT.TObjectPainter(), done = false;
      dummy.SetDivId(divid, -1);
      dummy.ForEachPainter(function(painter) {
         if (!done && typeof painter.CheckResize == 'function')
            done = painter.CheckResize(arg);
      });
      return done;
   }

   // for compatibility, keep old name
   JSROOT.CheckElementResize = JSROOT.resize;

   // safely remove all JSROOT objects from specified element
   JSROOT.cleanup = function(divid) {
      var dummy = new JSROOT.TObjectPainter(), lst = [];
      dummy.SetDivId(divid, -1);
      dummy.ForEachPainter(function(painter) {
         if (lst.indexOf(painter) < 0) lst.push(painter);
      });
      for (var n=0;n<lst.length;++n) lst[n].Cleanup();
      dummy.select_main().html("");
      return lst;
   }

   // function to display progress message in the left bottom corner
   // previous message will be overwritten
   // if no argument specified, any shown messages will be removed
   JSROOT.progress = function(msg, tmout) {
      if (JSROOT.BatchMode || !document) return;
      var id = "jsroot_progressbox",
          box = d3.select("#"+id);

      if (!JSROOT.gStyle.ProgressBox) return box.remove();

      if ((arguments.length == 0) || !msg) {
         if ((tmout !== -1) || (!box.empty() && box.property("with_timeout"))) box.remove();
         return;
      }

      if (box.empty()) {
         box = d3.select(document.body)
                .append("div")
                .attr("id", id);
         box.append("p");
      }

      box.property("with_timeout", false);

      if (typeof msg === "string") {
         box.select("p").html(msg);
      } else {
         box.html("");
         box.node().appendChild(msg);
      }

      if (!isNaN(tmout) && (tmout>0)) {
         box.property("with_timeout", true);
         setTimeout(JSROOT.progress.bind(JSROOT,'',-1), tmout);
      }
   }

   JSROOT.Painter.createRootColors();

   return JSROOT;

}));
