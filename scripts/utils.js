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
    _canvas.setAttribute("width", "512");
    _canvas.setAttribute("height", "512");
    _canvas.setAttribute("viewer", "shaders/defaults/viewer.shader");
    _canvas.setAttribute("progressive", "shaders/examples/qmc-sequence.shader");
    _canvas.style.position = "absolute";
    _canvas.style.width  = "512px";
    _canvas.style.height = "512px";
    document.body.appendChild(_canvas);
}

function replaceElement(name, scale=1.0) {
    var viewport = $("#_webglViewport");
    var element  = $("#" + name);
    var offset   = element.position();
    viewport.insertAfter(element);
    viewport[0].style["visibility"] = "visible";
    viewport[0].style["top"]  = (offset.top  / scale) + "px";
    viewport[0].style["left"] = (offset.left / scale) + "px";
    viewport[0].style["width"]  = (element[0].style["width"]);// + "px";
    viewport[0].style["height"] = (element[0].style["height"]);// + "px";
}