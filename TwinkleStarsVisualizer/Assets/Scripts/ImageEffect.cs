using System;
using System.Collections.Generic;
using UnityEngine;

// [ExecuteInEditMode]
public class ImageEffect : MonoBehaviour
{

    public AudioSource audioSource;

    public Material material;

    public List<Material> materials;
    int materialIndex = 0;

    private RenderTexture rt1;
    // private RenderTexture rt2;

    void Update()
    {
        float t = audioSource.time;
        float localT = t;
        float bpm = 58.0f;
        float offset = 0.6f;


        if (t < 75f) // intro
        {
            materialIndex = 0;
            localT = t - 46.8f;
            offset = 0.4f;
        }
        else if (t < 100f) // jolly
        {
            materialIndex = 1;
            localT = t - 75f;
            offset = 0;
        }
        else if (t < 134.70f) // soft
        {
            materialIndex = 2;
            localT = t - 100f;
        }
        else if (t < 162.5f) // superjolly
        {
            materialIndex = 3;
            localT = t - 133.8f;
            bpm = 72.0f;
            offset = 0f;
        }
        else if (t < 200.0f)// spinny
        {
            materialIndex = 4;
            localT = t - 162.5f;
        }
        else {
            materialIndex = 5;
            localT = t - 200.0f;
        }

        // Debug.Log(t);

        material = materials[materialIndex];

        Shader.SetGlobalFloat("_time", localT);
        // bpm
        // float bpm = 58.0f;
        float secPerBeat = 60.0f / bpm;
        float beat = localT / secPerBeat + offset; // int + frac
        int intBeat = (int)Mathf.Floor(beat); // integer beat count (increments every beat)
        float fracBeat = beat - intBeat; // fractional phase of the beat (0 to 1)

        Shader.SetGlobalInt("_intBeat", intBeat);
        Shader.SetGlobalFloat("_fracBeat", fracBeat);
    }


    void OnEnable()
    {  
        rt1 = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32);
        rt1.Create();
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material == null) return;

        Graphics.Blit(source, rt1, material, 0);
        Graphics.Blit(rt1, destination, material, 1);
    }

    void OnDisable()
    {
        // Clean up
        if (rt1 != null) rt1.Release();
    }
}
