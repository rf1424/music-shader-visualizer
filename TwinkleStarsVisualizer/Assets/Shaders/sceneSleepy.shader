Shader "Unlit/sceneSleepy"
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
                else {albedo = float3(0.1, 0.05, 0.05);}
                
                float3 col = albedo;
                // for (int i = 0; i < 3; i++) {
                //     col += albedo * lights[i].color * max(0., dot(nor, lights[i].dir));
                // }
                 
                col = pow(col, 1.0 / 2.2);
                return col;
            }

            void cameraMove(out float3 EYEPOS, out float3 REF, int version) {
                REF = float3(0., 0., 0.);
                EYEPOS = float3(0.0, 0., 3.);//float3(0.0, 1.3, 3.);
                
            }

            float sceneSDF(float3 query, out int materialID, int sceneVer)
            {
                float d;

                float star = sdfPentagram(query.xy, 0.3);
                float starThick = opExtrusionSmoothSDF(query, star, 0.1, 0.01);
                
                
                query = rotateX(query, radians(-28.));
                float starCreature = starAnimalSDF2(query - float3(0., -0.5, 0.), materialID);

                float t = (TIME - 40.5)/ 30.;
                t = min(t, 1.);
                return lerp(starThick, starCreature, t);
;                
            }
            

            float3 shootRays(float2 uv)
            {
                // camera setup
                float3 EYEPOS = _CameraPos;
                float3 REF = _CameraTarget;
                int switchBt = ((_intBeat - 1) / 4) % 5;
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

                Intersection intersection = sdfRayMarch(ray, TIME, switchBt);

                float3 bgColor = float3(random3(_intBeat));
                float3 color = bgColor;

                // float3 color = float3(1., 0.1, 0.5); PINK

                if (intersection.hit && intersection.distance < 10000.) // TODO
                {
                    
                    color = getSimpleShading(intersection.normal, intersection.materialID);
                }

                
                return color;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv * 2 - 1;
                float AR = _ScreenParams.x / _ScreenParams.y;
                uv.x *= AR;

                uv = rotate2d(uv, TIME * 0.5 + 0.23);
                fixed3 col = float3(0., 0., 0.);

                col = random3(_intBeat);

                // USEFUL?
                // col.g = random(_highestBeat4);
                float radius = _PeakLevels[2] * 10.;
                float circle = step(length(uv), radius);
                col.r += circle; 
                
                float3 squareVignetteCol = squareVignette(uv);
                col += squareVignetteCol;

                

                // raymarch
                col = shootRays(uv);               

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
                float2 pixUnit = 2. / _ScreenParams.xy;
                        
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
                float2 uv = i.uv - 0.5;
                float AR = _ScreenParams.y / _ScreenParams.x;
                uv.x /= AR; // scale X to match Y
                uv = rotate2d(uv, TIME);
                uv.x /= AR; // scale back X
                uv += 0.5;
                float3 col = tex2D(_MainTex, i.uv).rgb;
                
                // edges extract
                uv.x *= AR;
                col = EdgeCrossFilter(i.uv);
                col = min(0.99, col);

                return float4(col, 1);
            }

            ENDCG
        }
    }
}
