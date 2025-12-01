// Put this hlsl file before others (#defines)

#define ASPECT (_ScreenParams.x / _ScreenParams.y)
#define TIME _time
#define STIME sin(_time)
#define CTIME cos(_time)
#define PTIME sin(_time) * 0.5 + 0.5
#define LINTIME abs(frac(_time) * 2. - 1.)

// materials
#define YELLOW 0
#define RED 1
#define BROWN 2
#define YELLOW1 3
#define YELLOW2 4
#define YELLOW3 5
#define BLUE 6


#define CMUL(u, v) float2((u).x*(v).x - (u).y*(v).y, (u).x*(v).y + (u).y*(v).x)
#define CDIV(u, v) (CMUL((u), float2((v).x, -(v).y)) / dot((v), (v)))
#define PI 3.14159265


// transformations
float2 rotate2d(float2 p, float a)
{
    float s = sin(a), c = cos(a);
    return float2(c * p.x - s * p.y, s * p.x + c * p.y);
}

float smoothUnion(float d1, float d2, float k)
{
    float h = saturate(0.5 + 0.5 * (d2 - d1) / k);
    return lerp(d2, d1, h) - k * h * (1.0 - h);
}

float subtract(float d1, float d2)
{
    return max(- d1, d2);
}

float smoothSubtract(float d1, float d2, float k)
{
    float h = saturate(0.5 - 0.5 * (d2 + d1) / k);
    return lerp(d2, -d1, h) + k * h * (1.0 - h);
}



// -1 to 1 repeater
float remapRepeat(float x, float freq)
{
    x = x * 0.5 + 0.5; //0 to 1
    x = frac(x * freq); // (0...1) * freq
    return x * 2. - 1.; // (-1...1) * freq
                
}
            
float2 scroll(float2 uv, float2 speedXY)
{
    uv += speedXY;
    uv.x = frac((uv.x + ASPECT) / (2.0 * ASPECT)) * (2.0 * ASPECT) - ASPECT;
    uv.y = frac((uv.y + 1.0) / 2.0) * 2.0 - 1.0;
    return uv;
}

float2 mobius(float2 uv)
{
    float2 a = float2(0.9, 0.9);
    float2 b = float2(0.0, 0.0);
    float2 c = float2(sin(TIME), 0.0);
    float2 d = float2(0.0, 0.5);
    float2 w = uv;
            
    float2 num = CMUL(d, w) - b;
    float2 den = -CMUL(c, w) + a;
            
    return CDIV(num, den);
}

float3 hsv2rgb(float3 c)
{
    float4 K = float4(1., 2. / 3., 1. / 3., 3.);
    float3 p = abs(frac(c.xxx + K.xyz) * 6. - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

float3 rgb2hsv(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = (c.g < c.b) ? float4(c.bg, K.wz) : float4(c.gb, K.xy);
    float4 q = (c.r < p.x) ? float4(p.xyw, c.r) : float4(c.r, p.yzx);

    float d = q.x - min(q.w, q.y);
    float e = 1e-10;

    float h = abs(q.w - q.y) / (6.0 * d + e);
    float s = d / (q.x + e);
    float v = q.x;

    return float3(h, s, v);
}

float3 posterize(float3 col, float steps)
{
    return floor(col * steps) / steps;
}

float random(float s)
{
    return frac(sin(s * 123.49) *
                43758.5453123);
}

float3 random3(float s)
{
    return frac(sin(s * float3(127.1, 311.7, 74.7)) * 43758.5453123);
}

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

// Noise functions by IQ ----------------------------------------------------
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

float hash2D(int2 p)
{
    // 3D -> 1D collapse
    int n = p.x * 3 + p.y * 113;

    // Hugo Elias 1D hash
    n = (n << 13) ^ n;
    n = n * (n * n * 15731 + 789221) + 1376312589;

    // convert to 0..1 float
    return float(n & 0x0fffffff) / float(0x0fffffff);
}

float valueNoise2D(float2 x)
{
    int2 i = int2(floor(x));
    float2 f = frac(x);

    // Hermite smoothstep: f = f*f*(3-2*f)
    f = f * f * (3.0 - 2.0 * f);

    float a = lerp(hash2D(i + int2(0, 0)),
                   hash2D(i + int2(1, 0)), f.x);

    float b = lerp(hash2D(i + int2(0, 1)),
                   hash2D(i + int2(1, 1)), f.x);

    return lerp(a, b, f.y);
}




float fbm(float2 p, int iter)
{
    // PARAMETERS
    int iterCount = iter;
    float ampDecreaseFactor = 0.5;
    float freqIncreaseFactor = 2.0;
    float amp = 0.5;

    // base values
    float fbmSum = 0.0;
    float2 seed = p;

    [loop] 
    for (int i = 0; i < iterCount; i++)
    {
        float g = valueNoise2D(seed);
        fbmSum += g * amp;

        amp *= ampDecreaseFactor;
        seed *= freqIncreaseFactor;
    }

    return fbmSum;
}
// ------------------------------------------------------

// KOF Fractals
float2 getAngleNormal(float a)
{
    return float2(sin(a), cos(a));
                // visualize (pass uv)
                //float reflLine = dot(nor1, uv);
                //col.b += smoothstep(0.02, 0., abs(reflLine));
}

// this one is more correct
float2 getAngleNor(float a)
{
    return float2(- sin(a), cos(a));
}

float2 kofFractal(float2 uv, int numLoops, out float scale)
{
    // zoom out, move up
    uv *= 2.;
    uv.y -= 1.5 / sqrt(3);

    // triangle folding
    uv.x = abs(uv.x);
    float2 nor1 = getAngleNor(radians(30.));// getAngleNormal(radians(150.)); // getAngleNormal(PI * 5. / 6.);
    uv = uv - nor1 * min(0., dot(nor1, uv - float2(1.5, 0.))) * 2.;

    // arb line reflection params
    float2 nor = getAngleNor(radians(240.));

    // folding
    scale = 1.;
    for (int i = 0; i < numLoops; i++)
    {
        // #0 put back into operation space
        if (i > 0)
        {
            uv *= 3.;
            uv.x -= 1.5;
        }
        scale *= 3.;

        // #1 half reflection    
        uv.x = abs(uv.x);
        uv.x -= 0.5;
        // angle reflection
        uv = uv - nor * min(0., dot(uv, nor)) * 2.; // BENDER, dot is the distance proj
        // uv = uv - nor * d * 2. * STIME; // maybe cool
    }
    // uv /= scale;
    return uv;
}

// 5 star fractal
            // use 1-3 numloops and scale back uv for texture
float2 kofFractal2(float2 uv, int numLoops, out float scale)
{
    // zoom out, move up
    uv *= 2.;
    uv.y -= 0.5;
            
    // triangle folding
    uv.x = abs(uv.x);
    float baseRad = 0.3;
    float2 nor1 = getAngleNormal(PI * 7. / 10.);
    uv = uv - nor1 * max(0., dot(nor1, uv - float2(baseRad, 0.))) * 2.;

    nor1 = getAngleNormal(radians(234.));
    uv = uv - nor1 * max(0., dot(nor1, uv + float2(baseRad, 0.))) * 2.;
            
    // arb line reflection params
    float2 nor = getAngleNormal(2. / 3. * PI);
            
    // folding
    scale = 1.;
    for (int i = 0; i < numLoops; i++)
    {
        // #0 put back into operation space
        if (i > 0)
        {
            uv *= 3.;
            uv.x -= 1.5;
        }
        scale *= 3.;
            
        // #1 half reflection    
        uv.x = abs(uv.x);
        //  uv.x -= 1.;
        // angle reflection
        float motion = (STIME * 0.5 + 0.5) * 0.5; // += 0-0.5, just time, etc., -0.5 t0 0.5
        nor = getAngleNormal((-4. - motion) / 5. * PI); // 3. 5. 
        uv = uv - nor * min(0., dot(uv - float2(baseRad, 0.), nor)) * 2.; // BENDER, dot is the distance proj
        // uv = uv - nor * dot(uv, nor) * 2. * STIME; // maybe cool
    }
                // uv /= scale;
    return uv;
}

// star folding is at the dents
float2 kofFractal3(float2 uv, int numLoops, out float scale)
{
                // zoom out, move up
    uv *= 2.;
    uv.y -= tan(radians(54.)) * 0.5;

                // star folding (at the dents)
    uv.x = abs(uv.x);
  
    float center = tan(radians(54.));
    +tan(radians(72.));
    float baseRad = 0.5;

    float2 nor1 = getAngleNor(radians(54.));
    uv = uv - nor1 * min(0., dot(nor1, uv - float2(-baseRad, -center))) * 2.;
                
    nor1 = getAngleNor(radians(306.));
    uv = uv - nor1 * min(0., dot(nor1, uv - float2(-baseRad, 0.))) * 2.;

                // arb line reflection params
    float2 nor = getAngleNor(radians(240.));

                // folding
    scale = 1.;
    for (int i = 0; i < numLoops; i++)
    {
        // #0 put back into operation space
        if (i > 0)
        {
            uv *= 3.;
            uv.x -= 1.5;
            
        }
        scale *= 3.;
        // #1 half reflection 
        uv.x = abs(uv.x);
        uv.x -= 0.5;
                    // angle reflection
        uv = uv - nor * min(0., dot(uv, nor)) * 2.; // BENDER, dot is the distance proj
                    // uv = uv - nor * d * 2. * STIME; maybe cool
    }
    // uv /= scale;
    return uv;
}


