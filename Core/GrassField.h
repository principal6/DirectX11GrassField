#pragma once

#include "SharedHeader.h"
#include "Material.h"

class CGame;
class CGrassField
{
public:
	struct SVertexGrass
	{
		XMVECTOR	GroundPosition{};
		XMVECTOR	TipPosition{};
		XMVECTOR	GroundColor{};
		XMVECTOR	TipColor{};
	};

	struct SComponentTransform
	{
		XMVECTOR	Translation{};
		XMVECTOR	Scaling{ XMVectorSet(1, 1, 1, 0) };
		XMMATRIX	MatrixWorld{ XMMatrixIdentity() };

		float		Pitch{};
		float		Yaw{};
		float		Roll{};
	};

	struct SVertexBufferSet
	{
		SVertexBufferSet(size_t VertexStructureBufferCount) : Stride{ static_cast<UINT>(VertexStructureBufferCount) } {}

		ComPtr<ID3D11Buffer>	Buffer{};
		UINT					Stride{};
		UINT					Offset{};
	};

	struct SCBGSGrassData
	{
		float	BladeWidth{};
		float	Pads[3]{};
	};

	struct SCBPSFlags
	{
		BOOL	bUseTexture{ FALSE };
		float	Pads[3]{};
	};

public:
	CGrassField(ID3D11Device* const PtrDevice, ID3D11DeviceContext* const PtrDeviceContext, CGame* const PtrGame) :
		m_PtrDevice{ PtrDevice }, m_PtrDeviceContext{ PtrDeviceContext }, m_PtrGame{ PtrGame }
	{
		assert(m_PtrDevice);
		assert(m_PtrDeviceContext);
		assert(m_PtrGame);
	}
	~CGrassField() {}

public:
	void Create(size_t BladeCount, float MinBladeLength, float MaxBladeLength, float BladeWidth,
		float MinBendingAngleRadian, float MaxBendingAngleRadian, float BladeDisplacementFromCenter,
		const XMVECTOR& GroundSegmentColor, const XMVECTOR& TipSegmentColor, const char* BladeTextureFileName = nullptr);

	void Draw();

private:
	void CreateVertexBuffer();

public:
	static constexpr float KBladeWidthMinLimit{ 0.1f };
	static constexpr float KBladeWidthMaxLimit{ 2.0f };
	static constexpr size_t KMinBladeCount{ 1 };
	static constexpr size_t KMaxBladeCount{ 18 };
	static constexpr D3D11_INPUT_ELEMENT_DESC KInputElementDescs[]
	{
		{ "POSITION"	, 0, DXGI_FORMAT_R32G32B32A32_FLOAT	, 0,  0, D3D11_INPUT_PER_VERTEX_DATA, 0 },
		{ "POSITION"	, 1, DXGI_FORMAT_R32G32B32A32_FLOAT	, 0, 16, D3D11_INPUT_PER_VERTEX_DATA, 0 },
		{ "COLOR"		, 0, DXGI_FORMAT_R32G32B32A32_FLOAT	, 0, 32, D3D11_INPUT_PER_VERTEX_DATA, 0 },
		{ "COLOR"		, 1, DXGI_FORMAT_R32G32B32A32_FLOAT	, 0, 48, D3D11_INPUT_PER_VERTEX_DATA, 0 },
	};

private:
	ID3D11Device* const			m_PtrDevice{};
	ID3D11DeviceContext* const	m_PtrDeviceContext{};
	CGame* const				m_PtrGame{};

private:
	SComponentTransform			m_ComponentTransform{};
	SVertexBufferSet			m_VertexBufferSet{ sizeof(SVertexGrass) };
	std::vector<SVertexGrass>	m_vVertices{};
	size_t						m_BladeCount{};
	SCBGSGrassData				m_cbGSGrassData{};
	SCBPSFlags					m_cbPSFlags{};
	CMaterial::CTexture			m_BladeTexture{ m_PtrDevice, m_PtrDeviceContext };
};