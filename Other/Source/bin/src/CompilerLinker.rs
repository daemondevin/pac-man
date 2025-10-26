use std::{
    ffi::OsStr,
    os::windows::ffi::OsStrExt,
    path::PathBuf,
    ptr,
};

use owo_colors::OwoColorize;
use structopt::StructOpt;

#[link(name = "kernel32")]
extern "system" {
    fn CreateDirectoryW(
        lpPathName: *const u16,
        lpSecurityAttributes: *const std::ffi::c_void,
    ) -> i32;

    fn CreateSymbolicLinkW(
        lpSymlinkFileName: *const u16,
        lpTargetFileName: *const u16,
        dwFlags: u32,
    ) -> u8;

    fn CreateFileW(
        lpFileName: *const u16,
        dwDesiredAccess: u32,
        dwShareMode: u32,
        lpSecurityAttributes: *const std::ffi::c_void,
        dwCreationDisposition: u32,
        dwFlagsAndAttributes: u32,
        hTemplateFile: *mut std::ffi::c_void,
    ) -> *mut std::ffi::c_void;

    fn DeviceIoControl(
        hDevice: *mut std::ffi::c_void,
        dwIoControlCode: u32,
        lpInBuffer: *const std::ffi::c_void,
        nInBufferSize: u32,
        lpOutBuffer: *mut std::ffi::c_void,
        nOutBufferSize: u32,
        lpBytesReturned: *mut u32,
        lpOverlapped: *const std::ffi::c_void,
    ) -> i32;

    fn CloseHandle(hObject: *mut std::ffi::c_void) -> i32;
}

const SYMBOLIC_LINK_FLAG_DIRECTORY: u32 = 1;
const SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE: u32 = 2;

#[derive(StructOpt, Debug)]
#[structopt(name = "CompilerLinker", about = "Portable symbolic, junction, and hard/soft link creator.")]
struct CliOpts {
    #[structopt(short = "t", long = "link", help = "Source path where link will be created")]
    src: PathBuf,

    #[structopt(short = "o", long = "target", help = "Destination path the link points to")]
    dst: PathBuf,

    #[structopt(short = "s", long = "soft", help = "Create a soft link (directory symlink)")]
    soft: bool,

    #[structopt(short = "h", long = "hard", help = "Create a hard link")]
    hard: bool,

    #[structopt(short = "d", long = "symbolic", help = "Create a symbolic link (file symlink)")]
    symbolic: bool,

    #[structopt(short = "j", long = "junction", help = "Create a junction point")]
    junction: bool,
}

#[derive(Debug, Clone, Copy)]
enum LinkType {
    Soft,
    Hard,
    Symbolic,
    Junction,
}

impl LinkType {
    fn name(self) -> &'static str {
        match self {
            LinkType::Soft => "Soft Link",
            LinkType::Hard => "Hard Link",
            LinkType::Symbolic => "Symbolic Link",
            LinkType::Junction => "Junction",
        }
    }
}

struct LinkError {
    message: String,
    exit_code: i32,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let argv = CliOpts::from_args();

    let link_type = match parse_link_type(&argv) {
        Ok(lt) => lt,
        Err(e) => {
            eprintln!("{} {}", "error:".bright_red(), e.message.bright_red());
            std::process::exit(e.exit_code);
        }
    };

    if let Err(e) = create_link(link_type, &argv.src, &argv.dst) {
        eprintln!("{} {}", "error:".bright_red(), e.message.bright_red());
        std::process::exit(e.exit_code);
    }

    print_success(link_type, &argv.src, &argv.dst);
    Ok(())
}

fn parse_link_type(opts: &CliOpts) -> Result<LinkType, LinkError> {
    let count = [opts.soft, opts.hard, opts.symbolic, opts.junction]
        .iter()
        .filter(|&&b| b)
        .count();

    match count {
        0 => Err(LinkError {
            message: "No link type specified. Use --soft, --hard, --symbolic, or --junction.".to_string(),
            exit_code: 1,
        }),
        1 => {
            if opts.soft {
                Ok(LinkType::Soft)
            } else if opts.hard {
                Ok(LinkType::Hard)
            } else if opts.symbolic {
                Ok(LinkType::Symbolic)
            } else {
                Ok(LinkType::Junction)
            }
        }
        _ => Err(LinkError {
            message: "Multiple link types specified. Choose only one.".to_string(),
            exit_code: 1,
        }),
    }
}

fn create_link(link_type: LinkType, src: &PathBuf, dst: &PathBuf) -> Result<(), LinkError> {
    #[cfg(windows)]
    {
        use std::os::windows::fs as winfs;

        match link_type {
            LinkType::Junction => create_junction(dst, src),
            LinkType::Symbolic => winfs::symlink_file(dst, src).map_err(|e| LinkError {
                message: format!("Failed to create symbolic link: {}", e),
                exit_code: 3,
            }),
            LinkType::Hard => std::fs::hard_link(dst, src).map_err(|e| LinkError {
                message: format!("Failed to create hard link: {}", e),
                exit_code: 4,
            }),
            LinkType::Soft => winfs::symlink_dir(dst, src).map_err(|e| LinkError {
                message: format!("Failed to create soft link: {}", e),
                exit_code: 5,
            }),
        }
    }

    #[cfg(not(windows))]
    {
        Err(LinkError {
            message: "This utility only works on Windows.".to_string(),
            exit_code: 7,
        })
    }
}

fn utf16_encode(s: &std::path::Path) -> Vec<u16> {
    let mut encoded: Vec<u16> = s.as_os_str().encode_wide().collect();
    encoded.push(0); // Null terminate
    encoded
}

fn create_junction(target: &PathBuf, link: &PathBuf) -> Result<(), LinkError> {
    unsafe {
        // Prepare wide strings
        let link_wide = utf16_encode(link);
        let target_wide = utf16_encode(target);

        // Create the directory for the junction point if it doesn't exist
        if CreateDirectoryW(link_wide.as_ptr(), ptr::null()) == 0 {
            // If it failed for a reason other than "already exists", return error.
            let err = std::io::Error::last_os_error();
            if let Some(code) = err.raw_os_error() {
                // ERROR_ALREADY_EXISTS == 183
                if code != 183 {
                    return Err(LinkError {
                        message: format!("Failed to create directory for junction point: {}", err),
                        exit_code: 2,
                    });
                }
            }
        }

        // Build reparse data for mount point (junction)
        // Use substitute name with prefix "\??\" followed by the target path, and print name = target path
        let target_no_nul = &target_wide[..target_wide.len().saturating_sub(1)];
        let mut substitute: Vec<u16> = OsStr::new(r"\??\").encode_wide().collect();
        substitute.extend_from_slice(target_no_nul);

        let print_name: Vec<u16> = target_no_nul.to_vec();

        // PathBuffer contains substitute name followed by print name, terminated by a NUL WCHAR
        let mut path_buffer: Vec<u16> = Vec::with_capacity(substitute.len() + print_name.len() + 1);
        path_buffer.extend_from_slice(&substitute);
        path_buffer.extend_from_slice(&print_name);
        path_buffer.push(0u16);

        // Lengths in bytes
        let substitute_len_bytes = (substitute.len() * 2) as u16;
        let print_len_bytes = (print_name.len() * 2) as u16;
        let path_buffer_bytes = (path_buffer.len() * 2) as usize;

        // Reparse data length = size of MountPointReparseBuffer (8 bytes for offsets/lengths) + path buffer size
        let reparse_data_len = 8usize + path_buffer_bytes;

        // Full buffer = 8 byte header + reparse_data_len
        let full_len = 8 + reparse_data_len;
        let mut buffer = vec![0u8; full_len];

        // IO_REPARSE_TAG_MOUNT_POINT
        const IO_REPARSE_TAG_MOUNT_POINT: u32 = 0xA0000003;
        let tag = IO_REPARSE_TAG_MOUNT_POINT.to_le_bytes();
        buffer[0..4].copy_from_slice(&tag);

        // ReparseDataLength (u16)
        let rdl = (reparse_data_len as u16).to_le_bytes();
        buffer[4..6].copy_from_slice(&rdl);

        // Reserved (2 bytes) already zeroed

        // MountPointReparseBuffer fields start at offset 8:
        // SubstituteNameOffset (u16) - offset in bytes from start of PathBuffer -> 0
        buffer[8..10].copy_from_slice(&0u16.to_le_bytes());
        // SubstituteNameLength (u16)
        buffer[10..12].copy_from_slice(&substitute_len_bytes.to_le_bytes());
        // PrintNameOffset (u16) - offset in bytes from start of PathBuffer -> substitute_len_bytes
        buffer[12..14].copy_from_slice(&substitute_len_bytes.to_le_bytes());
        // PrintNameLength (u16)
        buffer[14..16].copy_from_slice(&print_len_bytes.to_le_bytes());

        // Write PathBuffer (UTF-16 little-endian) starting at offset 16
        let mut write_offset = 16;
        for &wc in &path_buffer {
            let bytes = wc.to_le_bytes();
            buffer[write_offset..write_offset + 2].copy_from_slice(&bytes);
            write_offset += 2;
        }

        // Open the directory with flags to allow setting reparse point
        const GENERIC_WRITE: u32 = 0x4000_0000;
        const FILE_SHARE_READ: u32 = 0x0000_0001;
        const FILE_SHARE_WRITE: u32 = 0x0000_0002;
        const FILE_SHARE_DELETE: u32 = 0x0000_0004;
        const OPEN_EXISTING: u32 = 3;
        const FILE_FLAG_OPEN_REPARSE_POINT: u32 = 0x0020_0000;
        const FILE_FLAG_BACKUP_SEMANTICS: u32 = 0x0200_0000;

        let handle = CreateFileW(
            link_wide.as_ptr(),
            GENERIC_WRITE,
            FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
            ptr::null(),
            OPEN_EXISTING,
            FILE_FLAG_OPEN_REPARSE_POINT | FILE_FLAG_BACKUP_SEMANTICS,
            ptr::null_mut(),
        );

        if handle as isize == -1 {
            let err = std::io::Error::last_os_error();
            return Err(LinkError {
                message: format!("Failed to open junction directory for reparse: {}", err),
                exit_code: 2,
            });
        }

        const FSCTL_SET_REPARSE_POINT: u32 = 0x0009_00A4;
        let mut bytes_returned = 0u32;

        if DeviceIoControl(
            handle,
            FSCTL_SET_REPARSE_POINT,
            buffer.as_ptr() as *const _,
            buffer.len() as u32,
            ptr::null_mut(),
            0,
            &mut bytes_returned,
            ptr::null(),
        ) == 0
        {
            let err = std::io::Error::last_os_error();
            // Clean up handle
            CloseHandle(handle);
            return Err(LinkError {
                message: format!("Failed to set reparse point for junction: {}", err),
                exit_code: 2,
            });
        }

        // Close the handle
        CloseHandle(handle);

        Ok(())
    }
}

fn print_success(link_type: LinkType, src: &PathBuf, dst: &PathBuf) {
    println!(
        "{} {} {} {}, {} {}",
        link_type.name().bright_green(),
        "created at source".bright_green(),
        "→".bright_green(),
        format!("{}", src.display()).bright_green(),
        "pointing to".bright_green(),
        format!("{}", dst.display()).bright_green()
    );
}
