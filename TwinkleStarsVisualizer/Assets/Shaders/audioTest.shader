Shader "Unlit/AudioTest"
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

                fixed4 col = tex2D(_MainTex, uv);
                col = float4(uv, 0, 1);

                float radius = _PeakLevels[5] * 10.;
                float circle = step(length(uv), radius);
                
                col += circle;
                return col;
            }
            ENDCG
        }
    }
}