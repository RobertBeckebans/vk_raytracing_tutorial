struct Vertex
{
  float3 pos;
  float3 nrm;
  float3 color;
  float2 texCoord;
};

struct WaveFrontMaterial
{
  float3  ambient;
  float3  diffuse;
  float3  specular;
  float3  transmittance;
  float3  emission;
  float shininess;
  float ior;       // index of refraction
  float dissolve;  // 1 == opaque; 0 == fully transparent
  int   illum;     // illumination model (see http://www.fileformat.info/format/material/)
  int   textureId;
};

struct sceneDesc
{
  int  objId;
  int  txtOffset;
  float4x4 transfo;
  float4x4 transfoIT;
};


float3 computeDiffuse(WaveFrontMaterial mat, float3 lightDir, float3 normal)
{
  // Lambertian
  float dotNL = max(dot(normal, lightDir), 0.0);
  float3  c     = mat.diffuse * dotNL;
  if(mat.illum >= 1)
    return c + mat.ambient; 
  return float3(0,0,0);
}

float3 computeSpecular(WaveFrontMaterial mat, float3 viewDir, float3 lightDir, float3 normal)
{
  if(mat.illum < 2)
    return float3(0,0,0);

  // Compute specular only if not in shadow
  const float kPi        = 3.14159265;
  const float kShininess = max(mat.shininess, 4.0);

  // Specular
  const float kEnergyConservation = (2.0 + kShininess) / (2.0 * kPi);
  float3        V                   = normalize(-viewDir);
  float3        R                   = reflect(-lightDir, normal);
  float       specular            = kEnergyConservation * pow(max(dot(V, R), 0.0), kShininess);

  return float3(mat.specular * specular);
}
