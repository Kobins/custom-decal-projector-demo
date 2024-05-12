Shader "Unlit/CustomUnlitDecal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NearPlaneOffset ("Near Plane Offset", float) = 0.03
    }
    SubShader
    {
        Cull Off
        ZTest Greater
//        ZClip True
        ZWrite Off
        Tags { "RenderType"="Transparent"  "IgnoreProjector"="True" }
        LOD 100

        Pass
        {
            
            Cull Front
            ZWrite Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            // 내장 함수 및 프로퍼티
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // 깊이 버퍼 참조
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            float _NearPlaneOffset;
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
            };

            struct Varyings
            {
                // HCS: Homogeneous Clip Space, 동차 클립 공간
                float4 positionHCS  : SV_POSITION;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                // TransformObjectToHClip: 로컬 공간에서 클립 공간까지 한번에 쭉 보내기
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

/*
    // Get our world-space position and its distance from the camera.
    float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
    float3 cameraToPositionWS = positionWS - _WorldSpaceCameraPos;


    float distanceToCamera = length(cameraToPositionWS) * sign(dot(unity_CameraToWorld._m02_m12_m22, cameraToPositionWS));
    // float distanceToCamera = dot(unity_CameraToWorld._m02_m12_m22, cameraToPositionWS);
    float distanceBeforeNearPlane = (distanceToCamera - _NearPlaneOffset) - _ProjectionParams.y;

    // If our vertex is beyond the far plane, then we pull it back in.
    if (distanceBeforeNearPlane <= 0.0f)
    {
        // Our new distance is the previous distance minus the how far past the plane we are.
        // We use _FarPlaneOffset to provide a material configurable further nudge.
        float correctedDistance = distanceToCamera - distanceBeforeNearPlane + _NearPlaneOffset;
        float3 dirCameraToPosition = normalize(cameraToPositionWS);
        float3 correctedPositionWS = _WorldSpaceCameraPos + (dirCameraToPosition * correctedDistance);
        
        // Transform the corrected world-space position to clip space.
        OUT.positionHCS = TransformWorldToHClip(correctedPositionWS);
    }
     */           
                return OUT;
            }

            sampler2D _MainTex;
            float4 _MainTex_ST;

            half4 frag(Varyings IN) : SV_Target
            {
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
                float3 positionOS = mul(unity_WorldToObject, float4(positionWS, 1.0));
                // 데칼 Projector 박스 범위를 벗어나는 픽셀은 클리핑
                float clipValue = 0.5 - max(max(abs(positionOS).x, abs(positionOS).y), abs(positionOS).z);
                // if(clipValue <= 0) return half4(1, 1, 1, 0.5);
                clip(clipValue);

                // 박스 로컬 좌표 기반으로 UV 구하기
                float2 uv = positionOS.xy + 0.5;
                // 텍스처 샘플링
                half4 color = tex2D(_MainTex, TRANSFORM_TEX(uv, _MainTex));
                return color;
            }
            ENDHLSL
        }
    }
}
