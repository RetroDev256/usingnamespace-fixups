Fear no more! Semi-automated fixups for your many `usingnamespace` keywords are now here.

Simply run `zig fetch --save git+https://github.com/RetroDev256/usingnamespace-fixups` to add usingnamespace fixups to your program, then fix individual files with the following code in your `build.zig`:
```zig
const root_file = b.path("src/main.zig");
@import("usingnamespace").fixup(b, root_file);
```

Enjoy!
