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

        Debug.Log(t);
        if (t < 75f) materialIndex = 3; // TEMP
        else if (t < 100f) materialIndex = 1;
        else if (t < 162f) materialIndex = 2;
        else if (t < 200f) materialIndex = 3;

        material = materials[materialIndex];
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
