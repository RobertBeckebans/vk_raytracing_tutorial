#include "raycommon.hlsl"

[[vk::binding(0,0)]] RaytracingAccelerationStructure topLevelAS;
[[vk::binding(1,0)]] RWTexture2D<float4> image;

struct CameraProperties
{
  float4x4 view;
  float4x4 proj;
  float4x4 viewInverse;
  float4x4 projInverse;
};
[[vk::binding(0, 1)]] ConstantBuffer<CameraProperties> cam;
struct Constants
{
  float4  clearColor;
  float3  lightPosition;
  float lightIntensity;
  int   lightType;
  int   maxDepth;
};
[[vk::push_constant]] ConstantBuffer<Constants> pushC;

[shader("raygeneration")]
void main()
{
  const float2 pixelCenter = float2(DispatchRaysIndex().xy) + float2(0.5, 0.5);
  const float2 inUV        = pixelCenter / float2(DispatchRaysDimensions().xy);
  float2       d           = inUV * 2.0 - 1.0;

  float4 origin    = mul(cam.viewInverse, float4(0,0,0,1));
  float4 target    = mul(cam.projInverse, float4(d.x, d.y, 1, 1));
  float4 direction = mul(cam.viewInverse, float4(normalize(target.xyz), 0));

  uint  rayFlags = RAY_FLAG_FORCE_OPAQUE;
  float tMin     = 0.001;
  float tMax     = 10000.0;



  hitPayload prd;
  prd.depth       = 0;
  prd.hitValue    = float3(0,0,0);
  prd.attenuation = float3(1.f, 1.f, 1.f);
  prd.done        = 1;
  prd.rayOrigin   = origin.xyz;
  prd.rayDir      = direction.xyz;

  float3 hitValue = float3(0,0,0);
  for(;;)
  {
  RayDesc desc;
  desc.Origin = origin.xyz;
  desc.Direction = direction.xyz;
  desc.TMin = tMin;
  desc.TMax = tMax;
  TraceRay(topLevelAS,    
          rayFlags,       
          0xFF,           
          0,              
          0,              
          0,              
	  desc,
          prd
  );
    hitValue += prd.hitValue * prd.attenuation;

    prd.depth++;
    if(prd.done == 1 || prd.depth >= pushC.maxDepth)
      break;

    origin.xyz    = prd.rayOrigin;
    direction.xyz = prd.rayDir;
    prd.done      = 1;  // Will stop if a reflective material isn't hit
  }

  image[DispatchRaysIndex().xy] = float4(prd.hitValue, 1.0);
}
