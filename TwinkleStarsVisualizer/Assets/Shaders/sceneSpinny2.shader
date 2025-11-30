Shader "Unlit/sceneSpinny2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Toggle(_FULLSCREENMODE_ON)] _FullScreenMode ("Full Screen Mode", Float) = 1
    }
    SubShader
    {
        Tags { 
            "RenderType"="Opaque"
            // "RenderType"="Overlay" 
            // "Queue"="Overlay" 
            // "IgnoreProjector"="True"
            // "ForceNoShadowCasting"="True"
        }
        LOD 100

        Pass
        {
            // ZTest Always
            // ZWrite Off
            // Cull Off
            // Blend Off
            
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _FullScreenMode;

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
           
            float3 getSimpleShading(float3 nor, int materialID, float d) {
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
                else if (materialID == 3) albedo = float3(0.5, 1., 0.5);

                else { albedo = random3(nor.x + materialID); }
                

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
                else { // 2
                    // EYEPOS = float3(10., CTIME, 0.);
                    EYEPOS = float3(STIME, CTIME, 0.);
                }
                
            
            }

            float starTunnelSDF3(float3 query, out int materialID)
            {
                // float speed = 0.;
                // for (int i = 0; i < 4; i++)
                // {
                //     speed += _MeanLevels[i] * 10.;
            
                // }

                float speed =  3.;//_MeanLevels[2] * 1;
                    
                // parameters
                float2 offset = 0.05 * float2(cos(TIME + 0.3), STIME);
                float forwardSpeed = TIME * (speed);//TIME * 3.;
                
                // spin
                query.xy = mul(rot(TIME), query.xy);
                
                float spacing = .4;
                query -= float3(0., 0., forwardSpeed);
                float queryID = round(clamp(query.z, -10. - forwardSpeed, 1.) / spacing);
                query.z = query.z - spacing * queryID;
                
                float plane = abs(query.z) - 0.001; // width 0.01
                
                // float3 sq = query / float3(speed, speed, speed);
                float starFlat = sdfPentagram(query.xy, 0.5);
                // starFlat *= speed;
                
                float starExtruded = max(starFlat, abs(query.z) - 0.1);
                
                float d = max(-starExtruded, plane);
                
                materialID = queryID;
                return d;
            }

            

            float starTunnelSDF4(float3 query, out int materialID)
            {
                float tunnelEndz = - 23.;
                // rotate
                float angle = .1 * query.z + TIME;
                query.xy = mul(rot(angle), query.xy);

                
                // star creature
                float3 sq = query - float3(0., 0., tunnelEndz - 1.);
                sq = rotateX(sq, radians(180.));
                float scale = 0.3;
                sq /= scale;
                float starCreature = stardanceSDF0(sq, materialID);
                starCreature *= scale;

                // z axis domain repetition 
                float spacing = .4;
                float queryID = round(clamp(query.z, tunnelEndz, - tunnelEndz) / spacing);
                query.z = query.z - spacing * queryID;
                
                // star tunnel
                float starFlat = sdfPentagram(query.xy, 0.5);
                starFlat = starFlat - 0.03; // round
                starFlat = abs(starFlat) - 0.01; // near-edge only
                float starExtruded = max(starFlat, abs(query.z) - 0.1);
                
                float d = min(starExtruded, starCreature);

                if (starExtruded < starCreature) {
                    materialID = queryID + 50;
                }
                
                return d;
            }

            float sceneSDF(float3 query, out int materialID, int sceneVer)
            {
                materialID = BROWN;
                return starTunnelSDF4(query, materialID);
            }

            float3 shootRays(float2 uv)
            {
                // camera setup
                float3 EYEPOS = _CameraPos;
                float3 REF = _CameraTarget;
                int switchBt = (_intBeat / 4) % 3;
                //float3 EYEPOS;
                //float3 REF;
                // cameraMove(EYEPOS, REF, switchBt);

                // z axis motion
                float zPos = 0.;
                float limitPos = -23.;
                float flipt = 15.4;
                if (TIME < flipt) {
                    float rawPos = - TIME * 3.;
                    float t = 1. - saturate((rawPos - limitPos) / 3.0); // 0->1 right before limitPos
                    float ease = smoothstep(0., 1., t);

                    zPos = lerp(rawPos, limitPos, ease);//max(rawPos, limitPos)
                } else {
                    float t = TIME - flipt;
                    zPos = limitPos + t * 3.;
                    // EYEPOS += float3(10., 0., 0.);
                }

                float2 offset = 0.15 * float2(cos(TIME + 0.3), STIME);
                EYEPOS += float3(offset, 0.) * step(limitPos, TIME);
                EYEPOS += float3(0., 0., zPos);

                REF = EYEPOS - float3(0., 0., 1.);// // EYEPOS - float3(0., 0., 1.);
                REF = float3(0., 0., limitPos + 1.);
                // REF = float3(0., 0., -10.);

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

                float3 bgcolor = float3(0., 0., 0.);
                float3 color = bgcolor;

                if (intersection.hit && intersection.distance < 10000.) // TODO
                {
                    
                    color = getSimpleShading(intersection.normal, intersection.materialID, intersection.distance);
                }

                // Bloom
                float bloomIntensity = 0.6;
                float3 bloomColor = float3(0.7, 0., 0.);
                color += bloomColor * intersection.bloom * bloomIntensity;

                // fog
                // float s = smoothstep(1., 10., intersection.distance);
                // color = lerp(color, bgcolor, s);
                
                return color;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv * 2 - 1;
                float AR = _ScreenParams.x / _ScreenParams.y;
                uv.x *= AR;
                uv.y = -uv.y;

                float3 col = shootRays(uv);
                return float4(col, 1);
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

            

            fixed4 fragPass1(v2f i) : SV_Target
            {
                float2 uv = i.uv * 2. - 1.;
                float AR = _ScreenParams.x / _ScreenParams.y;
                uv.x *= AR;
                float3 col = tex2D(_MainTex, i.uv).rgb;


               float freq = 10.;
               float3 starOverlay = starRand(uv, freq) * float3(1., 1., 0.8);

               col = lerp(col, starOverlay, starOverlay.x * 0.3);


               float scale = 1.;
                uv = kofFractal3(uv, 3., scale);
                uv /= scale;

                float beatSum = _MeanLevels[4] + _MeanLevels[5];
                beatSum = beatSum * 2000.;
                beatSum = pow(beatSum, 0.4);
                // float d = step(length(frac(uv * 2.)), beatSum);
                float d = step(length(frac(uv * 2.)), beatSum);
                uv = scroll(uv, beatSum);
                d = starChecker(uv, 5.);

                float3 bgColor = d * random3(_intBeat);

                col = lerp(col, bgColor, d);

               return float4(col, 1);
            }

            ENDCG
            
        }
    }
}