#include "HGrassField.hlsli"

SamplerState CurrentSampler : register(s0);
Texture2D BladeTexture : register(t0);

cbuffer cbFlags : register(b0)
{
	bool bUseTexture;
	float3 Pads;
}

/*
cbuffer cbLights : register(b1)
{
	float4	DirectionalLightDirection;
	float4	DirectionalLightColor;
	float3	AmbientLightColor;
	float	AmbientLightIntensity;
	float4	EyePosition;
}
*/

float4 main(GS_GRASS_FIELD_OUTPUT Input) : SV_TARGET
{
	if (bUseTexture == true)
	{
		return BladeTexture.Sample(CurrentSampler, Input.UV);
	}
	else
	{
		return Input.Color;
	}
}