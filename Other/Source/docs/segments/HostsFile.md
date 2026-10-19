# Hosts file entries

The Hosts segment adds hostname overrides to the Windows hosts file (`%WINDIR%\System32\drivers\etc\hosts`) for as long as the app runs.

It's also the reference segment for the journal: it records its undo step before touching the file and cleans up with nothing but the journal's rollback, so a normal exit and crash recovery run exactly the same code. It's a good one to read before writing a segment of your own.

## Enabling it

```ini
[Activate]
Hosts=true
```

Recompile the launcher after adding the key.

Writing the hosts file needs administrator rights. Without them the segment changes nothing and shows a warning. See [README.md](README.md#administrator-rights) for `RunAsAdmin`.

## Entries

Each key under `[Hosts]` is one hosts-file line: an address, then one or more hostnames.

```ini
[Hosts]
1=127.0.0.1 example.local
2=::1 example.local
3=10.0.0.5 api.example.local cdn.example.local
```

An entry that's already in the hosts file is left alone and not added twice.

## How it's undone

Every line the launcher adds ends with the tag `# [pac-man:<AppID>]`:

```
127.0.0.1 example.local # [pac-man:MyAppPortable]
```

The journal records a `STRIPLINES` entry for that tag. On exit, every line carrying the tag is removed and nothing else, so changes other programs make to the hosts file while the app runs are kept.

Before its first change, the segment also saves a full copy of the hosts file in the journal's backup folder (`%LOCALAPPDATA%\pac-man\Journal\<AppID>`). It's kept until the rollback succeeds, for manual recovery if ever needed.

## Notes

- Some programs cache name lookups. If an override doesn't take effect straight away, the program may need restarting, or `ipconfig /flushdns` may help.
- The segment runs only for the first launch of an app.
