#include "raycommon.hlsl"
#include "wavefront.hlsl"

struct Attrib
{
    float3 HitAttribute;
};

//layout(binding = 7, set = 1, scalar) buffer allSpheres_
//{
//  Sphere i[];
//}
//allSpheres;

[[vk::binding(7,1)]] StructuredBuffer<Sphere> allSpheres;


struct Ray
{
  float3 origin;
  float3 direction;
};

// Ray-Sphere intersection
// http://viclw17.github.io/2018/07/16/raytracing-ray-sphere-intersection/
float hitSphere(Sphere s, Ray r)
{
  float3  oc           = r.origin - s.center;
  float a            = dot(r.direction, r.direction);
  float b            = 2.0 * dot(oc, r.direction);
  float c            = dot(oc, oc) - s.radius * s.radius;
  float discriminant = b * b - 4 * a * c;
  if(discriminant < 0)
  {
    return -1.0;
  }
  else
  {
    return (-b - sqrt(discriminant)) / (2.0 * a);
  }
}

// Ray-AABB intersection
float hitAabb(Aabb aabb, Ray r)
{
  float3  invDir = 1.0 / r.direction;
  float3  tbot   = invDir * (aabb.minimum - r.origin);
  float3  ttop   = invDir * (aabb.maximum - r.origin);
  float3  tmin   = min(ttop, tbot);
  float3  tmax   = max(ttop, tbot);
  float t0     = max(tmin.x, max(tmin.y, tmin.z));
  float t1     = min(tmax.x, min(tmax.y, tmax.z));
  return t1 > max(t0, 0.0) ? t0 : -1.0;
}

[shader("intersection")]
void main()
{
  Ray ray;
  ray.origin    = WorldRayOrigin();
  ray.direction = WorldRayDirection();

  // Sphere data
  Sphere sphere = allSpheres[PrimitiveIndex()];

  float tHit    = -1;
  int   hitKind = PrimitiveIndex() % 2 == 0 ? KIND_SPHERE : KIND_CUBE;
  if(hitKind == KIND_SPHERE)
  {
    // Sphere intersection
    tHit = hitSphere(sphere, ray);
  }
  else
  {
    // AABB intersection
    Aabb aabb;
    aabb.minimum = sphere.center - float3(sphere.radius, sphere.radius, sphere.radius);
    aabb.maximum = sphere.center + float3(sphere.radius, sphere.radius, sphere.radius);
    tHit         = hitAabb(aabb, ray);
  }

  Attrib A;
  // Report hit point
  if(tHit > 0)
    ReportHit(tHit, hitKind, A);
}
