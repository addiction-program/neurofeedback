#!/bin/bash

# ==============================================================================
# AFNI Spatial Smoothing Script for fMRIPrep Outputs
# ==============================================================================
# Developed by: Amir Hossein Dakhili
# Email: amirhossein.dakhili@myacu.edu.au
# Affiliation: Australian Catholic University
# Date: March 2025
# Last Modified: June 2025 (Current Date)
#
# Description:
# This script automates the spatial smoothing of preprocessed functional MRI
# (fMRI) BOLD data, specifically targeting outputs from the fMRIPrep pipeline.
# It uses AFNI's `3dmerge` command to apply a Gaussian blur, which is a common
# step in fMRI preprocessing to increase signal-to-noise ratio and account for
# inter-subject anatomical variability. The script processes all relevant BOLD
# runs for a given subject.
#
# Important Notes for Usage:
# 1.  **Dependencies**:
#     -   `AFNI`: This script requires AFNI to be installed and available
#         via a module system (`module load afni/VERSION`) or directly in your PATH.
#         Adjust the `module load` command to match your environment's AFNI version.
# 2.  **Directory Paths**: The `der_path` variable MUST be updated to reflect
#     the actual root directory of your fMRIPrep derivatives. This is where
#     the input BOLD files are expected to reside.
# 3.  **Subject ID Input**: The script prompts for a subject ID. Ensure it is
#     entered as a numeric string (e.g., '068') without any letters.
# 4.  **fMRIPrep Output Naming**: The script relies on the standard fMRIPrep
#     output naming convention for preprocessed BOLD files (`*desc-preproc_bold.nii.gz`).
#     If your fMRIPrep outputs are named differently, adjust the wildcard pattern
#     in the `for` loop accordingly.
# 5.  **Smoothing Kernel**: The script applies a 6mm FWHM (Full Width at Half Maximum)
#     Gaussian smoothing kernel. This value is a common choice but can be
#     adjusted by changing `6.0` in the `3dmerge` command.
# 6.  **Output Naming**: Smoothed files will have `_6mm_blur.nii.gz` appended
#     to their original fMRIPrep filename.
#
# This script is designed to be a streamlined part of the post-fMRIPrep
# preprocessing workflow within the Neuroscience of Addiction and Mental
# Health Program at Australian Catholic University.
# ==============================================================================

# --- Load AFNI Module ---
# Load the specified AFNI version on the system.
# If AFNI is directly in your PATH, you might comment this line.
# !!! IMPORTANT: Update the module name/version as per your cluster/system setup !!!
module load afni/24.1.22

# --- Get Subject Input ---
# Prompt the user to enter the Subject ID.
# This ID should correspond to the `sub-XXX` naming in your BIDS dataset.
read -p 'Subject ID (Example - 068) (do not enter letters) : ' subjID
# Confirm the entered subject ID format.
echo "Subject ID entered is sub-$subjID"

# Construct the full subject identifier (e.g., "sub-068").
sub=sub-$subjID

# --- Define Derivatives Path ---
# This variable points to the base directory where fMRIPrep stores its derivatives.
# The structure is typically: <der_path>/fmriprep/sub-XXX/ses-YYY/func/
# !!! IMPORTANT: Update this path to your fMRIPrep derivatives root directory !!!
der_path='/path/to/your/bids_derivatives/fmriprep'

# --- Loop Through Preprocessed BOLD Files ---
# This `for` loop iterates through all gzipped preprocessed BOLD files
# for the specified subject across all sessions.
# - `${der_path}/$sub/*/func/*desc-preproc_bold.nii.gz`:
#   - `$der_path/$sub`: Navigates to the subject's directory within derivatives.
#   - `*`: Wildcard to match any session directory (e.g., `ses-01`, `ses-02`).
#   - `/func/`: Specifies the functional data directory.
#   - `*desc-preproc_bold.nii.gz`: Matches any filename ending with
#     `desc-preproc_bold.nii.gz`, which is the standard fMRIPrep preprocessed BOLD output.
for n in ${der_path}/$sub/*/func/*desc-preproc_bold.nii.gz; do

    # --- Extract Filename and Base String ---
    # `basename "${n}"`: Extracts just the filename from the full path.
    #   Example: /path/to/file/sub-001_ses-01_task-NFB_run-01_desc-preproc_bold.nii.gz -> sub-001_ses-01_task-NFB_run-01_desc-preproc_bold.nii.gz
    fname=$(basename "${n}")
    # `cutstring="${n%.nii.gz}"`: Removes the `.nii.gz` extension from the full path.
    #   This will be used as the prefix for the output smoothed file.
    #   Example: /path/to/file/sub-001_ses-01_task-NFB_run-01_desc-preproc_bold.nii.gz -> /path/to/file/sub-001_ses-01_task-NFB_run-01_desc-preproc_bold
    cutstring="${n%.nii.gz}"

    echo "Processing: ${fname}"
    echo "Output file: ${cutstring}_6mm_blur.nii.gz"

    # --- Apply Spatial Smoothing using AFNI's 3dmerge ---
    # `3dmerge`: AFNI program for merging and processing datasets.
    # `-1blur_fwhm 6.0`: Applies a 3D Gaussian smoothing filter with a
    #   Full Width at Half Maximum (FWHM) of 6.0 mm.
    # `-doall`: Applies the operation to all sub-bricks (time points) of the input.
    # `-prefix ${cutstring}_6mm_blur.nii.gz`: Specifies the output filename.
    #   It uses the `cutstring` (original path/filename without `.nii.gz`) and appends
    #   `_6mm_blur.nii.gz` to indicate it's a 6mm smoothed and gzipped file.
    # `${n}`: The input preprocessed BOLD file to be smoothed.
    3dmerge -1blur_fwhm 6.0 -doall -prefix "${cutstring}_6mm_blur.nii.gz" "${n}"

done

echo "--- Smoothing process completed for subject ${sub} ---"
