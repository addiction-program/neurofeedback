% ==============================================================================
% Process Neurofeedback Log Data for Event-Related Analysis
% ==============================================================================
% Developed by: Amir Hossein Dakhili
% Email: amirhossein.dakhili@myacu.edu.au
% Affiliation: Australian Catholic University
% Date: March 2025
% Last Modified: June 2025
%
% Description:
% This script is designed to process raw log data from real-time neurofeedback
% (rt-NFB) experiments, typically generated by Psychtoolbox. Its primary
% function is to extract event onset, offset, and duration information for
% various experimental conditions (e.g., Upregulation, Downregulation, Neutral,
% FixationCross, and Instruction blocks). The extracted timing data is then
% organized into standardized cell arrays and saved into a new MATLAB `.mat`
% file, which is a common format required for event-related fMRI analysis
% pipelines (e.g., SPM, FSL, AFNI).
%
% Key Features:
% 1.  **Interactive File Selection**: Prompts the user to graphically select
%     the input `.mat` log file, providing flexibility in data management.
% 2.  **Robust Data Extraction**: Safely loads data and checks for the
%     existence and non-emptiness of expected timing variables (e.g.,
%     `Up_block_timings`, `Down_block_timings`, `Neutral_block_timings`,
%     `Fix_block_timings`, `cue_timings`). This prevents errors if certain
%     blocks did not occur or if log variables are empty.
% 3.  **Standardized Output**: Organizes the extracted timings into four
%     cell arrays: `names` (condition names), `onsets` (onset times),
%     `offsets` (offset times), and `durations` (event durations). Each
%     cell within these arrays corresponds to a specific experimental condition.
% 4.  **Duration Truncation**: Durations are explicitly truncated to integers
%     using `floor()`, which is often required by fMRI analysis software.
% 5.  **Output File**: Saves the processed timing information into a new
%     `.mat` file with "_processed" appended to the original filename,
%     located in the same directory as the input file.
% 6.  **Error Handling**: Includes a `try-catch` block for robust handling
%     of file loading errors or other unexpected issues during processing.
%
% This script is an essential utility for preparing behavioral timing data
% for fMRI analysis within the Neuroscience of Addiction and Mental Health
% Program at Australian Catholic University.
% ==============================================================================

function processMatFile()
    % processMatFile()
    % This function guides the user through selecting a .mat log file,
    % extracts specific timing information for different experimental blocks,
    % and then saves this organized data into a new .mat file.
    % It's designed to be robust against missing or empty timing variables.

    % --- Step 1: File Selection ---
    % Prompts the user to select a .mat file using a graphical dialog box.
    % '*.mat': Filters the displayed files to only show MATLAB .mat files.
    % 'Select a .mat file': Title of the file selection dialog.
    [filename, pathname] = uigetfile('*.mat', 'Select a .mat file');

    % Check if the user cancelled the file selection.
    % If filename is 0, the user cancelled.
    if isequal(filename, 0)
        disp('User canceled file selection. Script execution aborted.');
        return; % Exit the function.
    end

    % Construct the full path to the selected file.
    fullFilePath = fullfile(pathname, filename);

    % --- Step 2: Load Data and Initialize Variables ---
    % Use a try-catch block to gracefully handle potential errors during file loading
    % or subsequent data processing.
    try
        % Load all variables from the selected .mat file into a structure named `data`.
        data = load(fullFilePath);

        % Initialize variables that will hold timing data from the loaded file.
        % Setting them to empty arrays initially prevents errors if a field
        % does not exist in the loaded .mat file or is empty.
        up_timings = [];        % For Upregulation block timings
        down_timings = [];      % For Downregulation block timings
        neutral_timings = [];   % For Neutral block timings
        fix_timings = [];       % For FixationCross block timings
        inst_timings = [];      % For Instruction cue timings

        % --- Step 3: Conditionally Extract Timing Variables ---
        % Check if each expected timing variable exists as a field in the loaded `data`
        % structure AND if it is not empty. If both conditions are true, extract the data.
        if isfield(data, 'Up_block_timings') && ~isempty(data.Up_block_timings)
            up_timings = data.Up_block_timings;
        end

        if isfield(data, 'Down_block_timings') && ~isempty(data.Down_block_timings)
            down_timings = data.Down_block_timings;
        end

        if isfield(data, 'Neutral_block_timings') && ~isempty(data.Neutral_block_timings)
            neutral_timings = data.Neutral_block_timings;
        end

        if isfield(data, 'Fix_block_timings') && ~isempty(data.Fix_block_timings)
            fix_timings = data.Fix_block_timings;
        end

        if isfield(data, 'cue_timings') && ~isempty(data.cue_timings)
            inst_timings = data.cue_timings;
        end

        % --- Step 4: Organize Timings into Standardized Cell Arrays ---
        % Initialize cell arrays that will store the processed timing data.
        % These are common structures for fMRI analysis software (e.g., SPM).
        names = {};     % Cell array to store condition names (e.g., 'Upregulation')
        onsets = {};    % Cell array to store onset times for each condition
        offsets = {};   % Cell array to store offset times for each condition
        durations = {}; % Cell array to store durations for each condition

        % Process Upregulation timings if available
        % `size(up_timings, 2) >= 3`: Ensures the matrix has at least onset, offset, and duration columns.
        if ~isempty(up_timings) && size(up_timings, 2) >= 3
            names{end+1} = 'Upregulation';              % Add condition name
            onsets{end+1} = up_timings(:, 1)';          % Extract onset column (1st), transpose to row vector
            offsets{end+1} = up_timings(:, 2)';         % Extract offset column (2nd), transpose to row vector
            durations{end+1} = floor(up_timings(:, 3))'; % Extract duration column (3rd), truncate to integer, transpose
        end

        % Process Downregulation timings if available
        if ~isempty(down_timings) && size(down_timings, 2) >= 3
            names{end+1} = 'Downregulation';
            onsets{end+1} = down_timings(:, 1)';
            offsets{end+1} = down_timings(:, 2)';
            durations{end+1} = floor(down_timings(:, 3))';
        end

        % Process Neutral timings if available
        if ~isempty(neutral_timings) && size(neutral_timings, 2) >= 3
            names{end+1} = 'Neutral';
            onsets{end+1} = neutral_timings(:, 1)';
            offsets{end+1} = neutral_timings(:, 2)';
            durations{end+1} = floor(neutral_timings(:, 3))';
        end

        % Process FixationCross timings if available
        if ~isempty(fix_timings) && size(fix_timings, 2) >= 3
            names{end+1} = 'FixationCross';
            onsets{end+1} = fix_timings(:, 1)';
            offsets{end+1} = fix_timings(:, 2)';
            durations{end+1} = floor(fix_timings(:, 3))';
        end

        % Process Instruction timings if available
        if ~isempty(inst_timings) && size(inst_timings, 2) >= 3
            names{end+1} = 'Instruction';
            onsets{end+1} = inst_timings(:, 1)';
            offsets{end+1} = inst_timings(:, 2)';
            durations{end+1} = floor(inst_timings(:, 3))';
        end

        % --- Step 5: Save Processed Data to a New .mat File ---
        % `fileparts`: Extracts the path, filename (without extension), and extension from the input file's full path.
        [pathstr, name, ext] = fileparts(fullFilePath);
        % Construct the output file path. It will be named like 'original_filename_processed.mat'.
        outputFilePath = fullfile(pathstr, [name, '_processed', ext]);

        % Save the newly created cell arrays ('names', 'onsets', 'offsets', 'durations')
        % into the new .mat file.
        save(outputFilePath, 'names', 'onsets', 'offsets', 'durations');
        disp(['Processed timing data successfully saved to: ', outputFilePath]);

    % --- Step 6: Error Handling for Processing ---
    catch ME
        % If any error occurs during the try block (e.g., file corruption, unexpected data format),
        % this catch block will execute and display the error message.
        disp(['An error occurred during processing: ', ME.message]);
        % Optionally, rethrow(ME) to stop execution and show the full stack trace.
    end
end
