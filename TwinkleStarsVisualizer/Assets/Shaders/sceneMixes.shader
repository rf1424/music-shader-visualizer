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
            
            struct Light {
                float3 dir;
                float3 color;
            };
           
            float3 getSimpleShading(float3 nor, int materialID) {
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
                
                // float3 col = albedo;
               
                float3 col = float3(0.0, 0.0, 0.0);
                for (int i = 0; i < 3; i++) {
                    col += albedo * lights[i].color * max(0., dot(nor, lights[i].dir));
                }
                 
                col = pow(col, 1.0 / 2.2);
                return col;
            }

            void cameraMove(out float3 EYEPOS, out float3 REF, int version) {
                REF = float3(0., 0., 0.);
                // default
                if (version == 0) {
                    
                    REF    = float3(0., -0.5, 0.);
                    EYEPOS = float3(0.0, -0.6, 1.);
                    
                }
                else if (version == 1) {
                    // spin
                    EYEPOS = float3(-1.6 + sin(_fracBeat * 2.), 1., 1.9);
                }
                else if (version == 2) {
                    EYEPOS = float3(0.1, - 0.2, 5.);
                    
                }
                else if (version == 3) { // 2
                     // EYEPOS = float3(10., CTIME, 0.);
                    // EYEPOS = float3(STIME, CTIME, 0.);
                    EYEPOS = float3(0.65, 1., 2.36) + float3(sin(_fracBeat), cos(TIME * 2.), 0.);
                } else {
                    EYEPOS = float3(0.65, 1., 2.36) + float3(0., 0., - TIME * _fracBeat);
                }
            }

            float sceneSDF(float3 query, out int materialID, int sceneVer)
            {
                return superStardanceSDF1(query, materialID);
                if (sceneVer == 0)
                {
                    return superStardanceSDF0(query, materialID);
                }
                else
                {
                    return superStardanceSDF1(query, materialID);
                }

                
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

                // BG
                // float scale = 1.;
                // uv = kofFractal3(uv, 3., scale);
                // uv /= scale;

                // float beatSum = _MeanLevels[4] + _MeanLevels[5];
                // beatSum = beatSum * 2000.;
                // beatSum = pow(beatSum, 0.4);
                // float d = step(length(frac(uv * 2.)), beatSum);
                // uv = scroll(uv, beatSum);
                // d = starChecker(uv, 3.);
                // int odd = (int)floor(beatSum * 10.) & 1;
                // uv = scroll(uv, float2(0., TIME * odd));
                // d = starChecker(uv,3.);
                // float3 bgColor = d * random3(_intBeat);

                float3 bgColor = float3(random3(_intBeat));
                float3 color = bgColor;

                // float3 color = float3(1., 0.1, 0.5); PINK

                if (intersection.hit && intersection.distance < 10000.) // TODO
                {
                    
                    color = getSimpleShading(intersection.normal, intersection.materialID);
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
                float3 col1 = pow(shootRays(uv, 0).r, 3.);

                float3 col2 = shootRays(uv, 1);

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
            

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv * 2 - 1;
                float AR = _ScreenParams.x / _ScreenParams.y;
                uv.x *= AR;
                fixed3 col = float3(0., 0., 0.);
                
                
                
                // raymarch
                // uv = mobius(uv);

                col = doubleLayeredStars(uv);
                // col = shootRays(uv, 1);
                
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
                
                // overlay outlines
                // float3 outlines = EdgeCrossFilter(i.uv + 0.2);
                // col += length(outlines);

                // col = 1. - col;
                return float4(col, 1);
            }

            ENDCG
        }
    }
}