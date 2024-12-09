shader_type canvas_item;
uniform sampler2D screenTex : hint_screen_texture;
uniform vec3 darkColor : source_color;
uniform vec3 lightColor : source_color;
uniform sampler2D dataTex;
uniform float dissapation = 0.01;


void fragment() {
	vec2 uv = UV;
	vec3 col = vec3(texture(dataTex, uv).r);
	vec3 oldCol = vec3(texture(screenTex, uv).r);
	vec3 avg = vec3(0.0);

		for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			avg += texture(screenTex, uv + vec2(0.001*float(i), 0.001*float(j))).rgb;
		}
	}
	
	
	oldCol = avg / 9.0;
	
	col = max(col, oldCol);
	
	col = mix(col, vec3(0.0), dissapation);
	
	COLOR.rgb = col;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
