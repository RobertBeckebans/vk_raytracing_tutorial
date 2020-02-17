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
  D.cLight.outLightDistance = 10000000;
  D.cLight.outIntensity     = 1.0;
  D.cLight.outLightDir      = normalize(-C.lightDirection);
}
