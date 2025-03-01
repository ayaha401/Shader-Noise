#ifndef _NOISE
#define _NOISE

float rand(float2 uv)
{
    return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123);
}

float f1Rand2(float2 uv)
{
    uv=float2(dot(uv,float2(127.1,311.7)),
              dot(uv,float2(269.5,183.3)));
    return -1.+2.*frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123);
}

float2 f2rand2ZeroOne(float2 uv)
{
    uv=float2(dot(uv,float2(127.1,311.7)),
              dot(uv,float2(269.5,183.3)));
    return -1.+2.*frac(sin(uv)*43758.5453123);
}

float2 f2rand2HalfOne(float2 uv)
{
    uv=float2(dot(uv,float2(127.1,311.7)),
              dot(uv,float2(269.5,183.3)));
    return frac(sin(uv)*43758.5453123);
}

float blockNoise(float2 uv, float s = 1.0)
{
    uv=floor(uv*s);
    return rand(uv);
}

float valueNoise(float2 uv, float s)
{
    float2 i=floor(uv*s);
    float2 f=frac(uv*s);

    float v00=f1Rand2(i+float2(0.,0.));
    float v10=f1Rand2(i+float2(1.,0.));
    float v01=f1Rand2(i+float2(0.,1.));
    float v11=f1Rand2(i+float2(1.,1.));

    float2 u=f*f*(3.-2.*f);

    float v0010 = lerp(v00, v10, u.x);
    float v0111 = lerp(v01, v11, u.x);

    return lerp(v0010, v0111, u.y)*.5+.5;
}

float perlinNoise(float2 uv,float s)
{
    float2 i=floor(uv*s);
    float2 f=frac(uv*s);

    float2 u=f*f*(3.-2.*f);

    float2 v00=f2rand2ZeroOne(i+float2(0.,0.));
    float2 v10=f2rand2ZeroOne(i+float2(1.,0.));
    float2 v01=f2rand2ZeroOne(i+float2(0.,1.));
    float2 v11=f2rand2ZeroOne(i+float2(1.,1.));

    return lerp(lerp(dot(v00, f-float2(0.,0.)),
                     dot(v10, f-float2(1.,0.)), u.x),
                lerp(dot(v01, f-float2(0.,1.)),
                     dot(v11, f-float2(1.,1.)), u.x), u.y)*.5+.5;
}

//=================================================//
// distanceType = 1        : MachineCellularNoise  //
// distanceType = 2        : CellularNoise         //
// distanceType = infinity : MachineCellularNoise  //
//=================================================//
float cellularNoise(float2 uv, float s, float distanceType, float moveSpeed = 0.)
{
    float2 i=floor(uv*s);
    float2 f=frac(uv*s);

    float minDist = 8.;

    for(int y=-1;y<=1;y++)
    for(int x=-1;x<=1;x++)
    {
        float2 neighbor=float2(float(x), float(y));
        float2 p=f2rand2HalfOne(i+neighbor);
        p=.5+.5*sin(moveSpeed*_Time.y+6.2831*p);
        float2 diff=neighbor+p-f;

        // Calc minkowskiDistance
        float2 d1 = pow(abs(float2(diff.x, diff.y)),(float2)distanceType);
        float minkowskiDistance = pow((d1.x + d1.y), 1.0 / distanceType);

        minDist=min(minDist,minkowskiDistance);
    }
    
    return minDist;
}

//=================================================//
// distanceType = 1        : MachineCellularNoise  //
// distanceType = 2        : CellularNoise         //
// distanceType = infinity : MachineCellularNoise  //
//=================================================//
float voronoi(float2 uv, float s, float distanceType, float moveSpeed = 0.)
{
    float2 i=floor(uv*s);
    float2 f=frac(uv*s);

    float minDist = 8.;
    float2 minP;

    for(int y=-1;y<=1;y++)
    for(int x=-1;x<=1;x++)
    {
        float2 neighbor=float2((float)x, (float)y);
        float2 p=f2rand2HalfOne(i+neighbor);
        p=.5+.5*sin(moveSpeed*_Time.y+6.2831*p);
        float2 diff=neighbor+p-f;

        // Calc minkowskiDistance
        float2 d1 = pow(abs(float2(diff.x, diff.y)),(float2)distanceType);
        float minkowskiDistance = pow((d1.x + d1.y), 1.0 / distanceType);
        
        if(minkowskiDistance < minDist)
        {
            minDist = minkowskiDistance;
            minP=p;
        }
    }
    return (minP.x+minP.y)*.5;
}

// https://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare/
// value : uv
float interleavedGradientNoise(float2 value)
{
    float f = 0.06711056 * value.x + 0.00583715 * value.y;
    return frac(52.9829189 * frac(f));
}

#endif
