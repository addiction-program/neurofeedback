#!/bin/bash

# ==============================================================================
# MNI Coordinates to NIfTI Mask Generation Script
# ==============================================================================
# Developed by: Amir Hossein Dakhili
# Email: amirhossein.dakhili@myacu.edu.au
# Affiliation: Australian Catholic University
# Date: March 2025
# Last Modified: June 2025 (Current Date)
#
# Description:
# This script creates a binary NIfTI mask file (.nii) by converting a list of
# MNI (Montreal Neurological Institute) coordinates (x, y, z) into voxel
# coordinates within a standard MNI template brain. Each specified MNI coordinate
# will correspond to a single voxel (or the closest voxel) being set to 1 in
# the output mask, while all other voxels remain 0. This is useful for creating
# custom Regions of Interest (ROIs) or seed points for connectivity analyses.
#
# Important Notes for Usage:
# 1.  **Dependencies**:
#     -   `FSL`: The script relies on FSL being installed as it uses the MNI152
#         standard brain template. Ensure `FSLDIR` is correctly set.
#     -   `Python 3`: With `numpy` and `nibabel` libraries installed. These are
#         essential for NIfTI file manipulation and numerical operations.
#         If running on a cluster, ensure the correct Python environment is loaded.
# 2.  **File Paths**: All file paths (`FSLDIR`, `MNI_2MM`, `INPUT`, `OUTPUT`) are
#     **example placeholders**. You MUST change them to reflect the actual
#     locations on your computer system or server before running the script.
# 3.  **Input File (`coordinates.txt`)**:
#     -   This file MUST contain MNI coordinates, one set per line.
#     -   Each line should have at least 3 space-separated floating-point numbers
#         representing the X, Y, and Z coordinates in MNI space (in millimeters).
#     -   Example `coordinates.txt` content:
#         -2.0 1.5 8.0
#         10.5 -3.2 25.1
#         ...
# 4.  **MNI Template**: The script uses the FSL MNI152_T1_2mm_brain.nii.gz template.
#     If you need to use a different template, update the `MNI_2MM` variable.
# 5.  **Output Mask**: The output `mask_output.nii` will be a binary NIfTI file,
#     where voxels corresponding to the input MNI coordinates are set to 1.
#
# This script is a fundamental utility for creating custom anatomical masks
# within neuroimaging data analysis workflows for the Neuroscience of Addiction
# and Mental Health Program at Australian Catholic University.
# ==============================================================================

# --- Define Bash Variables ---

# FSLDIR: Path to your FSL installation directory.
# !!! IMPORTANT: Update this path to your FSL installation !!!
FSLDIR=/apps/fsl/6.0.7.10/fsl # Example FSL path

# MNI_2MM: Full path to the standard 2mm MNI brain template.
# This template is used to define the voxel space, affine transform, and dimensions of the output mask.
# !!! IMPORTANT: Ensure this path is correct for your FSL installation, or change to a custom template !!!
MNI_2MM=$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz

# INPUT: Path to the text file containing the MNI coordinates.
# Each line in this file should contain X Y Z coordinates, separated by spaces.
# !!! IMPORTANT: Update this path to your input coordinates file !!!
INPUT=coordinates.txt

# OUTPUT: Name of the output NIfTI mask file.
# This file will be created in the directory where the script is executed.
# !!! IMPORTANT: Update this to your desired output mask filename/path !!!
OUTPUT=mask_output.nii

# --- Embedded Python Script ---
# This block executes a Python script directly within the bash script.
# `python3 - <<EOF`: Tells bash to execute the following lines as a Python3 script.
# `EOF`: Marks the end of the Python script block.

python3 - <<EOF
import numpy as np    # Numerical computing library (for array operations)
import nibabel as nib # Library for reading and writing neuroimaging file formats (NIfTI)

# --- Load MNI Template ---
# Load the 2mm MNI template NIfTI image.
img = nib.load('$MNI_2MM')
# Extract the affine transformation matrix from the template image.
# The affine matrix maps voxel coordinates to MNI (world) coordinates.
affine = img.affine
# Extract the dimensions (shape) of the template image in voxels.
shape = img.shape

# --- Calculate Inverse Affine for MNI to Voxel Conversion ---
# Calculate the inverse of the affine matrix.
# The inverse affine converts MNI (world) coordinates back into voxel indices.
inv_affine = np.linalg.inv(affine)

# --- Initialize Empty Mask ---
# Create an empty 3D NumPy array of the same shape as the MNI template.
# This array will serve as the binary mask, initialized with zeros.
# `dtype=np.uint8`: Sets the data type to unsigned 8-bit integer (0 or 1).
mask = np.zeros(shape, dtype=np.uint8)

# --- Read MNI Coordinates and Populate Mask ---
# Open the input text file containing MNI coordinates.
with open('$INPUT') as f:
    # Iterate over each line in the input file.
    for line in f:
        # Remove leading/trailing whitespace and split the line by spaces.
        parts = line.strip().split()
        # Skip line if it doesn't contain at least 3 parts (X, Y, Z).
        if len(parts) < 3:
            continue
        # Convert the first three parts (X, Y, Z) to floating-point numbers.
        x, y, z = map(float, parts[:3])
        # Create an MNI coordinate vector, adding a 1 for the homogeneous coordinate.
        mni = np.array([x, y, z, 1])
        # Convert MNI coordinates to approximate voxel coordinates using the inverse affine.
        # `.dot(mni)` performs the matrix-vector multiplication.
        # `[:3]` selects only the X, Y, Z voxel coordinates (discards the homogeneous component).
        voxel = inv_affine.dot(mni)[:3]
        # Round the voxel coordinates to the nearest integer and convert to integer type.
        # Voxel indices must be integers.
        voxel = np.round(voxel).astype(int)

        # Check if the calculated voxel coordinates are within the bounds of the image volume.
        # This prevents indexing errors if a coordinate falls outside the template's dimensions.
        if all(0 <= voxel[i] < shape[i] for i in range(3)):
            # If within bounds, set the voxel at these coordinates in the mask to 1.
            mask[tuple(voxel)] = 1

# --- Save Mask as NIfTI File ---
# Create a new NIfTI image object from the populated mask data.
# `mask`: The NumPy array containing the binary mask data.
# `affine`: The affine matrix from the original MNI template, ensuring the mask
#           has the same spatial orientation and resolution.
mask_img = nib.Nifti1Image(mask, affine)
# Save the NIfTI image to the specified output file path.
nib.save(mask_img, '$OUTPUT')
EOF

# --- Confirmation Message ---
# Display a confirmation message to the user after the Python script completes.
# `\u2705` is a Unicode checkmark symbol for visual confirmation.
echo -e "\u2705 Mask saved as: $OUTPUT" # -e enables interpretation of backslash escapes (like \u for Unicode).
