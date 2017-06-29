#define PIVOT_SHADER

#ifndef COMMON_SHADER
  #error Missing common.shader include in pivot header
#endif


///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                        Transformation functions                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

/* Pivot operator
 *
 *  + x: sample on the sphere
 *  + xi: pivot
 */
vec3 PivotProject(in vec3 x, in vec3 xi) {
	vec3 tmp = x - xi;
	vec3 cp1 = cross(x, xi);
	vec3 cp2 = cross(tmp, cp1);
	float dp = dot(x, xi) - 1.0;
	float qf = dp * dp + dot(cp1, cp1);

	return ((dp * tmp - cp2) / qf);
}


// transform spherical cap
// x: spherical cap main direction
// theta: spherical cap angle
// xi: pivot
void PivotProjectCap(in vec3 x, in float theta, in vec3 xi,
                     out vec3 x_, out float theta_) {

	vec3 yi = xi - x*dot(xi, x);
	if(length(yi) > 1.0E-8) {
		yi = normalize(yi);
	} else {
		vec3 tmp;
		FrameFrisvad(x, yi, tmp);
	}
	float sin_theta = sin(theta);
	float cos_theta = cos(theta);
	vec3 p1 = cos_theta*x + sin_theta*yi;
	vec3 p2 = cos_theta*x - sin_theta*yi;
	vec3 p1_ = PivotProject(p1, xi);
	vec3 p2_ = PivotProject(p2, xi);
	x_ = normalize(p1_+p2_);
	theta_ = acos(clamp(dot(p1_, x_), -1.0, 1.0));

	// inside or outside?
	if( dot(PivotProject(x, xi), x_) < cos(theta_) )
	{
		x_ = -x_;
		theta_ = PI-theta_;
	}
}