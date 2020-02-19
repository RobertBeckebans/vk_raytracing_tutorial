#include "raycommon.hlsl"
struct C
{
  float4 clearColor;
};
[[vk::push_constant]]
C Constants;
[shader("miss")]
void main(inout hitPayload prd)
{
  prd.hitValue = Constants.clearColor.xyz * 0.8;
}
