Shader "NMG/Survivor/PoisonMovement"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}	//0
		_Color("Main Color", Color) = (1,1,1,1)		//1
		_Alpha("General Alpha",  Range(0,1)) = 1	//2

       
		_WaveAmount("Wave Amount", Range(0, 25)) = 7 //94
		_WaveSpeed("Wave Speed", Range(0, 25)) = 10 //95
		_WaveStrength("Wave Strength", Range(0, 25)) = 7.5 //96
		_WaveX("Wave X Axis", Range(0, 1)) = 0 //97
		_WaveY("Wave Y Axis", Range(0, 1)) = 0.5 //98

		
		

		_DistortTex("Distortion Texture", 2D) = "white" {} //109
		_DistortAmount("Distortion Amount", Range(0,2)) = 0.5 //110
		_DistortTexXSpeed("Scroll speed X", Range(-50,50)) = 5 //111
		_DistortTexYSpeed("Scroll speed Y", Range(-50,50)) = 5 //112


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

			#pragma shader_feature WAVEUV_ON
			#pragma shader_feature DISTORT_ON

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

			
			#if WAVEUV_ON
			float _WaveAmount, _WaveSpeed, _WaveStrength, _WaveX, _WaveY;
			#endif


			#if DISTORT_ON
			sampler2D _DistortTex;
			half4 _DistortTex_ST;
			half _DistortTexXSpeed, _DistortTexYSpeed, _DistortAmount;
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


				#if DISTORT_ON
				o.uvDistTex = TRANSFORM_TEX(v.uv, _DistortTex);
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

				

				#if DISTORT_ON
				#if ATLAS_ON
            	i.uvDistTex.x = i.uvDistTex.x * (1 / (_MaxXUV - _MinXUV));
				i.uvDistTex.y = i.uvDistTex.y * (1 / (_MaxYUV - _MinYUV));
				#endif
            	i.uvDistTex.x += ((_Time + _RandomSeed) * _DistortTexXSpeed) % 1;
				i.uvDistTex.y += ((_Time + _RandomSeed) * _DistortTexYSpeed) % 1;
				half distortAmnt = (tex2D(_DistortTex, i.uvDistTex).r - 0.5) * 0.2 * _DistortAmount;
				i.uv.x += distortAmnt;
				i.uv.y += distortAmnt;
				#endif

				#if WAVEUV_ON
				float2 uvWave = half2(_WaveX *  _MainTex_ST.x, _WaveY *  _MainTex_ST.y) - i.uv;
            	uvWave %= 1;
				#if ATLAS_ON
				uvWave = half2(_WaveX, _WaveY) - uvRect;
				#endif
				uvWave.x *= _ScreenParams.x / _ScreenParams.y;
            	float waveTime = _Time.y + _RandomSeed;
				float angWave = (sqrt(dot(uvWave, uvWave)) * _WaveAmount) - ((waveTime *  _WaveSpeed));
				i.uv = i.uv + uvWave * sin(angWave) * (_WaveStrength / 1000.0);
				#endif
				

				half4 col = tex2D(_MainTex, i.uv) * i.color;
				half originalAlpha = col.a;
				

				half luminance = 0;
							

				//OUTLINE-------------------------------------------------------------
				#if OUTBASE_ON
					#ifdef OUTBASEPIXELPERF_ON
					half2 destUv = half2(_OutlinePixelWidth * _MainTex_TexelSize.x, _OutlinePixelWidth * _MainTex_TexelSize.y);
					#else
					half2 destUv = half2(_OutlineWidth * _MainTex_TexelSize.x * 200, _OutlineWidth * _MainTex_TexelSize.y * 200);
					#endif

					#if OUTDIST_ON
					i.uvOutDistTex.x += ((_Time + _RandomSeed) * _OutlineDistortTexXSpeed) % 1;
					i.uvOutDistTex.y += ((_Time + _RandomSeed) * _OutlineDistortTexYSpeed) % 1;
					#if ATLAS_ON
					i.uvOutDistTex = half2((i.uvOutDistTex.x - _MinXUV) / (_MaxXUV - _MinXUV), (i.uvOutDistTex.y - _MinYUV) / (_MaxYUV - _MinYUV));
					#endif
					half outDistortAmnt = (tex2D(_OutlineDistortTex, i.uvOutDistTex).r - 0.5) * 0.2 * _OutlineDistortAmount;
					destUv.x += outDistortAmnt;
					destUv.y += outDistortAmnt;
					#endif

					half spriteLeft = tex2D(_MainTex, i.uv + half2(destUv.x, 0)).a;
					half spriteRight = tex2D(_MainTex, i.uv - half2(destUv.x, 0)).a;
					half spriteBottom = tex2D(_MainTex, i.uv + half2(0, destUv.y)).a;
					half spriteTop = tex2D(_MainTex, i.uv - half2(0, destUv.y)).a;
					half result = spriteLeft + spriteRight + spriteBottom + spriteTop;

					#if OUTBASE8DIR_ON
					half spriteTopLeft = tex2D(_MainTex, i.uv + half2(destUv.x, destUv.y)).a;
					half spriteTopRight = tex2D(_MainTex, i.uv + half2(-destUv.x, destUv.y)).a;
					half spriteBotLeft = tex2D(_MainTex, i.uv + half2(destUv.x, -destUv.y)).a;
					half spriteBotRight = tex2D(_MainTex, i.uv + half2(-destUv.x, -destUv.y)).a;
					result = result + spriteTopLeft + spriteTopRight + spriteBotLeft + spriteBotRight;
					#endif
					
					result = step(0.05, saturate(result));

					#if OUTTEX_ON
					i.uvOutTex.x += ((_Time + _RandomSeed) * _OutlineTexXSpeed) % 1;
					i.uvOutTex.y += ((_Time + _RandomSeed) * _OutlineTexYSpeed) % 1;
					#if ATLAS_ON
					i.uvOutTex = half2((i.uvOutTex.x - _MinXUV) / (_MaxXUV - _MinXUV), (i.uvOutTex.y - _MinYUV) / (_MaxYUV - _MinYUV));
					#endif
					half4 tempOutColor = tex2D(_OutlineTex, i.uvOutTex);
					tempOutColor *= _OutlineColor;
					_OutlineColor = tempOutColor;
					#endif

					result *= (1 - originalAlpha) * _OutlineAlpha;

					half4 outline = _OutlineColor;
					outline.rgb *= _OutlineGlow;
					outline.a = result;
					#if ONLYOUTLINE_ON
					col = outline;
					#else
					col = lerp(col, outline, result);
					#endif
				#endif
				//-----------------------------------------------------------------------------

				

				col.a *= _Alpha;

				

				col *= _Color;

				

                return col;
            }
            ENDCG
        }
    }
	CustomEditor "AllIn1SpriteShaderMaterialInspector"
	//Fallback "Sprites/Default" //Remove fallback so that any shader error is obvious to the user
}