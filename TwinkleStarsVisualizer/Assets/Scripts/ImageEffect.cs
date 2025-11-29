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

        if (t < 75f) // intro
        {
            materialIndex = 0;
            localT = t - 0f;
        }
        else if (t < 100f) // jolly
        {
            materialIndex = 1;
            localT = t - 75f;
        }
        else if (t < 133.8f) // soft
        {
            materialIndex = 2;
            localT = t - 100f;
        }
        else if (t < 162.5f) // superjolly
        {
            materialIndex = 3;
            localT = t - 133.8f;
        }
        else // spinny
        {
            materialIndex = 4;
            localT = t - 162.5f;
        }

        material = materials[materialIndex];
        Shader.SetGlobalFloat("_time", localT);
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
