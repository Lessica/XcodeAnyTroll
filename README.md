# XcodeAnyTroll

This jailbreak tweak allows you to “run” app directly from Xcode without code signing or with any entitlements.

## How to use?

1. Install this tweak from <https://apt.82flex.com>
2. Open Xcode and modify the target settings of your app: `CODE_SIGNING_ALLOWED=NO`
3. Add a “Run Script” phase to your target with the following content:

    ```bash
    ldid -S${CODE_SIGN_ENTITLEMENTS} ${CODESIGNING_FOLDER_PATH}
    ```
