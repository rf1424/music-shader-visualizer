# Twinkle Star Music Video


[![Pp Blend1](image/ppBlend1.png)](https://github.com/your/repo)
# [LINK TO VIDEO HERE](https://youtu.be/CtJviZKfxnU)

This was an attempt for me to create a real-time music video/audio visualizer entirely using shaders.
For my music, I used variations from [*7 Variations of Twinkle Twinkle Little Star*](https://youtu.be/IpqFDOliUpA?si=YhmFR4N3xhVINMSU) by the pianist Hayato Sumino.
My goal was to make a different shader that match the tone of each variation.
I used Unity as my platform. 


SCENE 1
![Scenelerp](image/scenelerp.png)
SCENE 2
![Sdf1](image/sdf1.png)
SCENE 3
![Scene3](image/scene3.png)
SCENE 4
![Scene Jolly](image/sceneJolly.png)
SCENE 5
![Scene Spinny](image/sceneSpinny.png)
SCENE 6
![Scene Mix](image/sceneMix.png)

## BREAKDOWNS

### Visualizing audio: Sound to Screen
In order to convert the sound into different audio bands, I used this [unity-audio-spectrum](https://github.com/keijiro/unity-audio-spectrum) script. 
I also passed in BPM and time variables to control scene switches.

Here is an example of translating the audio bands into the y-positions and rotations
of the stars. 
![A U D I O](image/AUDIO.png)
![A U D I O S T A R](image/AUDIOSTAR.png)
### Shader Implementations

#### SDFs
I creatured a star character that appears in all of my scenes by SDF modeling.
![Sdf0](image/sdf0.png)
They have tails:
![Sdf3](image/sdf3.png)

Domain Repetition of the Star Creatures:
![Sdf2](image/sdf2.png)
![Domain Rep0](image/domainRep0.png)
![Domain Rep2](image/domainRep2.png)
![Domain Rep1](image/domainRep1.png)

Domain Repetition for the Star Tunnel, base SDF by extruding star at the edges:
![Domain Rep3](image/domainRep3.png)
Domain-repeat along z-axis:
![Tunnel Domain Rep1](image/tunnelDomainRep1.png)
Twist along z:
![Tunnel Domain Rep2](image/tunnelDomainRep2.png)
#### KIFS Fractals
I followed this [tutorial](https://youtu.be/__dSLc7-Cpo?si=G0Z9K2c7RjMLnStR) create KIFS fractals. This is a technique that folds UV space recursively to create fractals like origami.

![Kof Fold0](image/kofFold0.png)
![Kof Fold1](image/kofFold1.png)
![Kof Fold2](image/kofFold2.png)
![Kof Fold3](image/kofFold3.png)
Using this to fold this sparkle pattern:
![Kof Sparkle1](image/kofSparkle1.png)
![Kof Sparkle0](image/kofSparkle0.png)

Applying KIF Fractals to 3D space:
![Kofsdf U V](image/kofsdfUV.png)
Take the x-coords:
![Kofsdf Xvalue](image/kofsdfXvalue.png)
Use it as 2D distance field:
![Kofsd2d](image/kofsd2d.png)
Extrude:
![Kof3dextrude](image/kof3dextrude.png)
Extrude along all three axis and union them:
![Kof3dall Axis](image/kof3dallAxis.png)

#### Post processing effects
Original:
![Pp Kif1](image/ppKif1.png)
Overlay kif fractal outlines, randomly domain-repeated sparks:
![Pp Kif0](image/ppKif0.png)

UV distortions:
![Noise U V0](image/noiseUV0.png)
![Noise U V](image/noiseUV.png)

![Mobius Transform2](image/mobiusTransform2.png)
![Mobius Transform1](image/mobiusTransform1.png)
Original:
![Pp Blend Orig](image/ppBlendOrig.png)
Mask: 
![Pp Blend Mask](image/ppBlendMask.png)
Blend using mask, invert colors:
![Pp Blend3](image/ppBlend3.png)
Posterize:
![Pp Blend2](image/ppBlend2.png)
Overlay outline with distortion:
![Pp Blend0](image/ppBlend0.png)




## Post Mortem
I had a lot of fun writing shaders. I learned a lot of interesting shader and audio visual techniques. 
Thinking of a way to visualize audio nicely was a challenge, and I hope to explore 
how others creatively translate audio to visual more.

I have been considering why this project makes sense to build with real-time shaders. At times, I spent a lot of 
effort making dynamic camera movements or optimizing runtime performance. These were tasks that might have been 
simpler in a traditional 3D tool, especially since this project was tied to a specific audio track.
At the same time many cool techniques built on shader capabilities - fractal generation, domain repetition, smooth 
SDF blending, and other procedural techniques that are hard to achieve as efficiently with other tools. 
I hope to explore more on what shaders are good at so I can utilize its power to a greater extent. Overall this project
was a great combination of technical and artistic :star:

## References
- [unity-audio-spectrum](https://github.com/keijiro/unity-audio-spectrum)
- [KIFS fractals tutorial](https://youtu.be/__dSLc7-Cpo?si=G0Z9K2c7RjMLnStR)
- [Noise functions](https://iquilezles.org/articles/gradientnoise/) / [2D](https://iquilezles.org/articles/distfunctions2d/) / [3D SDFs](https://iquilezles.org/articles/distfunctions/) by Inigo Quilez
