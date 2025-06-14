# Recent Changes - Odin Document Scanner

A command-line program written in Odin that scans a directory and its subdirectories for recently changed documents.

## Features

- Recursively scans directories and subdirectories
- Displays file path, modification time, and file size
- Sorts results by modification time (most recent first)

## Prerequisites

- Odin compiler installed on your system
- You can download Odin from: https://odin-lang.org/

## Building

To compile the program:

```bash
# build and run
odin run .
```

## Usage

### Scan current directory:
```bash
# Check for changes in test folder from the last hour
./RecentChanges.exe c:/test/ 1
# Check current folder for the last 24 hours
./RecentChanges.exe . 24
```
