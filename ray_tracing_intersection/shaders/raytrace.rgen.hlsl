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

  RayDesc desc;
  desc.Origin = origin.xyz;
  desc.Direction = direction.xyz;
  desc.TMin = tMin;
  desc.TMax = tMax;

  hitPayload prd;

  TraceRay(topLevelAS,    
          rayFlags,       
          0xFF,           
          0,              
          0,              
          0,              
	  desc,
          prd
  );

  image[DispatchRaysIndex().xy] = float4(prd.hitValue, 1.0);
}
