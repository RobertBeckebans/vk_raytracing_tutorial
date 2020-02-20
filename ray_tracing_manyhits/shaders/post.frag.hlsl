[[vk::binding(0,0)]] Texture2D<float4> noisyTxtTex;
[[vk::binding(0,0)]] SamplerState noisyTxtSamp;

struct shaderInformation
{
  float aspectRatio;
};

[[vk::push_constant]] ConstantBuffer<shaderInformation> pushC;

[[vk::location(0)]] float4 main([[vk::location(0)]] in float2 outUV : A) : SV_Target0
{
  float2  uv    = outUV;
  float gamma = 1. / 2.2;
  return pow(noisyTxtTex.Sample(noisyTxtSamp, uv).rgba , float4(gamma,gamma,gamma,gamma));
}
