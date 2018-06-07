/* Placement and creation of WebGL canvas
 * Those function are defined to ease the integration of webgl elements inside
 * RevealJS. We create a global WebGL canvas and move it when they are needed
 * from a slide to the next.
 */
var _canvas = null;
var _canvasName = "_webglViewport";

function createCanvas() {
    _canvas = document.createElement("canvas");
    _canvas.setAttribute("class", "glcanvas");
    _canvas.setAttribute("id", _canvasName);
    _canvas.setAttribute("width", "1024");
    _canvas.setAttribute("height", "1024");
    _canvas.setAttribute("viewer", "shaders/defaults/viewer.shader");
    _canvas.setAttribute("progressive", "shaders/examples/qmc-sequence.shader");
    _canvas.style.position = "absolute";
    _canvas.style.width  = "512px";
    _canvas.style.height = "512px";
    document.body.appendChild(_canvas);
}

function replaceElement(element, scale=1.0) {
    var viewport = $("#_webglViewport");
    // var element  = $("#" + name);
    if(element == undefined) {
       alert('Unable to find element ' + name);
       return;
    }

    var offset   = element.position();
    if(offset == undefined) {
       offset.top  = 0;
       offset.left = 0;
    }

    viewport.insertAfter(element);
    viewport[0].style["visibility"] = "visible";
    viewport[0].style["top"]  = (offset.top  / scale) + "px";
    viewport[0].style["left"] = (offset.left / scale) + "px";

    if(element[0].style["width"] != undefined)
       viewport[0].style["width"]  = (element[0].style["width"]);// + "px";
    if(element[0].style["height"] != undefined)
      viewport[0].style["height"] = (element[0].style["height"]);// + "px";
}

function ProjectiveSpace(snap, NB_ELEMS = 6, COLOR = "#AAF", SIZE = 256, POS_X=SIZE, POS_Y=SIZE, FONTSIZE='0.4em') {
    var g = snap.g();
    var dtheta = 0.5*Math.PI/NB_ELEMS;
    for(theta=dtheta; theta<0.5*Math.PI-dtheta; theta+=dtheta) {
        var degree = 180.0 * theta / Math.PI;

        var radius = SIZE * Math.sin(theta);
        var c = snap.circle(POS_X, POS_Y, radius).attr({fillOpacity: 0, stroke: COLOR, strokeWidth: 2, opacity: 0.2});
        var t = snap.text(POS_X/*-18*/, POS_Y-radius+8, Math.round(degree) + '°').attr({fill: COLOR, fontSize: FONTSIZE, textAnchor: 'middle'});
        g.add(c);
        g.add(t);

        for(phi=theta; phi<theta+dtheta; phi+= dtheta/3) {
            var radius = SIZE * Math.sin(phi);
            var c = snap.circle(POS_X, POS_Y, radius).attr({fillOpacity: 0, stroke: COLOR, strokeWidth: 1, opacity: 0.1});
            g.add(c);
        }
    }
    return g;
}