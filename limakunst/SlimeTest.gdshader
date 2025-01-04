shader_type canvas_item;
uniform sampler2D screenTex : hint_screen_texture;
uniform vec3 darkColor : source_color;
uniform vec3 lightColor : source_color;
uniform sampler2D dataTex;
uniform float dissapation = 0.01;
uniform float maxBrightness = 0.75;


void fragment() {
	vec2 uv = UV;
	vec3 col = vec3(texture(dataTex, uv).rgb);
	vec3 oldCol = vec3(texture(screenTex, uv).rgb);
	vec3 avg = vec3(0.0);

		for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			
			vec3 temp = vec3(0.0);
			temp += texture(screenTex, uv + vec2(0.001*float(i), 0.001*float(j))).rgb;
			temp += texture(dataTex, uv + vec2(0.001*float(i), 0.001*float(j))).rgb;
			avg += temp / maxBrightness;
		}
	}
	
	
	avg = avg / 9.0;
	col = max(avg, oldCol);
	
	col = mix(col, vec3(0.0), dissapation);
	//col = max(col - dissapation, 0.0);
	COLOR.rgb = col;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
