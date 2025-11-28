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

        // Debug.Log(spectrum.highestBeat4);
        Shader.SetGlobalFloat("_highestBeat4", spectrum.highestBeat4);
        Shader.SetGlobalFloat("_time", Time.time);
        // Debug.Log(Time.time);

        // bpm
        float bpm = 58.0f;
        float secPerBeat = 60.0f / bpm;
        float beat = Time.time / secPerBeat + 0.6f; // int + frac
        int intBeat = (int)Mathf.Floor(beat); // integer beat count (increments every beat)
        float fracBeat = beat - intBeat; // fractional phase of the beat (0 to 1)

        Shader.SetGlobalInt("_intBeat", intBeat);
        Shader.SetGlobalFloat("_fracBeat", fracBeat);

    }
}
