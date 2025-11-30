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

                // Super Early Morning Light
                lights[0].dir   = normalize(float3(-1.0, -0.3, -0.5));   
                lights[0].color = float3(0.9, 0.6, 0.3) * 0.2;         

                lights[1].dir   = normalize(float3(0.2, 1.0, -0.2));      
                lights[1].color = float3(0.4, 0.6, 0.9) * 0.7;            
                
                lights[2].dir   = normalize(float3(0.0, -0.7, 1.0));     
                lights[2].color = float3(0.3, 0.4, 0.6) * 0.3;           


                
                // TEMP
                float3 albedo;
                if (materialID == 0) albedo = float3(0.5, 0.5, 0.5);
                else if (materialID == 1) albedo = float3(1., 0., 0.5);
                else if (materialID == 2) albedo = float3(0.1, 0.05, 0.05);
                else albedo = float3(0.5, 1., 0.5);

                albedo = float3(0.01, 0.01, 0.01);//float3(0.5, 0.5, 0.5);

                float3 col = float3(0.0, 0.0, 0.0);
                for (int i = 0; i < 3; i++) {
                    col += albedo * lights[i].color * max(0., dot(nor, lights[i].dir));
                }
                 
                col = pow(col, 1.0 / 2.2);
                return col;
            }

            float3 getSimpleShading2(float3 N, float3 V, int materialID)
            {
                Light lights[3];
            
                // lights
                lights[0].dir   = normalize(float3(-1.0, -0.3, -0.5));   
                lights[0].color = float3(0.1, 0.9, 0.7) * 0.2;
            
                lights[1].dir   = normalize(float3(0.2, 1.0, -0.2));
                lights[1].color = float3(0.4, 0.6, 0.9) * 0.7;
            
                lights[2].dir   = normalize(float3(0.0, -0.7, 1.0));
                lights[2].color = float3(0.3, 0.4, 0.6) * 0.3;
            
                // material
                float3 metalColor;
                float metalness;
                float roughness;
            
                materialID = 1;
                if (materialID == 0) { metalColor=float3(1.0,0.8,0.3); metalness=1.; roughness=0.15; }
                else if (materialID == 1) { metalColor=float3(1.0,0.2,0.6); metalness=1.; roughness=0.2; }
                else if (materialID == 2) { metalColor=float3(0.2,0.05,0.05); metalness=1.; roughness=0.3; }
                else { metalColor=float3(0.8,0.9,1.0); metalness=0.; roughness=0.5; } // default
            
               
                float3 diffuseColor = lerp(float3(0.01,0.01,0.01), metalColor * 0.05, 1.0 - metalness);  
                float3 specColor = lerp(float3(1.0,1.0,1.0), metalColor, metalness);
                float shininess = lerp(256.0, 8.0, roughness);
            
                // lighting
                float3 result = 0;
                for (int i=0; i<3; i++)
                {
                    float3 L = lights[i].dir;
                    float3 H = normalize(L + V);
            
                    float NdotL = max(dot(N, L), 0.0);
            
                    // Diffuse
                    float3 diff = diffuseColor * lights[i].color * NdotL;
            
                    // Specular
                    float spec = pow(max(dot(N, H), 0.0), shininess);
                    float3 specular = specColor * spec * lights[i].color;
            
                    result += diff + specular;
                }
            
                return pow(result, 1.0/2.2);
            }


            void cameraMove(out float3 EYEPOS, out float3 REF, int version) {
                REF = float3(0., 0., 0.);
                // default
                if (version == 0) {
                    EYEPOS = float3(0.0, 5., 3.0);// * sin(TIME);
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

            // modified for sdf
            // star folding is at the dents
            float2 kofFractal4(float2 uv, int numLoops, out float scale)
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
                float2 nor = getAngleNor(radians(TIME * 10.));//radians(240));getAngleNor(radians(240));
            
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
                    // uv = uv - nor * min(0., dot(uv, nor)) * 2. * STIME; // maybe cool
                }
                // uv /= scale;
                return uv;
            }

            float kofSDF1(float3 query, out int materialID)
            {
                materialID = 1;

                // float thickness = 0.03;
                // float complexity = 2;3. * (_fracBeat) + 1;
                // float lerpTime = 0.;

                float thickness = 0.03;
                float complexity = 2.;//3. * (_fracBeat) + 1;
                float lerpTime = 0.;

                // XY
                float scaleXY;
                float2 kofXY = kofFractal4(query.xy, complexity, scaleXY);
                kofXY /= scaleXY;
                float dXY = lerp(kofXY.x, kofXY.y, lerpTime);
                // dXY = abs(dXY) - 0.01;
            
                float slabXY = abs(query.z) - thickness;
                float sdfXY = max(dXY, slabXY);
            
                // YZ
                float scaleYZ;
                float2 kofYZ = kofFractal4(query.yz, complexity, scaleYZ);
                kofYZ /= scaleYZ;
                float dYZ = lerp(kofYZ.x, kofYZ.y, lerpTime);
                // dYZ = abs(dYZ) - 0.01;

                float slabYZ = abs(query.x) - thickness;
                float sdfYZ = max(dYZ, slabYZ);
            
                // ZX
                float scaleZX;
                float2 kofZX = kofFractal4(query.zx, complexity, scaleZX);
                kofZX /= scaleZX;
                float dZX = lerp(kofZX.x, kofZX.y, lerpTime);
                // dZX = abs(dZX) - 0.01;

                float slabZX = abs(query.y) - thickness;
                float sdfZX = max(dZX, slabZX);
            
                // union
                // float finalSDF = smoothUnion(sdfXY, smoothUnion(sdfYZ, sdfZX, 0.5), 0.5);
                float finalSDF = min(sdfXY, min(sdfYZ, sdfZX));
                return finalSDF;
            }



            float sceneSDF(float3 query, out int materialID, int sceneVer)
            {
                // query = query - 10. * round(query / 10.);

                query = rotateX(query, TIME * 0.3);
                query = rotateY(query, TIME * 0.1);
                materialID = 1;    
                // return sphereSDF(query, 0.4);
                return kofSDF1(query, materialID);
            }
            
            float3 bgColor(float3 rayDir) {
                float dirNor = rayDir.y * .5 + .5;
                return pow(dirNor, 3.);
            }

            float3 shootRays(float2 uv)
            {
                // camera setup
                float3 EYEPOS = _CameraPos;
                float3 REF = _CameraTarget;
                int switchBt = (_intBeat / 4) % 4;
                //float3 EYEPOS;
                //float3 REF;
                // cameraMove(EYEPOS, REF, switchBt);
                
                // EYEPOS = float3(0.0, 2., 1.0);
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

                
                float3 bgcolor = float3(1., 1., 1.) * bgColor(ray.dir);
                //float s = smoothstep(1., 10., intersection.distance);
                //float3 color = float3(.5,.6,.7) * pow(s + 0.9,2.);
                float3 color = bgcolor;

                if (intersection.hit && intersection.distance < 10000.) // TODO
                {
                    
                    float3 wo = normalize(intersection.position - ray.origin);
                    color = getSimpleShading2(intersection.normal,  - wo, intersection.materialID);

                    // AO
                    float strength = 2.;
                    float ao = 1. - intersection.steps * strength / (float)MAX_ITER;

                    color *= ao;          
                }

                // Bloom
                float bloomIntensity = 0.6;
                float3 bloomColor = float3(0.7, 0.8, 0.7);
                color += bloomColor * intersection.bloom * bloomIntensity;

                // fog
                float s = smoothstep(1., 100., intersection.distance);
                color = lerp(color, bgcolor, s);

                return color;
            }

            
            
            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv * 2 - 1;
                float AR = _ScreenParams.x / _ScreenParams.y;
                uv.x *= AR;
                // uv.y = -uv.y;

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

               

               // starchecker
               // uv = scroll(uv, float2(TIME, 0.));
               float freq = 10.;
               float3 starOverlay = starRand(uv, freq) * float3(1., 1., 0.8);

               col = lerp(col, starOverlay, starOverlay.x * 0.3);

                // col = 1. - col;
                return float4(col, 1);
            }

            ENDCG
        }
    }
}