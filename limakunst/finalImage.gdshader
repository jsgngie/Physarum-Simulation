shader_type canvas_item;
uniform vec3 darkColor : source_color;
uniform vec3 lightColor : source_color;
uniform float maxBrightness = 0.75;

void fragment() {
	vec3 col = texture(TEXTURE, SCREEN_UV).rgb;
	col = vec3(col.r / maxBrightness);
	col = mix(darkColor, lightColor, col.r);
	COLOR.rgb = col;
}
//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
