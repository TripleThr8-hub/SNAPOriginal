shader_type canvas_item;

uniform float glow_strength : hint_range(0.0, 3.0) = 1.5;
uniform float glow_size : hint_range(0.0, 10.0) = 3.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    
    vec2 texel = glow_size / vec2(textureSize(TEXTURE, 0));
    
    vec4 glow = vec4(0.0);
    glow += texture(TEXTURE, UV + vec2(-texel.x, 0.0));
    glow += texture(TEXTURE, UV + vec2(texel.x, 0.0));
    glow += texture(TEXTURE, UV + vec2(0.0, -texel.y));
    glow += texture(TEXTURE, UV + vec2(0.0, texel.y));
    glow += texture(TEXTURE, UV + vec2(-texel.x, -texel.y));
    glow += texture(TEXTURE, UV + vec2(texel.x, -texel.y));
    glow += texture(TEXTURE, UV + vec2(-texel.x, texel.y));
    glow += texture(TEXTURE, UV + vec2(texel.x, texel.y));
    glow /= 8.0;
    
    color.rgb += glow.rgb * glow.a * glow_strength;
    
    COLOR = color;
}