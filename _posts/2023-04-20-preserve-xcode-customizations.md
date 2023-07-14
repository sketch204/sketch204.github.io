---
layout: post
title: Preserve Xcode Customizations
description: A list file and folders that contain some of the customization that you've made to Xcode
---

The files containing your Xcode customization are typically at the following paths:

1. `~/Library/Developer/Xcode/UserData/CodeSnippets`
    - This contains your custom saved code snippets. There will be one file with a unique name, per code snippet. There is no easy way to tell which is which, except by opening it as a text file and looking at the contents.
2. `~/Library/Developer/Xcode/UserData/FontAndColorThemes`
    - This contains your custom themes. One file per theme.
3. `~/Library/Developer/Xcode/UserData/KeyBindings`
    - This is where you keybindings are. If you've never customized your key bindings there should be a single file called `Default.idekeybindings`. If you have customized key binding but never saved them to a dedicated key bindings set, they will saved in the `Default` file. Otherwise if you did create a separate key bindings set, there should be a file for that.
4. `~/Library/Developer/Xcode/Templates`
    - If you've created custom file templates, those will be stored here.
5. `~/Library/Preferences/com.apple.dt.Xcode.plist`
    - This should contain settings that you've set through Xcode's preferences pane. Keep in mind not all options might be stored in this file.
6. `~/Library/MobileDevice/Provisioning Profiles`
    - This contains all the provisioning profiles you've created for any physical devices that you've deployed apps for. It's a good idea to save these so you don't have to regenerate them.

It is a good idea to backup all the files that you care about from these directories. Personally I save them to a GitHub repo along with config files for other applications that I use often. In case you loose your laptop, or have to set up a new one, it will greatly simplify the process for you. Just drop in these files and you're good to go!

Sources
-------

- [Uninstall xcode 10 \| Apple Developer Forums](https://developer.apple.com/forums/thread/110227?answerId=341753022#341753022)