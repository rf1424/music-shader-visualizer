// b.x = half width
// b.y = half height
// roundness
float sdRoundedBox(in float2 p, in float2 b, in float re)
{
    float4 r = float4(re, re, re, re);
    r.xy = (p.x > 0.0) ? r.xy : r.zw;
    r.x = (p.y > 0.0) ? r.x : r.y;
    float2 q = abs(p) - b + r.x;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

float sdfPentagram(float2 p, float r)
{
    const float k1x = (sqrt(5.0) + 1.0) / 4.0; // 0.809016994 = cos(pi/5)
    const float k2x = (sqrt(5.0) - 1.0) / 4.0; // 0.309016994 = sin(pi/10)
    const float k1y = (sqrt(10.0 - 2.0 * sqrt(5.0))) / 4.0; // 0.587785252 = sin(pi/5)
    const float k2y = (sqrt(10.0 + 2.0 * sqrt(5.0))) / 4.0; // 0.951056516 = cos(pi/10)
    const float k1z = (sqrt(5.0 - 2.0 * sqrt(5.0))); // 0.726542528 = tan(pi/5)
                
    const float2 v1 = float2(k1x, -k1y);
    const float2 v2 = float2(-k1x, -k1y);
    const float2 v3 = float2(k2x, -k2y);
            
                // repeat domain 5x
    p.x = abs(p.x);
    p -= 2.0 * max(dot(v1, p), 0.0) * v1;
    p -= 2.0 * max(dot(v2, p), 0.0) * v2;
    p.x = abs(p.x);
            
                // draw edge
    p.y -= r;
    float d = length(p - v3 * clamp(dot(p, v3), 0.0, k1z * r)); // distance
    float s = sign(p.y * v3.x - p.x * v3.y); // sign
    return d * s;
}