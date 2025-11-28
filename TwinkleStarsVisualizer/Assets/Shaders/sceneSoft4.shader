Shader "Unlit/sceneSoft4"
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

            float beatSum() {
                float beatSum = 0.;
                for (int i = 0; i < 8; i++) {
                    beatSum = _MeanLevels[i];
                }
                
                beatSum = beatSum * 5000.;
                beatSum = pow(beatSum, 0.4);
                return beatSum;
            }
            

            float kofSDF0(float3 query, out int materialID) {

                materialID = 1;

                float scale;
                
                float2 kof = kofFractal3(query.xy, 5. * (_fracBeat) + 1., scale);
                kof /= scale;
                float kofd = lerp(kof.x, kof.y, STIME);

                // clamp
                float w = abs(query.z) - .05;
                return max(kofd, w);
                // return sphereSDF(query, 0.2);
            }



            float kofSDF1(float3 query, out int materialID)
            {
                materialID = 1;
            
                //----------------------------------------------------
                // 1. XY projection (slab along Z)
                //----------------------------------------------------
                float scaleXY;
                float2 kofXY = kofFractal3(query.xy, 5.0 * _fracBeat + 1.0, scaleXY);
                kofXY /= scaleXY;
                float dXY = lerp(kofXY.x, kofXY.y, STIME);
            
                float slabXY = abs(query.z) - 0.05;
                float sdfXY = max(dXY, slabXY);
            
                //----------------------------------------------------
                // 2. YZ projection (slab along X)
                //----------------------------------------------------
                float scaleYZ;
                float2 kofYZ = kofFractal3(query.yz, 5.0 * _fracBeat + 1.0, scaleYZ);
                kofYZ /= scaleYZ;
                float dYZ = lerp(kofYZ.x, kofYZ.y, STIME);
            
                float slabYZ = abs(query.x) - 0.05;
                float sdfYZ = max(dYZ, slabYZ);
            
                //----------------------------------------------------
                // 3. ZX projection (slab along Y)
                //----------------------------------------------------
                float scaleZX;
                float2 kofZX = kofFractal3(query.zx, 5.0 * _fracBeat + 1.0, scaleZX);
                kofZX /= scaleZX;
                float dZX = lerp(kofZX.x, kofZX.y, STIME);
            
                float slabZX = abs(query.y) - 0.05;
                float sdfZX = max(dZX, slabZX);
            
                //----------------------------------------------------
                // union of the 3 fractal slabs
                //----------------------------------------------------
                // float finalSDF = smoothUnion(sdfXY, smoothUnion(sdfYZ, sdfZX, 0.5), 0.5);
                float finalSDF = min(sdfXY, min(sdfYZ, sdfZX));
                return finalSDF;
            }


            float sceneSDF(float3 query, out int materialID, int sceneVer)
            {
                query = rotateX(query, TIME * 0.3);
                query = rotateY(query, TIME * 0.3);
                materialID = 1;
                return kofSDF1(query, materialID);
            }
            

            float3 shootRays(float2 uv)
            {
                // camera setup
                float3 EYEPOS = _CameraPos;
                float3 REF = _CameraTarget;
                int switchBt = 3.;//(_intBeat / 4) % 4;
                //float3 EYEPOS;
                //float3 REF;
                // cameraMove(EYEPOS, REF, switchBt);

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

                if (intersection.hit)// && intersection.distance < 10000.) // TODO
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
                float scale;
                
                
                col = shootRays(uv);

                
                // col += kofFractal(uv, 1, scale).y * 0.5;

                return float4(col, 1.);
            }
            ENDCG
        }
    }
}