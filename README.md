Fear no more! Semi-automated fixups for your many `usingnamespace` keywords are now here.

Simply run the following to add this to your project:
```
zig fetch --save git+https://github.com/RetroDev256/usingnamespace-fixups
```
Then annotate fixups for individual files with this code in your `build.zig`:
```zig
// Where b is of type *std.Build:
const root_file = b.path("src/main.zig");
@import("usingnamespace").fixup(b, root_file);
```

Enjoy!
