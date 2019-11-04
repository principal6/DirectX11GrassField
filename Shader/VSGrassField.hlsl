#include "HGrassField.hlsli"

cbuffer cbSpace : register(b0)
{
	float4x4 ViewProjection;
	float4x4 World;
}

VS_GRASS_FIELD_OUTPUT main(VS_GRASS_FIELD_INPUT Input)
{
	VS_GRASS_FIELD_OUTPUT Output = Input;

	Output.GroundPosition = float4(mul(Input.GroundPosition, World).xyz, 1);
	Output.TipPosition = float4(mul(Input.TipPosition, World).xyz, 1);
	
	return Output;
}