using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AudioPlayControl : MonoBehaviour
{
    public AudioSource audioSource;
    public float startTime = 46.8f;


    public float loopStart = 46.8f;
    public float loopEnd = 229f;
    // Start is called before the first frame update
    void Start()
    {
        audioSource.time = startTime;
        audioSource.Play();
    }

    // Update is called once per frame
    void Update()
    {
        // If we pass the loop end, jump back to loop start
        if (audioSource.time >= loopEnd)
        {
            audioSource.time = loopStart;
        }

    }
}