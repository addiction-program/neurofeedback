#!/bin/bash

# ==============================================================================
# NIfTI Mask to MNI Coordinates Extraction Script
# ==============================================================================
# Developed by: Amir Hossein Dakhili
# Email: amirhossein.dakhili@myacu.edu.au
# Affiliation: Australian Catholic University
# Date: March 2025
# Last Modified: June 2025
#
# Description:
# This script extracts the MNI (Montreal Neurological Institute) coordinates
# for all non-zero voxels (i.e., active voxels) within a given NIfTI mask file.
# It uses FSL tools for initial processing (binarization) and an embedded
# Python script with `nibabel` and `numpy` to perform the core coordinate
# transformation from voxel space to MNI anatomical space. The output is a
# text file listing the X, Y, Z MNI coordinates for each active voxel.
#
# Important Notes for Usage:
# 1.  **Dependencies**:
#     -   `FSL`: Required for `fslmaths`, `fslstats`, `fslval`. Ensure FSL is
#         installed and its executables are in your system's PATH.
#     -   `Python 3`: With `numpy` and `nibabel` libraries installed. These are
#         essential for NIfTI file manipulation and coordinate transformations.
#         If running on a cluster, ensure the correct Python environment is loaded.
# 2.  **Input Mask (`INPUT_MASK`)**: This variable **MUST BE UPDATED** to the
#     full path of the NIfTI mask file (`.nii` or `.nii.gz`) from which you
#     want to extract MNI coordinates. The script checks for its existence.
# 3.  **Output File**: The MNI coordinates will be saved to a text file
#     (`_mni_coordinates.txt`) in the current directory, named after the input mask.
# 4.  **Temporary Files**: The script uses a temporary directory (`mktemp -d`)
#     to store intermediate files. This directory is automatically cleaned up
#     upon script exit (successful or otherwise) using `trap`.
#
# This script is a fundamental utility for anatomical localization and
# ROI-based analyses within neuroimaging data processing workflows for the
# Neuroscience of Addiction and Mental Health Program at Australian Catholic University.
# ==============================================================================

# --- Define Input Mask Path ---
# INPUT_MASK: Full path to the NIfTI mask file (e.g., a region of interest).
# !!! IMPORTANT: Update this path to your specific input NIfTI mask file !!!
INPUT_MASK="/path/to/your/input_mask.nii"

# --- Validate Input Mask Existence ---
# Check if the specified input mask file actually exists.
# If the file is not found, print an error message and exit the script.
if [ ! -f "$INPUT_MASK" ]; then # `-f` checks if it's a regular file and exists. `!` negates the condition.
    echo "Error: Input mask file not found: $INPUT_MASK"
    exit 1 # Exit with a non-zero status indicating an error.
fi

# --- Create Temporary Directory ---
# `mktemp -d`: Creates a unique temporary directory.
# `-t mni_coords_XXXXXX`: Specifies a template for the directory name.
# `TEMP_DIR`: Stores the path to the created temporary directory.
TEMP_DIR=$(mktemp -d -t mni_coords_XXXXXX)
# `trap "rm -rf $TEMP_DIR" EXIT`: Sets a trap to automatically delete
# the temporary directory (`rm -rf`) when the script exits, regardless
# of whether it exits successfully or due to an error. This ensures cleanup.
trap "rm -rf $TEMP_DIR" EXIT

# --- Binarize the Mask ---
# `fslmaths`: FSL's image calculator.
# `"$INPUT_MASK"`: The input NIfTI mask.
# `-bin`: Binarizes the image, setting all non-zero values to 1 and zero values to 0.
#         This ensures a clean binary mask for coordinate extraction.
# `"$TEMP_DIR/mask_bin.nii.gz"`: Output path for the binarized mask in the temporary directory.
fslmaths "$INPUT_MASK" -bin "$TEMP_DIR/mask_bin.nii.gz"

# --- Get Voxel Count (Optional Information) ---
echo "Getting voxel coordinates..." # Informative message.
# `fslstats "$TEMP_DIR/mask_bin.nii.gz" -V`: Gets the number of non-zero voxels and the volume.
# `| read num_voxels _`: Pipes the output of fslstats to `read`. `num_voxels` gets the first word (voxel count), `_` discards the rest.
fslstats "$TEMP_DIR/mask_bin.nii.gz" -V | read num_voxels _

# --- Dump All Voxel Indices (Redundant for this script's Python logic) ---
# Note: The following `fsl2ascii` command dumps ALL voxel values (0s and 1s)
# in text format. The Python script below uses `np.where(data > 0)` which directly
# finds the indices of active voxels from the NIfTI data, making this `fsl2ascii`
# step technically redundant for the current script's functionality.
# It's kept here as it was in the original script.
fsl2ascii "$TEMP_DIR/mask_bin.nii.gz" > "$TEMP_DIR/raw_voxels.txt"

# --- Get Image Dimensions (Redundant for this script's Python logic) ---
# Note: These `fslval` commands extract image dimensions. The Python script
# directly loads the NIfTI and gets its shape via `img.shape`, so these specific
# `fslval` calls are not strictly necessary for the Python logic's execution.
# They are kept here as they were in the original script.
dim1=$(fslval "$TEMP_DIR/mask_bin.nii.gz" dim1)
dim2=$(fslval "$TEMP_DIR/mask_bin.nii.gz" dim2)
dim3=$(fslval "$TEMP_DIR/mask_bin.nii.gz" dim3)

# --- Embedded Python Script for Coordinate Transformation ---
# `python3 - <<EOF > "$TEMP_DIR/voxel_coords.txt"`: Executes the following block
# as a Python3 script and redirects its standard output to `voxel_coords.txt`
# in the temporary directory.
python3 - <<EOF
import numpy as np    # NumPy for numerical operations (array manipulation)
import nibabel as nib # NiBabel for neuroimaging file I/O and affine transforms

# Load the binarized mask NIfTI image created by fslmaths.
img = nib.load("$TEMP_DIR/mask_bin.nii.gz")
# Get the image data as a NumPy array.
data = img.get_fdata()
# Get the affine transformation matrix from the NIfTI image.
# This matrix defines the mapping from voxel coordinates to MNI (world) coordinates.
affine = img.affine

# Find the coordinates (indices) of all non-zero (active) voxels in the mask.
# `np.where(data > 0)` returns a tuple of arrays, one array per dimension (x_indices, y_indices, z_indices).
# `.T` transposes this, so `coords` becomes an N x 3 array where N is the number of active voxels,
# and each row is a [x, y, z] voxel coordinate.
coords = np.array(np.where(data > 0)).T
# Convert these voxel coordinates to MNI (world) coordinates using the affine matrix.
# `nib.affines.apply_affine`: Efficiently applies the affine transformation to a set of points.
mni_coords = nib.affines.apply_affine(affine, coords)

# Save the MNI coordinates to a text file.
# `"$TEMP_DIR/mni_coords.txt"`: Output file path in the temporary directory.
# `mni_coords`: The NumPy array containing the MNI coordinates.
# `fmt="%d"`: Formats the output numbers as integers (e.g., -2 1 8). Change to `fmt="%.2f"` for floats.
# `header="X Y Z (mm)"`: Adds a header line to the output file.
# `comments=''`: Prevents NumPy from adding '#' before the header line.
np.savetxt("$TEMP_DIR/mni_coords.txt", mni_coords, fmt="%d", header="X Y Z (mm)", comments='')
EOF

# --- Move Final Output File ---
# `basename "${INPUT_MASK%.nii*}"`: Extracts the base name of the input mask file
#   and removes any extension (`.nii`, `.nii.gz`).
#   Example: /path/to/r
