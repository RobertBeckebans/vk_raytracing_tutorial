struct VOutput
{
    [[vk::location(0)]] float2 outUV : TEXCOORD0;
    float4 position : SV_Position;
};


VOutput main(in uint vertexIndex : SV_VertexID)
{
  VOutput VO;
  VO.outUV = float2((vertexIndex << 1) & 2, vertexIndex & 2);
  VO.position = float4(VO.outUV * 2.0f - 1.0f, 1.0f, 1.0f);
  return VO;
}
