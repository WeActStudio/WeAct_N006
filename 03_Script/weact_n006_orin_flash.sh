#!/bin/bash
# Copyright (c) 2026 Greetrix - greetrix@qq.com
#                WeAct Studio 
#
# ============================================
# Configuration
# ============================================

# Global variable to store Linux_for_Tegra directory
LINUX_FOR_TEGRA_DIR=""

# Global flag for -n option (use non-super board)
USE_NON_SUPER=false

# ============================================
# Logging Functions
# ============================================

log_info()    { echo "[INFO]    $1"; }
log_success() { echo "[SUCCESS] $1"; }
log_error()   { echo "[ERROR]   $1"; }
log_warning() { echo "[WARNING] $1"; }

# ============================================
# Version Comparison Function
# ============================================

# Compare two version strings (e.g., "5.1.3" vs "5.1.4")
# Returns 0 (true) if first version > second version, else 1 (false)
version_gt() {
    local v1="$1"
    local v2="$2"
    awk -v a="$v1" -v b="$v2" '
    BEGIN {
        split(a, A, ".");
        split(b, B, ".");
        for (i = 1; i <= 3; i++) {
            if (A[i] == "") A[i] = 0;
            if (B[i] == "") B[i] = 0;
            if (A[i] > B[i]) exit 0;
            if (A[i] < B[i]) exit 1;
        }
        exit 1;  # equal
    }'
}

# ============================================
# Core Functions
# ============================================

# Check if current path contains Linux_for_Tegra and extract its absolute path
check_and_extract_path() {
    local current_path="$1"
    
    # Check if path contains Linux_for_Tegra
    if [[ "$current_path" != *"Linux_for_Tegra"* ]]; then
        log_error "Current path does not contain Linux_for_Tegra: $current_path. Please move the script in Linux_for_Tegra."
        return 1
    fi
    
    # Extract Linux_for_Tegra directory path
    if [[ "$current_path" == */Linux_for_Tegra/* ]]; then
        # Path format: .../Linux_for_Tegra/...
        LINUX_FOR_TEGRA_DIR="${current_path%/Linux_for_Tegra/*}/Linux_for_Tegra"
    elif [[ "$current_path" == */Linux_for_Tegra ]]; then
        # Path format: .../Linux_for_Tegra
        LINUX_FOR_TEGRA_DIR="$current_path"
    else
        # Find Linux_for_Tegra in the path
        local temp_path="$current_path"
        while [[ "$temp_path" != "/" ]]; do
            if [[ "$temp_path" == *Linux_for_Tegra* ]]; then
                LINUX_FOR_TEGRA_DIR="${temp_path%Linux_for_Tegra*}Linux_for_Tegra"
                break
            fi
            temp_path=$(dirname "$temp_path")
        done
    fi
    
    # Convert to absolute path
    LINUX_FOR_TEGRA_DIR=$(cd "$LINUX_FOR_TEGRA_DIR" && pwd)
    
    if [[ ! -d "$LINUX_FOR_TEGRA_DIR" ]]; then
        log_error "Failed to find Linux_for_Tegra directory"
        return 1
    fi
    
    log_success "Found Linux_for_Tegra directory: $LINUX_FOR_TEGRA_DIR"
    return 0
}

# Extract JetPack version from path
extract_version() {
    local current_path="$1"
    
    if [[ "$current_path" =~ JetPack_([0-9]+\.[0-9]+(\.[0-9]+)?)_Linux_JETSON_ORIN_NX_TARGETS ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    else
        log_error "Cannot extract JetPack version from path"
        return 1
    fi
}

# Get major version
get_major_version() {
    echo "${1%%.*}"
}

# Copy files for a specific version
copy_files() {
    local major_version="$1"      # e.g., "5", "6", "7"
    local full_version="$2"       # e.g., "5.1.2"
    local script_dir="$3"
    
    log_info "Copying files for JetPack $full_version (major $major_version)"
    
    # Determine source and target directories based on version
    if [[ "$major_version" == "5" ]]; then
        # JP5: choose DTB subdir based on version > 5.1.3
        if version_gt "$full_version" "5.1.3"; then
            dtb_subdir="M513"
        else
            dtb_subdir="N513"
        fi
        source_dtb="$script_dir/DTB/JP5/KN_DTB/${dtb_subdir}"
        source_gpio_bct="$script_dir/DTB/JP5/GPIO_BCT"
        source_gpio_bl="$script_dir/DTB/JP5/GPIO_BL"
        target_dtb="$LINUX_FOR_TEGRA_DIR/kernel/dtb"
        target_gpio_bct="$LINUX_FOR_TEGRA_DIR/bootloader/t186ref/BCT"
        target_gpio_bl="$LINUX_FOR_TEGRA_DIR/bootloader"
        gpio_bct_files=("tegra234-mb1-bct-padvoltage-p3767-dp-a03.dtsi" "tegra234-mb1-bct-padvoltage-p3767-hdmi-a03.dtsi" \
                        "tegra234-mb1-bct-pinmux-p3767-dp-a03.dtsi" "tegra234-mb1-bct-pinmux-p3767-hdmi-a03.dtsi" \
                        "tegra234-mb2-bct-misc-p3767-0000.dts")
        gpio_bl_files=("tegra234-mb1-bct-gpio-p3767-dp-a03.dtsi" "tegra234-mb1-bct-gpio-p3767-hdmi-a03.dtsi")
    elif [[ "$major_version" == "6" ]]; then
        # JP6: choose DTB subdir based on version > 6.1
        if version_gt "$full_version" "6.1"; then
            dtb_subdir="M61"
        else
            dtb_subdir="N61"
        fi
        source_dtb="$script_dir/DTB/JP6/KN_DTB/${dtb_subdir}"
        source_gpio_bct="$script_dir/DTB/JP6/GPIO_BCT"
        source_gpio_bl="$script_dir/DTB/JP6/GPIO_BL"
        target_dtb="$LINUX_FOR_TEGRA_DIR/kernel/dtb"
        target_gpio_bct="$LINUX_FOR_TEGRA_DIR/bootloader/generic/BCT"
        target_gpio_bl="$LINUX_FOR_TEGRA_DIR/bootloader"
        gpio_bct_files=("tegra234-mb1-bct-padvoltage-p3767-dp-a03.dtsi" "tegra234-mb1-bct-padvoltage-p3767-hdmi-a03.dtsi" \
                        "tegra234-mb1-bct-pinmux-p3767-dp-a03.dtsi" "tegra234-mb1-bct-pinmux-p3767-hdmi-a03.dtsi" \
                        "tegra234-mb2-bct-misc-p3767-0000.dts")
        gpio_bl_files=("tegra234-mb1-bct-gpio-p3767-dp-a03.dtsi" "tegra234-mb1-bct-gpio-p3767-hdmi-a03.dtsi")
    elif [[ "$major_version" == "7" ]]; then
        # JP7: only M72 subdir
        dtb_subdir="M72"
        source_dtb="$script_dir/DTB/JP7/KN_DTB/${dtb_subdir}"
        source_gpio_bct="$script_dir/DTB/JP7/GPIO_BCT"
        source_gpio_bl="$script_dir/DTB/JP7/GPIO_BL"
        target_dtb="$LINUX_FOR_TEGRA_DIR/kernel/dtb"
        target_gpio_bct="$LINUX_FOR_TEGRA_DIR/bootloader/generic/BCT"
        target_gpio_bl="$LINUX_FOR_TEGRA_DIR/bootloader"
        gpio_bct_files=("tegra234-mb1-bct-padvoltage-p3767-dp-a03.dtsi" "tegra234-mb1-bct-padvoltage-p3767-hdmi-a03.dtsi" \
                        "tegra234-mb1-bct-pinmux-p3767-dp-a03.dtsi" "tegra234-mb1-bct-pinmux-p3767-hdmi-a03.dtsi" \
                        "tegra234-mb2-bct-misc-p3767-0000.dts")
        gpio_bl_files=("tegra234-mb1-bct-gpio-p3767-dp-a03.dtsi" "tegra234-mb1-bct-gpio-p3767-hdmi-a03.dtsi")
    else
        log_error "Unsupported version: $major_version"
        return 1
    fi
    
    log_info "Using DTB source directory: $source_dtb"
    
    # ============================================================
    # NEW: Copy ALL .dtb files from source_dtb to target_dtb
    # ============================================================
    # Check if source directory exists and contains .dtb files
    if [[ ! -d "$source_dtb" ]]; then
        log_error "DTB source directory does not exist: $source_dtb"
        return 1
    fi
    
    # Use nullglob to handle no matching files gracefully
    shopt -s nullglob
    dtb_files=("$source_dtb"/*.dtb)
    shopt -u nullglob
    
    if [[ ${#dtb_files[@]} -eq 0 ]]; then
        log_error "No .dtb files found in $source_dtb"
        return 1
    fi
    
    # Copy each .dtb file
    for file in "${dtb_files[@]}"; do
        filename=$(basename "$file")
        cp "$file" "$target_dtb/"
        log_info "Copied Kernel DTB: $file -> $target_dtb/"
    done
    # ============================================================
    
    # Copy GPIO BCT files
    for file in "${gpio_bct_files[@]}"; do
        if [[ -f "$source_gpio_bct/$file" ]]; then
            cp "$source_gpio_bct/$file" "$target_gpio_bct/"
            log_info "Copied GPIO BCT: $source_gpio_bct/$file -> $target_gpio_bct/"
        else
            log_error "GPIO BCT file not found: $source_gpio_bct/$file"
            return 1
        fi
    done
    
    # Copy GPIO Info files
    for file in "${gpio_bl_files[@]}"; do
        if [[ -f "$source_gpio_bl/$file" ]]; then
            cp "$source_gpio_bl/$file" "$target_gpio_bl/"
            log_info "Copied GPIO Info: $source_gpio_bl/$file -> $target_gpio_bl/"
        else
            log_error "GPIO Info file not found: $source_gpio_bl/$file"
            return 1
        fi
    done
    
    return 0
}

# Execute command based on version
execute_command() {
    local version="$1"
    
    # Determine board target based on -n flag
    local board_target
    if [ "$USE_NON_SUPER" = true ]; then
        board_target="jetson-orin-nano-devkit"
    else
        board_target="jetson-orin-nano-devkit-super"
    fi
    
    log_info "Executing flash command for version $version with board: $board_target"
    
    if [[ "$version" == "5" ]]; then
        # Execute command for version 5.x.x
        echo "Executing flash command for version 5.x.x"
        sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 \
             -c tools/kernel_flash/flash_l4t_t234_nvme.xml -p "-c bootloader/t186ref/cfg/flash_t234_qspi.xml" \
             --showlogs --network usb0 "$board_target" internal

    elif [[ "$version" == "6" ]]; then
        # Execute command for version 6.x.x
        echo "Executing flash for version 6.x.x"
        sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 \
             -c tools/kernel_flash/flash_l4t_t234_nvme.xml -p "-c bootloader/generic/cfg/flash_t234_qspi.xml" \
             --showlogs --network usb0 "$board_target" internal
    elif [[ "$version" == "7" ]]; then
        # Execute command for version 7.x.x
        echo "Executing flash for version 7.x.x"
        sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 \
             -c tools/kernel_flash/flash_l4t_t234_nvme.xml -p "-c bootloader/generic/cfg/flash_t234_qspi.xml" \
             --showlogs --network usb0 "$board_target" internal
    else
        log_error "No command defined for version $version"
        return 1
    fi
    
    return 0
}

# ============================================
# Main Script
# ============================================

# Parse command line options
while getopts "n" opt; do
    case $opt in
        n)
            USE_NON_SUPER=true
            ;;
        \?)
            echo "Usage: $0 [-n]"
            echo "  -n    Use non-super board (jetson-orin-nano-devkit instead of jetson-orin-nano-devkit-super)"
            exit 1
            ;;
    esac
done

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get current directory
CURRENT_DIR="$(pwd)"

log_info "Script directory: $SCRIPT_DIR"
log_info "Current directory: $CURRENT_DIR"

# Step 1: Check path and extract Linux_for_Tegra directory
if ! check_and_extract_path "$CURRENT_DIR"; then
    exit 1
fi

# Step 2: Extract JetPack version
jetpack_version=$(extract_version "$CURRENT_DIR")
if [[ $? -ne 0 ]]; then
    exit 1
fi

log_info "Detected JetPack version: $jetpack_version"

# Step 3: Get major version
major_version=$(get_major_version "$jetpack_version")
log_info "Major version: $major_version"

# Step 4: Check if version is supported
if [[ "$major_version" != "5" && "$major_version" != "6" && "$major_version" != "7" ]]; then
    log_error "Unsupported JetPack version: $jetpack_version"
    log_error "Only versions 5.x.x and 6.x.x and 7.x.x are supported"
    exit 1
fi

# Step 5: Copy files (now pass full version for subdir selection)
if ! copy_files "$major_version" "$jetpack_version" "$SCRIPT_DIR"; then
    log_error "Failed to copy DTB Files. Please use the \"sudo\" to rerun the script."
    exit 1
fi

# Step 6: Execute version-specific command
if ! execute_command "$major_version"; then
    log_error "Failed to execute flash command. Please use the \"sudo\" to rerun the script."
    exit 1
fi

log_success "Flash done. Please wait the Jetson Orin boot."