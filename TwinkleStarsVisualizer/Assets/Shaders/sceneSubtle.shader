Shader "Unlit/sceneSubtle"
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
            float _intBeat;
            float _fracBeat;

            #include "hlsl/allShaders.hlsl"

            float3 starOverlays(float2 uv) {
                float d1 = sdfPentagram(uv, 0.5);
                float d2 = sdfPentagram(uv - float2(1. * LINTIME, 0.), 0.5);
                float d = smoothUnion(d1, d2, 0.1);
                float l = 1. - smoothstep(0.0,0.01,abs(d));
                return float3(l, l, l);
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

                // star
                uv = rotate2d(uv, TIME * 0.3);
                uv = uv / (1. + 0.3 * LINTIME);
             
                col += starOverlays(uv);
                
                return float4(col, 1.);
            }
            ENDCG
        }
    }
}