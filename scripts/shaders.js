(function( root, factory ) {
	if( typeof define === 'function' && define.amd ) {
		// AMD. Register as an anonymous module.
		define( function() {
			root.Shaders = factory();
			return root.Shaders;
		} );
	} else if( typeof exports === 'object' ) {
		// Node. Does not work with strict CommonJS.
		module.exports = factory();
	} else {
		// Browser globals.
		root.Shaders = factory();
	}
}( this, function() {

    var _Shaders;
    var _baseUrl = '../';

    /* Global dictionary containing the include files buffers
    * We asynchronously load the file included in the main fragment and vertex
    * shaders and store them inside this dictionnary to finally replace the
    * strings into the shaders.
    */
    var _mainTimeOut  = 300;
    var _pendingLoads = new Set();
    var _everyLoads   = new Set();
    var _inlineDict   = new Map();
    var _inlineRegEx  = /^[ \t]*#include [\"\<](.+)[\"\>]/mg;

    function init (baseUrl = '../') {
        _baseUrl = baseUrl;
        _pendingLoads = new Set();
        _everyLoads   = new Set();
        _inlineDict   = new Map();
    }

    /* Load the content of a file using Require.JS.
    * This function should be used inside RegEx calls such as 'replace'
    */
    function loadTextFileFromMatch (match, filename) {
        // Do not attempt to load an already queried filename
        if(_everyLoads.has(match)) {
            return;
        }

        // Append the current filename to the list of queried
        // files. Async resolve will remove this file from the
        // list.
        _pendingLoads.add(match);
        _everyLoads.add(match);
        return jQuery.get(_baseUrl + filename, function(file) {
            _inlineDict[match] = file;
            _pendingLoads.delete(match);
        });
    }

    /* Search for every included file in a buffer and append its content
    * to the global include dictionnary '_inlineDict'. The include pattern
    * must match `#include <filename>` or `#include "filename"`. There
    * should be no space before the '#' character.
    */
    function searchIncludes (buffer) {
        var re = _inlineRegEx;
        var result;
        var deferreds = [];
        while((result = re.exec(buffer)) != null) {
            var deferred = loadTextFileFromMatch(result[0], result[1]);
            deferreds.push(deferred);
        }
        
        return $.when.apply(null, deferreds);
    }

    /* Inline every included file found in the global include dictionnary
    * into text buffer `buffer` and return it. Note that the system doesn't
    * catch when a file is included multiple times.
    */
   function processIncludes (buffer) {
        var re = _inlineRegEx;
        var result;
        while((result = re.exec(buffer)) != null) {
            prefix = '\n#line 1\n';
            buffer = buffer.replace(result[0], prefix+_inlineDict[result[0]]);
        }
        return buffer;
    }

    /* Include shader headers in `src_txt` using library in the search
     * path. This method is asynchronous. Once the shader is parsed and
     * all the includes inlined, it is passed to function `func`.
     */
    function generateShaderFromTxt (src_txt, func) {

        // Temporary list of currently loading files. One all the files are loaded
        // with the proper includes, process them and init the webGL context.
        var _set = new Set();
    
        // Fill the global dictionnary with all includes
        var deferred = searchIncludes(src_txt);
    
        // Load the WebGL code and create the context, geometry and shaders
        deferred.done(function() {
            out_txt = processIncludes(src_txt);
            func(out_txt);
        }).fail(function() {
            console.log('Missing GLSL header files:');
            _pendingLoads.forEach(element => {
                console.log(element);
            });
        });
    }

    // /* Use Require.JS to load a progressive renderer that uses the same vertex
    // * shader but does two passes of different fragment shaders. The result
    // * of the main fragment shader 'prog_src' will be stored into a texture
    // * and binded for the viewing fragment shader 'frag_src'.
    // */
    // function requireProgressiveWebGL(canvas, vert_src, frag_src, prog_src) {

    // // Temporary list of currently loading files. One all the files are loaded
    // // with the proper includes, process them and init the webGL context.
    // var _set = new Set();
    // _set.add(vert_src);
    // _set.add(frag_src);
    // _set.add(prog_src);

    // var vertDeferred = jQuery.get(_baseUrl + vert_src);
    // var fragDeferred = jQuery.get    (_baseUrl + frag_src);
    // var progDeferred = jQuery.get(_baseUrl + prog_src);

    // // Resolve the async text files query together
    // $.when(vertDeferred, fragDeferred, progDeferred)
    //     .done(function(vert, frag, prog) {

    //         var vertex   = vert[0];
    //         var fragment = frag[0];
    //         var progress = prog[0];

    //         // Fill the global dictionnary with all includes
    //         searchIncludes(vertex);
    //         searchIncludes(fragment);
    //         searchIncludes(progress);

    //         // Load the WebGL code and create the context, geometry and shaders
    //         setTimeout(function() {
    //             if(_pendingLoads.size > 0) {
    //             alert('Missing GLSL header files!');
    //             return;
    //             }

    //             vertex   = processIncludes(vertex);
    //             fragment = processIncludes(fragment);
    //             progress = processIncludes(progress);
    //             initWebGLProgressive(canvas, vertex, progress, fragment);
    //         }, _mainTimeOut);
    //     })
    //     .fail(function() {
    //         alert('Unable to load vertex and fragment shaders');
    //     });
    // }

    // /* Create a single draw pass that consist of a vertex shader and a fragment
    // * shader.
    // */
    // function requireClassicalWebGL(canvas, vert_src, frag_src) {

    // // Temporary list of currently loading files. One all the files are loaded
    // // with the proper includes, process them and init the webGL context.
    // var _set = new Set();
    // _set.add(vert_src);
    // _set.add(frag_src);

    // var vertDeferred = jQuery.get(_baseUrl + vert_src);
    // var fragDeferred = jQuery.get(_baseUrl + frag_src);

    // // Resolve the async text files query together
    // $.when(vertDeferred, fragDeferred)
    //     .done(function(vert, frag) {

    //         var vertex   = vert[0];
    //         var fragment = frag[0];

    //         // Fill the global dictionnary with all includes
    //         searchIncludes(vertex);
    //         searchIncludes(fragment);

    //         // Load the WebGL code and create the context, geometry and shaders
    //         setTimeout(function() {
    //             if(_pendingLoads.size > 0) {
    //             alert('Missing GLSL header files!');
    //             return;
    //             }

    //             vertex   = processIncludes(vertex);
    //             fragment = processIncludes(fragment);
    //             initWebGL(canvas, vertex, fragment);
    //         }, _mainTimeOut);
    //     })
    //     .fail(function() {
    //         alert('Unable to load vertex and fragment shaders');
    //     });
    // }

    // function createOpenGLCanvas(canvas) {
    //     // Query the vertex shader filename if available
    //     var vert_src = 'shaders/defaults/vertex.shader';
    //     if(canvas.hasAttribute('vertex')) {
    //         frag_src = canvas.getAttribute('vertex');
    //     }

    //     // Query the fragment shader filename if available
    //     if(canvas.hasAttribute('fragment')) {
    //         var frag_src = canvas.getAttribute('fragment');
    //         requireClassicalWebGL(canvas, vert_src, frag_src);
    //     } else if(canvas.hasAttribute('viewer')) {
    //         var frag_src = canvas.getAttribute('viewer');
    //         var prog_src = canvas.getAttribute('progressive');
    //         requireProgressiveWebGL(canvas, vert_src, frag_src, prog_src);
    //     } else {
    //         var frag_src = 'shaders/defaults/fragment.shader';
    //         requireClassicalWebGL(canvas, vert_src, frag_src);
    //     }
    // }

    // /* Load the shaders for every `.glcanvas` element in the DOM
    //  */
    // $(document).ready(function() {

    //    // Load the associated javascript files `webgl.js` and `utils.js`
    //    // here. And create OpenGL canvas for every .glcanvas element in
    //    // the DOM.
    //    //
    //    // {TODO: Maybe we should compress them into a single JS file}
    //    jQuery.getScript(_baseUrl + 'scripts/webgl.js')
    //       .done(function() {
    //          // Obtain the shader source files
    //          var query = $('.glcanvas');
    //          for(var k=0; k<query.length; ++k) {
    //             var canvas  = query[k];
    //             if(canvas == null) {
    //                alert('Unable to load canvas: ' + canvas);
    //                continue;
    //             }

    //             createOpenGLCanvas(canvas);
    //          }
    //       })
    //       .fail(function() {
    //          alert('ERROR: Unable to load webgl.js, check the baseURL');
    //       });
    // });

    /* Export the public interface of Shaders
     */
    _Shaders = {
        init : init,
        generateShaderFromTxt: generateShaderFromTxt
    };

    return _Shaders;
}));