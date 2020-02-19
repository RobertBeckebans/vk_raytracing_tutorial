struct hitPayload
{
  float3 hitValue;
};
struct Sphere
{
  float3  center;
  float radius;
};

struct Aabb
{
  float3 minimum;
  float3 maximum;
};

#define KIND_SPHERE 0
#define KIND_CUBE 1