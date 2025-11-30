
float2 random2(float2 p)
{
    return frac(sin(float2(
        dot(p, float2(127.1, 311.7)),
        dot(p, float2(183.3, 246.1))
    )) * 43758.5453);
}

float voronoi(float2 uv, float gridSize, out float2 closestPt)
{
    float2 st = uv * gridSize;

    float2 i = floor(st);
    float2 f = frac(st);

    float minDist = 1000000.0;
    closestPt = i;

    [unroll]
    for (int x = -1; x <= 1; x++)
    {
        [unroll]
        for (int y = -1; y <= 1; y++)
        {
            float2 offset = float2((float) x, (float) y);
            float2 randomPt = random2(i + offset);

            float currDist = length(f - (randomPt + offset));
            if (currDist < minDist)
            {
                minDist = currDist;
                closestPt = i + offset + randomPt;

            }
            
        }
    }

    return minDist;
}

// Gradient Noise 2D by IQ
float gradientNoise(float2 st)
{
    float2 i = floor(st);
    float2 f = frac(st);

    float2 u = f * f * (3.0 - 2.0 * f);

    float n00 = dot(random2(i + float2(0.0, 0.0)), f - float2(0.0, 0.0));
    float n10 = dot(random2(i + float2(1.0, 0.0)), f - float2(1.0, 0.0));
    float n01 = dot(random2(i + float2(0.0, 1.0)), f - float2(0.0, 1.0));
    float n11 = dot(random2(i + float2(1.0, 1.0)), f - float2(1.0, 1.0));

    float nx0 = lerp(n00, n10, u.x);
    float nx1 = lerp(n01, n11, u.x);

    return lerp(nx0, nx1, u.y);
}

float2 uvOffset(float2 uv)
{
    float2 closestPt;
    float v = voronoi(uv, 10. + TIME * 10., closestPt) * 0.5 + 0.5;
    float v2 = frac(v * 34.);
    // return uv += float2(v, v2) *  _fracBeat * 0.1;
    
    //float odd = (_intBeat & 1) == 1 ? _fracBeat : 1. - _fracBeat;
    //return uv += .1 * float2(v, v2) * odd;
    return uv += .1 * float2(v, v2) * _fracBeat;
}

float3 voronoiFilter(float2 uv, float3 col)
{
    float2 closestPt;
    float voronoiMask = voronoi(uv, 1000. + _fracBeat, closestPt);
    
    voronoiMask = pow(voronoiMask, 3.);
    
    return col *= 1. - voronoiMask;

}

float starRand(float2 uv, float freq)
{
    float2 uvRepeat = uv * 0.5 + 0.5;
    float2 repeatID = floor(uvRepeat * freq);
    uvRepeat = frac(uvRepeat * freq) * 2. - 1.;
               
    uv = uvRepeat;

               // star outline
    float d = 0.;
    float seed = random(repeatID.x * freq * freq + repeatID.y * freq + floor(TIME * 6.));
    if (seed < 0.2)
    {
        d = sdRoundedCross(uv / 0.5, 1.0);
        d = abs(d) - 0.01;
        d = 1. - smoothstep(0.0, 0.01, d / freq);
        d *= smoothstep(1., 0.95, length(uv));
    }
    return d;
}

float starChecker(float2 uv, float freq)
{
    float2 uvRepeat = uv * 0.5 + 0.5;
    float2 repeatID = floor(uvRepeat * freq);
    uvRepeat = frac(uvRepeat * freq) * 2. - 1.;
               
    uv = uvRepeat;

               // star outline
    float d = 0.;
               
    if (abs(repeatID.x + repeatID.y) % 2 > 0)
    {
        d = sdRoundedCross(uv, 1.0);
        d = abs(d) - 0.01;
        d = 1. - smoothstep(0.0, 0.01, d / freq);
        d *= smoothstep(1., 0.95, length(uv));
    }
    return d;
}

