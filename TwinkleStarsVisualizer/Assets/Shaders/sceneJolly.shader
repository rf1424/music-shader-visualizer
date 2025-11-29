Shader "Unlit/sceneJolly"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Toggle(_FULLSCREENMODE_ON)] _FullScreenMode ("Full Screen Mode", Float) = 1
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
            #pragma shader_feature _FULLSCREENMODE_ON
            

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

                lights[0].dir   = normalize(float3(10.0, 10.0, 15.0));
                lights[0].color = float3(1.0, 1.0, 0.1) * 1.5;
                
                lights[1].dir   = float3(0.0, 1.0, 0.0);
                lights[1].color = float3(0.7, 0.2, 0.7) * 0.5;
                
                lights[2].dir   = normalize(-float3(15.0, 0.0, 10.0));
                lights[2].color = float3(0.1, 0.3, 0.8) * 0.2;

                
                // TEMP
                float3 albedo;
                if (materialID == 0) albedo = float3(0.5, 0.5, 0.5);
                else if (materialID == 1) albedo = float3(1., 0., 0.5);
                else if (materialID == 2) albedo = float3(0.1, 0.05, 0.05);
                else albedo = float3(0.5, 1., 0.5);

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
                    EYEPOS = float3(0.0, 1.5, 3.0);
                }
                else if (version == 1) {
                    // spin
                    EYEPOS = float3(1.6, 1.7, 1.9);
                }
                else if (version == 2) {
                    // EYEPOS = float3(10., CTIME, 0.);
                    // EYEPOS = float3(STIME, CTIME, 0.);
                    EYEPOS = float3(0.65, 1.73, 2.36) + 0.1 * float3(STIME, CTIME, 0.);
                }
                else { // 2
                     EYEPOS = float3(0.1, - 0.2, 5.);
                }
            }

            float sceneSDF(float3 query, out int materialID, int sceneVer)
            {
                if (sceneVer == 0)
                {
                    return stardanceSDF0(query, materialID);
                }
                else if (sceneVer == 1)
                {
                    return stardanceSDF1(query, materialID);
                }
                else if (sceneVer == 2)
                {
                    return stardanceSDF2(query, materialID);
                }
                else {
                    return stardanceSDF3(query, materialID);
                }
            
            }
            

            float3 shootRays(float2 uv)
            {
                // camera setup
                float3 EYEPOS = _CameraPos;
                float3 REF = _CameraTarget;
                int switchBt = (_intBeat / 4) % 4;
                //float3 EYEPOS;
                //float3 REF;
                cameraMove(EYEPOS, REF, switchBt);

                // EYEPOS = float3(0.1, - 0.2, 5.);//float3(100 * STIME, 10., 100 * CTIME);
                float3 cameraForward = normalize(REF - EYEPOS);
                float3 cameraRight = normalize(cross(cameraForward, WORLD_UP));
                float3 cameraUp = normalize(cross(cameraRight, cameraForward));
                

                // get ray direction (note tan-1(fov/2) = 1 / len(REF - EYE))
                // changing len(REF-EYE) will change focal length -> fov
                float3 rayPoint = REF + cameraRight * uv.x + cameraUp * uv.y;
                float3 rayDir = normalize(rayPoint - EYEPOS);

                Ray ray;
                ray.origin = EYEPOS;
                ray.dir = rayDir;

                Intersection intersection = sdfRayMarch(ray, TIME, switchBt);

                float3 color = float3(0.1, 0.1, 0.2);
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
                // uv.y = -uv.y;
                
                // uv = uvOffset(uv);

                // uv.x = remapRepeat(uv.x, 2.);
                // baseCol
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

                // col *= 1. - vin * 0.4;
                
                // col = voronoiFilter(uv, col);
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

            fixed4 fragPass1(v2f i) : SV_Target
            {
                float3 col = tex2D(_MainTex, i.uv).rgb;

                col = 1. - col;
                return float4(col, 1);
            }

            ENDCG
        }
    }
}