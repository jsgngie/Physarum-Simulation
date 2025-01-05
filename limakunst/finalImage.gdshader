shader_type canvas_item;

uniform vec3 firstColor : source_color;
uniform vec3 secondColor : source_color;
uniform vec3 thirdColor : source_color;

uniform float maxBrightness = 0.75;
uniform int clear = 0;
void fragment() {
	vec4 col = texture(TEXTURE, SCREEN_UV).rgba;
	col = vec4(col / maxBrightness);
	
	vec3 redMapped = firstColor * col.r;
	vec3 greenMapped = secondColor * col.g;
	vec3 blueMapped = thirdColor * col.b;
	
	vec3 finalColor = redMapped + greenMapped + blueMapped;
	
	if (clear == 1) {
		COLOR.rgba = vec4(vec3(0.0, 0.0, 0.0), 1.0);
	} else {
		COLOR.rgba = vec4(finalColor, col.a);
	}
}
//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}