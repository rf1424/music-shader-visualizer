using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AudioPlayControl : MonoBehaviour
{
    public AudioSource audioSource;
    public float startTime = 0f;
    bool firstTime = true;
    // Start is called before the first frame update
    void Start()
    {
        audioSource.time = startTime;
        audioSource.Play();
    }

    // Update is called once per frame
    void Update()
    {
        // jump from 137sec to 150sec
        //if (audioSource.time > 132.8f && firstTime)
        //{
        //    audioSource.time = 162.5f;
        //    firstTime = false;
        //}
    }
}