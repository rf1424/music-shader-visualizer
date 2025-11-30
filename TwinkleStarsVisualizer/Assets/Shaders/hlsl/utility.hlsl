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

float3 hsv2rgb(float3 c)
{
    float4 K = float4(1., 2. / 3., 1. / 3., 3.);
    float3 p = abs(frac(c.xxx + K.xyz) * 6. - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
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



// KOF Fractals
float2 getAngleNormal(float a)
{
    return float2(sin(a), cos(a));
                // visualize (pass uv)
                //float reflLine = dot(nor1, uv);
                //col.b += smoothstep(0.02, 0., abs(reflLine));
}

float2 getAngleNor(float a)
{
    return float2(- sin(a), cos(a));
                // visualize (pass uv)
                //float reflLine = dot(nor1, uv);
                //col.b += smoothstep(0.02, 0., abs(reflLine));
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