using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AudioToShader : MonoBehaviour
{
    private AudioSpectrum spectrum;

    // Start is called before the first frame update
    void Start()
    {
        spectrum = GetComponent<AudioSpectrum>();
    }

    // Update is called once per frame
    void Update()
    {
        if (spectrum == null | spectrum.Levels == null) {
            return;
        }
        
        // using 8 bands
        Shader.SetGlobalFloatArray("_Levels", spectrum.Levels);
        Shader.SetGlobalFloatArray("_PeakLevels", spectrum.PeakLevels);
        Shader.SetGlobalFloatArray("_MeanLevels", spectrum.MeanLevels);

        Shader.SetGlobalFloat("_highestBeat4", spectrum.highestBeat4);
        // Shader.SetGlobalFloat("_time", Time.time);
        

        

    }
}
