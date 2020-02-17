#include "raycommon.hlsl"

struct Data
{
    rayLight cLight;
};

struct Constants
{
  float4  clearColor;
  float3  lightPosition;
  float lightIntensity;
  float3  lightDirection;
  float lightSpotCutoff;
  float lightSpotOuterCutoff;
  int   lightType;
};

[[vk::push_constant]] ConstantBuffer<Constants> C;

[shader("callable")]
void main(inout Data D)
{
  float3 lDir               = C.lightPosition - D.cLight.inHitPosition;
  D.cLight.outLightDistance = length(lDir);
  D.cLight.outIntensity     = C.lightIntensity / (D.cLight.outLightDistance * D.cLight.outLightDistance);
  D.cLight.outLightDir      = normalize(lDir);
  float theta             = dot(D.cLight.outLightDir, normalize(-C.lightDirection));
  float epsilon           = C.lightSpotCutoff - C.lightSpotOuterCutoff;
  float spotIntensity     = clamp((theta - C.lightSpotOuterCutoff) / epsilon, 0.0, 1.0);
  D.cLight.outIntensity *= spotIntensity;
}
