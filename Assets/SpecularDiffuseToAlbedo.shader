Shader "Custom/SpecularDiffuseToAlbedo"
{
    Properties
    {
        _DiffuseTexture ("_DiffuseTexture", 2D) = "white" {}
        _SpecularTexture ("_SpecularTexture", 2D) = "white" {}
    }
	SubShader
	{
        Tags { "RenderType"="Opaque" }
        LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

			#include "UnityCG.cginc"

			sampler2D _DiffuseTexture;			
            float4 _DiffuseTexture_ST;
			
			sampler2D _SpecularTexture;
            float4 _SpecularTexture_ST;
			
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
			};

			v2f vert(appdata v)
			{
				v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _DiffuseTexture);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
			}


			const float3 dielectricSpecular = float3(0.04,0.04,0.04);
			const float epsilon = 1e-10;

			float solveMetallic(float diffuseBrightness, float specularBrightness, float oneMinusSpecularStrength) {
				if (specularBrightness < dielectricSpecular.x) {
					return 0.0;
				}
				float a = dielectricSpecular.x;
				float b = diffuseBrightness * oneMinusSpecularStrength / (1.0 - dielectricSpecular.x) + specularBrightness - 2.0 * dielectricSpecular.x;
				float c = dielectricSpecular.x - specularBrightness;
				float D = b * b - 4.0 * a * c;
				return clamp((-b + sqrt(D)) / (2.0 * a), 0.0, 1.0);
			}

			float4 frag(v2f i) : SV_Target
			{
				float4 diffuse = tex2D(_DiffuseTexture, i.uv);
				float3 specular = tex2D(_SpecularTexture, i.uv).xyz;

				float diffuseBrightness =
					0.299 * pow(diffuse.x, 2.0) +
					0.587 * pow(diffuse.y, 2.0) +
					0.114 * pow(diffuse.z, 2.0);

				float specularBrightness =
					0.299 * pow(specular.x, 2.0) +
					0.587 * pow(specular.y, 2.0) +
					0.114 * pow(specular.z, 2.0);

				float specularStrength = max(max(specular.x, specular.y), specular.z);
				float oneMinusSpecularStrength = 1.0 - specularStrength;

				float metallic = solveMetallic(diffuseBrightness, specularBrightness, oneMinusSpecularStrength);

				float3 baseColorFromDiffuse = diffuse.xyz * (oneMinusSpecularStrength / (1.0 - dielectricSpecular.x) / max(1.0 - metallic, epsilon));
				float3 baseColorFromSpecular = specular - (dielectricSpecular * (1.0 - metallic)) * (1.0 / max(metallic, epsilon));
				float3 baseColor = clamp(lerp(baseColorFromDiffuse, baseColorFromSpecular, metallic * metallic), 0.0, 1.0);

				return float4(baseColor, 1.0);
			}
			ENDCG
		}
	}
}
