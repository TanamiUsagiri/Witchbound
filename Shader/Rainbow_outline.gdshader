shader_type canvas_item;

uniform bool rainbow = true; // bật rainbow hay dùng màu cố định
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float line_scale : hint_range(0.0, 5.0) = 1.0;
uniform float frequency : hint_range(0.0, 2.0) = 0.5;
uniform float light_offset : hint_range(0.0, 1.0) = 0.5;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 pixel = TEXTURE_PIXEL_SIZE * line_scale;

	float outline = 0.0;
	outline += texture(TEXTURE, UV + vec2(-pixel.x, 0.0)).a;
	outline += texture(TEXTURE, UV + vec2(pixel.x, 0.0)).a;
	outline += texture(TEXTURE, UV + vec2(0.0, -pixel.y)).a;
	outline += texture(TEXTURE, UV + vec2(0.0, pixel.y)).a;
	outline += texture(TEXTURE, UV + pixel).a;
	outline += texture(TEXTURE, UV - pixel).a;
	outline += texture(TEXTURE, UV + vec2(pixel.x, -pixel.y)).a;
	outline += texture(TEXTURE, UV + vec2(-pixel.x, pixel.y)).a;

	outline = clamp(outline, 0.0, 1.0);

	vec4 base_color = texture(TEXTURE, UV);

	vec4 rainbow_color = vec4(
		light_offset + sin(TIME * TAU * frequency),
		light_offset + sin(TIME * TAU * frequency + TAU / 3.0),
		light_offset + sin(TIME * TAU * frequency + 2.0 * TAU / 3.0),
		alpha
	);

	vec4 final_outline_color = rainbow ? rainbow_color : line_color;

	COLOR = mix(base_color, final_outline_color, outline * (1.0 - base_color.a));
}
