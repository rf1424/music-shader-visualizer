
// static variables 
// static const float3 EYE = float3(0.0, 2.5, 5.0);
// static const float3 REF = float3(0.0, 0.0, 0.0);
static const float3 WORLD_UP = float3(0.0, 1.0, 0.0);
static const float3 WORLD_RIGHT = float3(- 1.0, 0.0, 0.0);
static const float3 WORLD_FORWARD = float3(0.0, 0.0, 1.0);
static const float3 LIGHT0_Dir = float3(0.6, 1.0, 0.4);

static const float EPSILON = 1e-3; // for sdf threshold
static const float NORMALEPSILON = 0.001f; // for calculating gradient
static const int MAX_ITER = 256;

// ------------------------ STRUCTS ------------------------
struct Ray
{
    float3 origin;
    float3 dir;
};

struct Intersection
{
    float3 position;
    float3 normal;
    float distance;
    int materialID;
    bool hit;
    int steps;
    float bloom;
};

// ------------------------- TRANSFORMS ------------------------

float2x2 rot(float a)
{
    float s = sin(a);
    float c = cos(a);
    return float2x2(c, s,
                    -s, c);
}

float3 rotateX(float3 p, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3(
        p.x,
        c * p.y - s * p.z,
        s * p.y + c * p.z
    );
}

float3 rotateY(float3 p, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3(
        c * p.x + s * p.z,
        p.y,
       -s * p.x + c * p.z
    );
}

float3 rotateZ(float3 p, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3(
        c * p.x - s * p.y,
        s * p.x + c * p.y,
        p.z
    );
}

float3 bendPoint(float3 p, float k)
{
    float angle = k * p.y;
    float c = cos(angle);
    float s = sin(angle);

    // rotate p.x and p.y, angle
    float x = c * p.x - s * p.y;
    float y = s * p.x + c * p.y;

    return float3(x, y, p.z);
}

/*
float opTwist(float primitive, float3 p)
{
    const float k = 10.0; // or some other amount
    float c = cos(k * p.y);
    float s = sin(k * p.y);
    mat2 m = mat2(c, -s, s, c);
    vec3 q = vec3(m * p.xz, p.y);
    return primitive(q);
}
*/

// ------------------------ SDFs ------------------------
float sphereSDF(float3 query_position, float radius)
{
    return length(query_position) - radius;
}

float opExtrusionSDF(in float3 p, in float sdf, in float h)
{
    float2 w = float2(sdf, abs(p.z) - h);
    return min(max(w.x, w.y), 0.0) + length(max(w, 0.0));
}

float opExtrusionSmoothSDF(float3 p, float sdf, float h, float k)
{
    float2 w = float2(sdf, abs(p.z) - h);
    float d = min(max(w.x, w.y), 0.0) + length(max(w, 0.0));
    // optional smoothing
    d = d - k * exp(-d * d * 100.0);
    return d;
}

float coneSDF(float3 p, float2 c, float h)
{
  // c is the sin/cos of the angle, h is height
  // Alternatively pass q instead of (c,h),
  // which is the point at the base in 2D
    float2 q = h * float2(c.x / c.y, -1.0);
    
    float2 w = float2(length(p.xz), p.y);
    float2 a = w - q * clamp(dot(w, q) / dot(q, q), 0.0, 1.0);
    float2 b = w - q * float2(clamp(w.x / q.x, 0.0, 1.0), 1.0);
    float k = sign(q.y);
    float d = min(dot(a, a), dot(b, b));
    float s = max(k * (w.x * q.y - w.y * q.x), k * (w.y - q.y));
    return sqrt(d) * sign(s);
}

// r = sphere's radius
// h = cutting's plane's position
// t = thickness
float sdCutHollowSphere(float3 p, float r, float h, float t)
{
    float2 q = float2(length(p.xz), p.y);
    
    float w = sqrt(r * r - h * h);
    
    return ((h * q.x < w * q.y) ? length(q - float2(w, h)) :
                            abs(length(q) - r)) - t;
}

float boxSDF(float3 p, float3 b)
{
    float3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}


float capsuleSDF(float3 p, float3 a, float3 b, float r)
{
    float3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float cappedCylinderSDF(float3 p, float r, float h)
{
    float2 d = abs(float2(length(p.xz), p.y)) - float2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float planeSDF(float3 p, float height)
{
    return p.y - height;
}

float planeSDFz(float3 p, float dist)
{
    return p.z - dist;
}

float pyramidSDF(float3 p, float h)
{
    float m2 = h * h + 0.25;
    p.xz = abs(p.xz);
    p.xz = (p.z > p.x) ? p.zx : p.xz;
    p.xz -= 0.5;
    float3 q;
    q.x = p.z;
    q.y = h * p.y - 0.5 * p.x;
    q.z = h * p.x + 0.5 * p.y;
    float s = max(-q.x, 0.0);
    float t = clamp((q.y - 0.5 * p.z) / (m2 + 0.25), 0.0, 1.0);
    float a = m2 * (q.x + s) * (q.x + s) + q.y * q.y;
    float b = m2 * (q.x + 0.5 * t) * (q.x + 0.5 * t) + (q.y - m2 * t) * (q.y - m2 * t);
    float d2 = (min(q.y, -q.x * m2 - q.y * 0.5) > 0.0) ? 0.0 : min(a, b);
    return sqrt((d2 + q.z * q.z) / m2) * sign(max(q.z, -p.y));
}

float sdTriPrism(float3 p, float2 h)
{
    float3 q = abs(p);
    return max(q.z - h.y, max(q.x * 0.866025 + p.y * 0.5, -p.y) - h.x * 0.5);
}

float sdTriangleIsosceles(in float2 p, in float2 q)
{
    p.x = abs(p.x);
    float2 a = p - q * clamp(dot(p, q) / dot(q, q), 0.0, 1.0);
    float2 b = p - q * float2(clamp(p.x / q.x, 0.0, 1.0), 1.0);
    float k = sign(q.y);
    float d = min(dot(a, a), dot(b, b));
    float s = max(k * (p.x * q.y - p.y * q.x), k * (p.y - q.y));
    return sqrt(d) * sign(s);
}

// -------------------------------------------------------------------------------
float sunglassesSDF(float3 query, float scale)
{
    query /= scale;
    float cutPlane = planeSDF(query, 0.09);
    query = rotateX(query, radians(90.));
    
    float gap = 0.25;
    float thickness = 0.03;
    float rightEye = cappedCylinderSDF(query - float3(gap, 0., 0.),
                                       0.2,
                                       thickness);
    float leftEye = cappedCylinderSDF(query - float3(-gap, 0., 0.),
                                       0.2,
                                       thickness);
    // xzy
    float bridge = boxSDF(query, float3(0.2, thickness, 0.015));
    float d = min(rightEye, leftEye);
    
    d = max(d, cutPlane);
    d = min(d, bridge);
    return d * scale;
}


// simple star extrusion
float starCreatureSDF(float3 query, out int materialID)
{
    materialID = 1.;
    float d; 
    
    
    //2dsdf, thickness, smoothness
    float star = sdfPentagram(query.xy, 0.5);
    float smoothStar = opExtrusionSmoothSDF(query, star, 0.1, 0.1);
    
    float3 eyeLeftQ = query - float3(-0.1, 0., 0.2);
    float3 eyeRightQ = query - float3(0.1, 0., 0.2);
    float eyeLeft = capsuleSDF(eyeLeftQ, float3(0., 0., - 0.3), float3(0., 0., 0.1), 0.02);
    float eyeRight = capsuleSDF(eyeRightQ, float3(0., 0., -0.3), float3(0., 0., 0.1), 0.02);
    float eyes = min(eyeRight, eyeLeft);
    
    
    d = subtract(eyes, smoothStar);
    
    float3 querySG = query - float3(0., -0.1, 0.2);
    float sunglasses = sunglassesSDF(querySG, 0.5);
    
    d = min(d, sunglasses);
    
    materialID = d < sunglasses ? 1 : 0;
    
    return d;
}

float starAnimalSDF2BiColor(float3 q, int queryID, out int materialID)
{
    materialID = YELLOW;
    
    bool isOdd = (queryID & 1) != 0;
    if (isOdd)  materialID = BLUE;
    
    q -= float3(0., 1., 0.); // lift entire character

    // constants
    const float2 bodyAng = float2(sin(radians(30.0)), cos(radians(30.0)));
    const float2 armAng = float2(sin(radians(28.0)), cos(radians(28.0)));

    // BODY
    float3 bodyScale = float3(1., .95, 0.5); //float3(1., 1., 0.6)
    float3 bq = q / bodyScale;
    float body = coneSDF(bq, bodyAng, 1.0);
    body -= 0.06;//-0.01
    float bodyScaleMin = min(min(bodyScale.x, bodyScale.y), bodyScale.z);

    // MIRROR QUERY
    float3 mq = q;
    mq.x = abs(mq.x); // << Perfect mathematical symmetry here

    // ARMS
    float3 aq = (mq / bodyScale) - float3(0.65, -0.5, 0.);
    aq = rotateZ(aq, radians(75.0));

    float arms = coneSDF(aq, armAng, 0.4);
    arms -= 0.03;
    // BODY + ARMS
    float smoothStar = smoothUnion(body, arms, 0.02);
    smoothStar *= bodyScaleMin;

    // NOSE
    float3 nq = q - float3(0., -0.6, 0.03);
    nq = rotateX(nq, radians(-30));
    nq = rotateY(nq, radians(45));
    float nose = boxSDF(nq, float3(0.1, 0.1, 0.1));

    smoothStar = smoothUnion(smoothStar, nose, 0.2);
    
    // BOTTOM SPH
    float bottom = sphereSDF(q - float3(0., -1.36, 0.), 0.52);
    smoothStar = smoothSubtract(bottom, smoothStar, 0.15);
    
    // EYES
    float3 eyeScale = float3(1., 2., 0.7);
    float eyeScaleMin = min(min(eyeScale.x, eyeScale.y), eyeScale.z);

    float3 eq = mq - float3(0.12, -0.5, 0.19);
    eq = rotateX(eq, radians(30));
    eq /= eyeScale;

    float eye = sphereSDF(eq, 0.03) * eyeScaleMin;

    if (eye < smoothStar)
        materialID = 2;

    smoothStar = min(smoothStar, eye);

    // FEET
    float3 footScale = float3(0.6, 0.35, 1.);
    float footScaleMin = min(min(footScale.x, footScale.y), footScale.z);

    float3 fq = mq;
    fq = rotateY(fq, radians(-15));
    fq -= float3(0.15, -1., 0.2);
    
    fq /= footScale;

    float feet = sphereSDF(fq, 0.25) * footScaleMin;

    if (feet < smoothStar)
        materialID = RED;

    smoothStar = min(smoothStar, feet);

    return smoothStar;
}


float starAnimalSDF2(float3 q, out int materialID)
{
    return starAnimalSDF2BiColor(q, 0, materialID);
}

float starAnimalSDF2SpecColor(float3 q, int queryID, out int materialID)
{
    materialID = queryID;
    q -= float3(0., 1., 0.); // lift entire character

    // constants
    const float2 bodyAng = float2(sin(radians(30.0)), cos(radians(30.0)));
    const float2 armAng = float2(sin(radians(28.0)), cos(radians(28.0)));

    // BODY
    float3 bodyScale = float3(1., .95, 0.5);//float3(1., 1., 0.6);
    float3 bq = q / bodyScale;
    float body = coneSDF(bq, bodyAng, 1.0);
    body -= 0.06;//0.01;
    float bodyScaleMin = min(min(bodyScale.x, bodyScale.y), bodyScale.z);

    // MIRROR QUERY
    float3 mq = q;
    mq.x = abs(mq.x); // << Perfect mathematical symmetry here

    // ARMS
    float3 aq = (mq / bodyScale) - float3(0.6, -0.5, 0.);
    aq = rotateZ(aq, radians(75.0));

    float arms = coneSDF(aq, armAng, 0.4);
    arms -= 0.03;
    // BODY + ARMS
    float smoothStar = smoothUnion(body, arms, 0.02);
    smoothStar *= bodyScaleMin;

    // NOSE
    float3 nq = q - float3(0., -0.6, 0.03);
    nq = rotateX(nq, radians(-30));
    nq = rotateY(nq, radians(45));
    float nose = boxSDF(nq, float3(0.1, 0.1, 0.1));

    smoothStar = smoothUnion(smoothStar, nose, 0.2);
    
    // BOTTOM SPH
    float bottom = sphereSDF(q - float3(0., -1.36, 0.), 0.52);
    smoothStar = smoothSubtract(bottom, smoothStar, 0.15);
    
    // EYES
    float3 eyeScale = float3(1., 2., 0.7);
    float eyeScaleMin = min(min(eyeScale.x, eyeScale.y), eyeScale.z);

    float3 eq = mq - float3(0.12, -0.5, 0.19);
    eq = rotateX(eq, radians(30));
    eq /= eyeScale;

    float eye = sphereSDF(eq, 0.03) * eyeScaleMin;

    if (eye < smoothStar)
        materialID = 2;

    smoothStar = min(smoothStar, eye);

    // FEET
    float3 footScale = float3(0.6, 0.35, 1.);
    float footScaleMin = min(min(footScale.x, footScale.y), footScale.z);

    float3 fq = mq;
    fq = rotateY(fq, radians(-15));
    fq -= float3(0.15, -1., 0.2);
    
    fq /= footScale;

    float feet = sphereSDF(fq, 0.25) * footScaleMin;

    if (feet < smoothStar)
        materialID = RED;

    smoothStar = min(smoothStar, feet);

    return smoothStar;
}





// DEFAULT BEND --------------------------------------------------------------------------------
float stardanceSDF0(float3 query, out int materialID)
{
    float ret;
    materialID = YELLOW;
    
    query -= float3(0., -0.5, 0.);
    query = bendPoint(query, sin(TIME * 3.));
    
    float3 scale = float3(1., STIME * .01 + 1., 1.);
    query /= scale;
    
    
    float star2 = starAnimalSDF2(query, materialID);
    
    ret = star2;
    ret *= min(min(scale.x, scale.y), scale.z);
    
    return ret;
}

float stardanceSDF0Fast(float3 query, out int materialID)
{
    float ret;
    materialID = YELLOW;
    
    query -= float3(0., -0.5, 0.);
    query = bendPoint(query, sin(TIME * 3.2));
    
    float3 scale = float3(1., STIME * .01 + 1., 1.);
    query /= scale;
    
    
    float star2 = starAnimalSDF2(query, materialID);
    
    ret = star2;
    ret *= min(min(scale.x, scale.y), scale.z);
    
    return ret;
}

// ROTATE AND WALK
float stardanceSDF1(float3 query, out int materialID)
{
    float ret;
    materialID = YELLOW;
    
    // slide forward
    query.z -= TIME * 0.5 + 5.;
    
    // domain repeat along z
    int queryID = round(query.z / 1.2);
    query.z = query.z - 1.2 * round(query.z / 1.2);
    query -= float3(0., -0.5, 0.);
    
    // transforms
    query -= float3(0., -0.5, 0.);
    query = rotateY(query, 1.5 * (sin(TIME * 4.)) * query.y);
    
    float3 scale = float3(1., STIME * .01 + 1., 1.);
    query /= scale;
    
    // sdfs
    float star2 = starAnimalSDF2BiColor(query, queryID, materialID);
    ret = star2;
        
    ret *= min(min(scale.x, scale.y), scale.z);
    
    return ret;
}

// SPACIOUS DOMAIN REPETITION
float stardanceSDF2(float3 query, out int materialID)
{
    float ret;
    materialID = 0;
    
    // get query iD
    float spacing = 3.;
    float3 queryID = round(clamp(query.xyz, -10., +10.) / spacing);
    query.xyz -= spacing * queryID;
    
    // grid based variations
    
    float r = random(queryID.x + (queryID.y + 0.1) * (queryID.z + 29.));
    float2 r2 = float2(frac(r * 34.0), frac(r * 9.0));
    query += 0.2 * float3(r, r2);
    query.yz = mul(rot(queryID.x + TIME), query.yz);
    
    // transforms
    query -= float3(0., -0.5, 0.);
    query = rotateY(query, 2. * (sin(TIME * 4. + length(queryID))) * query.y);
    
    ret = starAnimalSDF2(query, materialID);
    return ret;
    
}


// AUDIO BASED HOP
float stardanceSDF3(float3 query, out int materialID)
{
    float ret;
    materialID = 0;
    
    int queryID = round(query.x / 1.5);
    query.x = query.x - 1.5 * round(query.x / 1.5);
    
    query -= float3(0., - 1.5, -10.);
    
    float3 scale = float3(1., 1., 1.);
    
    int offsetID = queryID + 3;
    if (offsetID < 8 & offsetID > 0)
    {
        // float h = _MeanLevels[(int)offsetID] * 30. + 0.8;
        // scale.y = h;
        float h = _PeakLevels[(int) offsetID] * 30.;
        float h2 = _MeanLevels[(int) offsetID] * 30.;
        
        // h = smoothstep(0.1, 4., h);
        // h2 = smoothstep(0.1, 4., h2);
        query.y -= h2;
        query = rotateY(query, h2 * 1.);
    }
    
    query /= scale;
    
    // sdfs
    float star2 = starAnimalSDF2BiColor(query, queryID, materialID);
    ret = star2;
    
    ret = star2;
    ret *= min(min(scale.x, scale.y), scale.z);
    
    return ret;
}


// SPACIOUS DOMAIN REPETITION
float stardanceSDF4(float3 query, out int materialID)
{
    float ret;
    materialID = 0;
    
    // get query iD
    float spacing = 3.;
    float3 queryID = round(clamp(query.xyz, -10., +10.) / spacing);
    query.x = abs(query.x) - 0.8;
    
    
    
    // transforms
    query -= float3(0., -0.5, 0.);
    query = rotateX(query, 1. * (sin(TIME * 6.2 )) * (query.y - 0.2));
    
    ret = starAnimalSDF2(query, materialID);
    return ret;
    
}
// ----------------------------------------------------------------------------------------------
// SUPER STAR (WITH SUNGLASSES)

float superStardanceSDF0(float3 query, out int materialID)
{
    float ret;
    materialID = 0;
    
    // domain repeat along z
    int queryID = round(query.z / 1.5);
    query.z = query.z - 1.5 * round(query.z / 1.2);
    query -= float3(0., -0.5, 0.);
    
    query -= float3(0., -0.5, 0.);
    query = bendPoint(query, sin(TIME * 8.));
    
    float3 scale = float3(1., STIME * .01 + 1., 1.);
    query /= scale;
    
    // sdfs
    float sunglasses = sunglassesSDF(query - float3(0., 0.48, 0.25), 0.5);
    float star2 = starAnimalSDF2SpecColor(query, queryID, materialID);
    
    // material
    materialID = star2 < sunglasses ? materialID : RED;

    ret = min(star2, sunglasses);
    ret *= min(min(scale.x, scale.y), scale.z);
    
    return ret;
}

// ROTATE AND WALK
float superStardanceSDF1(float3 query, out int materialID)
{
    float ret;
    materialID = 0;
    
    // slide forward
    query.z -= TIME * 0.5 + 5.;
    
    // domain repeat along z
    float spacing = 1.2;
    int queryID = round(query.z / spacing);
    int matSeed = round(query.z / spacing) * 73 + round(query.x / spacing) * 13;
    query.z = query.z - spacing * round(query.z / spacing);
    query.x = query.x - spacing * round(query.x / spacing);
    
    query -= float3(0., -0.5, 0.);
    
    // transforms
    
    query -= float3(0., -0.5, 0.);
    query = rotateY(query, 2. * (sin(TIME * 4.)) * query.y);
    
    
    float3 scale = float3(1., STIME * .01 + 1., 1.);
    query /= scale;
    
    // sdfs
    
    float star2 = starAnimalSDF2SpecColor(query, matSeed, materialID);
    ret = star2;
    bool isOdd = (queryID & 1) != 0;
    if (isOdd)
    {
        float sunglasses = sunglassesSDF(query - float3(0., 0.47, 0.23), 0.5);
        // material
        materialID = star2 < sunglasses ? materialID : RED;
        ret = min(star2, sunglasses);
    }
        
    ret *= min(min(scale.x, scale.y), scale.z);
    
    return ret;
}

// crazy star dance
float superStardanceSDF2(float3 query, out int materialID)
{
    float ret;
    materialID = 0;
    // query.z -= TIME * 0.5 + 5.;
    
    // get query iD
    float spacing = 3.;
    int matSeed = round(query.z / spacing) * 733 + round(query.x / spacing) * 193 * round(query.y / spacing);
    // float3 queryID = round(clamp(query.xyz, -10., +10.) / spacing);
    float3 queryID = round(clamp(query.xyz, -10., +10.) / spacing);
    query.xyz -= spacing * queryID;
    
    // grid based variations
    
    float r = random(queryID.x + (queryID.y + 0.1) * (queryID.z + 29.));
    float2 r2 = float2(frac(r * 34.0), frac(r * 9.0));
    query += 0.2 * float3(r, r2);
    query.yz = mul(rot(queryID.x + TIME), query.yz);
    
    // transforms
    query -= float3(0., -0.5, 0.);
    query = rotateY(query, 2. * (sin(TIME * 8. + length(queryID))) * query.y);
  
    
    // sdfs
    float sunglasses = sunglassesSDF(query - float3(0., 0.5, 0.23), 0.5);
    float id = queryID.x + queryID.y * spacing + queryID.z * spacing * spacing;
    float star2 = starAnimalSDF2SpecColor(query, matSeed, materialID);
    
    
    // material
    materialID = star2 < sunglasses ? materialID : RED;

    ret = min(star2, sunglasses);
  
    return ret;
}

// crazy star dance 2 larger domain repetition
float superStardanceSDF4(float3 query, out int materialID)
{
    float ret;
    materialID = 0;
    // query.z -= TIME * 0.5 + 5.;
    
    // get query iD
    float spacing = 3.;
    int matSeed = round(query.z / spacing) * 733 + round(query.x / spacing) * 193 * round(query.y / spacing);
    // float3 queryID = round(clamp(query.xyz, -10., +10.) / spacing);
    float3 queryID = round(clamp(query.xyz, -50., +50.) / spacing);
    query.xyz -= spacing * queryID;
    
    // grid based variations
    
    float r = random(queryID.x + (queryID.y + 0.1) * (queryID.z + 29.));
    float2 r2 = float2(frac(r * 34.0), frac(r * 9.0));
    query += 0.2 * float3(r, r2);
    query.yz = mul(rot(queryID.x + TIME), query.yz);
    
    // transforms
    query -= float3(0., -0.5, 0.);
    query = rotateY(query, 2. * (sin(TIME * 8. + length(queryID))) * query.y);
  
    
    // sdfs
    float sunglasses = sunglassesSDF(query - float3(0., 0.5, 0.23), 0.5);
    float id = queryID.x + queryID.y * spacing + queryID.z * spacing * spacing;
    float star2 = starAnimalSDF2SpecColor(query, matSeed, materialID);
    
    
    // material
    materialID = star2 < sunglasses ? materialID : RED;

    ret = min(star2, sunglasses);
  
    return ret;
}

float superStardanceSDF3(float3 query, out int materialID)
{
    float ret;
    materialID = 0;
    
    // domain repeat along x z
    query -= float3(0., -1.5, -10.);
    
    int queryID = round(query.x / 1.5);
    query.x = query.x - 1.5 * round(query.x / 1.5);
    query.z = query.z - 1.5 * round(query.z / 1.5);
    
    
    float3 scale = float3(1., 1., 1.);
    
    int offsetID = queryID + 3;
    int sign = 1 - 2 * (offsetID & 1);
    if (offsetID < 8 & offsetID > 0)
    {
        // float h = _MeanLevels[(int)offsetID] * 30. + 0.8;
        // scale.y = h;
        float h = _PeakLevels[(int) offsetID] * 30.;
        float h2 = _MeanLevels[(int) offsetID] * 30.;
        
        // h = smoothstep(0.1, 4., h);
        // h2 = smoothstep(0.1, 4., h2);
        query.y -= h2;
        query = rotateY(query, h * sign);
    }
    
    query /= scale;
    
    // sdfs
    float star2 = starAnimalSDF2(query, materialID);
    ret = star2;
    bool isOdd = (queryID & 1) != 0;
    if (isOdd)
    {
        float sunglasses = sunglassesSDF(query - float3(0., 0.47, 0.23), 0.5);
        // material
        materialID = star2 < sunglasses ? materialID : RED;
        ret = min(star2, sunglasses);
    }
        
    ret *= min(min(scale.x, scale.y), scale.z);
    
    return ret;
}

// audio reactive with many layers
float superStardanceSDF5(float3 query, out int materialID)
{
    float ret;
    materialID = 0;
    
    
    int queryID = round(query.x / 1.5);
    query.x = query.x - 1.5 * round(query.x / 1.5);
    query.y = query.y - 1.5 * round(query.y / 1.5);
    
    query -= float3(0., -1.5, -10.);
    
    float3 scale = float3(1., 1., 1.);
    
    int offsetID = queryID + 3;
    int sign = 1 - 2 * (offsetID & 1);
    if (offsetID < 8 & offsetID > 0)
    {
        // float h = _MeanLevels[(int)offsetID] * 30. + 0.8;
        // scale.y = h;
        float h = _PeakLevels[(int) offsetID] * 30.;
        float h2 = _MeanLevels[(int) offsetID] * 30.;
        
        // h = smoothstep(0.1, 4., h);
        // h2 = smoothstep(0.1, 4., h2);
        query.y -= h2;
        query = rotateY(query, h * sign);
    }
    
    query /= scale;
    
    // sdfs
    float star2 = starAnimalSDF2(query, materialID);
    ret = star2;
    bool isOdd = (queryID & 1) != 0;
    if (isOdd)
    {
        float sunglasses = sunglassesSDF(query - float3(0., 0.47, 0.23), 0.5);
        // material
        materialID = star2 < sunglasses ? materialID : RED;
        ret = min(star2, sunglasses);
    }
        
    ret *= min(min(scale.x, scale.y), scale.z);
    
    return ret;
}

// ----------------------------------------------------------------------------------------------

float starTunnelSDF2(float3 query, out int materialID)
{ 
    
    float speed = 0.;
    for (int i = 0; i < 4; i++)
    {
        speed += _MeanLevels[i] * 10.;

    }
        
    speed = abs(speed) * 5.;
    float2 offset = 0.1 * float2(CTIME, STIME);
    // float2 offset = 0.1 * float2(cos(speed), sin(speed));
    // query.xy += offset;
    query.xy = mul(rot(TIME), query.xy);
    
    float spacing = .4;
    query -= float3(0., 0., TIME * 2.);
    float queryID = round(clamp(query.z, -10. - TIME * 2., 1.) / spacing);
    query.z = query.z - spacing * queryID;
    
    float plane = abs(query.z) - 0.001; // width 0.01
    
    
    float3 sq = query / float3(speed, speed, speed);
    float starFlat = sdfPentagram(sq.xy, 0.5);
    starFlat *= speed;
    
    float starExtruded = max(starFlat, abs(query.z) - 0.1);
    
    float d = max(-starExtruded, plane);
    
    materialID = queryID;
    return d;
}

float starTunnelSDF3(float3 query, out int materialID)
{
                // float speed = 0.;
                // for (int i = 0; i < 4; i++)
                // {
                //     speed += _MeanLevels[i] * 10.;
            
                // }

    float speed = 3.; //_MeanLevels[2] * 1;
                    
                // parameters
    float2 offset = 0.05 * float2(cos(TIME + 0.3), STIME);
    float forwardSpeed = TIME * (speed); //TIME * 3.;
                
                // spin
    query.xy = mul(rot(TIME), query.xy);
                
    float spacing = .4;
    query -= float3(0., 0., forwardSpeed);
    float queryID = round(clamp(query.z, -10. - forwardSpeed, 1.) / spacing);
    query.z = query.z - spacing * queryID;
                
    float plane = abs(query.z) - 0.001; // width 0.01
                
                // float3 sq = query / float3(speed, speed, speed);
    float starFlat = sdfPentagram(query.xy, 0.5);
                // starFlat *= speed;
                
    float starExtruded = max(starFlat, abs(query.z) - 0.1);
                
    float d = max(-starExtruded, plane);
                
    materialID = queryID;
    return d;
}

            

float starTunnelSDF4(float3 query, out int materialID)
{
    float tunnelEndz = -23.;
                // rotate
    float angle = .1 * query.z + TIME;
    query.xy = mul(rot(angle), query.xy);

                
                // star creature
    float3 sq = query - float3(0., 0., tunnelEndz - 1.);
    sq = rotateX(sq, radians(180.));
    float scale = 0.3;
    sq /= scale;
    float starCreature = stardanceSDF0(sq, materialID);
    starCreature *= scale;

                // z axis domain repetition 
    float spacing = .4;
    float queryID = round(clamp(query.z, tunnelEndz, -tunnelEndz) / spacing);
    query.z = query.z - spacing * queryID;
                
                // star tunnel
    float starFlat = sdfPentagram(query.xy, 0.5);
    starFlat = starFlat - 0.03; // round
    starFlat = abs(starFlat) - 0.01; // near-edge only
    float starExtruded = max(starFlat, abs(query.z) - 0.1);
                
    float d = min(starExtruded, starCreature);

    if (starExtruded < starCreature)
    {
        materialID = queryID + 50;
    }
                
    return d;
}
// ----------------------------------------------------------------------------------------------

            // modified for sdf
            // star folding is at the dents
float2 kofFractal4(float2 uv, int numLoops, out float scale)
{
                // zoom out, move up
    uv *= 2.;
    uv.y -= tan(radians(54.)) * 0.5;
            
                // star folding (at the dents)
    uv.x = abs(uv.x);
              
    float center = tan(radians(54.));
    +tan(radians(72.));
    float baseRad = 0.5;
            
    float2 nor1 = getAngleNor(radians(54.));
    uv = uv - nor1 * min(0., dot(nor1, uv - float2(-baseRad, -center))) * 2.;
                            
    nor1 = getAngleNor(radians(306.));
    uv = uv - nor1 * min(0., dot(nor1, uv - float2(-baseRad, 0.))) * 2.;
            
                // arb line reflection params
    float2 nor = getAngleNor(radians(TIME * 10.)); //radians(240));getAngleNor(radians(240));
            
                            // folding
    scale = 1.;
    for (int i = 0; i < numLoops; i++)
    {
                    // #0 put back into operation space
        if (i > 0)
        {
            uv *= 3.;
            uv.x -= 1.5;
                        
        }
        scale *= 3.;
                    // #1 half reflection 
        uv.x = abs(uv.x);
        uv.x -= 0.5;
                    // angle reflection
        uv = uv - nor * min(0., dot(uv, nor)) * 2.; // BENDER, dot is the distance proj
                    // uv = uv - nor * min(0., dot(uv, nor)) * 2. * STIME; // maybe cool
    }
                // uv /= scale;
    return uv;
}

float kofSDF1(float3 query, out int materialID)
{
    materialID = 1;

                // float thickness = 0.03;
                // float complexity = 2;3. * (_fracBeat) + 1;
                // float lerpTime = 0.;

    float thickness = 0.03;
    float complexity = 2.; //3. * (_fracBeat) + 1;
    float lerpTime = 0.;

                // XY
    float scaleXY;
    float2 kofXY = kofFractal4(query.xy, complexity, scaleXY);
    kofXY /= scaleXY;
    float dXY = lerp(kofXY.x, kofXY.y, lerpTime);
                // dXY = abs(dXY) - 0.01;
            
    float slabXY = abs(query.z) - thickness;
    float sdfXY = max(dXY, slabXY);
            
                // YZ
    float scaleYZ;
    float2 kofYZ = kofFractal4(query.yz, complexity, scaleYZ);
    kofYZ /= scaleYZ;
    float dYZ = lerp(kofYZ.x, kofYZ.y, lerpTime);
                // dYZ = abs(dYZ) - 0.01;

    float slabYZ = abs(query.x) - thickness;
    float sdfYZ = max(dYZ, slabYZ);
            
                // ZX
    float scaleZX;
    float2 kofZX = kofFractal4(query.zx, complexity, scaleZX);
    kofZX /= scaleZX;
    float dZX = lerp(kofZX.x, kofZX.y, lerpTime);
                // dZX = abs(dZX) - 0.01;

    float slabZX = abs(query.y) - thickness;
    float sdfZX = max(dZX, slabZX);
            
                // union
                // float finalSDF = smoothUnion(sdfXY, smoothUnion(sdfYZ, sdfZX, 0.5), 0.5);
    float finalSDF = min(sdfXY, min(sdfYZ, sdfZX));
    return finalSDF;
}
// ----------------------------------------------------------------------------------------------------

float sceneSDF(float3 query, out int materialID, int sceneVer); // defined in each raymarch shader


float sceneSDF_noMat(float3 p, float time, int sceneVer)
{
    int dummy;
    return sceneSDF(p, dummy, sceneVer);
}

// ------------------------ NORMAL ------------------------
float3 calculateNormal(float3 p, float time, int sceneVer)
{
    float3 dx = float3(NORMALEPSILON, 0.0, 0.0);
    float3 dy = float3(0.0, NORMALEPSILON, 0.0);
    float3 dz = float3(0.0, 0.0, NORMALEPSILON);

    float nx = sceneSDF_noMat(p + dx, time, sceneVer) - sceneSDF_noMat(p - dx, time, sceneVer);
    float ny = sceneSDF_noMat(p + dy, time, sceneVer) - sceneSDF_noMat(p - dy, time, sceneVer);
    float nz = sceneSDF_noMat(p + dz, time, sceneVer) - sceneSDF_noMat(p - dz, time, sceneVer);

    return normalize(float3(nx, ny, nz));
}


float beatSum()
{
    float beatSum = 0.;
    for (int i = 0; i < 8; i++)
    {
        beatSum = _MeanLevels[i];
    }
                
    beatSum = beatSum * 5000.;
    beatSum = pow(beatSum, 0.4);
    return beatSum;
}
            
// ------------------------ RAY MARCH ------------------------
Intersection sdfRayMarch(Ray ray, float time, int sceneVer)
{
    Intersection intersection;
    float3 queryPoint = ray.origin;
    int mat;
    
    float bloomAccum = 0.;
    
            
    float signedDist = sceneSDF(queryPoint, mat, sceneVer);
            
    for (int i = 0; i < MAX_ITER; ++i)
    {
        // accumulate bloom light v1
        float fallOff = 8.;
        float d = max(signedDist, 0.0);
        float light = 1. / pow((d * 10. + 0.8) * fallOff, 2.);
        light = min(1., light);
        bloomAccum += light;
        
        // accumulate bloom light v2
        //float fallOff = 2.;
        //float light = 1. / pow((signedDist * 10. + 0.1) * fallOff, 2.);
        //light *= signedDist;
        //bloomAccum += light;
        
        if (abs(signedDist) < EPSILON)
        {
            intersection.hit = true;
            intersection.position = queryPoint;
            intersection.normal = calculateNormal(queryPoint, time, sceneVer);
            intersection.distance = length(queryPoint - ray.origin);
            intersection.materialID = mat;
            intersection.steps = i;
            intersection.bloom = bloomAccum;
            return intersection;
        }
        
        
        
        queryPoint += ray.dir * signedDist;
        signedDist = sceneSDF(queryPoint, mat, sceneVer);
    }
                
    intersection.hit = false;
    intersection.distance = -1.0; // no hit
    intersection.materialID = 0;
    intersection.normal = float3(0.5, 9.5, 0.5);
    intersection.bloom = bloomAccum;
    return intersection;
}

