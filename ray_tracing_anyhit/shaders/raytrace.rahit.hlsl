#include "random.hlsl"
#include "raycommon.hlsl"
#include "wavefront.hlsl"

struct Payload
{
    hitPayload prd;
};
struct Attrib
{
    float2 dummy;
};

[[vk::binding(2,1)]] StructuredBuffer<sceneDesc> scnDesc;

[[vk::binding(4,1)]] StructuredBuffer<int> matIndex[];

[[vk::binding(5,1)]] StructuredBuffer<Vertex> vertices[];

[[vk::binding(6,1)]] StructuredBuffer<uint> indices[];

[[vk::binding(1,1)]] StructuredBuffer<WaveFrontMaterial> materials[];

[shader("anyhit")]
void main(inout Payload P, in Attrib A)
{
  // Object of this instance
  uint objId = scnDesc[InstanceIndex()].objId;
  // Indices of the triangle
  uint ind = indices[objId][3 * PrimitiveIndex() + 0];
  // Vertex of the triangle
  Vertex v0 = vertices[objId][ind.x];

  // Material of the object
  int               matIdx = matIndex[objId][PrimitiveIndex()];
  WaveFrontMaterial mat    = materials[objId][matIdx];

  if(mat.illum != 4)
    return;

  if(mat.dissolve == 0.0)
    IgnoreHit();
  else if(rnd(P.prd.seed) > mat.dissolve)
    IgnoreHit();
}
