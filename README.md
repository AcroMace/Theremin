# Theramin

Playing music with your hands using the Vision framework, vaguely based off the Theramin

## Getting started

1. Open `Theramin.xcodeproj`
2. Build and run on an iOS device (note: it only supports portrait mode)
3. Move your index finger up and down to play different frequencies

## Notes

- It's currently configured to track up to two hands
- A hand that appears on the left half of the screen will be considered the left hand and play a frequency between A4 (440 Hz) and A5 (880 Hz)
- A hand that appears on the right half of the screen will be considered the left hand and play a frequency between A5 and A6 (1760 Hz)
- While the index finger is preferred, it will try and fall back to the thumb if the index finger cannot be detected. This is controlled in `pointForHandObservation` in `HandPositionController`

## Possible upgrades

- Unlike an actual theramin, there's no volume control here. You could add it fairly easily by exposing the volume from the `ToneGenerator` and setting it with one of the detected hands in `TheraminViewController`.
- You could make 3+ hands support in `TheraminViewController` by removing the assumption of just having the left and right hand. One way could be sorting by x-position and mapping to a list of tone generators instead. Another harder way might be using RealityKit and anchoring a ToneGenerator to a body tracking anchor.
- Landscape mode!
- This compiles and runs and works surprisingly well on Mac but the camera feed looks zoomed in. I suspect this could be fixed the same way as landscape mode.

## References

A lot of the code is from the following two resources:

- Hand position: [Apple's sample code for Detecting Hand Poses with Vision](https://developer.apple.com/documentation/vision/detecting_hand_poses_with_vision).
- Tone generation: [Matt Gallagher – An iOS tone generator](https://www.cocoawithlove.com/2010/10/ios-tone-generator-introduction-to.html)
