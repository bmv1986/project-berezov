shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.6;
uniform float grain_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float aberration_strength : hint_range(0.0, 0.05) = 0.015; // Максимальная сила по краям
uniform float flicker_intensity : hint_range(0.0, 0.3) = 0.05;
uniform float sepia_amount : hint_range(0.0, 1.0) = 0.3;
uniform float fade_blacks : hint_range(0.0, 0.5) = 0.1;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = SCREEN_UV;

    // 1. Хроматическая аберрация с радиальным градиентом
    vec2 to_center = uv - 0.5;             // Вектор от центра к пикселю
    float dist = length(to_center);        // Расстояние до центра (0 в центре, ~0.7 в углах)
    vec2 dir = normalize(to_center + 0.0001); // Направление от центра (с защитой от деления на 0)

    // Сила аберрации растёт с расстоянием от центра
    float current_aberration = aberration_strength * dist;

    // Смещаем UV радиально (от центра к краям)
    float r = texture(SCREEN_TEXTURE, uv + dir * current_aberration).r;
    float g = texture(SCREEN_TEXTURE, uv).g;
    float b = texture(SCREEN_TEXTURE, uv - dir * current_aberration).b;
    vec3 col = vec3(r, g, b);

    // 2. Виньетирование
    vec2 center = uv - 0.5;
    float vignette_dist = dot(center, center);
    float vignette = 1.0 - vignette_dist * vignette_intensity;
    col *= vignette;

    // 3. Зерно пленки
    float grain = random(uv * TIME * 50.0) * grain_intensity;
    col += grain - (grain_intensity * 0.5);

    // 4. Мерцание экспозиции
    float flicker = 1.0 + (random(vec2(TIME * 15.0, 0.0)) - 0.5) * flicker_intensity;
    col *= flicker;

    // 5. Выцветание
    col = mix(col, vec3(0.4, 0.38, 0.35), fade_blacks);

    // 6. Сепия
    vec3 sepia = vec3(
        dot(col, vec3(0.393, 0.769, 0.189)),
        dot(col, vec3(0.349, 0.686, 0.168)),
        dot(col, vec3(0.272, 0.534, 0.131))
    );
    col = mix(col, sepia, sepia_amount);

    COLOR = vec4(col, 1.0);
}