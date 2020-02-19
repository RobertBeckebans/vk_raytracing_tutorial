#include "raycommon.hlsl"
#include "wavefront.hlsl"

struct Attrib
{
    float3 attribs;
};

// clang-format off
//layout(location = 0) rayPayloadInNV hitPayload prd;
//layout(location = 1) rayPayloadNV bool isShadowed;

struct Payload
{
    hitPayload prd;
};

struct Payload2
{
    bool isShadowed;
};

//layout(binding = 0, set = 0) uniform accelerationStructureNV topLevelAS;
[[vk::binding(0,0)]] RaytracingAccelerationStructure topLevelAS;

//layout(binding = 2, set = 1, scalar) buffer ScnDesc { sceneDesc i[]; } scnDesc;
[[vk::binding(2,1)]] StructuredBuffer<sceneDesc> scnDesc;

//layout(binding = 5, set = 1, scalar) buffer Vertices { Vertex v[]; } vertices[];
[[vk::binding(5,1)]] StructuredBuffer<Vertex> vertices[];

//layout(binding = 6, set = 1) buffer Indices { uint i[]; } indices[];
[[vk::binding(6,1)]] StructuredBuffer<uint> indices[];

//layout(binding = 1, set = 1, scalar) buffer MatColorBufferObject { WaveFrontMaterial m[]; } materials[];
[[vk::binding(1,1)]] StructuredBuffer<WaveFrontMaterial> materials[];

//layout(binding = 3, set = 1) uniform sampler2D textureSamplers[];
[[vk::binding(3,1)]] Texture2D<float4> textureSamplers[];
[[vk::binding(3,1)]] SamplerState samplerSamplers[];

//layout(binding = 4, set = 1)  buffer MatIndexColorBuffer { int i[]; } matIndex[];
[[vk::binding(4,1)]] StructuredBuffer<int> matIndex[];

//layout(binding = 7, set = 1, scalar) buffer allSpheres_ {Sphere i[];} allSpheres;
[[vk::binding(7,1)]] StructuredBuffer<Sphere> allSpheres;

// clang-format on

//layout(push_constant) uniform Constants
//{
//  vec4  clearColor;
//  vec3  lightPosition;
//  float lightIntensity;
//  int   lightType;
//}
//pushC;

struct Constants
{
  float4  clearColor;
  float3  lightPosition;
  float lightIntensity;
  int   lightType;
};

[[vk::push_constant]] ConstantBuffer<Constants> pushC;

[shader("closesthit")]
void main(inout Payload P, in Attrib A)
{
  float3 worldPos = WorldRayOrigin() + WorldRayDirection() * RayTCurrent();

  Sphere instance = allSpheres[PrimitiveIndex()];

  // Computing the normal at hit position
  float3 normal = normalize(worldPos - instance.center);

  // Computing the normal for a cube
  if(HitKind()== KIND_CUBE)  // Aabb
  {
    float3  absN = abs(normal);
    float maxC = max(max(absN.x, absN.y), absN.z);
    normal     = (maxC == absN.x) ?
                 float3(sign(normal.x), 0, 0) :
                 (maxC == absN.y) ? float3(0, sign(normal.y), 0) : float3(0, 0, sign(normal.z));
  }

  // Vector toward the light
  float3  L;
  float lightIntensity = pushC.lightIntensity;
  float lightDistance  = 100000.0;
  // Point light
  if(pushC.lightType == 0)
  {
    float3 lDir      = pushC.lightPosition - worldPos;
    lightDistance  = length(lDir);
    lightIntensity = pushC.lightIntensity / (lightDistance * lightDistance);
    L              = normalize(lDir);
  }
  else  // Directional light
  {
    L = normalize(pushC.lightPosition - float3(0,0,0));
  }

  // Material of the object
  int               matIdx = matIndex[InstanceIndex()][PrimitiveIndex()];
  WaveFrontMaterial mat    = materials[InstanceIndex()][matIdx];

  // Diffuse
  float3  diffuse     = computeDiffuse(mat, L, normal);
  float3  specular    = float3(0,0,0);
  float attenuation = 0.3;

  // Tracing shadow ray only if the light is visible from the surface
  if(dot(normal, L) > 0)
  {
    float tMin   = 0.001;
    float tMax   = lightDistance;
    float3  origin = WorldRayOrigin() + WorldRayDirection() * RayTCurrent();
    float3  rayDir = L;
    uint  flags =
        RAY_FLAG_ACCEPT_FIRST_HIT_AND_END_SEARCH | RAY_FLAG_FORCE_OPAQUE |
        RAY_FLAG_SKIP_CLOSEST_HIT_SHADER;

    Payload2 P2;
    P2.isShadowed = true;

    RayDesc desc;
    desc.Origin = origin;
    desc.Direction = rayDir;
    desc.TMin = tMin;
    desc.TMax = tMax;

    TraceRay(topLevelAS,  // acceleration structure
            flags,       // rayFlags
            0xFF,        // cullMask
            0,           // sbtRecordOffset
            0,           // sbtRecordStride
            1,           // missIndex
            desc,
            P2           // payload (location = 1)
    );

    if(P2.isShadowed)
    {
      attenuation = 0.3;
    }
    else
    {
      attenuation = 1;
      // Specular
      specular = computeSpecular(mat, WorldRayDirection(), L, normal);
    }
  }

  P.prd.hitValue = float3(lightIntensity * attenuation * (diffuse + specular));
}
