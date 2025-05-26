# What I learned in the process of making this tool

live document since the tools isn't completed yet.

## Features List (aka wishlist)

1. ✅ Load ADFs that workbench can read
2. ✅ Show the content of files in a HEX editor
3.  ✅ Navigate folder structure back and forth
4.  👷🏻 Delete files
5. 👷🏻 Add files
6.  👷🏻 Add support for Drag and Drop for new files 
7. 👷🏻 Create an ADF from scratch
8. 👷🏻 Compare two ADF images
9.  👷🏻 Auto convert audio when adding them to an image
10. 👷🏻 Auto convert image format wehn adding them to an image
11. ✅ Open images by dropping the image over the files' window
12.  ✅ Show disk layout, file usage and other stats

# Feature one
The biggest hurdle was to to figure out how XCODE handles the types of C mapped types to SWIFT. That was not obvious and before I realized that change on the taget membership and then by mistake changing at the project level causes so much more debug and bogus error I start growing white cheast hair...

Fortunately I had tackled the complexity (for me) of linking the ADFLib library when I build [send2adf](https://github.com/GINNOV/littlethings/tree/master/Amiga/Tools/send2adf) and that helped a lot because I had become familiar with the various exported functions.

The settings you find in the project (architecture, stripping debugging symbols for release, and so on) turn out to be very helpful once I figure out the sequence of changes to make. This type of project and settings will become my template for future tools, considering the amount of clicking I had to do to set things up in the way necessary to provide people with a pre-compiled version.

I should have been a responsible and considerate Internet user and built a universal binary. However, I had already built everything for Silicon, so I penalized everyone else who doesn’t have one at the moment. 😅
😅

# Feature two
Turns out SwiftUI is not great at handling timing and cross-language (bridging) functions, so despite that, the code is exactly the same. Only the first time when you open a file for rendering it in the Hex Editor, you get an empty small view. Sure enough, you cancel, repeat the same identical steps (and code), and it works for the rest of the app's life while in run time. I couldn't trace what the heck the issue was, but I did run it many times (in the attempt of fixing it) in situations where the compiler would complain with "too complex expression to be evaluated". M99 will do it, probably...



