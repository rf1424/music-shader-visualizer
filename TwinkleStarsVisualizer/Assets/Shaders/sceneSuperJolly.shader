Shader "Unlit/sceneSuperJolly"
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
                   
                    float f = fmod(_fracBeat, 1.) * 2.5;
                    EYEPOS = float3(-1.6 + sin(f), 1., 1.9);
                }
                else if (version == 2) {

                    EYEPOS = float3(0.04, 6.60, -0.11);//float3(0.1, 0., 10.);// + float3(0., 0., TIME * 0.1);
                   
                }
                else if (version == 3) {
                    EYEPOS = float3(0.65, 1., 2.36) + float3(sin(_fracBeat), cos(TIME * 2.), 0.);
                } else if (version == 4) {
                    float f = fmod(_fracBeat - 0.2, 1.);
                    EYEPOS = float3(0.65, 1., 2.36) + float3(0., 0., - TIME * f);
                }
                else {
                    float f = fmod(_fracBeat - 0.2, 1.);
                    EYEPOS = float3(0.65, 1., 2.36) - float3(0., - TIME * f, -TIME);
                }
            }

            float sceneSDF(float3 query, out int materialID, int sceneVer)
            {

                if (sceneVer == 0)
                {
                    return superStardanceSDF0(query, materialID);
                }
                else if (sceneVer == 1)
                {
                    return superStardanceSDF1(query, materialID);
                }
                else if (sceneVer == 2)
                {
                    return superStardanceSDF3(query, materialID);
                    
                }
                else if (sceneVer == 3) {
                    return superStardanceSDF2(query, materialID);
                }
                else {
                    return superStardanceSDF4(query, materialID);
                }
            
            }
            

            float3 shootRays(float2 uv)
            {
                // camera setup
                float3 EYEPOS = _CameraPos;
                float3 REF = _CameraTarget;
                int switchBt = ((_intBeat) / 4) % 5;
                if (switchBt==0 && (_intBeat) / 4 !=0) switchBt = 4;
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

                

                // fog
                float s = smoothstep(1., 50., intersection.distance);
                color = lerp(color, bgColor, s);
                
                
                return color;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv * 2 - 1;
                float AR = _ScreenParams.x / _ScreenParams.y;
                uv.x *= AR;
               
                fixed3 col = float3(0., 0., 0.);

                col = random3(_intBeat);

                
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
            

            float3 _CameraPos;
            float3 _CameraTarget;
           
            #include "hlsl/allShaders.hlsl"   
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

            float3 hatch(float2 uv)
            {
                
                float3 imgColor = tex2D(_MainTex, uv).rgb;
            
                float lum = brightness(imgColor);
            
                float uLineThickness = 1.0;
            
                float scale = 500.0 * uLineThickness / _ScreenParams.y;
            
                float hatchValue;
            
                
                if (lum < 0.2) hatchValue = sampleHatchingPattern(uv * _ScreenParams.xy, scale * 4.0);
                else if (lum < 0.4) hatchValue = sampleHatchingPattern(uv * _ScreenParams.xy, scale * 3.0);
                else if (lum < 0.6) hatchValue = sampleHatchingPattern(uv * _ScreenParams.xy, scale * 2.0);
                else if (lum < 0.8) hatchValue = sampleHatchingPattern(uv * _ScreenParams.xy, scale * 1.0);
                else hatchValue = 1.0;
                
            
                return hatchValue;
            }


            fixed4 fragPass1(v2f i) : SV_Target
            {
                float3 col = tex2D(_MainTex, i.uv).rgb;

                float h = hatch(i.uv);
                col *= h;
                // col = 1. - col;
                return float4(col, 1);
            }

            ENDCG
        }
    }
}