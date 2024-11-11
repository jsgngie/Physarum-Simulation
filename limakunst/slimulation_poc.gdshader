shader_type canvas_item;

uniform vec2 actor_coordinates[25000]; // the length of the array here specifies the maximum amount of actors
uniform int number_of_actors; // this specifies the actual number of actors

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	bool is_colored = false;

    // Iterate over the array to check for matching coordinates
    for (int i = 0; i < number_of_actors; i++) {
        if (distance(UV, actor_coordinates[i]) < 0.001) { // Adjust threshold as needed
            is_colored = true; // Mark the pixel to be colored
            break; // Exit the loop early since we found a match
        }
    }

    // Set the color based on whether a match was found
    if (is_colored) {
        COLOR = vec4(1.0, 0.0, 0.0, 1.0); // Color the pixel red if it matches
    } else {
        COLOR = vec4(1.0, 1.0, 1.0, 1.0); // Default color (white)
    }
}
