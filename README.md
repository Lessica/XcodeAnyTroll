# XcodeAnyTroll

This jailbreak tweak allows you to “run” app directly from Xcode without code signing or with any entitlements.

Which makes it super easy to develop TrollStore based system apps, or to test your own apps without the need to sign them with a developer certificate.

Tested on iOS 15.0/15.4/16.2/16.4/16.5.1 with Dopamine and Dopamine (RootHide) jailbreaks.

## How to use?

1. (RootHide) Install “Xcode Any Debug” from <https://roothide.github.io>
2. (Other) Install and configure “XcodeRootDebug” from <https://apt.82flex.com>
3. Install this tweak from <https://apt.82flex.com>
4. Open Xcode and modify the target settings of your app: `CODE_SIGNING_ALLOWED=NO`
5. Add a “Run Script” phase to your target with the following content:

    ```bash
    if [ "$CODE_SIGNING_ALLOWED" = "NO" ]; then
      ldid -S${CODE_SIGN_ENTITLEMENTS} ${CODESIGNING_FOLDER_PATH}
    fi
    ```

## LICENSE

WTFPL License
