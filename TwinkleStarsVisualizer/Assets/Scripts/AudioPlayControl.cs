using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static ImageEffect;

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
    //void Update()
    //{
    //    // If we pass the loop end, jump back to loop start
    //    if (audioSource.time >= loopEnd)
    //    {
    //        audioSource.time = loopStart;
    //    }

    //}

    void Update()
    {
        // loop
        if (audioSource.time >= loopEnd)
        {
            audioSource.time = loopStart;
        }

        
        if (Input.GetKeyDown(KeyCode.Alpha1))
        {
            JumpToScene(SceneStartTimes.scene1Start);
        }
        else if (Input.GetKeyDown(KeyCode.Alpha2))
        {
            JumpToScene(SceneStartTimes.scene2Start);
        }
        else if (Input.GetKeyDown(KeyCode.Alpha3))
        {
            JumpToScene(SceneStartTimes.scene3Start);
        }
        else if (Input.GetKeyDown(KeyCode.Alpha4))
        {
            JumpToScene(SceneStartTimes.scene4Start);
        }
        else if (Input.GetKeyDown(KeyCode.Alpha5))
        {
            JumpToScene(SceneStartTimes.scene5Start);
        }
        else if (Input.GetKeyDown(KeyCode.Alpha6))
        {
            JumpToScene(SceneStartTimes.scene6Start);
        }
    }

    void JumpToScene(float sceneTime)
    {
        audioSource.time = sceneTime;
        audioSource.Play();
    }
}