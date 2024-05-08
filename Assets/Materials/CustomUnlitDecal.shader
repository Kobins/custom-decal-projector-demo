Shader "Unlit/CustomUnlitDecal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent"  "IgnoreProjector"="True" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            // #include "UnityShaderVariables.cginc"
            

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 screenPosition : TEXCOORD1;
                float3 camRelativeWorldPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.screenPosition = ComputeScreenPos(o.vertex);
                o.camRelativeWorldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz - _WorldSpaceCameraPos;
                return o;
            }
            
            float4 ComputeClipSpacePosition(float2 positionNDC, float deviceDepth)
            {
                float4 positionCS = float4(positionNDC * 2.0 - 1.0, deviceDepth, 1.0);

            #if UNITY_UV_STARTS_AT_TOP
                // Our world space, view space, screen space and NDC space are Y-up.
                // Our clip space is flipped upside-down due to poor legacy Unity design.
                // The flip is baked into the projection matrix, so we only have to flip
                // manually when going from CS to NDC and back.
                positionCS.y = -positionCS.y;
            #endif

                return positionCS;
            }

            float3 ComputeWorldSpacePosition(float2 positionSS, float depth, float4x4 invViewProjectionMatrix)
            {
                float4 positionCS  = ComputeClipSpacePosition(positionSS, depth);
                float4 hpositionWS = mul(invViewProjectionMatrix, positionCS);
                return hpositionWS.xyz / hpositionWS.w;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float2 screenPositionUV = i.screenPosition.xy / i.screenPosition.w;
                // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPositionUV);

                // {
                //     // get linear depth from the depth
                //     float sceneZ = LinearEyeDepth(depth);
                //
                //     // calculate the view plane vector
                //     // note: Something like normalize(i.camRelativeWorldPos.xyz) is what you'll see other
                //     // examples do, but that is wrong! You need a vector that at a 1 unit view depth, not
                //     // a1 unit magnitude.
                //     float3 viewPlane = i.camRelativeWorldPos.xyz / dot(i.camRelativeWorldPos.xyz, unity_WorldToCamera._m20_m21_m22);
                //     
                //     // calculate the world position
                //     // multiply the view plane by the linear depth to get the camera relative world space position
                //     // add the world space camera position to get the world space position from the depth texture
                //     float3 positionWS = viewPlane * sceneZ + _WorldSpaceCameraPos;
                //     positionWS = mul(unity_CameraToWorld, float4(positionWS, 1.0));
                // }
                
                // float2 zw = _ScreenParams.zw;
                // zw.x -= 1;
                // zw.y -= 1;
                float3 positionWS = ComputeWorldSpacePosition(screen, depth, mul(unity_CameraInvProjection, UNITY_MATRIX_I_V));
                float3 positionDS = mul(unity_WorldToObject, float4(positionWS, 1.0));
                positionDS = positionDS * float3(1.0, -1.0, 1.0); 
                // call clip as early as possible
                float clipValue = 0.5 - max(max(abs(positionDS).x, abs(positionDS).y), abs(positionDS).z);
                // clip(clipValue);

                // return clipValue;
                // return sceneZ;
                // return fixed4(1, 0, 0, 1);
                    col.rgb = saturate(2.0 - abs(frac(positionWS) * 2.0 - 1.0) * 100.0);
 
                return col;
            }
            ENDCG
        }
    }
}
