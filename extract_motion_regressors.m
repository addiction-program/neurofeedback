% ==============================================================================
% Extract Motion Regressors from fMRIPrep Confounds TSV
% ==============================================================================
% Developed by: Amir Hossein Dakhili
% Email: amirhossein.dakhili@myacu.edu.au
% Affiliation: Australian Catholic University
% Date: March 2025
% Last Modified: June 2025 
%
% Description:
% This script is designed to extract the six rigid-body motion parameters
% (3 translations and 3 rotations) from the confound `.tsv` files generated
% by the fMRIPrep preprocessing pipeline. These motion parameters are
% critical regressors of no interest for inclusion in subsequent fMRI
% statistical analyses (e.g., General Linear Model), helping to account
% for variance in the BOLD signal due to head motion. The extracted data
% is saved as a MATLAB `.mat` file for easy loading into GLM software.
%
% Important Notes for Usage:
% 1.  **Input File**: The script prompts the user to select an fMRIPrep
%     confounds `.tsv` file. These files are typically found in the `func`
%     directory within the fMRIPrep derivatives, named like:
%     `sub-XXX_ses-YYY_task-TASK_run-ZZ_desc-confounds_timeseries.tsv`.
% 2.  **Required Columns**: This script specifically looks for the following
%     six columns in the `.tsv` file, which represent the motion parameters:
%     `trans_x`, `trans_y`, `trans_z`, `rot_x`, `rot_y`, `rot_z`.
%     Ensure your fMRIPrep version outputs these exact column names.
%     If any are missing, the script will throw an error.
% 3.  **Output Format**: The extracted motion regressors are saved into a
%     MATLAB `.mat` file. The file will contain a single variable named `R`,
%     which is an N x 6 matrix, where N is the number of time points (rows
%     in the TSV) and 6 corresponds to the motion parameters.
%     The output file will be named `motion_regressors_originalfilename.mat`
%     and saved in the same directory as the input `.tsv` file.
% 4.  **Path Handling**: The script uses `uigetfile` to handle file selection,
%     making directory path management interactive.
%
% This script is a utility for preparing motion regressors for fMRI statistical
% analysis pipelines within the Neuroscience of Addiction and Mental Health
% Program at Australian Catholic University.
% ==============================================================================

% Prompt user to select a .tsv file using a graphical file selection dialog.
% The 'uigetfile' function opens a standard file open dialog box.
% '*.tsv': Filters files to show only those with a .tsv extension.
% 'Select the Confounds TSV File': Title of the dialog box.
[filename, pathname] = uigetfile('*.tsv', 'Select the Confounds TSV File');

% Check if the user cancelled the file selection (filename will be 0 if cancelled).
if isequal(filename, 0)
    error('No file selected. Exiting script.'); % Terminate script execution with an error message.
end

% Construct the full path to the selected TSV file.
tsv_file = fullfile(pathname, filename);

% --- Read the .tsv file ---
% `detectImportOptions`: Automatically detects import options for a text file,
% which is robust for varying TSV structures.
opts = detectImportOptions(tsv_file, 'FileType', 'text', 'Delimiter', '\t');
% `readtable`: Reads the data from the TSV file into a MATLAB table.
DATA = readtable(tsv_file, opts);

% --- Validate Required Columns ---
% Define the exact names of the motion confound columns expected in the TSV.
required_fields = {'trans_x', 'trans_y', 'trans_z', 'rot_x', 'rot_y', 'rot_z'};
% `setdiff`: Finds elements in `required_fields` that are NOT in the `DATA` table's variable names.
missing_fields = setdiff(required_fields, DATA.Properties.VariableNames);

% If `missing_fields` is not empty, it means some required columns are absent.
if ~isempty(missing_fields)
    % Throw an error and stop the script, informing the user about missing columns.
    error(['Missing required motion confound columns in the TSV file: ', strjoin(missing_fields, ', '), ...
           '. Please ensure your fMRIPrep output contains these fields.']);
end

% --- Extract Relevant Motion Confounds ---
% `zeros(height(DATA), 6)`: Preallocate a matrix `R` with the number of rows
% matching the number of time points (rows in the TSV) and 6 columns for the regressors.
% Preallocation is good practice for performance in MATLAB loops/assignments.
R = zeros(height(DATA), 6);
% Assign data from the table columns to the matrix `R`.
% The order here (trans_x, trans_y, trans_z, rot_x, rot_y, rot_z) is standard.
R(:, 1) = DATA.trans_x;
R(:, 2) = DATA.trans_y;
R(:, 3) = DATA.trans_z;
R(:, 4) = DATA.rot_x;
R(:, 5) = DATA.rot_y;
R(:, 6) = DATA.rot_z;

% --- Prepare Output Filename ---
% `fileparts(filename)`: Breaks down the filename into its path, base name, and extension.
% We only need the base name (`name_without_ext`) to construct the output file's name.
[~, name_without_ext, ~] = fileparts(filename);

% Construct the full path for the output .mat file.
% It will be saved in the same directory as the input TSV file.
% The name will be 'motion_regressors_' followed by the original TSV filename (without its extension).
output_filename = fullfile(pathname, sprintf('motion_regressors_%s.mat', name_without_ext));

% --- Save Regressors to .mat file ---
% `save(filename, variable_name)`: Saves the specified variable(s) to a .mat file.
% Here, we save the matrix `R`.
save(output_filename, 'R');

% Display a success message to the command window.
fprintf('Motion regressors successfully extracted and saved to: %s\n', output_filename);
