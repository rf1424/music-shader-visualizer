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

            

            // SPACIOUS DOMAIN REPETITION
            float starFallSDF(float3 query, out int materialID)
            {
                float ret;
                materialID = 0;
                
                // get query iD
                float spacing = 5.;
                float3 queryID = round(clamp(query.xyz, -5., +5) / spacing);
                // query.xyz -= spacing * queryID;
                
                // grid based variations
                
                float r = random(queryID.x + (queryID.y + 0.1) * (queryID.z + 29.));
                float2 r2 = float2(frac(r * 34.0), frac(r * 9.0));
                query += 0.2 * float3(r, r2);
                query.yz = mul(rot(queryID.x + TIME), query.yz);
                
                // transforms
                query -= float3(0., -0.5, 0.);
                query = rotateY(query, 2. * (sin(TIME * 4. + length(queryID))) * query.y);
                
                ret = starAnimalSDF2(query, materialID);
                return ret;
                
            }

            float sceneSDF(float3 query, out int materialID, int sceneVer)
            {
                
                float d;
                // query = query - 10. * round(query / 10.);
                
                query = rotateX(query, TIME * 0.3);
                query = rotateY(query, TIME * 0.1);
                materialID = 1;    
                
                // return sphereSDF(query, 0.4);
                float kof =  kofSDF1(query, materialID);
                d = kof;
                if (TIME > 16.5) {
                    float stars = starFallSDF(query / 0.3, materialID);
                    stars *= 0.3;
                    d = min(stars, kof);
                }
                
                return d;
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