Shader "Unlit/sceneMixes"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { 
            "RenderType"="Overlay"
        }
        LOD 100

        Pass
        {
           
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            

            #include "UnityCG.cginc"
            

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _FullScreenMode;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }


            float _Levels[8];
            float _PeakLevels[8];
            float _MeanLevels[8];
            float _highestBeat4; /// simply tracks current peakLevel max for 2
            float _time;
            int _intBeat; // float _intBeat;
            float _fracBeat;
            

            float3 _CameraPos;
            float3 _CameraTarget;
           
            #include "hlsl/allShaders.hlsl"  
            
            // All the sceneVers!!!
            #define DOUBLELAYER0 0
            #define DOUBLELAYER1 1
            #define BROKENSD 2
            #define KALEID 3
            #define KALEID2 4
            #define TUNNEL 5
            
            struct Light {
                float3 dir;
                float3 color;
            };
           
            float3 getSimpleShading(float3 nor, int materialID, int sceneVer) {
                Light lights[3];

                lights[0].dir   = normalize(float3(-10.0, 15.0, 10.0));
                lights[0].color = float3(1.0, 1.0, 1.0) * 1.;
                
                lights[1].dir   = float3(0.0, 1.0, 0.0);
                lights[1].color = float3(0.2, 0.8, 0.2) * 0.5;
                
                lights[2].dir   = normalize(-float3(15.0, 0.0, 10.0));
                lights[2].color = float3(0.1, 0.3, 0.8) * 0.2;

                
                // TEMP
                float3 albedo;
                if (materialID == 0) albedo = float3(0.5, 0.5, 0.);
                else if (materialID == 1) albedo = float3(1., 0., 0.5);
                else if (materialID == 2) albedo = float3(0.1, 0.05, 0.05);
                // randomized star body color
                else {
                    float h = random(materialID * 0.001);
                    albedo = hsv2rgb(float3(h, .9, 0.6));
                    // albedo.b *= 0.1;
                }

                // ----------------------------------------------------------------------
                float3 col = 0;

                if (sceneVer <=4) {
                    col = albedo;
                }
                else {
                    col = float3(0.0, 0.0, 0.0);
                    for (int i = 0; i < 3; i++) {
                        col += albedo * lights[i].color * max(0., dot(nor, lights[i].dir));
                    }
                }
    
                col = pow(col, 1.0 / 2.2);
                return col;
            }

            void cameraMove(out float3 EYEPOS, out float3 REF, int version) {
                REF = float3(0., 0., 0.);
                
                // default
                if (version == DOUBLELAYER0) {
                    
                    REF    = float3(0., -0.5, 0.);
                    EYEPOS = float3(0.0, -0.6, 1.);
                    
                }
                else if (version == DOUBLELAYER1) {
                    // spin
                    EYEPOS = float3(-1.6 + sin(_fracBeat * 2.), 1., 1.9);
                }
                else if (version == BROKENSD) {
                    EYEPOS = float3(0.94, 0.86, 0.25);
                    
                }
                else if (version == KALEID) {
                    EYEPOS = float3(0., 0., 0.2);
                }
                else if (version == KALEID2) { // 2
                    EYEPOS = float3(5.23, 7.80, 13.44);   
                } else if (version == TUNNEL) {
                    EYEPOS = float3(0.1, -0.2, 5.);
                }
                else {
                    EYEPOS = float3(0., - 0.2, 5.);
                }
            }

            float brokenSDF(float3 query, out int materialID)
            {
                float t = 0;
                materialID = 0;
                float3 q = query;
                // q += (gradientNoise(query.xy + t*1.0));
                float ret;
                materialID = 0;
                
                // slide forward
                // query.z -= TIME * 0.5 + 5.;
                
                // domain repeat along z
                float spacing = 1.2;
                int queryID = round(query.z / spacing);
                int matSeed = round(query.z / spacing) * 73 + round(query.x / spacing) * 13;
                query.z = query.z - spacing * round(query.z / spacing);
                query.x = query.x - spacing * round(query.x / spacing);
                
                query -= float3(0., -0.5, 0.);
                
                // transforms:rotate
                float noise = gradientNoise(query.xy + t*1.0);
                query -= float3(0., -0.5, 0.);
                query = rotateY(query, 20. * (sin(TIME * 5.)) * query.y + noise);
                query = rotateX(query, 1. * (sin(TIME * 4.)) * query.y);
                
                
                float3 scale = float3(1., STIME * .01 + 1., 1.);
                query /= scale;
                
                // sdfs
                
                float star2 = starAnimalSDF2SpecColor(query, matSeed, materialID);
                ret = star2;
                bool isOdd = (queryID & 1) != 0;
                if (isOdd)
                {
                    float sunglasses = sunglassesSDF(query - float3(0., 0.47, 0.23), 0.5);
                    // material
                    materialID = star2 < sunglasses ? materialID : RED;
                    ret = min(star2, sunglasses);
                }
                    
                ret *= min(min(scale.x, scale.y), scale.z);
                return ret;
            }

            float sceneSDF(float3 query, out int materialID, int sceneVer)
            {
                
                if (sceneVer == DOUBLELAYER0)
                {
                    return superStardanceSDF0(query, materialID);
                }
                else if (sceneVer == DOUBLELAYER1)
                {
                    return superStardanceSDF1(query, materialID);
                }
                else if (sceneVer == BROKENSD) {
                    return brokenSDF(query, materialID);
                }
                else if (sceneVer == KALEID) {
                    return stardanceSDF3(query, materialID);
                }
                else if (sceneVer == KALEID2) {

                    return superStardanceSDF3(query, materialID);
                    // return starTunnelSDF2(query, materialID);
                }

                else if (sceneVer == TUNNEL) {
                   return starTunnelSDF4(query, materialID);
                }

                materialID = 0;
                return sphereSDF(query, 0.3);
            }
            

            float3 shootRays(float2 uv, int sceneVer)
            {
                // camera setup
                float3 EYEPOS = _CameraPos;
                float3 REF = _CameraTarget;
                int switchBt = sceneVer;//((_intBeat - 1) / 4) % 5;
                //float3 EYEPOS;
                //float3 REF;
                cameraMove(EYEPOS, REF, switchBt);

                // EYEPOS = float3(0.1, - 0.2, 5.);//float3(100 * STIME, 10., 100 * CTIME);
                float3 cameraForward = normalize(REF - EYEPOS);
                float3 cameraRight = normalize(cross(cameraForward, WORLD_UP));
                float3 cameraUp = normalize(cross(cameraRight, cameraForward));
                

                float fov = 45.0;
                float3 rayPoint = EYEPOS 
                + cameraForward
                + cameraRight * uv.x * tan(radians(fov)/2)
                + cameraUp    * uv.y * tan(radians(fov)/2);
                float3 rayDir = normalize(rayPoint - EYEPOS);

                Ray ray;
                ray.origin = EYEPOS;
                ray.dir = rayDir;

                Intersection intersection = sdfRayMarch(ray, TIME, sceneVer);

                float3 bgColor = float3(random3(_intBeat));
                float3 color = bgColor;

                // float3 color = float3(1., 0.1, 0.5); PINK

                if (intersection.hit && intersection.distance < 10000.) // TODO
                {
                    
                    color = getSimpleShading(intersection.normal, intersection.materialID, sceneVer);
                }

                // fog
                float s = smoothstep(1., 50., intersection.distance);
                color = lerp(color, bgColor, s);
                
                
                return color;
            }

            float starRand2(float2 uv, float freq)
            {
                float2 uvRepeat = uv * 0.5 + 0.5;
                float2 repeatID = floor(uvRepeat * freq);
                uvRepeat = frac(uvRepeat * freq) * 2. - 1.;
                           
                uv = uvRepeat;
            
                           // star outline
                float d = 0.;
                float seed = random(repeatID.x * freq * freq + repeatID.y * freq + floor(TIME * 6.));
                if (seed < 0.9)
                {
                    float size = random(seed);
                    d = sdRoundedCross(uv / size, 1.0);
                    // d = abs(d) - 0.01;
                    d = 1. - smoothstep(0.0, 0.01, d / freq);
                    d *= smoothstep(1., 0.95, length(uv));
                }
                return d;
            }

            // mix of big stars too
            float starRand3(float2 uv) {
                float2 duv = uv;
                float d = starRand2(duv, 1.3);
                d += starRand2(duv * 2. + 0.5, 1.3);

                float r = random(floor(TIME * 6.));
                float spark = sdRoundedCross(uv * 0.8 + float2(r, frac(r * 10.)) * 2. - 1., 1.0);
                spark = 1. - smoothstep(0.0, 0.01, spark);
                float spark2 = sdRoundedCross(uv * 0.9 - float2(frac(r * 10.), frac(r * 23.)) * 2. - 1., 1.0);
                spark2 = 1. - smoothstep(0.0, 0.01, spark2);
                d += spark + spark2;
                d = min(1., d);
                return d;
            }

            float3 doubleLayeredStars(float2 uv) {
                float3 col1 = pow(shootRays(uv, DOUBLELAYER0).r, 3.);
                

                float3 col2 = shootRays(uv, DOUBLELAYER1);

                // BLUR
                uv = uvOffset(uv);

                // REMAPPER
                float t = floor((sin(TIME * 0.1) * .5 + .5) * 3.);
                if ((_intBeat / 4) & 1 == 1) {
                    uv.x = remapRepeat(uv.x, t);
                    uv.y = remapRepeat(uv.y, t);
                }
                
                float d = starRand3(uv);
                return lerp(col1, col2, d);
            }

            float3 sceneMixer(float2 uv, int i) {
                float3 col = 0.;
                if (i==0) {col = doubleLayeredStars(uv); DOUBLELAYER0 & DOUBLELAYER1;}
                else if (i==1) {
                    col = shootRays(uv, BROKENSD);  
                }
                else if (i==2) {
                    float scale = 1.;
                    uv = kofFractal3(uv, 2., scale);
                    uv /= scale;
                    col = shootRays(uv / 0.5, KALEID);
                }
                else if (i==3) {
                    uv = mobius(uv);
                    col = shootRays(uv * 0.5, KALEID2);
                }
                else if (i==4) {
                    float2 uvSeed = uv * 1. - float2(TIME, 0.) + floor(TIME * 2.);
                    float mask = fbm(uvSeed, 2);
                    // mask = mask * 0.5 + 0.5;
                    mask = smoothstep(0.3, 0.5, mask);
                    float2 cp;
                    // mask = abs(mask - voronoi(uv, 1000., cp)) - mask;
                    //mask = clamp(mask, 0., 1.);

                    float3 c1 = shootRays(uv, DOUBLELAYER1);
                    float3 c2 = 1 - pow(c1, 0.1);
                    col = lerp(c2, c1, mask);
                    col = posterize(col, 3.);
                }
                else if (i==5) {
                    float t = cos(TIME * 2.) > 0.7 ? sin(TIME * 3.) : 1;
                    float uvOffset = fbm(uv + TIME, 2.);
                    col = shootRays(uv * t + uvOffset, TUNNEL);
                    col = posterize(col, 3.);
                }

               

                return col;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv * 2 - 1;
                float AR = _ScreenParams.x / _ScreenParams.y;
                uv.x *= AR;
                fixed3 col = float3(0., 0., 0.);
                
                
                int scene = floor(_intBeat / 2 - 1) % 6;
                scene = max(0, scene); // beginning
                if (TIME > 24.) scene = 5; // ending
                col = sceneMixer(uv, scene);

                // col = sceneMixer(uv, 3);
                return float4(col, 1.);
            }
            ENDCG
        }

        // second pass
        Pass {
            ZTest Always
            ZWrite Off
            Cull Off
            Blend Off

            CGPROGRAM
            #pragma vertex vertPass1
            #pragma fragment fragPass1
            #include "UnityCG.cginc"

            float _Levels[8];
            float _PeakLevels[8];
            float _MeanLevels[8];
            float _highestBeat4; /// simply tracks current peakLevel max for 2
            float _time;
            int _intBeat; // float _intBeat;
            float _fracBeat;

            #include "hlsl/allPostProcess.hlsl"

            sampler2D _MainTex; // rtA

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vertPass1(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float3 EdgeCrossFilter(float2 uv)
            {
                float2 pixUnit = 1.0 / _ScreenParams.xy;
                        
                float3 center = tex2D(_MainTex, uv).rgb;
                float3 left = tex2D(_MainTex, uv + float2(-pixUnit.x, 0)).rgb;
                float3 right = tex2D(_MainTex, uv + float2(pixUnit.x, 0)).rgb;
                float3 top = tex2D(_MainTex, uv + float2(0, pixUnit.y)).rgb;
                float3 bottom = tex2D(_MainTex, uv + float2(0, -pixUnit.y)).rgb;
                        
                            // Simple horizontal and vertical differences
                float3 hDiff = right - left;
                float3 vDiff = top - bottom;
                        
                            // Combine
                return sqrt(hDiff * hDiff + vDiff * vDiff);
            }

            fixed4 fragPass1(v2f i) : SV_Target
            {
                float3 col = tex2D(_MainTex, i.uv).rgb;
                

                if (TIME > 15. && sin(TIME * 10.) > 0.7) {
                    col = rgb2hsv(col);
                    float t = (TIME * 0.5 + gradientNoise(i.uv * 2.));
                    float h = frac(col.x + t);
                    col = hsv2rgb(float3(h, col.y, col.z));
                }


                // overlay outlines
                float3 outline1 = EdgeCrossFilter(i.uv + 0.2);
                col += length(outline1);

                
                float2 uvSeed = i.uv + gradientNoise(i.uv * STIME * 10.);
                float3 outline2 = EdgeCrossFilter(uvSeed);
                // col += outline2;

                if (TIME > 25.5) {
                    col = 0;
                }
                return float4(col, 1);
            }

            ENDCG
        }
    }
}