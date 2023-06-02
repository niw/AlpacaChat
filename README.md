AlpacaChat
==========

A Swift library that runs Alpaca-LoRA prediction locally
to implement ChatGPT like app on Apple platform devices.

![AlpacaChat](Resources/AlpacaChat.png)

It is basically a wrapper for [alpaca.cpp](https://github.com/antimatter15/alpaca.cpp)
that provides a simple Swift API for it.

```swift
import AlpacaChat

// Load model and instantiate a chat.
let model = try await Model.load(from: URL(fileURLWithPath: "model.bin"))
let chat = Chat(model: model)

// Ask users to get prompt.
let prompt = readLine()!

// Run prediction and print tokens.
for try await token in chat.predictTokens(for: prompt) {
    print(token)
}
```


Model
-----

Read [alpaca.cpp](https://github.com/antimatter15/alpaca.cpp),
[alpaca-lora](https://github.com/tloen/alpaca-lora), and
[llma.cpp](https://github.com/ggerganov/llama.cpp),
then create 4-bits quantized `ggml` model bin file.

Place it in `/Applications/AlpacaChatApp/Resouces/model.bin` for example,
and build app and run it.


Usage
-----

See actual command line and SwiftUI application for usages.


Applications
------------

### `/Applications/AlpacaChatCLI`

A command line chat app that can run on macOS.

To build, use Xcode or simply use `swift` command.

```
$ cd Applications/AlpacaChatCLI
$ swift build -c release
$ .build/release/AlpacaChatCLI -m /path/to/model.bin
```

### `/Applications/AlpacaChatApp.xcodeproj`

A SwiftUI chat app that can run on iOS devices.

To build app runs on actual device, you need to create your own AppID
and provisioning profile that allows extended memory usage with
an entitlement.

Place `/Applications/AlpacaChatApp/Configurations/Local.xcconfig`
to provide these your local development configurations for signing.

You may want to change scheme to use Release configuration for Run,
or it may be seriously slow.
