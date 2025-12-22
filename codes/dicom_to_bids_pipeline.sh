#!/bin/bash

# ==============================================================================
# DICOM Data Acquisition, Processing, and BIDS Conversion Script
# ==============================================================================
# Developed by: Amir Hossein Dakhili
# Email: amirhossein.dakhili@myacu.edu.au
# Affiliation: Australian Catholic University
# Date: March 2025
# Last Modified: June 2025
#
# Description:
# This script automates the process of downloading fMRI and anatomical DICOM data
# from DaRIS (Data Repository for Interdisciplinary Science), unzipping it,
# organizing the directory structure, converting DICOM files to gzipped NIfTI
# format, and finally, organizing the NIfTI files into a BIDS (Brain Imaging
# Data Structure) compliant format. This workflow is crucial for standardizing
# neuroimaging data for subsequent preprocessing and analysis pipelines.
#
# Important Notes for Usage:
# 1.  **Directory Paths**: All directory paths defined in this script are
#     **example placeholders**. You MUST change them to reflect the actual, desired
#     paths on your computer system or server before running the script.
#     Look for variables clearly marked with "!!! IMPORTANT: UPDATE THIS PATH !!!".
# 2.  **Dependencies**:
#     -   `wget`: For downloading data from URLs.
#     -   `7z` (p7zip): For extracting `.zip` archives.
#     -   `dcm2niix`: For converting DICOM files to NIfTI. This script assumes
#         `dcm2niix` is available as a module (`module load dcm2niix/VERSION`).
#         Adjust the `module load` command or ensure `dcm2niix` is in your PATH.
#     -   `scp`: For securely copying files between directories (assumes local
#         copy here, but can be configured for remote).
# 3.  **DaRIS URL**: Ensure the provided DaRIS URL is correct and accessible.
# 4.  **Subject/Session IDs**: Input for `subjID` and `sessID` should be numeric.
#     The script automatically formats `subjID` with leading zeros.
# 5.  **File Naming Conventions**: The script relies on specific naming
#     conventions within the downloaded DICOM folders (e.g., "*Projects - Addiction*")
#     and NIfTI filenames (e.g., "*_MP2RAGE_0.75mm_iso_sag_WIP.nii.gz*",
#     "*_Cue_1p6iso_cmrr_TR1sec.nii.gz*"). If your data has different naming
#     patterns, you will need to adjust the `find` and `scp` commands accordingly.
# 6.  **BIDS Structure**: This script currently only handles the conversion for
#     the `ses-01` (baseline) session. For follow-up sessions (`sessID=02` etc.),
#     the BIDS conversion logic will need to be extended or adjusted.
# 7.  **Excluded Files**: The script explicitly deletes folders containing
#     "SBref", "Physio", or "OPO" (likely referring to UNI-DEN, SBRef, PhysioLog)
#     to clean up unnecessary files before NIfTI conversion.
#
# This script is designed to streamline the initial data preparation steps
# for neuroimaging projects within the Neuroscience of Addiction and Mental
# Health Program at Australian Catholic University.
# ==============================================================================


# --- Step 1: Download Data from DaRIS ---
echo "--- Starting Data Download from DaRIS ---"

# Prompt user for necessary input for data retrieval.
read -p 'Enter the URL of DaRIS data: ' DATA_URL
read -p 'Enter Subject ID (e.g., 008) (do not enter letters): ' subjID
read -p 'If baseline, enter 01; follow-up 02 (do not enter letters): ' sessID

# Format the subject ID to ensure it always has three digits (e.g., 8 becomes 008).
# This is crucial for consistent file naming and BIDS compliance.
subjID=$(printf "%03d" $subjID)
OUTPUT_FILE="sub_${subjID}" # Define the name for the downloaded raw file.

# Define the output directory where the DaRIS zip file will be saved.
# !!! IMPORTANT: Update this path to your desired download location !!!
OUTPUT_DIR="/path/to/your/daris_downloads"
# Create the output directory if it does not already exist.
mkdir -p "$OUTPUT_DIR"

# Execute the wget command to download the file from the provided URL.
# -O: Specifies the output filename.
wget -O "$OUTPUT_DIR/$OUTPUT_FILE" "$DATA_URL"

# Check the exit status of the last executed command (`wget`).
# If `wget` failed (exit status is not 0), print an error and exit the script.
if [ $? -ne 0 ]; then
    echo "Error: Failed to download the file from DaRIS. Check the URL or network connection."
    exit 1 # Exit with a non-zero status indicating an error.
fi

echo "Download completed! File saved to $OUTPUT_DIR/$OUTPUT_FILE"

# --- Step 2: Unzip and Organize Downloaded DICOM Data ---
echo "--- Starting Unzipping and Initial Organization ---"

ZIP_FILE="$OUTPUT_DIR/$OUTPUT_FILE" # Path to the downloaded zip file.
# Define the final destination directory for the organized DICOM folders.
# !!! IMPORTANT: Update this path to your desired DICOM storage location !!!
FINAL_OUTPUT_DIR="/path/to/your/dicom_storage"
# Define a temporary directory for extracting the zip contents.
# This ensures a clean workspace and avoids clutter in the final directory.
# !!! IMPORTANT: Update this path to a suitable temporary directory !!!
TEMP_DIR="/path/to/your/temp_extraction_dir"

# Create the output and temporary directories if they do not already exist.
mkdir -p "$FINAL_OUTPUT_DIR"
mkdir -p "$TEMP_DIR"

# Extract the contents of the zip file to the temporary directory using 7z.
# -o"$TEMP_DIR": Specifies the output directory for extraction.
# > /dev/null: Redirects standard output of 7z to null, suppressing verbose output.
7z x -o"$TEMP_DIR" "$ZIP_FILE" > /dev/null

# Check the exit status of the 7z extraction.
if [ $? -ne 0 ]; then
    echo "Error: Failed to extract the file with 7z. Ensure 7z is installed and the file is not corrupted."
    exit 1
fi

# Find the specific project folder within the extracted contents.
# DaRIS often zips data into a top-level folder with a specific name.
# `find`: Searches for directories.
# `-type d`: Specifies that we are looking for directories.
# `-name "*Projects - Addiction*"`: Matches directories containing "Projects - Addiction".
# `head -n 1`: Takes only the first matching directory.
PROJECT_FOLDER=$(find "$TEMP_DIR" -type d -name "*Projects - Addiction*" | head -n 1)

# Check if the expected project folder was found.
if [ -z "$PROJECT_FOLDER" ]; then # -z checks if the string is empty.
    echo "Error: No folder named 'Projects - Addiction' found within the extracted content."
    rm -rf "$TEMP_DIR" # Clean up the temporary directory.
    exit 1
fi

# Define the new standardized name for the project folder.
# This typically includes subject ID and session ID for clear organization.
NEW_FOLDER_NAME="MRH111_SUBJ${subjID}_MR${sessID}"
# Move the found project folder to the final output directory and rename it.
mv "$PROJECT_FOLDER" "$FINAL_OUTPUT_DIR/$NEW_FOLDER_NAME"

# Check the status of the move/rename operation.
if [ $? -eq 0 ]; then # -eq 0 means success.
    echo "Successfully renamed and moved the folder to $FINAL_OUTPUT_DIR/$NEW_FOLDER_NAME"
else
    echo "Error: Failed to move or rename the folder. Permissions issue or target exists?"
    rm -rf "$TEMP_DIR" # Clean up the temporary directory.
    exit 1
fi

# Delete specific sub-folders within the newly organized DICOM directory.
# These folders often contain unwanted data (e.g., localizers, physiology logs).
# `find`: Searches within the subject's new DICOM folder.
# `-type d`: Specifies directories.
# `\( ... \)`: Groups multiple conditions.
# `-o`: Logical OR.
# `! -name "*UNI-DEN_ND*"`: Excludes specific sub-variants (e.g., non-denoised).
# `-exec rm -rf {} +`: Executes `rm -rf` on all found directories.
find "$FINAL_OUTPUT_DIR/$NEW_FOLDER_NAME" -type d \( \( -name "*UNI-DEN*" ! -name "*UNI-DEN_ND*" \) -o -name "*SBRef*" -o -name "*PhysioLog*" \) -exec rm -rf {} +

# Remove the temporary extraction directory to clean up.
rm -rf "$TEMP_DIR"
echo "Extraction and renaming complete. Unnecessary folders removed."

# --- Step 3: Convert DICOM to gzipped NIfTI Format ---
echo "--- Starting DICOM to NIfTI Conversion ---"

# Define the directory where the raw NIfTI files will be saved.
# !!! IMPORTANT: Update this path to your desired NIfTI storage location !!!
raw_nifti_path="/path/to/your/nifti_raw_data"
# Define the output base name for the NIfTI files (e.g., sub-008-MR01).
outputname="sub-${subjID}-MR${sessID}"

# Create the subject-specific NIfTI output directory.
mkdir -p "$raw_nifti_path/$outputname"
# Create a temporary staging directory for DICOMs before conversion.
mkdir -p "$raw_nifti_path/temp"

# Securely copy the organized DICOM folder to the temporary NIfTI staging area.
# This ensures `dcm2niix` operates on a copy, preserving the original DICOMs.
scp -r "$FINAL_OUTPUT_DIR/$NEW_FOLDER_NAME" "$raw_nifti_path/temp/$outputname"

# Load the dcm2niix module. Adjust the version as per your system's module environment.
# If `dcm2niix` is directly in your PATH, you can comment this line out.
module load dcm2niix/1.0.20201102

# Run dcm2niix to convert DICOMs to NIfTI.
# -z y: Compress output NIfTI files with gzip (.nii.gz).
# -o <output_directory>: Specifies the output directory for NIfTI files.
# -b y: BIDS sidecar JSON file for each NIfTI (contains metadata).
# -ba y: BIDS anonymization (anonymize patient names in JSON).
# -f %f_%p: Output filename format. %f is folder name, %p is protocol name.
# ${raw_nifti_path}/temp/${outputname}: Input directory containing the DICOMs.
dcm2niix -z y -o ${raw_nifti_path}/${outputname} -b y -ba y -f %f_%p ${raw_nifti_path}/temp/${outputname}

# Clean up the temporary DICOM staging area after NIfTI conversion.
rm -rf "$raw_nifti_path/temp/$outputname"
echo "DICOM to NIfTI conversion completed."


# --- Step 4: Organize NIfTI Data into BIDS Format ---
echo "--- Starting BIDS Conversion ---"

# Define the root directory for the BIDS dataset.
# !!! IMPORTANT: Update this path to your BIDS dataset root !!!
bids_path="/path/to/your/bids_dataset"
# Define the BIDS subject name (e.g., sub-008).
bidsname="sub-${subjID}"

# This `if` condition currently only processes baseline (sessID 01) subjects.
# For follow-up sessions (e.g., sessID 02), you would need to extend this logic
# to create `ses-02` directories and copy files accordingly.
if [[ ${sessID} == 01 ]]; then

    echo "This is a new subject (baseline). Converting NIfTI to BIDS format."

    # Create the necessary BIDS directory structure for the subject and session.
    # mkdir -p creates parent directories if they don't exist and doesn't error if they do.
    echo "Creating BIDS directories for ${bidsname}/ses-1..."
    mkdir -p ${bids_path}/${bidsname}
    mkdir -p ${bids_path}/${bidsname}/ses-1
    mkdir -p ${bids_path}/${bidsname}/ses-1/anat # Anatomical data
    mkdir -p ${bids_path}/${bidsname}/ses-1/func # Functional data
    mkdir -p ${bids_path}/${bidsname}/ses-1/fmap # Field maps

    echo "Converting T1-weighted anatomical data to BIDS format..."
    # Copy T1w NIfTI and JSON sidecar to the BIDS anat directory.
    # The `*` wildcard is used to match the protocol name output by `dcm2niix`.
    # Ensure these wildcard patterns match your actual NIfTI filenames generated by dcm2niix.
    scp -r ${raw_nifti_path}/${outputname}/*_MP2RAGE_0.75mm_iso_sag_WIP.nii.gz ${bids_path}/${bidsname}/ses-1/anat/${bidsname}_ses-1_T1w.nii.gz
    scp -r ${raw_nifti_path}/${outputname}/*_MP2RAGE_0.75mm_iso_sag_WIP.json ${bids_path}/${bidsname}/ses-1/anat/${bidsname}_ses-1_T1w.json

    echo "Converting functional Cue Reactivity (CR) data to BIDS format..."
    # Copy functional CR NIfTI and JSON.
    scp -r ${raw_nifti_path}/${outputname}/*_Cue_1p6iso_cmrr_TR1sec.nii.gz ${bids_path}/${bidsname}/ses-1/func/${bidsname}_ses-1_task-CR_bold.nii.gz
    scp -r ${raw_nifti_path}/${outputname}/*_Cue_1p6iso_cmrr_TR1sec.json ${bids_path}/${bidsname}/ses-1/func/${bidsname}_ses-1_task-CR_bold.json

    echo "Converting functional Neurofeedback (NFB) data (all runs) to BIDS format..."
    # Copy functional NFB NIfTI and JSON for each run.
    # Assuming run numbers are _1, _2, _3, _4 in the filename.
    scp -r ${raw_nifti_path}/${outputname}/*_NFB_1_1p6iso_cmrr_TR1sec.nii.gz ${bids_path}/${bidsname}/ses-1/func/${bidsname}_ses-1_task-NFB_run-01_bold.nii.gz
    scp -r ${raw_nifti_path}/${outputname}/*_NFB_1_1p6iso_cmrr_TR1sec.json ${bids_path}/${bidsname}/ses-1/func/${bidsname}_ses-1_task-NFB_run-01_bold.json

    scp -r ${raw_nifti_path}/${outputname}/*_NFB_2_1p6iso_cmrr_TR1sec.nii.gz ${bids_path}/${bidsname}/ses-1/func/${bidsname}_ses-1_task-NFB_run-02_bold.nii.gz
    scp -r ${raw_nifti_path}/${outputname}/*_NFB_2_1p6iso_cmrr_TR1sec.json ${bids_path}/${bidsname}/ses-1/func/${bidsname}_ses-1_task-NFB_run-02_bold.json

    scp -r ${raw_nifti_path}/${outputname}/*_NFB_3_1p6iso_cmrr_TR1sec.nii.gz ${bids_path}/${bidsname}/ses-1/func/${bidsname}_ses-1_task-NFB_run-03_bold.nii.gz
    scp -r ${raw_nifti_path}/${outputname}/*_NFB_3_1p6iso_cmrr_TR1sec.json ${bids_path}/${bidsname}/ses-1/func/${bidsname}_ses-1_task-NFB_run-03_bold.json

    scp -r ${raw_nifti_path}/${outputname}/*_NFB_4_1p6iso_cmrr_TR1sec.nii.gz ${bids_path}/${bidsname}/ses-1/func/${bidsname}_ses-1_task-NFB_run-04_bold.nii.gz
    scp -r ${raw_nifti_path}/${outputname}/*_NFB_4_1p6iso_cmrr_TR1sec.json ${bids_path}/${bidsname}/ses-1/func/${bidsname}_ses-1_task-NFB_run-04_bold.json


    echo "Converting field maps to BIDS format..."
    # Copy field map NIfTI and JSON files.
    # Note: `magnitude1`, `magnitude2`, `phasediff` and `dir-AP_epi` are standard BIDS field map entities.
    scp -r ${raw_nifti_path}/${outputname}/*_gre_field_mapping_ax-3mm_e1.nii.gz ${bids_path}/${bidsname}/ses-1/fmap/${bidsname}_ses-1_magnitude1.nii.gz
    scp -r ${raw_nifti_path}/${outputname}/*_gre_field_mapping_ax-3mm_e1.json ${bids_path}/${bidsname}/ses-1/fmap/${bidsname}_ses-1_magnitude1.json

    scp -r ${raw_nifti_path}/${outputname}/*_gre_field_mapping_ax-3mm_e2.nii.gz ${bids_path}/${bidsname}/ses-1/fmap/${bidsname}_ses-1_magnitude2.nii.gz
    scp -r ${raw_nifti_path}/${outputname}/*_gre_field_mapping_ax-3mm_e2.json ${bids_path}/${bidsname}/ses-1/fmap/${bidsname}_ses-1_magnitude2.json

    scp -r ${raw_nifti_path}/${outputname}
