/* {TODO Add a global uniform variables dictionnary}
 * {TODO Add local uniform variables into the canvas}
 */


/* Load WebGL Module */
function initWebGL(canvas, vert_txt, frag_txt) {
    if(!vert_txt || !frag_txt) {
        canvas.innerHTML = 'No fragment or vertex shader loaded';
        console.log(vert_txt);
        console.log(frag_txt);
        return;
    }

    var gl = canvas.getContext("webgl2", {antialias: true});
    if(!gl) {
        return;
    }

    var program = loadShaders(gl, vert_txt, frag_txt);
    if(! program) {
        console.log('ERROR: Unable to create a program.');
        return;
    }


    var geomId = createQuad(gl);

    linkUniformToHtml(canvas, gl, program);

    gl.clear(gl.COLOR_BUFFER_BIT);

    canvas.gl = gl;
    canvas.program = program;
    canvas.geomId = geomId;

    // Register different callbacks such as mousemove if present
    if(canvas.hasAttribute('callback')) {
        var callback = new Function('canvas', canvas.getAttribute('callback') + '(canvas)' )
        callback(canvas);
    }

    var drawCalls = function(canvas) {
        canvas.gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
        drawGeometry(canvas.gl, canvas.program, canvas.geomId); 
    };

    setInterval(drawCalls, 1, canvas);
}

/* Load WebGL Module using a progressive renderer
 *
 *   + 'vert_txt' is the vertex shader sources.
 *   + 'prog_txt' and 'view_txt' are fragment shader sources.
 * 
 */
function initWebGLProgressive(canvas, vert_txt, prog_txt, view_txt) {
    if(!vert_txt || !prog_txt || !view_txt) {
        canvas.innerHTML = 'No fragment or vertex shader loaded';
        console.log(vert_txt);
        console.log(prog_txt);
        console.log(view_txt);
        return;
    }

    var gl = canvas.getContext("webgl2", {antialias: true});
    if(!gl) {
        return;
    }
    gl.getExtension('OES_texture_float');
    gl.getExtension('EXT_color_buffer_float');

    // Create programs
    var prg_prog = loadShaders(gl, vert_txt, prog_txt);
    var prg_view = loadShaders(gl, vert_txt, view_txt);
    if(! prg_prog || ! prg_view) {
        console.log('ERROR: Unable to create a program.');
    }

    // Create framebuffers & texture
    var tex_prog = gl.createTexture();
    var dataf = new Float32Array(512*512*4);
    
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, tex_prog);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA32F, 512, 512, 0, gl.RGBA, gl.FLOAT, dataf);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);

    var fb_prog = gl.createFramebuffer();
    gl.bindFramebuffer(gl.FRAMEBUFFER, fb_prog);
    fb_prog.width  = 512;
    fb_prog.height = 512;
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, tex_prog, 0);
    var enut = gl.checkFramebufferStatus(gl.FRAMEBUFFER);
    
    // Add special constant uniform to the viewing program
    gl.useProgram(prg_view);
    var uniform_tex = gl.getUniformLocation(prg_view, 'u_FramebufferSampler');
    gl.uniform1i(uniform_tex, 0);

    // Create geometry
    var geomId = createQuad(gl);

    // Bind all uniforms
    linkUniformToHtml(canvas, gl, prg_prog);
    linkUniformToHtml(canvas, gl, prg_view);

    // Store all the WebGL ids in the canvas object
    canvas.gl = gl;
    canvas.programs = [prg_prog, prg_view];
    canvas.framebuffers = [fb_prog];
    canvas.geomId = geomId;
    canvas.passId = 0;

    // Register different callbacks such as mousemove if present
    if(canvas.hasAttribute('callback')) {
        var callback = new Function('canvas', canvas.getAttribute('callback') + '(canvas)' )
        callback(canvas);
    }

    // Create a rendering loop that calls both the progressive renderer
    // and the viewing loop.
    var drawCalls = function(canvas) {
        // Increment the pass number
        canvas.passId = canvas.passId+1;

        // Accumulate samples into the progressive framebuffer
        //gl.viewport(0, 0, 512, 512);
        gl.useProgram(canvas.programs[0]);
        if(canvas.passId > 1) {
            gl.enable(gl.BLEND);
            gl.blendFunc(gl.ONE, gl.ONE);
        }
        
        // Update the pass number in the shader
        var uniform_num = gl.getUniformLocation(canvas.programs[0], 'u_PassNumber');
        gl.uniform1i(uniform_num, canvas.passId);

        // Progressive renderer
        canvas.gl.bindFramebuffer(gl.FRAMEBUFFER, canvas.framebuffers[0]);
        if(canvas.passId == 1) gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);        
        drawGeometry(canvas.gl, canvas.programs[0], canvas.geomId);


        // Draw the normalized values
        gl.useProgram(canvas.programs[1]);
        gl.disable(gl.BLEND);

        // Update the pass number in the shader
        var uniform_num = gl.getUniformLocation(canvas.programs[1], 'u_PassNumber');
        gl.uniform1i(uniform_num, canvas.passId);

        gl.disable(gl.BLEND);
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
        drawGeometry(canvas.gl, canvas.programs[1], canvas.geomId);
    };
    setInterval(drawCalls, 1, canvas);
}

/* Bind uniform HTML elements (using the 'uniform' class) to the WebGL
 * program 'program'. Also set an event listener to dynamically change the
 * value of the uniform variable.
 */
function setUniformK (elem, gl, program) {
    gl.useProgram(program);
    var uniform_id = gl.getUniformLocation(program, elem.id);
    if(elem.nodeName == 'SELECT') {
        gl.uniform1i(uniform_id, elem.selectedIndex);
    } else {
        gl.uniform1f(uniform_id, elem.value);
    }            
}

function linkUniformToHtml(canvas, gl, program) {
    gl.useProgram(program);
    var query = $('.uniform');
    for(var k=0; k<query.length; ++k) {
        // Get the element
        var elem    = query[k];

        // Set the current value of the uniform location
        setUniformK(elem, gl, program);

        // Add an event handler when changing the value
        elem.addEventListener('input', function() {
            // Reset pass number
            canvas.passId = 0;
            setUniformK(this, gl, program);
        });
    }
}

/* Display the error in the HTML page by replacing the canvas element
 * by a div with some text in it.
 */
function displayError(canvas, error) {
        var text = '';
        text += '<div style="';
        text += 'width:' + canvas.width + 'px;';
        text += 'height:' + canvas.height + 'px;';
        text += canvas.style;
        text += '">';
        text += error;
        text += '</div>';
        canvas.outerHTML = text;
}

/* Generate a webgl (or webgl2) context on canvas 'canvas' and return it.
 * We specify here the clear color and the depth tests.
 */
function getContext(canvas, ctx_type) {
    var gl = canvas.getContext(ctx_type)
    if(gl) {
        gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.enable(gl.DEPTH_TEST);
        gl.depthFunc(gl.LEQUAL);
        gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);
    } else {
        displayError(canvas, 'Unable to load WebGL 2.0');
    }

    return gl;
}

function createShader(gl, source, type) {
    var shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        console.log(source);
        displayError(gl.canvas, 'WebGL Compilation issue: ' + gl.getShaderInfoLog(shader));
        return null;
    }

    return shader;
}

function loadShaders(gl, vert_txt, frag_txt) {
    // Create shaders
    var vert = createShader(gl, vert_txt, gl.VERTEX_SHADER);
    var frag = createShader(gl, frag_txt, gl.FRAGMENT_SHADER);
    if(!vert) {
        displayError(gl.canvas, 'Unable to create the vertex shader:\n' + vert_txt);
        return null;
    }
    if(!frag) {
        displayError(gl.canvas, 'Unable to create the fragment shader:\n' + frag_txt);
        return null;
    }

    // Create program
    var program = gl.createProgram();
    gl.attachShader(program, vert);
    gl.attachShader(program, frag);
    gl.linkProgram(program);

    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
        displayError(gl.canvas, 'ERROR: Unable to link program');
        return null;
    }

    gl.useProgram(program);

    // Set vertex position attribute {TODO change place?}
    vpAttribute = gl.getAttribLocation(program, "aVertexPosition");
    gl.enableVertexAttribArray(vpAttribute);

    return program;
}

function createQuad(gl) {
    var buff_id = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buff_id);

    var vertices = [
         1.0,  1.0, 0.0,
        -1.0,  1.0, 0.0,
         1.0, -1.0, 0.0,
        -1.0, -1.0, 0.0
    ];

    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
    return buff_id;
}


var client_sh = Math.sin(0.0 * Math.PI);
var client_ch = Math.sqrt(1.0 - client_sh*client_sh);

function drawGeometry(gl, program, geomId) {
    var wi = gl.getUniformLocation(program, 'wi');
    var sh = client_sh;
    var ch = client_ch;
    gl.uniform3f(wi, sh,0,ch);

    gl.bindBuffer(gl.ARRAY_BUFFER, geomId);
    gl.vertexAttribPointer(vpAttribute, 3, gl.FLOAT, false, 0, 0);
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
}


/* Update the light position with mouse position 
 */
function getMousePositionInCanvas(canvas, event) {
    var rect = canvas.getBoundingClientRect();
    return {
        x: 2.0*((event.clientX - rect.left) / event.target.width)  - 1.0,
        y: 2.0*((event.clientY - rect.top)  / event.target.height) - 1.0
    };
}

function setLightDirection(canvas) {
    canvas.addEventListener('mousemove', function(e) {
        if(e.buttons == 1 || e.button == 1) {
            // Reset pass number
            canvas.passId = 0;
            var clientXY = getMousePositionInCanvas(canvas, e);
            client_sh = (clientXY.x);
            client_ch = Math.sqrt(1.0 - client_sh*client_sh);
        }
    });

    canvas.addEventListener('mousedown', function(e) {
        if(e.buttons == 1 || e.button == 1) {
            // Reset pass number
            canvas.passId = 0;
            var clientXY = getMousePositionInCanvas(canvas, e);
            client_sh = (clientXY.x);
            client_ch = Math.sqrt(1.0 - client_sh*client_sh);
        }
    });
}
