#include "Header.hlsli"

cbuffer cbCamera : register(b0)
{
	float4 EyePosition;
};

cbuffer cbTessFactor : register(b1)
{
	float TessFactor;
	float3 Pads;
}

HS_CONSTANT_DATA_OUTPUT CalcHSPatchConstants(InputPatch<VS_OUTPUT, 3> Patch, uint PatchID : SV_PrimitiveID)
{
	HS_CONSTANT_DATA_OUTPUT Output;

	const float KEdgeMax = 0.5f * TessFactor;
	const float KInsideMax = 1.0f * TessFactor;
	float4 CenterPosition = (Patch[0].WorldPosition + Patch[1].WorldPosition + Patch[2].WorldPosition) / 3.0f;
	float Distance = distance(CenterPosition, EyePosition);
	float Edge = KEdgeMax;
	float Inside = KInsideMax / Distance;
	
	if (Distance >= 75.0f) Edge = Inside = 0.0f;

	Output.EdgeTessFactor[0] = Edge;
	Output.EdgeTessFactor[1] = Edge;
	Output.EdgeTessFactor[2] = Edge;
	Output.InsideTessFactor = Inside;

	return Output;
}

[domain("tri")]
[maxtessfactor(64.0f)]
[outputcontrolpoints(3)]
[outputtopology("triangle_cw")]
[partitioning("fractional_even")]
[patchconstantfunc("CalcHSPatchConstants")]
HS_OUTPUT main(InputPatch<VS_OUTPUT, 3> Patch, uint i : SV_OutputControlPointID, uint PatchID : SV_PrimitiveID)
{
	HS_OUTPUT Output;

	Output = Patch[i];

	return Output;
}
