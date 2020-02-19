#include "random.hlsl"
#include "raycommon.hlsl"

[[vk::binding(0,0)]] RaytracingAccelerationStructure topLevelAS;

[[vk::binding(1,0)]] RWTexture2D<float4> image;

struct Payload 
{
    hitPayload prd;
};

struct CameraProperties
{
  float4x4 view;
  float4x4 proj;
  float4x4 viewInverse;
  float4x4 projInverse;
};
[[vk::binding(0,1)]] ConstantBuffer<CameraProperties> cam;

struct Constants
{
  float4  clearColor;
  float3  lightPosition;
  float lightIntensity;
  int   lightType;
  int   frame;
};
[[vk::push_constant]] ConstantBuffer<Constants> pushC;

static const int NBSAMPLES = 10;

[shader("raygeneration")]
void main()
{
  // Initialize the random number
  uint seed = tea(DispatchRaysIndex().y * DispatchRaysDimensions().x + DispatchRaysIndex().x, pushC.frame);

  float3 hitValues = float3(0,0,0);

  Payload P;
  for(int smpl = 0; smpl < NBSAMPLES; smpl++)
  {

    float r1 = rnd(seed);
    float r2 = rnd(seed);
    // Subpixel jitter: send the ray through a different position inside the pixel
    // each time, to provide antialiasing.
    float2 subpixel_jitter = pushC.frame == 0 ? float2(0.5f, 0.5f) : float2(r1, r2);

    const float2 pixelCenter = float2(DispatchRaysIndex().xy) + subpixel_jitter;
    const float2 inUV        = pixelCenter / float2(DispatchRaysDimensions().xy);
    float2       d           = inUV * 2.0 - 1.0;

    float4 origin    = mul(cam.viewInverse , float4(0, 0, 0, 1));
    float4 target    = mul(cam.projInverse , float4(d.x, d.y, 1, 1));
    float4 direction = mul(cam.viewInverse , float4(normalize(target.xyz), 0));

    uint  rayFlags = RAY_FLAG_FORCE_OPAQUE;
    float tMin     = 0.001;
    float tMax     = 10000.0;

    RayDesc desc;
    desc.Origin = origin.xyz;
    desc.Direction = direction.xyz;
    desc.TMin = tMin;
    desc.TMax = tMax;

    TraceRay(topLevelAS,     // acceleration structure
            rayFlags,       // rayFlags
            0xFF,           // cullMask
            0,              // sbtRecordOffset
            0,              // sbtRecordStride
            0,              // missIndex
            desc,
            P               // payload (location = 0)
    );
    hitValues += P.prd.hitValue;
  }
  P.prd.hitValue = hitValues / NBSAMPLES;

  // Do accumulation over time
  if(pushC.frame > 0)
  {
    float a         = 1.0f / float(pushC.frame + 1);
    float3  old_color = image[DispatchRaysIndex().xy].xyz;
    image[DispatchRaysIndex().xy] = float4(lerp(old_color, P.prd.hitValue, a), 1.0f);
  }
  else
  {
    // First frame, replace the value in the buffer
    image[DispatchRaysIndex().xy] = float4(P.prd.hitValue, 1.0f);
  }
}
