using UnityEngine;

[ExecuteInEditMode]
public class ImageEffect : MonoBehaviour
{
    public Material material;
    private RenderTexture rt1;
    // private RenderTexture rt2;

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {     
        rt1 = RenderTexture.GetTemporary(source.width, source.height);
        //rt2 = RenderTexture.GetTemporary(source.width, source.height);
        
        Graphics.Blit(source, rt1, material, 0);
        Graphics.Blit(rt1, destination);
        
        RenderTexture.ReleaseTemporary(rt1);

    }
}
