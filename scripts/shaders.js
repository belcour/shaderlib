requirejs.config({
    baseUrl: '../scripts',
    paths: {
        shaders: '../shaders'
    }
});

/* Global dictionary containing the include files buffers
 * We asynchronously load the file included in the main fragment and vertex
 * shaders and store them inside this dictionnary to finally replace the
 * strings into the shaders.
 */
var _mainTimeOut = 300;
var _pendingLoads = new Set();
var _inlineDict = {};
var _inlineRegEx = /^#include [\"\<](.+)[\"\>]/mg;

/* Load the content of a file using Require.JS.
 * This function should be used inside RegEx calls such as 'replace'
 */
function loadTextFileFromMatch(match, filename) {
    //var result = '\n// Not included "' + filename + '"';
    _pendingLoads.add(match);
    require(['text!' + filename], function(file) {
        _inlineDict[match] = file;
        _pendingLoads.delete(match);
    });
}

/* Search for every included file in a buffer and append its content
 * to the global include dictionnary '_inlineDict'. The include pattern
 * must match `#include <filename>` or `#include "filename"`. There
 * should be no space before the '#' character.
 */
function searchIncludes(buffer) {
    var re = _inlineRegEx;
    var result;
    while((result = re.exec(buffer)) != null) {
        loadTextFileFromMatch(result[0], result[1]);
    }
}

/* Inline every included file found in the global include dictionnary
 * into text buffer `buffer` and return it. Note that the system doesn't
 * catch when a file is included multiple times.
 */
function processIncludes(buffer) {
    var re = _inlineRegEx;
    var result;
    while((result = re.exec(buffer)) != null) {
        prefix = '\n#line 1\n';
        buffer = buffer.replace(result[0], prefix+_inlineDict[result[0]]);
    }
    return buffer;
}

/* Use Require.JS to load a progressive renderer that uses the same vertex
 * shader but does two passes of different fragment shaders. The result
 * of the main fragment shader 'prog_src' will be stored into a texture
 * and binded for the viewing fragment shader 'frag_src'.
 */
function requireProgressiveWebGL(canvas, vert_src, frag_src, prog_src) {
    // Use the function defined in webgl to load the fragment and vertex shaders
    require(['text!' + vert_src, 'text!' + frag_src, 'text!' + prog_src],
        function(vertex, fragment, prog) {
            // Check if file loads
            if(vertex == undefined || fragment == undefined  || prog == undefined) {
                alert('Could not find one of the shaders');
            }

            // Fill the global dictionnary with all includes
            searchIncludes(vertex);
            searchIncludes(fragment);
            searchIncludes(prog);

            // Load the WebGL code and create the context, geometry and shaders
            setTimeout(function() {            
                require(['webgl'],
                    function(webgl) {
                        if(_pendingLoads.size > 0) { 
                            alert('Missing GLSL header files!');
                            return;                        
                        }

                        vertex   = processIncludes(vertex);
                        fragment = processIncludes(fragment);
                        prog = processIncludes(prog);
                        initWebGLProgressive(canvas, vertex, prog, fragment);
                    }
                );
            }, _mainTimeOut);            
        }
    );
}

/* Create a single draw pass that consist of a vertex shader and a fragment 
 * shader.
 */
function requireClassicalWebGL(canvas, vert_src, frag_src) {
    // Use the function defined in webgl to load the fragment and vertex shaders
    require(['text!' + vert_src, 'text!' + frag_src],
        function(vertex, fragment) {
            // Check if file loads
            if(vertex == undefined || fragment == undefined) {
                alert('Could not find one of the shaders');
            }

            // Fill the global dictionnary with all includes
            searchIncludes(vertex);
            searchIncludes(fragment);

            // Load the WebGL code and create the context, geometry and shaders
            setTimeout(function() {
                require(['webgl'],
                    function(webgl) {
                        if(_pendingLoads.size > 0) { 
                            alert('Missing GLSL header files!');
                            return;
                        }

                        vertex   = processIncludes(vertex);
                        fragment = processIncludes(fragment);
                        initWebGL(canvas, vertex, fragment);
                    }
                );
            }, _mainTimeOut);
        }
    );
}

function createOpenGLCanvas(canvas) {
    // Query the vertex shader filename if available
    var vert_src = 'shaders/defaults/vertex.shader';
    if(canvas.hasAttribute('vertex')) {
        frag_src = canvas.getAttribute('vertex');
    }

    // Query the fragment shader filename if available
    if(canvas.hasAttribute('fragment')) {
        var frag_src = canvas.getAttribute('fragment');
        requireClassicalWebGL(canvas, vert_src, frag_src);
    } else if(canvas.hasAttribute('viewer')) {
        var frag_src = canvas.getAttribute('viewer');
        var prog_src = canvas.getAttribute('progressive');
        requireProgressiveWebGL(canvas, vert_src, frag_src, prog_src);
    } else {
        var frag_src = 'shaders/defaults/fragment.shader';
        requireClassicalWebGL(canvas, vert_src, frag_src);
    }
}

/* Load the shaders using Require.JS.
 * {TODO: Add multiple webgl context in a page}
 */
$(document).ready(function() {

    // Load Require.JS plugin to handle text files
    require(['text'], function(text) {
        // Obtain the shader source files
        var query = $('.glcanvas');
        for(var k=0; k<query.length; ++k) {
            var canvas  = query[k];
            if(canvas == null) {
                alert('Unable to load canvas: ' + canvas);
                continue;
            }

            createOpenGLCanvas(canvas);
        }
    });
});
