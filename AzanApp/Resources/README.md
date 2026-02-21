# Audio Resources

Due to the iOS sandbox and background execution limits, custom notification sounds must be bundled with the app inside this folder.
The `xcodegen` configuration will automatically bundle any audio file placed here into the final iOS `.ipa`.

## How to add custom Azan sounds

1. Place your `.caf` or `.aiff` or `.wav` sound files in this directory.
    - Example: `makkah.caf`
    - *Note: iOS limits background playback of notification sounds to 30 SECONDS.*
2. Once placed here, run `xcodegen` (or let the GitHub action run).
3. In the app settings, manually type the exact filename (e.g. `makkah.caf`) to use it.
