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

// valueNoiseを使用したFBM
// pos:座標
// size:ノイズのサイズ
// octaves:繰り返す回数
// persistence:各オクターブの振幅減衰率 半減させると自然
float valueNoiseFbm(float2 pos, float size, int octaves, float persistence = 0.5)
{
    float total = 0.0;
    float frequency = 1.0;
    float amplitude = 1.0;
    float maxValue = 0.0; // 正規化用

    for (int i = 0; i < octaves; i++)
    {
        total += valueNoise(pos * frequency, size) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= 2.0;
    }

    return total / maxValue;
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

// PerlinNoiseのFBMにabs(ノイズは-1~1にする)することで鋭い線のようなノイズが作れる
// pos:座標
// size:ノイズのサイズ
// octaves:繰り返す回数
// persistence:各オクターブの振幅減衰率 半減させると自然
float turbulencePerlinNoiseFbm(float2 pos, float size, int octaves, float persistence = 0.5)
{
    float total = 0.0;
    float frequency = 1.0;
    float amplitude = 1.0;
    float maxValue = 0.0; // 正規化用

    for (int i = 0; i < octaves; i++)
    {
        total += abs(perlinNoise(pos, size * frequency) * 2.0 - 1.0) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= 2.0;
    }

    return total / maxValue;
}

// PerlinNoiseのFBMとOffsetを組み合わせることでturbulencePerlinNoiseFbmとは逆の模様を作ることができる
// pos:座標
// size:ノイズのサイズ
// octaves:繰り返す回数
// offset(0~1ぐらいを入れる)
// persistence:各オクターブの振幅減衰率 半減させると自然
float ridgePerlinNoiseFbm(float2 pos, float size, int octaves, float offset, float persistence = 0.5)
{
    float total = 0.0;
    float frequency = 1.0;
    float amplitude = 1.0;
    float maxValue = 0.0; // 正規化用

    for (int i = 0; i < octaves; i++)
    {
        float ridge = abs(perlinNoise(pos, size * frequency) * 2.0 - 1.0); // absして折り返す
        ridge = offset - ridge; // 折り目が上になるように反転する 
        ridge = ridge * ridge; // シャープにする

        // FBM作るための処理を行う
        total += ridge * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= 2.0;
    }

    return total / maxValue;
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
