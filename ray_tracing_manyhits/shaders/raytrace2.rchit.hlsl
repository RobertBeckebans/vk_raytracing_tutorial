#include "raycommon.hlsl"

struct Payload
{
    hitPayload prd;
};
struct Attrib
{
    float2 dummy;
};

struct SR
{
    float4 c;
};

[[vk::shader_record_nv]] ConstantBuffer<SR> shaderRec;


[shader("closesthit")]
void main(inout Payload P, in Attrib A)
{
  P.prd.hitValue = shaderRec.c.rgb;
}
