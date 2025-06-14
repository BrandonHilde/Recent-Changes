package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:time"
import "core:path/filepath"
import "core:slice"
import "core:strconv"

main :: proc() {
    // Get the directory to scan from command line args, default to current directory
    scan_dir := "."
    hours :f64= 12
    if len(os.args) > 1 {
        scan_dir = os.args[1]
    }

    if len(os.args) > 2 {
        hours = strconv.atof(os.args[2])
    }

    fmt.printf("Scanning for recently changed documents in: %s\n", scan_dir)
    fmt.printf("Looking for files changed within the last %f hours\n\n", hours)
    
    // Get current time for comparison
    now := time.now()
    threshold_seconds := i64(60 * 60 * hours) // Convert days to seconds
    cutoff_time := time.Time{_nsec = now._nsec - threshold_seconds * 1_000_000_000}
    
    recent_files: [dynamic]os.File_Info
    defer delete(recent_files)
    
    // Scan the directory recursively
    scan_directory(scan_dir, cutoff_time, &recent_files)
    
    if len(recent_files) == 0 {
        fmt.printf("No recently changed documents found.\n")
        return
    }
    
    // Sort files by modification time (most recent first)
    slice.sort_by(recent_files[:], proc(a, b: os.File_Info) -> bool {
        return time.time_to_unix(a.modification_time) > time.time_to_unix(b.modification_time)
    })
    
    // Display results
    fmt.printf("Found %d recently changed documents:\n", len(recent_files))
    fmt.printf("%-50s %-20s %-10s\n", "File Path", "Modified", "Size")
    fmt.printf("%s\n", strings.repeat("-", 80))
    
    for file in recent_files {
        size_str := format_file_size(file.size)
        time_str := format_time(file.modification_time)
        fmt.printf("%-50s %-20s %-10s\n", file.fullpath, time_str, size_str)
    }
}

directory_exists :: proc(dir_path: string) -> bool {
    return os.is_dir(dir_path)
}

scan_directory :: proc(dir_path: string, cutoff_time: time.Time, recent_files: ^[dynamic]os.File_Info) {
   
    exists := directory_exists(dir_path)

    if !exists {
        return
    }

    handle, err := os.open(dir_path)    
    if err != os.ERROR_NONE {
        fmt.printf("Error opening directory %s: %v\n", dir_path, err)
        return
    }
    defer os.close(handle)
    
    file_infos, read_err := os.read_dir(handle, -1)
    if read_err != os.ERROR_NONE {
        fmt.printf("Error reading directory %s: %v\n", dir_path, read_err)
        return
    }
    defer delete(file_infos)
    
    for info in file_infos {
        full_path := filepath.join({dir_path, info.name})
        
        if info.is_dir {
            // Recursively scan subdirectories
            scan_directory(full_path, cutoff_time, recent_files)
        } else {
            // Check if it's a document file and if it's recent
            if is_document_file(info.name) && time.time_to_unix(info.modification_time) > time.time_to_unix(cutoff_time) {
                file_info := os.File_Info{
                    fullpath = full_path,
                    modification_time = info.modification_time,
                    size = info.size,
                }
                append(recent_files, file_info)
            }
            else if is_document_file(info.name) && time.time_to_unix(info.creation_time) > time.time_to_unix(cutoff_time) {
                file_info := os.File_Info{
                    fullpath = full_path,
                    modification_time = info.creation_time,
                    size = info.size,
                }
                append(recent_files, file_info)
            }
        }
    }
}

is_document_file :: proc(filename: string) -> bool {
    return os.is_file(filename)
}

format_file_size :: proc(size: i64) -> string {
    if size < 1024 {
        return fmt.aprintf("%d B", size)
    } else if size < 1024 * 1024 {
        return fmt.aprintf("%.1f KB", f64(size) / 1024.0)
    } else if size < 1024 * 1024 * 1024 {
        return fmt.aprintf("%.1f MB", f64(size) / (1024.0 * 1024.0))
    } else {
        return fmt.aprintf("%.1f GB", f64(size) / (1024.0 * 1024.0 * 1024.0))
    }
}

format_time :: proc(t: time.Time) -> string {
    // Format time as YYYY-MM-DD HH:MM
    year, month, day := time.date(t)
    hour, min, _ := time.clock(t)
    return fmt.aprintf("%04d-%02d-%02d %02d:%02d", year, int(month), day, hour, min)
}
