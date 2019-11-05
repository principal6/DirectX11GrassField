#include "HShared.hlsli"

struct VS_GRASS_FIELD_INPUT
{
	float4	GroundPosition	: POSITION0;
	float4	TipPosition		: POSITION1;
	float4	GroundColor		: COLOR0;
	float4	TipColor		: COLOR1;
};

struct VS_GRASS_FIELD_OUTPUT
{
	float4	GroundPosition	: SV_POSITION;
	float4	TipPosition		: POSITION;
	float4	GroundColor		: COLOR0;
	float4	TipColor		: COLOR1;
};

struct GS_GRASS_FIELD_OUTPUT
{
	float4	Position		: SV_POSITION;
	float4	Color			: COLOR;
	float2	UV				: TEXCOORD;
	float3	WorldPosition	: POSITION;
	float3	WorldNormal		: NORMAL;
};