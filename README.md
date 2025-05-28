# XcodeAnyTroll

**⚠️ This is a developer tweak. Use with caution.**

This jailbreak tweak allows you to “click-to-run” (and debug) app directly from Xcode without code signing or with any entitlements.

Which makes it super easy to develop TrollStore based system apps, or to test your own apps without the need to sign them with a developer certificate.

Tested on iOS 15.0/15.4/16.2/16.4/16.5.1 with Dopamine and Dopamine (RootHide) jailbreaks.

## How to use?

1. (RootHide) Install “Xcode Any Debug” from <https://roothide.github.io>
2. (Other) Install and configure “XcodeRootDebug” from <https://apt.82flex.com>
3. Install this tweak from <https://apt.82flex.com>
4. Open Xcode and modify the target settings of your app: `CODE_SIGNING_ALLOWED=NO`

    <img width="499" alt="截屏2025-05-29 上午5 05 42" src="https://github.com/user-attachments/assets/7ca46b03-6554-4e57-a1b8-04e709e1a0bc" />

7. Add a “Run Script” phase to your target with the following content:

    ```bash
    if [ "$CODE_SIGNING_ALLOWED" = "NO" ]; then
      ldid -S${CODE_SIGN_ENTITLEMENTS} ${CODESIGNING_FOLDER_PATH}
    fi
    ```

    <img width="743" alt="截屏2025-05-29 上午5 06 20" src="https://github.com/user-attachments/assets/611ee75d-006f-423e-a855-112f31aad808" />

## LICENSE

WTFPL License
