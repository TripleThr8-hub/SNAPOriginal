shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float dot_size : hint_range(2.0, 20.0) = 12.0;
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.25;

void fragment() {
    vec4 color = texture(screen_texture, SCREEN_UV);
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));

    if (SCREEN_UV.y < 0.4) {
        COLOR = color;
    }

    if (lum < shadow_threshold) {
        vec2 cell_uv = mod(FRAGCOORD.xy, dot_size) / dot_size;
        float dist = distance(cell_uv, vec2(0.5));
        float radius = (1.0 - lum) * 0.45;

        if (dist > radius) {
            color.rgb *= 1.04;
        }
    }

    COLOR = color;
}