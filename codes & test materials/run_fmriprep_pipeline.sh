#!/bin/bash

# ==============================================================================
# fMRIPrep Preprocessing Pipeline Script
# ==============================================================================
# Developed by: Amir Hossein Dakhili
# Email: amirhossein.dakhili@myacu.edu.au
# Affiliation: Australian Catholic University
# Date: March 2025
# Last Modified: June 2025
#
# Description:
# This script automates the execution of the fMRIPrep pipeline for neuroimaging
# data preprocessing. It is designed to be run on a computing cluster or a
# powerful workstation, taking a list of subject IDs and processing their
# raw BIDS-formatted data to generate high-quality, preprocessed derivatives.
# The output is suitable for subsequent statistical analysis (e.g., GLM).
#
# Important Notes for Usage:
# 1.  **Dependencies**:
#     -   `fmriprep`: This script assumes `fmriprep` is installed and available
#         via a module system (`module load fmriprep/VERSION`) or directly in your PATH.
#         Adjust the `module load` command to match your environment's fMRIPrep version.
#     -   FreeSurfer License: `fmriprep` requires a valid FreeSurfer license.
#         The path to your `license.txt` file MUST be correctly specified.
# 2.  **Directory Paths**: All directory paths (e.g., `bids_root_dir`,
#     `FS_LICENSE`, `work` directory, and `sublist.txt` path) are **example
#     placeholders**. You MUST change them to reflect the actual, desired
#     paths on your computer system or server before running the script.
# 3.  **Subject List**: The script reads subject IDs from `sublist.txt`.
#     Ensure this file exists and contains one subject ID per line.
# 4.  **Resources**: Adjust `nthreads` (number of CPU cores) and `mem` (memory in GB)
#     according to your system's capabilities and the size of your data.
#     Insufficient resources can lead to crashes.
# 5.  **fMRIPrep Version**: The `module load` command specifies a version.
#     Verify this matches the fMRIPrep version you intend to use.
# 6.  **Output Spaces**: The script is configured to output data in MNI152NLin2009cAsym
#     space with 2mm resolution. Adjust `--output-spaces` if different spaces
#     or resolutions are required.
# 7.  **Task ID**: The `--task-id NFB` argument specifies that only runs
#     associated with the 'NFB' task label will be processed. If you have
#     other tasks (e.g., 'CR'), you'll need to run fMRIPrep separately for them
#     or adjust this argument.
# 8.  **`--fs-no-reconall`**: This argument prevents fMRIPrep from running
#     FreeSurfer's `recon-all` if it has already been run or is not desired.
#     Remove this argument if you want fMRIPrep to perform `recon-all`.
#
# This script is part of the neuroimaging data preprocessing workflow within
# the Neuroscience of Addiction and Mental Health Program at Australian Catholic University.
# ==============================================================================

# --- Load fMRIPrep Module ---
# Load the desired fMRIPrep version on the system.
# If fMRIPrep is directly in your PATH, you might comment this line.
# !!! IMPORTANT: Update the module name/version as per your cluster/system setup !!!
# module load fmriprep/23.2.1 # Example for a newer version
module load fmriprep/20.2.3 # Current specified version

# --- Loop Through Subjects ---
# The 'while read subj; do ... done < file.txt' construct reads each line
# from `sublist.txt` into the variable `subj` and executes the loop body for it.
# This allows processing multiple subjects sequentially.
# !!! IMPORTANT: Update the path to your 'sublist.txt' file !!!
while read subj; do

    # --- User-Defined Configuration ---
    # These variables define the paths and resources for the fMRIPrep run.

    # Root directory of your BIDS dataset.
    # fMRIPrep expects data to be organized in a BIDS-compliant structure here.
    # !!! IMPORTANT: Update this path to your BIDS dataset directory !!!
    bids_root_dir="/path/to/your/NFB_BIDS_dataset"

    # Number of CPU threads/cores fMRIPrep is allowed to use.
    # Adjust based on available resources to optimize performance.
    nthreads=8

    # Maximum memory (RAM) fMRIPrep is allowed to use, in gigabytes (GB).
    # fMRIPrep can be memory-intensive, especially for T1w processing.
    mem=80 #gb

    echo "################## Processing Subject: ${subj} ###################"

    # --- Convert Memory to Megabytes and Adjust for Buffer ---
    # fMRIPrep's `--mem_mb` argument expects memory in megabytes.
    # Remove any non-numeric characters (like 'gb') from the 'mem' variable.
    mem=`echo "${mem//[!0-9]/}"`
    # Convert GB to MB (multiply by 1000) and subtract a small buffer (5000 MB = 5 GB).
    # This buffer helps prevent memory-related crashes by leaving some head-room.
    mem_mb=`echo $(((mem*1000)-5000))`

    # --- Set FreeSurfer License Path ---
    # FreeSurfer is an essential dependency for fMRIPrep's anatomical processing.
    # You MUST have a FreeSurfer license file.
    # !!! IMPORTANT: Update this path to the actual location of your FreeSurfer license.txt !!!
    export FS_LICENSE="/path/to/your/NFB_BIDS/code/license.txt"

    # --- Run fMRIPrep Command ---
    # Execute the fmriprep command with specified arguments.
    fmriprep "$bids_root_dir" "$bids_root_dir/derivatives" \
        participant \
        --participant-label "$subj" \
        --skip-bids-validation \
        --md-only-boilerplate \
        --fs-license-file "$FS_LICENSE" \
        --fs-no-reconall \
        --output-spaces MNI152NLin2009cAsym:res-2 \
        --task-id NFB \
        --nthreads "$nthreads" \
        --stop-on-first-crash \
        --mem_mb "$mem_mb" \
        --work "/path/to/your/fmriprep_work_dir" # !!! IMPORTANT: Update this path for fMRIPrep's working directory !!!

done <"/path/to/your/NFB_BIDS/code/sublist.txt" # !!! IMPORTANT: Update this path to your 'sublist.txt' file !!!

# --- Subject List File ---
# The `sublist.txt` file should contain subject IDs, one per line, without the "sub-" prefix.
# Example content for `sublist.txt`:
# 001
# 002
# 003
# ...
