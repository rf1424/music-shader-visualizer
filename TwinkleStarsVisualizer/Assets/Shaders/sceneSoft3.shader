Shader "Unlit/sceneSoft3"
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
            "Queue"="Overlay" 
            // "IgnoreProjector"="True"
            // "ForceNoShadowCasting"="True"
        }
        LOD 100

        Pass
        {
            ZTest Always
            ZWrite Off
            Cull Off
            Blend Off
            
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
                #ifdef _FULLSCREENMODE_ON
                    o.vertex = float4(v.vertex.xy * 2.0, 0.0, 1.0);
                #else
                    v.vertex.y *= 7.;
                    v.vertex.x *= 10.;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                #endif
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
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

            float3 starOverlays(float2 uv) {
                float d1 = sdfPentagram(uv, 0.5);
                float d2 = sdfPentagram(uv - float2(1. * LINTIME, 0.), 0.5);
                float d = smoothUnion(d1, d2, 0.1);
                float l = 1. - smoothstep(0.0,0.01,abs(d));
                return float3(l, l, l);
            }

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
                int switchBt = 3;//(_intBeat / 4) % 4;
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
                // uv transformations [-1, 1]
                float2 uv = i.uv * 2. - 1.;
                #ifdef _FULLSCREENMODE_ON
                    float AR = _ScreenParams.x / _ScreenParams.y;
                #else
                   float AR = 10. / 7.;
                #endif
                uv.x *= AR;
                uv.y = - uv.y;

                // rotate
                // uv = rotate2d(uv, TIME);

                float3 col = float3(0., 0., 0.);

                float scale = 1.;
                uv = kofFractal3(uv, 3., scale);
                
                // scale = 1.;
                // draw line
                float d = length(uv - float2(clamp(uv.x, -1., 1.), 0.));
                col += smoothstep(20. / _ScreenParams.y , 0., d / scale);

                // rescale back the uvs
                // uv /= scale;
                
               
                // draw uv (for visualization)
                col += float3(uv, 0.);

                // col += 1. - uv.y;
                //col = 1. - step(0., uv.y);

                // draw circles
                float beatSum = 0.;
                for (int i = 0; i < 8; i++) {
                    beatSum = _MeanLevels[i];
                }
                
                beatSum = beatSum * 5000.;
                beatSum = pow(beatSum, 0.4);
                
                // draw star dance
                // col = shootRays(uv);

                // col = step(length(frac(uv * 2.)), beatSum);
                
                return float4(col, 1.);
            }
            ENDCG
        }
    }
}