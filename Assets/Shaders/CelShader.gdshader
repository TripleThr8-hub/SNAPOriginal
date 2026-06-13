shader_type spatial;
render_mode diffuse_lambert;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_nearest;
uniform int light_bands : hint_range(2, 6) = 2;

void fragment() {
    vec4 tex = texture(texture_albedo, UV) * albedo;
    ALBEDO = tex.rgb;
}

void light() {
    float NdotL = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
    float banded = floor(NdotL * float(light_bands) + 0.5) / float(light_bands);
    DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * banded;
}