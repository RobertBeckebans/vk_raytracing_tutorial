#include "wavefront.hlsl"


struct shaderInformation
{
  float3  lightPosition;
  uint  instanceId;
  float lightIntensity;
  int   lightType;
};

[[vk::push_constant]] ConstantBuffer<shaderInformation> pushC;

struct PSInput
{
    [[vk::location(1)]] float2 fragTexCoord : A;
    [[vk::location(2)]] float3 fragNormal : B;
    [[vk::location(3)]] float3 viewDir : C;
    [[vk::location(4)]] float3 worldPos : D;
    int primID : SV_PrimitiveID;
};

struct PSOutput
{
    [[vk::location(0)]] float4 outColor : SV_Target0;
};


// Buffers
//layout(binding = 1, scalar) buffer MatColorBufferObject { WaveFrontMaterial m[]; } materials[];
[[vk::binding(1)]] StructuredBuffer<WaveFrontMaterial> materials[];

//layout(binding = 2, scalar) buffer ScnDesc { sceneDesc i[]; } scnDesc;
[[vk::binding(2)]] StructuredBuffer<sceneDesc> scnDesc;

//layout(binding = 3) uniform sampler2D[] textureSamplers;
[[vk::binding(3)]] Texture2D<float4> textureSamplers[];
[[vk::binding(3)]] SamplerState samplerSamplers[];

//layout(binding = 4, scalar) buffer MatIndex { int i[]; } matIdx[];
[[vk::binding(4)]] StructuredBuffer<int> matIdx[];

// clang-format on


PSOutput main(PSInput PSIn)
{
  PSOutput POut;
  // Object of this instance
  int objId = scnDesc[pushC.instanceId].objId;

  // Material of the object
  int               matIndex = matIdx[objId][PSIn.primID];
  WaveFrontMaterial mat      = materials[objId][matIndex];

  float3 N = normalize(PSIn.fragNormal);

  // Vector toward light
  float3  L;
  float lightIntensity = pushC.lightIntensity;
  if(pushC.lightType == 0)
  {
    float3  lDir     = pushC.lightPosition - PSIn.worldPos;
    float d        = length(lDir);
    lightIntensity = pushC.lightIntensity / (d * d);
    L              = normalize(lDir);
  }
  else
  {
    L = normalize(pushC.lightPosition - float3(0,0,0));
  }


  // Diffuse
  float3 diffuse = computeDiffuse(mat, L, N);
  if(mat.textureId >= 0)
  {
    int  txtOffset  = scnDesc[pushC.instanceId].txtOffset;
    uint txtId      = txtOffset + mat.textureId;
    float3 diffuseTxt = textureSamplers[txtId].Sample(samplerSamplers[txtId], PSIn.fragTexCoord).xyz;
    diffuse *= diffuseTxt;
  }

  // Specular
  float3 specular = computeSpecular(mat, PSIn.viewDir, L, N);

  // Result
  POut.outColor = float4(lightIntensity * (diffuse + specular), 1);
  return POut;
}
