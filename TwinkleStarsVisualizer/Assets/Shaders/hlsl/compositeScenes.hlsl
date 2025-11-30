

// COMPOSITE SCENES ----------------------------------------------------------------
float3 squareVignette(float2 uv)
{
                
    uv = scroll(uv, float2(0.5, 0.));
                // PARAMETERS
    float repeaterX = ceil(5. * LINTIME) + 1.; // CP0
    uv.x = remapRepeat(uv.x, repeaterX);
    uv.y *= repeaterX;
                // uv.x = remapRepeat(uv.x, 2);
                // uv.y = remapRepeat(uv.y, 2);

    float2 size = float2(0.1, 0.1); // CP2
    float edgeR = 0.1 * STIME; // CP3
                // uv = scroll(uv, float2(0.5, 0.));


    float boxSDF = sdRoundedBox(uv, size, edgeR);
                //float starSDF = sdfPentagram(uv * 5. * LINTIME, 0.3);
                //boxSDF = min(boxSDF, starSDF);

    float box = boxSDF < 0.0 ? 1.0 : 0.0;
    float3 col = float3(box, box, box);
    return col;
}

// fractal stuff
// float beatSum = _MeanLevels[4] + _MeanLevels[5];
//                 beatSum = beatSum * 2000.;
//                 beatSum = pow(beatSum, 0.4);
//                 // float d = step(length(frac(uv * 2.)), beatSum);
// float d = step(length(frac(uv * 2.)), beatSum);
//                 // uv = scroll(uv, beatSum);
//                 d = starChecker(uv, beatSum * 10.);
// 
// float3 bgColor = d * random3(_intBeat);