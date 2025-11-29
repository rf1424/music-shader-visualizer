using UnityEngine;

[ExecuteInEditMode]
public class ImageEffect : MonoBehaviour
{

    public AudioSource audioSource;

    public Material material;
    private RenderTexture rt1;
    // private RenderTexture rt2;


    void OnEnable()
    {  
        rt1 = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32);
        rt1.Create();
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {     
        Graphics.Blit(source, rt1, material, 0);
        Graphics.Blit(rt1, destination, material, 1);
    }

    void OnDisable()
    {
        // Clean up
        if (rt1 != null) rt1.Release();
    }
}
