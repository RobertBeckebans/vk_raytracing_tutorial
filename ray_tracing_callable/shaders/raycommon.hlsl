struct hitPayload
{
  float3 hitValue;
};
struct rayLight
{
  float3  inHitPosition;
  float outLightDistance;
  float3  outLightDir;
  float outIntensity;
};