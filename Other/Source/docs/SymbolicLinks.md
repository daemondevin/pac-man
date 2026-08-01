# Symbolic Links

> [!CAUTION]
> Before proceeding with this topic I would like to point out that John, the founder of PortableApps.com, [explains in detail](https://portableapps.com/comment/233867#comment-233867) why it would be bad practice to make use of any of these concepts in this topic. 
> 
> **TLDR:** Basically a portable application can potentionally render a host machine in a much worse state if it crashes while running a portable app which uses junctions or the like. Luckily, this is precisely what pac-man tries to mitigate against with it's journaling system. 

## Synopsis

Hard Links, Junction Points and Symbolic Links are all methods used by your operating system to "link" files, directories or volumes together. To a computer, you could say that symbolic links are just _advance shortcuts_ which make a file or folder appear to be the same as another file or folder located elsewhere on the host machine—even though it's just a link pointing at the original file or folder.

> [!IMPORTANT]
> **NTSF Reparse Points**
> Windows supports five forms of links (with _symlinks_ implemented as [`ntfs-reparse-points`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa365511%28v=vs.85%29.aspx)). More detailed information for each can be found further below.
> 
> - Hard links for files _(but not directories)_ that live on the same volume partition.
> - Exported (global) links known as directory junctions (a type of `ntfs-reparse-point` _only for directories not files_)
> - Imported (local) links known simply as “directory or file symbolic links” (a type of “ntfs-reparse-point”)
> - LNK files known simply as “shortcuts” (contain paths and can be tracked)
> - URL files known simply as “browser URL files” (portably work as URI forms with file://…))

## Reparse Points

A reparse point for Windows is basically what Linux calls a symbolic link, or mount point. It is actually similar to a shortcut or link that people use all the time. For instance, any icon on your computer's desktop is just a file that redirects the machine and tells it where to find the application as it is located usually in the _Program Files_ folder. A reparse point is the same concept essentially except that it is implemented at the operating system level and not at the user level. For a visual example, open a command prompt and type `dir /a` and press enter. You should see something similar to the following:

```
Microsoft Windows [Version 10.0.18362.239]
(c) 2019 Microsoft Corporation. All rights reserved.

C:\Users\daemon>dir /a

 Directory of C:\Users\daemon

 <DIR>          .
 <DIR>          ..
 <DIR>          AppData
 <JUNCTION>     Application Data [C:\Users\daemon\AppData\Roaming]
 <DIR>          Contacts
 <DIR>          Desktop
 <DIR>          Documents
 <JUNCTION>     Local Settings [C:\Users\daemon\AppData\Local]
 <DIR>          Music
 <JUNCTION>     My Documents [C:\Users\daemon\Documents]
 <DIR>          Pictures
 <JUNCTION>     SendTo [C:\Users\daemon\AppData\Roaming\Microsoft\Windows\SendTo]
 <JUNCTION>     Start Menu [C:\Users\daemon\AppData\Roaming\Microsoft\Windows\Start Menu]
 <DIR>          Videos

C:\Users\daemon>
```

Notice that there are a few that say _JUNCTION_ instead of _DIR_. Then take note that those entries also show you where they are pointing to. If a program writes data to a directory that's actually a reparse point, it instead gets sent to the real directory all unbeknownst to the program.

## Hard Links

A hard link is like an empty shell of a file which points to another. This empty shell will mirror this other file on the same machine without duplicating any of the original file's data which means no additional hard drive space is used to store the hard link. There can be multiple hard links which represent the same one file. Hard links cannot link to a file that is on a different partition, volume or drive and they cannot be used to point to directories. It should also be noted that hard links only work on partitions formatted in NTFS.

## Junctions

Junctions, also referred to as _soft links_, are only able to reference a directory, unlike a hard link which represents a file. Junctions can be used to link directories located on a different partition and/or volume, but only on a locally hosted machine. Folders that are redirected through junctions are defined by an [absolute path](https://github.com/daemondevin/pac-man/wiki/Absolute-and-Relative-Paths#absolute-paths). All of the information required to locate the target is contained in the path string.

To put it simply, a _Symlink_ is to a _Junction_ in Windows as a Symlink is to a Hardlink in Unix.

Both my [Discord Portable](https://github.com/daemondevin/DiscordPortable) and [GitHub Desktop Portable](https://github.com/daemondevin/DiscordPortable) make use of Junctions to allow for better handling of its configuration/settings speeding up the launch process. Remember, using this method calls for administrative rights so if the end user doesn't have elevated privileges than you'll have to make the launcher fallback on copying/moving files/directories.

## Symlinks

Symbolic links can be used to link both files or folders. Both these files and folders can also be located on either the locally hosted machine or on a network share, also known as [UNC](https://github.com/daemondevin/pac-man/wiki/Absolute-and-Relative-Paths#unc-paths) (i.e. `"\\System\Folder\file.txt"` → `"D:\Folder\file.txt"` or `"\\System\Folder"` → `"D:\Folder"`).

## Moreover

Junctions Points are limited to folders on the local system only, while Symbolic Links can create links to folders or files accessible via a [UNC path](https://github.com/daemondevin/pac-man/wiki/Absolute-and-Relative-Paths#unc-paths) or on the local system with more versatility in how those locations are designated. Symbolic Links is basically a more versatile replacement for both Junction Points and Hard Links. Plus, Symbolic Links are compatible with Unix and Linux when creating a cross platform UNC pathed link.

Junctions and Symbolic links are really doing the same thing in the same way (reparse points), aside from the aforementioned differences in how they're processed. Technically speaking, a Junction is a symbolic link and is documented on [Microsoft](https://docs.microsoft.com/en-us/sysinternals/downloads/junction) as such.


> [!NOTE]
> **CompilerLinker**
>
> PortableApps Compiler comes with a small utility to help in the creation in making symbolic links. More information can be found [here](https://github.com/daemondevin/CompilerLinker).

## Launcher.ini

To make use of this feature in PortableApps Compiler, simply add the section `[SymLink#]` (where `#` represents a number in numerical order) to your `launcher.ini`.

### Configuration

| **Key** | **Description** |
|----------|-------------|
| `type` | The type of link to create. Either one of the following four: `soft`, `hard`, `symbolic`, or `junction` |
| `source` | The name of the folder or file in the Data directory (i.e. Data\SymlinkFolder or Data\HardlinkFile.txt) |
| `target` | The path that the link points to (supports all environment variables) |

### Examples

```ini
[Symlink1]
Type=hard
Source=HardlinkFile.txt
Target="%USERPROFILE%\Documents\HardlinkFile.txt"

[Symlink2]
Type=soft
Source="Symlink'Folder"
Target="%APPDATA%\Symlink'Folder"
```
