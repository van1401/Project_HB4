Shader "NMG/Survivor/HitImpact"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}	//0
		_Color("Main Color", Color) = (1,1,1,1)		//1
		_Alpha("General Alpha",  Range(0,1)) = 1	//2

		_HitEffectColor("Hit Effect Color", Color) = (1,1,1,1) //46
		_HitEffectGlow("Glow Intensity", Range(1,100)) = 5 //47
		[Space]
		_HitEffectBlend("Hit Effect Blend", Range(0,1)) = 1 //48

		_MySrcMode ("SrcMode", Float) = 5 // 131
        _MyDstMode ("DstMode", Float) = 10 // 132

     }

    SubShader
    {
		Tags { "Queue" = "Transparent" "CanUseSpriteAtlas" = "True" "IgnoreProjector" = "True" "RenderType" = "Transparent" "PreviewType" = "Plane" }
		Blend [_MySrcMode] [_MyDstMode]
		Cull [_CullingOption]
		ZWrite [_ZWrite]
		ZTest [_ZTestMode]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			#pragma shader_feature HITEFFECT_ON
			


            #include "UnityCG.cginc"
			#include "AllIn1OneShaderFunctions.cginc"

			#if FOG_ON
			#pragma multi_compile_fog
			#endif

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				half4 color : COLOR;
            	UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				half4 color : COLOR;
				#if OUTTEX_ON
				half2 uvOutTex : TEXCOORD1;
				#endif
				#if OUTDIST_ON
				half2 uvOutDistTex : TEXCOORD2;
				#endif
				#if DISTORT_ON
				half2 uvDistTex : TEXCOORD3;
				#endif
				#if FOG_ON
				UNITY_FOG_COORDS(4)
				#endif
            	UNITY_VERTEX_OUTPUT_STEREO 
            };

            sampler2D _MainTex;
            half4 _MainTex_ST, _MainTex_TexelSize, _Color;
			half _Alpha;
            float _RandomSeed;

	

			#if HITEFFECT_ON
			half4 _HitEffectColor;
			half _HitEffectGlow, _HitEffectBlend;
			#endif


            v2f vert (appdata v)
            {
				#if RECTSIZE_ON
				v.vertex.xyz += (v.vertex.xyz * (_RectSize - 1.0));
				#endif

                v2f o;
            	UNITY_SETUP_INSTANCE_ID(v);
            	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
            	
				#if BILBOARD_ON
				half3 camRight = mul((half3x3)unity_CameraToWorld, half3(1,0,0));
				half3 camUp = half3(0,1,0);
				#if BILBOARDY_ON
				camUp = mul((half3x3)unity_CameraToWorld, half3(0,1,0));
				#endif
				half3 localPos = v.vertex.x * camRight + v.vertex.y * camUp;
				o.vertex = UnityObjectToClipPos(half4(localPos, 1));
				#else
				o.vertex = UnityObjectToClipPos(v.vertex);
				#endif
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;

				half2 center = half2(0.5, 0.5);
				#if ATLAS_ON
				center = half2((_MaxXUV + _MinXUV) / 2.0, (_MaxYUV + _MinYUV) / 2.0);
				#endif

				#if POLARUV_ON
				o.uv = v.uv - center;
				#endif

				#if ROTATEUV_ON
				half2 uvC = v.uv;
				half cosAngle = cos(_RotateUvAmount);
				half sinAngle = sin(_RotateUvAmount);
				half2x2 rot = half2x2(cosAngle, -sinAngle, sinAngle, cosAngle);
				uvC -= center;
				o.uv = mul(rot, uvC);
				o.uv += center;
				#endif

				#if OUTTEX_ON
				o.uvOutTex = TRANSFORM_TEX(v.uv, _OutlineTex);
				#endif

				#if OUTDIST_ON
				o.uvOutDistTex = TRANSFORM_TEX(v.uv, _OutlineDistortTex);
				#endif

				#if DISTORT_ON
				o.uvDistTex = TRANSFORM_TEX(v.uv, _DistortTex);
				#endif

				#if FOG_ON
				UNITY_TRANSFER_FOG(o,o.vertex);
				#endif

                return o;
            }

			half3 GetPixel(in int offsetX, in int offsetY, half2 uv, sampler2D tex)
			{
				return tex2D(tex, (uv + half2(offsetX * _MainTex_TexelSize.x, offsetY * _MainTex_TexelSize.y))).rgb;
			}

            half4 frag (v2f i) : SV_Target
            {
				float2 uvRect = i.uv;
				half2 center = half2(0.5, 0.5);
				#if ATLAS_ON
				center = half2((_MaxXUV + _MinXUV) / 2.0, (_MaxYUV + _MinYUV) / 2.0);
				uvRect = half2((i.uv.x - _MinXUV) / (_MaxXUV - _MinXUV), (i.uv.y - _MinYUV) / (_MaxYUV - _MinYUV));
				#endif
				half2 centerTiled = half2(center.x *  _MainTex_ST.x, center.y *  _MainTex_ST.y);
		

				half4 col = tex2D(_MainTex, i.uv) * i.color;
				half originalAlpha = col.a;
		

				#if HITEFFECT_ON
				col.rgb = lerp(col.rgb, _HitEffectColor.rgb * _HitEffectGlow, _HitEffectBlend);
				#endif


                return col;
            }
            ENDCG
        }
    }
	CustomEditor "AllIn1SpriteShaderMaterialInspector"
	//Fallback "Sprites/Default" //Remove fallback so that any shader error is obvious to the user
}