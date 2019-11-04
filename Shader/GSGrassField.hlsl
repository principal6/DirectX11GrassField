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
	const float4 KLeftDirectionRightYDisplacement = float4(0, 0.5f, 0, 0);
	
	const float4 P0 = KGroundPosition - KGroundToTipOnGround;
	const float4 P1 = KTipPosition - KGroundToTipOnGround;
	
	const float4 KGroundColor = Input[0].GroundColor;
	const float4 KTipColor = Input[0].TipColor;

	GS_GRASS_FIELD_OUTPUT Result;
	
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
			Result.Position = SlerpHigher;

			SideDisplacement = Slerp(KLeftDirection * KBladeHalfWidth - KLeftDirectionRightYDisplacement, KUp, THigherSquare) + 
				KLeftDirectionRightYDisplacement;
			Result.Position += SideDisplacement;

			Result.Position.y += KYBottomToTip * THigher;
			Result.Position = mul(Result.Position, ViewProjection);

			Result.Color = lerp(KGroundColor, KTipColor, THigher);

			SideDisplacementLength = dot(SideDisplacement, KLeftDirection);
			Result.UV = float2(0.5f - SideDisplacementLength / KBladeDoubleWidth, 1.0f - THigher);
			Output.Append(Result);


			// Upper right
			Result.Position = SlerpHigher;

			SideDisplacement = Slerp(KRightDirection * KBladeHalfWidth - KLeftDirectionRightYDisplacement, KUp, THigherSquare) +
				KLeftDirectionRightYDisplacement;
			Result.Position += SideDisplacement;
			Result.Position.y += KYBottomToTip * THigher;
			Result.Position = mul(Result.Position, ViewProjection);

			Result.Color = lerp(KGroundColor, KTipColor, THigher);

			SideDisplacementLength = dot(SideDisplacement, KRightDirection);
			Result.UV = float2(0.5f + SideDisplacementLength / KBladeDoubleWidth, 1.0f - THigher);
			Output.Append(Result);


			// Lower left
			Result.Position = SlerpLower;
			SideDisplacement = Slerp(KLeftDirection * KBladeHalfWidth - KLeftDirectionRightYDisplacement, KUp, TLowerSquare) + 
				KLeftDirectionRightYDisplacement;
			Result.Position += SideDisplacement;
			Result.Position.y += KYBottomToTip * TLower;
			Result.Position = mul(Result.Position, ViewProjection);

			Result.Color = lerp(KGroundColor, KTipColor, TLower);

			SideDisplacementLength = dot(SideDisplacement, KLeftDirection);
			Result.UV = float2(0.5f - SideDisplacementLength / KBladeDoubleWidth, 1.0f - TLower);
			Output.Append(Result);
			Output.RestartStrip();
		}

		{
			// Right segment && tip segment

			// Upper right
			Result.Position = SlerpHigher;

			SideDisplacement = Slerp(KRightDirection * KBladeHalfWidth - KLeftDirectionRightYDisplacement, KUp, THigherSquare) + 
				KLeftDirectionRightYDisplacement;
			Result.Position += SideDisplacement;
			Result.Position.y += KYBottomToTip * THigher;
			Result.Position = mul(Result.Position, ViewProjection);

			Result.Color = lerp(KGroundColor, KTipColor, THigher);

			SideDisplacementLength = dot(SideDisplacement, KRightDirection);
			Result.UV = float2(0.5f + SideDisplacementLength / KBladeDoubleWidth, 1.0f - THigher);
			Output.Append(Result);


			// Lower right
			Result.Position = SlerpLower;

			SideDisplacement = Slerp(KRightDirection * KBladeHalfWidth - KLeftDirectionRightYDisplacement, KUp, TLowerSquare) + 
				KLeftDirectionRightYDisplacement;
			Result.Position += SideDisplacement;
			Result.Position.y += KYBottomToTip * TLower;
			Result.Position = mul(Result.Position, ViewProjection);

			Result.Color = lerp(KGroundColor, KTipColor, TLower);

			SideDisplacementLength = dot(SideDisplacement, KRightDirection);
			Result.UV = float2(0.5f + SideDisplacementLength / KBladeDoubleWidth, 1.0f - TLower);
			Output.Append(Result);


			// Lower left
			Result.Position = SlerpLower;

			SideDisplacement = Slerp(KLeftDirection * KBladeHalfWidth - KLeftDirectionRightYDisplacement, KUp, TLowerSquare) + 
				KLeftDirectionRightYDisplacement;
			Result.Position += SideDisplacement;
			Result.Position.y += KYBottomToTip * TLower;
			Result.Position = mul(Result.Position, ViewProjection);

			Result.Color = lerp(KGroundColor, KTipColor, TLower);

			SideDisplacementLength = dot(SideDisplacement, KLeftDirection);
			Result.UV = float2(0.5f - SideDisplacementLength / KBladeDoubleWidth, 1.0f - TLower);
			Output.Append(Result);
			Output.RestartStrip();
		}
	}
}