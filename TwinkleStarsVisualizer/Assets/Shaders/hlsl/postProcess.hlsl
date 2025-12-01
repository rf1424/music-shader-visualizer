float sampleHatchingPattern(float2 uv, float scale)
{
    float line1 = sin((uv.x + uv.y) * scale);
    float line2 = sin((uv.x - uv.y) * scale);
    return max(line1, line2);
}

// lum
float brightness(float3 color)
{
    return dot(color, float3(0.2126, 0.7152, 0.0722));
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

