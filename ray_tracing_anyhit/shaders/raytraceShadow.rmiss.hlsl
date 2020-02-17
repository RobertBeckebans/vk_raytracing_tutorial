
struct Payload
{
    bool isShadowed;
};

[shader("miss")]
void main(inout Payload P)
{
  P.isShadowed = false;
}
