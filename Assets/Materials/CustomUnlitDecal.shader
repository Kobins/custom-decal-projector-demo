Shader "Unlit/CustomUnlitDecal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AngleFade ("Angle Fade", Vector) = (1, 1, 0, 0)
        _Tint ("Tint", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Cull Off
        ZTest Greater
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        Tags { "RenderType"="Transparent"  "IgnoreProjector"="True" }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            
            // 메인 라이트 셰도우 캐스케이드를 받을 수 있는 키워드를 선언합니다.
            // 이후 TransformWorldToShadowCoord 함수에서 사용 
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE 
            // 소프트 셰도우 
            #pragma multi_compile_fragment _ _SHADOWS_SOFT 
            // GPU Instancing
            #pragma multi_compile_instancing
            
            // 내장 함수 및 프로퍼티
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // 깊이 버퍼 참조
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
            // 노말 버퍼 참조
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"

            // 라이팅
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" 
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                // HCS: Homogeneous Clip Space, 동차 클립 공간
                float4 positionHCS  : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
                
                // TransformObjectToHClip: 로컬 공간에서 클립 공간까지 한번에 쭉 보내기
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            sampler2D _NormalTex;
            float4 _NormalTex_ST;
            

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float2, _AngleFade)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Tint)
            UNITY_INSTANCING_BUFFER_END(Props)
            
            half4 frag(Varyings IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                // SV_POSITION가 가지는 값들 ...
                // - xy: 픽셀 위치, z: 비선형 깊이, w: 카메라 깊이 (orthogonal은 1.0)
                // ScaledScreenParams의 xy값으로 나눠서 [0, 1]로 정규화
                float2 depthUV = IN.positionHCS.xy / _ScaledScreenParams.xy;

                // 카메라 깊이 가져오기
                #if UNITY_REVERSED_Z
                    real depth = SampleSceneDepth(depthUV);
                #else
                    // Adjust Z to match NDC for OpenGL ([-1, 1])
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                #endif
                
                // 월드공간 좌표 가져오기
                float3 positionWS = ComputeWorldSpacePosition(depthUV, depth, UNITY_MATRIX_I_VP);
                // 월드공간 -> 로컬공간 변환
                float3 positionOS = TransformWorldToObject(positionWS);
                // 데칼 Projector 박스 범위를 벗어나는 픽셀은 클리핑
                float clipValue = 0.5 - max(max(abs(positionOS).x, abs(positionOS).y), abs(positionOS).z);
                // if(clipValue <= 0) return half4(1, 1, 1, 0.5);
                clip(clipValue);

                
                // 법선 가져오기
                float3 normalWS = SampleSceneNormals(depthUV);
                float4x4 objectToWorld = GetObjectToWorldMatrix();
                // Box forward 가져오기
                float3 projectorForward = normalize(float3(objectToWorld[0].z, objectToWorld[1].z, objectToWorld[2].z));
                // 내적
                float angleCos = dot(-projectorForward, normalWS);
                float2 angleFadeSettings = UNITY_ACCESS_INSTANCED_PROP(Props, _AngleFade);
                float angleFadeFactor = saturate(angleFadeSettings.x + angleFadeSettings.y * (-angleCos * (-angleCos - 2.0)));
                clip(angleFadeFactor);

                
                // 월드 포지션 기반으로 MainLight의 Shadow Coord 받아오기
                // Shadow Coord = Main Light 기준의 뷰 공간, Shadow Mapping 용도
                float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                // Shadow Coord 기반으로 광원 정보 & Shadow Map 값 가져오기 
                Light light = GetMainLight(shadowCoord);

                // 램버트: n dot l
                float3 lightDir = normalize(light.direction);
                float ndotl = saturate(dot(lightDir, normalWS));
                // 환경광
                float3 ambient = SampleSH(normalWS);

                
                // 텍스처 샘플링
                // 박스 로컬 좌표 기반으로 UV 구하기
                float2 uv = positionOS.xy + 0.5;
                half4 color = tex2D(_MainTex, TRANSFORM_TEX(uv, _MainTex));
                color.rgb *= UNITY_ACCESS_INSTANCED_PROP(Props, _Tint);
                color.rgb = (ndotl * light.shadowAttenuation * color.rgb) + (ambient * color.rgb);
                color.a = angleFadeFactor;
                return color;
            }
            ENDHLSL
        }
    }
}
