#include "HGrassField.hlsli"

static const int KSegmentCount = 5; // This value must not be ZERO

cbuffer cbSpace : register(b0)
{
	float4x4 ViewProjection;
}

cbuffer cbGrass : register(b1)
{
	float BladeWidth;
	float3 Pads;
}

static float4 GetBladeTrianglePosition(float4 BasePosition, float4 SideDisplacement, float YDisplacement, float T)
{
	float4 OutputElement;
	OutputElement = BasePosition + SideDisplacement;
	OutputElement.y += YDisplacement * T;
	return OutputElement;
}

static float3 GetNormal(float4 V0, float4 V1, float4 V2)
{
	float4 Edge01 = normalize(V1 - V0);
	float4 Edge02 = normalize(V2 - V0);
	return normalize(cross(Edge01.xyz, Edge02.xyz));
}

[maxvertexcount(KSegmentCount * 6 * 2 - 3)] // @important: (-3) the tip segment only has one triangle, not two.
void main(point VS_GRASS_FIELD_OUTPUT Input[1], inout TriangleStream<GS_GRASS_FIELD_OUTPUT> Output)
{
	const float KBladeHalfWidth = BladeWidth / 2.0f;
	const float KBladeDoubleWidth = BladeWidth * 2.0f;
	const float4 KUp = float4(0, 1, 0, 0);
	const float4 KGroundPosition = float4(Input[0].GroundPosition.xyz, 1);
	const float4 KTipPosition = Input[0].TipPosition;
	const float4 KGroundToTipOnGround = KTipPosition.xwzw - KGroundPosition.xwzw;
	const float3 KGroundNormal = normalize(-KGroundToTipOnGround.xyz);
	const float KYBottomToTip = KTipPosition.y - Input[0].GroundPosition.y;
	const float4 KLeftDirection = normalize(float4(cross(normalize(KGroundToTipOnGround.xyz), float3(0, 1, 0)), 0));
	const float4 KRightDirection = -KLeftDirection;
	const float4 KSideYOffset = float4(0, -BladeWidth, 0, 0);
	
	const float4 P0 = KGroundPosition - KGroundToTipOnGround;
	const float4 P1 = KTipPosition - KGroundToTipOnGround;
	
	const float4 KGroundColor = Input[0].GroundColor;
	const float4 KTipColor = Input[0].TipColor;

	GS_GRASS_FIELD_OUTPUT OutputElement;
	for (int iSegment = 0; iSegment < KSegmentCount; ++iSegment)
	{
		float TLower = (float)(iSegment + 0) / (float)KSegmentCount;
		float THigher = (float)(iSegment + 1) / (float)KSegmentCount;
		float TLowerSquare = TLower * TLower;
		float THigherSquare = THigher * THigher;

		float4 SlerpLower = Slerp(P0, P1, TLower) + KGroundToTipOnGround;
		float4 SlerpHigher = Slerp(P0, P1, THigher) + KGroundToTipOnGround;

		float4 SideDisplacement;
		float SideDisplacementLength0;
		float SideDisplacementLength1;
		float SideDisplacementLength2;

		if (THigher < 1.0f)
		{
			// ### Left segment

			// ## Front face
			// # Upper left
			SideDisplacement = Slerp(KLeftDirection * KBladeHalfWidth + KSideYOffset, KUp, THigherSquare) - KSideYOffset;
			SideDisplacementLength0 = dot(SideDisplacement, KLeftDirection);
			float4 V0 = GetBladeTrianglePosition(SlerpHigher, SideDisplacement, KYBottomToTip, THigherSquare);

			// # Upper right
			SideDisplacement = Slerp(KRightDirection * KBladeHalfWidth + KSideYOffset, KUp, THigherSquare) - KSideYOffset;
			SideDisplacementLength1 = dot(SideDisplacement, KRightDirection);
			float4 V1 = GetBladeTrianglePosition(SlerpHigher, SideDisplacement, KYBottomToTip, THigherSquare);

			// # Lower left
			SideDisplacement = Slerp(KLeftDirection * KBladeHalfWidth + KSideYOffset, KUp, TLowerSquare) - KSideYOffset;
			SideDisplacementLength2 = dot(SideDisplacement, KLeftDirection);
			float4 V2 = GetBladeTrianglePosition(SlerpLower, SideDisplacement, KYBottomToTip, TLowerSquare);

			float3 NLower = Slerp(float4(KGroundNormal, 0), KUp, TLower).xyz;
			float3 NHigher = Slerp(float4(KGroundNormal, 0), KUp, THigher).xyz;

			// # V0 Upper left
			OutputElement.Position = mul(V0, ViewProjection);
			OutputElement.Color = lerp(KGroundColor, KTipColor, THigher);
			OutputElement.UV = float2(0.5f - SideDisplacementLength0 / KBladeDoubleWidth, 1.0f - THigher);
			OutputElement.WorldPosition = V0.xyz;
			OutputElement.WorldNormal = NHigher;
			Output.Append(OutputElement);

			// # V1 Upper right
			OutputElement.Position = mul(V1, ViewProjection);
			OutputElement.Color = lerp(KGroundColor, KTipColor, THigher);
			OutputElement.UV = float2(0.5f + SideDisplacementLength1 / KBladeDoubleWidth, 1.0f - THigher);
			OutputElement.WorldPosition = V1.xyz;
			OutputElement.WorldNormal = NHigher;
			Output.Append(OutputElement);

			// # V2 Lower left
			OutputElement.Position = mul(V2, ViewProjection);
			OutputElement.Color = lerp(KGroundColor, KTipColor, TLower);
			OutputElement.UV = float2(0.5f - SideDisplacementLength2 / KBladeDoubleWidth, 1.0f - TLower);
			OutputElement.WorldPosition = V2.xyz;
			OutputElement.WorldNormal = NLower;
			Output.Append(OutputElement);

			Output.RestartStrip();

			// ## Back face
			// # V1 Upper right
			OutputElement.Position = mul(V1, ViewProjection);
			OutputElement.Color = lerp(KGroundColor, KTipColor, THigher);
			OutputElement.UV = float2(0.5f + SideDisplacementLength1 / KBladeDoubleWidth, 1.0f - THigher);
			OutputElement.WorldPosition = V1.xyz;
			OutputElement.WorldNormal = -NHigher;
			Output.Append(OutputElement);

			// # V0 Upper left
			OutputElement.Position = mul(V0, ViewProjection);
			OutputElement.Color = lerp(KGroundColor, KTipColor, THigher);
			OutputElement.UV = float2(0.5f - SideDisplacementLength0 / KBladeDoubleWidth, 1.0f - THigher);
			OutputElement.WorldPosition = V0.xyz;
			OutputElement.WorldNormal = -NHigher;
			Output.Append(OutputElement);

			// # V2 Lower left
			OutputElement.Position = mul(V2, ViewProjection);
			OutputElement.Color = lerp(KGroundColor, KTipColor, TLower);
			OutputElement.UV = float2(0.5f - SideDisplacementLength2 / KBladeDoubleWidth, 1.0f - TLower);
			OutputElement.WorldPosition = V2.xyz;
			OutputElement.WorldNormal = -NLower;
			Output.Append(OutputElement);

			Output.RestartStrip();
		}

		{
			// ### Right segment && tip segment

			// ## Front face
			// # Upper right
			SideDisplacement = Slerp(KRightDirection * KBladeHalfWidth + KSideYOffset, KUp, THigherSquare) - KSideYOffset;
			SideDisplacementLength0 = dot(SideDisplacement, KRightDirection);
			float4 V0 = GetBladeTrianglePosition(SlerpHigher, SideDisplacement, KYBottomToTip, THigherSquare);

			// # Lower right
			SideDisplacement = Slerp(KRightDirection * KBladeHalfWidth + KSideYOffset, KUp, TLowerSquare) - KSideYOffset;
			SideDisplacementLength1 = dot(SideDisplacement, KRightDirection);
			float4 V1 = GetBladeTrianglePosition(SlerpLower, SideDisplacement, KYBottomToTip, TLowerSquare);

			// # Lower left
			SideDisplacement = Slerp(KLeftDirection * KBladeHalfWidth + KSideYOffset, KUp, TLowerSquare) - KSideYOffset;
			SideDisplacementLength2 = dot(SideDisplacement, KLeftDirection);
			float4 V2 = GetBladeTrianglePosition(SlerpLower, SideDisplacement, KYBottomToTip, TLowerSquare);

			float3 NLower = Slerp(float4(KGroundNormal, 0), KUp, TLower).xyz;
			float3 NHigher = Slerp(float4(KGroundNormal, 0), KUp, THigher).xyz;

			// # V0 Upper right
			OutputElement.Position = mul(V0, ViewProjection);
			OutputElement.Color = lerp(KGroundColor, KTipColor, THigher);
			OutputElement.UV = float2(0.5f + SideDisplacementLength0 / KBladeDoubleWidth, 1.0f - THigher);
			OutputElement.WorldPosition = V0.xyz;
			OutputElement.WorldNormal = NHigher;
			Output.Append(OutputElement);

			// # V1 Lower right
			OutputElement.Position = mul(V1, ViewProjection);
			OutputElement.Color = lerp(KGroundColor, KTipColor, TLower);
			OutputElement.UV = float2(0.5f + SideDisplacementLength1 / KBladeDoubleWidth, 1.0f - TLower);
			OutputElement.WorldPosition = V1.xyz;
			OutputElement.WorldNormal = NLower;
			Output.Append(OutputElement);

			// # V2 Lower left
			OutputElement.Position = mul(V2, ViewProjection);
			OutputElement.Color = lerp(KGroundColor, KTipColor, TLower);
			OutputElement.UV = float2(0.5f - SideDisplacementLength2 / KBladeDoubleWidth, 1.0f - TLower);
			OutputElement.WorldPosition = V2.xyz;
			OutputElement.WorldNormal = NLower;
			Output.Append(OutputElement);

			Output.RestartStrip();

			// ## Back face
			// # V0 Upper right
			OutputElement.Position = mul(V0, ViewProjection);
			OutputElement.Color = lerp(KGroundColor, KTipColor, THigher);
			OutputElement.UV = float2(0.5f + SideDisplacementLength0 / KBladeDoubleWidth, 1.0f - THigher);
			OutputElement.WorldPosition = V0.xyz;
			OutputElement.WorldNormal = -NHigher;
			Output.Append(OutputElement);

			// # V2 Lower left
			OutputElement.Position = mul(V2, ViewProjection);
			OutputElement.Color = lerp(KGroundColor, KTipColor, TLower);
			OutputElement.UV = float2(0.5f - SideDisplacementLength2 / KBladeDoubleWidth, 1.0f - TLower);
			OutputElement.WorldPosition = V2.xyz;
			OutputElement.WorldNormal = -NLower;
			Output.Append(OutputElement);

			// # V1 Lower right
			OutputElement.Position = mul(V1, ViewProjection);
			OutputElement.Color = lerp(KGroundColor, KTipColor, TLower);
			OutputElement.UV = float2(0.5f + SideDisplacementLength1 / KBladeDoubleWidth, 1.0f - TLower);
			OutputElement.WorldPosition = V1.xyz;
			OutputElement.WorldNormal = -NLower;
			Output.Append(OutputElement);

			Output.RestartStrip();
		}
	}
}