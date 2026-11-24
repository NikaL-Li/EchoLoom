# Face-to-face UI checks

The tests use real simulator UI and actual bundled/system speech playback. The Chinese conversations are test input, not customer data. They do not validate live speech recognition accuracy, the other end of a telephone call, or real Deaf-user experience.

Run from ios/Native:

```sh
python3 Tests/UI/prepare_project.py
xcodebuild test -project UITesting.xcodeproj -scheme ConversationChecks \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

The helper generates a disposable UITesting.xcodeproj; the production Xcode project is not rewritten. Screenshots are retained as xcresult attachments. Scenarios cover typed replies, replay, cancellation, history and draft retention, partner input, clearing, large-text keyboard layout, and light/dark appearance. Live microphone tests need a consenting participant and physical device.

DeliveryFlowUITests covers independent home/delivery defaults and drafts, address context, navigation preview, confirmed phone handoff, incomplete phone numbers, return-to-edit, auto-generated address question refresh and preservation of user-edited drafts. These tests use the DEBUG simulator-only --test-external-links flag to inspect outgoing URLs without opening Maps or placing real calls. Normal text size is the focus for delivery checks.

CustomPhraseUITests covers saving both voices, previewing without changing the default voice, restarting and playing offline, using saved replies in face-to-face chat, editing/deleting, and refusing partial generation. Its DEBUG simulator-only --test-custom-phrases flag stores fixtures in CustomPhrases-UIReview, separate from the real library. Fixture synthesis is not a claim of live MiMo generation; live service checks are recorded separately.

CallStatusAndOrderUITests covers actual drag gestures, mixed built-in/custom ordering, relaunch persistence, filtering in face-to-face mode, compact pinned status, and all seven presentation states. --test-call-status is a DEBUG simulator-only presentation fixture; it does not enable injection or simulate receipt at the far end. Normal production status is derived from system permission, microphone-injection availability, and the successful preferred-mode request.
