#include "HGrassField.hlsli"

SamplerState CurrentSampler : register(s0);
Texture2D BladeTexture : register(t0);

cbuffer cbFlags : register(b0)
{
	bool bUseTexture;
	float3 Pads;
}

cbuffer cbLights : register(b1)
{
	float4	DirectionalLightDirection;
	float4	DirectionalLightColor;
	float3	AmbientLightColor;
	float	AmbientLightIntensity;
	float4	EyePosition;
}

float4 main(GS_GRASS_FIELD_OUTPUT Input) : SV_TARGET
{
	float4 Albedo;
	if (bUseTexture == true)
	{
		Albedo = BladeTexture.Sample(CurrentSampler, Input.UV);
	}
	else
	{
		Albedo = Input.Color;
	}

	float4 Result;
	float4 Ambient = CalculateAmbient(Albedo, AmbientLightColor, AmbientLightIntensity);
	float4 Directional = CalculateDirectional(Albedo, float4(1, 1, 1, 1), 1.0f, 0.0f,
		DirectionalLightColor, DirectionalLightDirection, normalize(EyePosition - float4(Input.WorldPosition, 1)), float4(Input.WorldNormal, 0));
	Result = Ambient + Directional;

	return Result;
}