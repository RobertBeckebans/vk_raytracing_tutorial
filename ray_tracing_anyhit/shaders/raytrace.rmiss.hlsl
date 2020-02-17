#include "raycommon.hlsl"

struct Payload
{
    hitPayload prd;
};
struct C
{
    float4 clearColor;
};

[[vk::push_constant]]
ConstantBuffer<C> Constants;

[shader("miss")]
void main(inout Payload P)
{
  P.prd.hitValue = Constants.clearColor.xyz * 0.8;
}
