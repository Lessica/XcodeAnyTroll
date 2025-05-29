# XcodeAnyTroll

**⚠️ This is a developer tweak. Use with caution.**

This jailbreak tweak allows you to “click-to-run” (and debug) app directly from Xcode without code signing or with any entitlements.

Which makes it super easy to develop TrollStore based system apps, or to test your own apps without the need to sign them with a developer certificate.

Tested on iOS 15.0/15.4/16.2/16.4/16.5.1/16.7.10 with palera1n, Dopamine and Dopamine (RootHide) jailbreaks. TrollStore is required.

https://github.com/user-attachments/assets/36af81b7-724b-4fb7-b29e-0e71235c2edd

## How to use?

0. Prepare your jailbroken iOS device for development.
1. Install this tweak from <https://apt.82flex.com>
2. Open Xcode and modify the target settings of your app: `CODE_SIGNING_ALLOWED=NO`, `ENABLE_USER_SCRIPT_SANDBOXING=NO`

    <img width="499" alt="截屏2025-05-29 上午5 05 42" src="https://github.com/user-attachments/assets/7ca46b03-6554-4e57-a1b8-04e709e1a0bc" />
    <img width="482" alt="截屏2025-05-29 上午6 04 22" src="https://github.com/user-attachments/assets/f4feae75-393c-44e0-af75-918ec2973fb9" />

3. Set `CODE_SIGN_ENTITLEMENTS` to the path of your entitlement.

    <img width="597" alt="截屏2025-05-29 下午11 29 07" src="https://github.com/user-attachments/assets/cfd484e3-3237-4c40-8975-5296fa96f755" />

4. Ensure that you’ve installed [`ldid-procursus`](https://github.com/opa334/ldid).
5. Add a “Run Script” phase to your target with the following content:

    ```bash
    if [ "$CODE_SIGNING_ALLOWED" = "NO" ]; then
      ldid -S${CODE_SIGN_ENTITLEMENTS} ${CODESIGNING_FOLDER_PATH}
    fi
    ```

    <img width="743" alt="截屏2025-05-29 上午5 06 20" src="https://github.com/user-attachments/assets/611ee75d-006f-423e-a855-112f31aad808" />

## Known issues

- The installation is much slower than normal ones because `trollstorehelper` only accepts `.ipa` files :-(

## Example Project

- [TrollFools](https://github.com/Lessica/TrollFools)

## LICENSE

WTFPL License
