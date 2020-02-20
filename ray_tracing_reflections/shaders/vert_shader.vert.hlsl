#include "wavefront.hlsl"

//layout(binding = 2, set = 0, scalar) buffer ScnDesc { sceneDesc i[]; } scnDesc;
[[vk::binding(2,0)]] StructuredBuffer<sceneDesc> scnDesc;

struct UniformBufferObject
{
  float4x4 view;
  float4x4 proj;
  float4x4 viewI;
};

[[vk::binding(0)]] ConstantBuffer<UniformBufferObject> ubo;

struct shaderInformation
{
  float3  lightPosition;
  uint  instanceId;
  float lightIntensity;
  int   lightType;
};
[[vk::push_constant]] ConstantBuffer<shaderInformation> pushC;

struct VSInput
{
    
    [[vk::location(0)]] float3 inPosition : A;
    [[vk::location(1)]] float3 inNormal : B;
    [[vk::location(2)]] float3 inColor : C;
    [[vk::location(3)]] float2 inTexCoord : D;
};


struct VSOutput
{
    float4 position : SV_Position;
    [[vk::location(1)]] float2 fragTexCoord : Q;
    [[vk::location(2)]] float3 fragNormal : W;
    [[vk::location(3)]] float3 viewDir : E;
    [[vk::location(4)]] float3 worldPos : R;
};


VSOutput main(VSInput VIn)
{
  VSOutput VOut;
  float4x4 objMatrix   = scnDesc[pushC.instanceId].transfo;
  float4x4 objMatrixIT = scnDesc[pushC.instanceId].transfoIT;

  float3 origin = mul(ubo.viewI , float4(0, 0, 0, 1)).xyz;

  VOut.worldPos     = mul(objMatrix , float4(VIn.inPosition, 1.0)).xyz;
  VOut.viewDir      = float3(VOut.worldPos - origin);
  VOut.fragTexCoord = VIn.inTexCoord;
  VOut.fragNormal   = mul(objMatrixIT , float4(VIn.inNormal, 0.0)).xyz;

  VOut.position = mul(mul(ubo.proj , ubo.view), float4(VOut.worldPos, 1.0));
  return VOut;
}
