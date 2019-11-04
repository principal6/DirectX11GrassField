#include "GrassField.h"
#include "Game.h"

void CGrassField::Create(size_t BladeCount, float MinBladeLength, float MaxBladeLength, float BladeWidth, 
	float MinBendingAngleRadian, float MaxBendingAngleRadian, float BladeDisplacementFromCenter,
	const XMVECTOR& GroundSegmentColor, const XMVECTOR& TipSegmentColor, const char* BladeTextureFileName)
{
	srand(static_cast<unsigned int>(GetTickCount64()));

	m_BladeCount = BladeCount;
	m_BladeCount = max(min(m_BladeCount, KMaxBladeCount), KMinBladeCount);

	BladeWidth = max(min(BladeWidth, KBladeWidthMaxLimit), KBladeWidthMinLimit);
	m_cbGSGrassData.BladeWidth = BladeWidth;
	m_PtrGame->UpdateGSGrass(m_cbGSGrassData);

	const XMVECTOR KFirstDirection{ 0, 0, 1, 0 };
	const XMVECTOR KUpDirection{ 0, 1, 0, 0 };
	for (size_t iBlade = 0; iBlade < m_BladeCount; ++iBlade)
	{
		const float KT{ (float)iBlade / (float)m_BladeCount };
		const float KTheta{ KT * XM_2PI };

		m_vVertices.emplace_back();

		XMMATRIX RotationMatrix{ XMMatrixRotationY(KTheta) };
		XMVECTOR CurrentDirection{ XMVector3TransformNormal(KFirstDirection, RotationMatrix) };

		m_vVertices.back().GroundPosition = CurrentDirection * BladeDisplacementFromCenter;

		float BendingAngle{ GetRandom(MinBendingAngleRadian, MaxBendingAngleRadian) };
		float TipHeight{ GetRandom(MinBladeLength, MaxBladeLength) };
		XMVECTOR BendingAxis{ XMVector3Cross(KUpDirection, CurrentDirection) };
		XMMATRIX BendingMatrix{ XMMatrixRotationAxis(BendingAxis, BendingAngle) };
		XMVECTOR TipPosition{ XMVectorSet(0, TipHeight, 0, 1) };
		TipPosition = XMVector3TransformCoord(TipPosition, BendingMatrix);

		m_vVertices.back().TipPosition = TipPosition;
		m_vVertices.back().GroundColor = GroundSegmentColor;
		m_vVertices.back().TipColor = TipSegmentColor;
	}

	CreateVertexBuffer();

	if (BladeTextureFileName)
	{
		m_BladeTexture.CreateTextureFromFile(BladeTextureFileName, true);
		m_cbPSFlags.bUseTexture = TRUE;
		m_PtrGame->UpdatePSGrassFieldFlags(m_cbPSFlags);
	}
}

void CGrassField::Draw()
{
	m_PtrGame->UpdateVSSpace(XMMatrixIdentity());
	m_PtrGame->UpdateGSSpace();

	if (m_BladeTexture.IsCreated())
	{
		m_BladeTexture.Use();
	}

	CShader* const VS{ m_PtrGame->GetBaseShader(EBaseShader::VSGrassField) };
	CShader* const GS{ m_PtrGame->GetBaseShader(EBaseShader::GSGrassField) };
	CShader* const PS{ m_PtrGame->GetBaseShader(EBaseShader::PSGrassField) };

	VS->UpdateAllConstantBuffers();
	VS->Use();

	GS->UpdateAllConstantBuffers();
	GS->Use();

	PS->UpdateAllConstantBuffers();
	PS->Use();

	ComPtr<ID3D11RasterizerState> RSState{};
	m_PtrDeviceContext->RSGetState(RSState.GetAddressOf());
	m_PtrDeviceContext->RSSetState(m_PtrGame->GetCommonStates()->CullNone());

	ID3D11SamplerState* SamplerState{ m_PtrGame->GetSamplerLinearMirror() };
	m_PtrDeviceContext->PSSetSamplers(0, 1, &SamplerState);
	
	m_PtrDeviceContext->IASetVertexBuffers(0, 1, m_VertexBufferSet.Buffer.GetAddressOf(), &m_VertexBufferSet.Stride, &m_VertexBufferSet.Offset);
	m_PtrDeviceContext->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_POINTLIST);
	m_PtrDeviceContext->Draw(static_cast<UINT>(m_vVertices.size()), 0);

	m_PtrDeviceContext->RSSetState(RSState.Get());

	m_PtrDeviceContext->GSSetShader(nullptr, nullptr, 0);
}

void CGrassField::CreateVertexBuffer()
{
	D3D11_BUFFER_DESC BufferDesc{};
	BufferDesc.BindFlags = D3D11_BIND_VERTEX_BUFFER;
	BufferDesc.ByteWidth = static_cast<UINT>(sizeof(SVertexGrass) * m_vVertices.size());
	BufferDesc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
	BufferDesc.MiscFlags = 0;
	BufferDesc.StructureByteStride = 0;
	BufferDesc.Usage = D3D11_USAGE_DYNAMIC;

	D3D11_SUBRESOURCE_DATA SubresourceData{};
	SubresourceData.pSysMem = &m_vVertices[0];
	m_PtrDevice->CreateBuffer(&BufferDesc, &SubresourceData, &m_VertexBufferSet.Buffer);
}
