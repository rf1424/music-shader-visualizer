using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AudioPlayControl : MonoBehaviour
{
    public AudioSource audioSource;
    public float startTime = 5f;
    // Start is called before the first frame update
    void Start()
    {
        audioSource.time = startTime;
        audioSource.Play();
    }

    // Update is called once per frame
    void Update()
    {

    }
}