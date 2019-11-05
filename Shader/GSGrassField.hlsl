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
	OutputElement = mul(OutputElement, ViewProjection);
	return OutputElement;
}

[maxvertexcount(KSegmentCount * 6 - 3)] // @important: the tip segment only has one triangle, not two.
void main(point VS_GRASS_FIELD_OUTPUT Input[1], inout TriangleStream<GS_GRASS_FIELD_OUTPUT> Output)
{
	const float KBladeHalfWidth = BladeWidth / 2.0f;
	const float KBladeDoubleWidth = BladeWidth * 2.0f;
	const float4 KUp = float4(0, 1, 0, 0);
	const float4 KGroundPosition = float4(Input[0].GroundPosition.xyz, 1);
	const float4 KTipPosition = Input[0].TipPosition;
	const float4 KGroundToTipOnGround = KTipPosition.xwzw - KGroundPosition.xwzw;
	const float KYBottomToTip = KTipPosition.y - Input[0].GroundPosition.y;
	const float4 KLeftDirection = float4(cross(normalize(KGroundToTipOnGround.xyz), float3(0, 1, 0)), 0);
	const float4 KRightDirection = -KLeftDirection;
	const float4 KSideYOffset = float4(0, -0.5f, 0, 0);
	
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
		float SideDisplacementLength;

		if (THigher < 1.0f)
		{
			// Left segment

			// Upper left
			SideDisplacement = Slerp(KLeftDirection * KBladeHalfWidth + KSideYOffset, KUp, THigherSquare) - KSideYOffset;
			SideDisplacementLength = dot(SideDisplacement, KLeftDirection);
			OutputElement.Position = GetBladeTrianglePosition(SlerpHigher, SideDisplacement, KYBottomToTip, THigher);
			OutputElement.Color = lerp(KGroundColor, KTipColor, THigher);
			OutputElement.UV = float2(0.5f - SideDisplacementLength / KBladeDoubleWidth, 1.0f - THigher);
			Output.Append(OutputElement);


			// Upper right
			SideDisplacement = Slerp(KRightDirection * KBladeHalfWidth + KSideYOffset, KUp, THigherSquare) - KSideYOffset;
			SideDisplacementLength = dot(SideDisplacement, KRightDirection);
			OutputElement.Position = GetBladeTrianglePosition(SlerpHigher, SideDisplacement, KYBottomToTip, THigher);
			OutputElement.Color = lerp(KGroundColor, KTipColor, THigher);
			OutputElement.UV = float2(0.5f + SideDisplacementLength / KBladeDoubleWidth, 1.0f - THigher);
			Output.Append(OutputElement);


			// Lower left
			SideDisplacement = Slerp(KLeftDirection * KBladeHalfWidth + KSideYOffset, KUp, TLowerSquare) - KSideYOffset;
			SideDisplacementLength = dot(SideDisplacement, KLeftDirection);
			OutputElement.Position = GetBladeTrianglePosition(SlerpLower, SideDisplacement, KYBottomToTip, TLower);
			OutputElement.Color = lerp(KGroundColor, KTipColor, TLower);
			OutputElement.UV = float2(0.5f - SideDisplacementLength / KBladeDoubleWidth, 1.0f - TLower);
			Output.Append(OutputElement);
			Output.RestartStrip();
		}

		{
			// Right segment && tip segment

			// Upper right
			SideDisplacement = Slerp(KRightDirection * KBladeHalfWidth + KSideYOffset, KUp, THigherSquare) - KSideYOffset;
			SideDisplacementLength = dot(SideDisplacement, KRightDirection);
			OutputElement.Position = GetBladeTrianglePosition(SlerpHigher, SideDisplacement, KYBottomToTip, THigher);
			OutputElement.Color = lerp(KGroundColor, KTipColor, THigher);
			OutputElement.UV = float2(0.5f + SideDisplacementLength / KBladeDoubleWidth, 1.0f - THigher);
			Output.Append(OutputElement);


			// Lower right
			SideDisplacement = Slerp(KRightDirection * KBladeHalfWidth + KSideYOffset, KUp, TLowerSquare) - KSideYOffset;
			SideDisplacementLength = dot(SideDisplacement, KRightDirection);
			OutputElement.Position = GetBladeTrianglePosition(SlerpLower, SideDisplacement, KYBottomToTip, TLower);
			OutputElement.Color = lerp(KGroundColor, KTipColor, TLower);
			OutputElement.UV = float2(0.5f + SideDisplacementLength / KBladeDoubleWidth, 1.0f - TLower);
			Output.Append(OutputElement);


			// Lower left
			SideDisplacement = Slerp(KLeftDirection * KBladeHalfWidth + KSideYOffset, KUp, TLowerSquare) - KSideYOffset;
			SideDisplacementLength = dot(SideDisplacement, KLeftDirection);
			OutputElement.Position = GetBladeTrianglePosition(SlerpLower, SideDisplacement, KYBottomToTip, TLower);
			OutputElement.Color = lerp(KGroundColor, KTipColor, TLower);
			OutputElement.UV = float2(0.5f - SideDisplacementLength / KBladeDoubleWidth, 1.0f - TLower);
			Output.Append(OutputElement);
			Output.RestartStrip();
		}
	}
}