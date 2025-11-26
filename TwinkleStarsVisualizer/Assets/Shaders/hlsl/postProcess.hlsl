
float2 random2(float2 p)
{
    return frac(sin(float2(
        dot(p, float2(127.1, 311.7)),
        dot(p, float2(183.3, 246.1))
    )) * 43758.5453);
}

float voronoi(float2 uv, float gridSize)
{
    float2 st = uv * gridSize;

    float2 i = floor(st);
    float2 f = frac(st);

    float minDist = 1000000.0;

    [unroll]
    for (int x = -1; x <= 1; x++)
    {
        [unroll]
        for (int y = -1; y <= 1; y++)
        {
            float2 offset = float2((float) x, (float) y);
            float2 randomPt = random2(i + offset);

            float currDist = length(f - (randomPt + offset));
            minDist = min(minDist, currDist);
        }
    }

    return minDist;
}

float2 uvOffset(float2 uv)
{
    float v = voronoi(uv, 10. + TIME * 10.) * 0.5 + 0.5;
    float v2 = frac(v * 34.);
    // return uv += float2(v, v2) *  _fracBeat * 0.1;
    
    //float odd = (_intBeat & 1) == 1 ? _fracBeat : 1. - _fracBeat;
    //return uv += .1 * float2(v, v2) * odd;
    return uv += .1 * float2(v, v2) * _fracBeat;
}

float3 voronoiFilter(float2 uv, float3 col)
{
    float voronoiMask = voronoi(uv, 1000. + _fracBeat);
    
    voronoiMask = pow(voronoiMask, 3.);
    
    return col *= 1. - voronoiMask;

}

