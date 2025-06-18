function extractOnsetsAndDurations()
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % extractOnsetsAndDurations
    % Developed by Amir Hossein Dakhili
    % amirhossein.dakhili@myacu.edu.au
    % Australian Catholic University
    % Created: April 2024
    % Last Modified: June 2025
    %
    % This script is designed to process experimental log data, typically
    % generated from a psychological experiment, and convert it into a
    % BrainVoyager PRT (Protocol) file. A PRT file is crucial for fMRI
    % data analysis, as it defines the onset and offset times of different
    % experimental conditions, allowing for the creation of design matrices
    % to analyze brain responses.
    %
    % Key Features:
    % - **User Interface for File Selection**: Provides a user-friendly dialog
    %   to select the input `.mat` log file, ensuring flexibility for
    %   different datasets.
    % - **Robust Data Loading**: Includes error handling for file loading,
    %   making the script more robust to invalid file selections.
    % - **Condition-Specific Onset Extraction**: Identifies and extracts
    %   stimulus onset times for 'Cannabis' and 'Neutral' trial types based
    %   on predefined trial index ranges within `log_triallist`.
    % - **Time Adjustment and Conversion**:
    %   - Adjusts onset times by adding a fixed 3000 ms (3 seconds), which
    %     might account for scanner trigger delays or an initial buffer period.
    %   - Converts all timings from seconds (as assumed from `log_stimOnset`)
    %     to milliseconds, the required unit for BrainVoyager PRT files.
    % - **Fixed Duration Calculation**: Automatically calculates stimulus
    %   offset times by adding a fixed duration of 4000 ms (4 seconds) to
    %   each onset, simplifying protocol creation for fixed-duration events.
    % - **PRT File Generation**: Creates a new BrainVoyager PRT file with a
    %   standard header, specifying file version, time resolution, experiment
    %   name, and default display colors for the protocol.
    % - **Formatted Output**: Writes the onset and offset times for 'Neutral'
    %   and 'Cannabis' conditions with precise formatting to ensure
    %   compatibility and readability within BrainVoyager.
    % - **Color Assignment**: Assigns distinct display colors for each condition
    %   within the PRT file (e.g., 'Neutral' as dark red, 'Cannabis' as dark green)
    %   for clear visual differentiation during analysis.
    %
    % Important Considerations:
    % - **Input Data Structure**: This script assumes the input `.mat` file
    %   contains specific variables: `log_triallist` (a matrix where the first
    %   column defines trial types/indices) and `log_stimOnset` (a matrix where
    %   the first column contains stimulus onset times in seconds). Any deviation
    %   from this structure will require modifications to the script's data
    %   extraction logic.
    % - **Trial Index Ranges**: The trial index ranges for 'Cannabis' (1-30)
    %   and 'Neutral' (31-60) are hardcoded. These values must be accurate
    %   for your specific experimental design.
    % - **Timing Adjustment Value**: The `+3000` ms adjustment to onsets is
    %   a critical parameter. Ensure this value correctly reflects any
    %   necessary delays (e.g., scanner pre-scan, initial fixation period)
    %   in your experiment relative to your logged onset times.
    % - **Fixed Stimulus Duration**: The `+4000` ms duration for all stimuli
    %   is also a hardcoded assumption. If your stimuli have variable durations,
    %   you will need to adjust the duration calculation accordingly, potentially
    %   by extracting durations from your log file.
    % - **Output Filename**: The output PRT file is named by appending `.prt`
    %   to the input `.mat` filename. If a different naming convention is desired,
    %   the `outputFilename` variable should be modified.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Select input log.mat file
    [filename, pathname] = uigetfile('*.mat', 'Select the input log.mat file');
    fullpath = fullfile(pathname, filename); 
    % Load data from the selected file
    try
        log_data = load(fullpath);
    catch
        error('Error loading the file. Please ensure it is a valid .mat file.');
    end
    % Extract relevant variables from log_data
    log_triallist = log_data.log_triallist;
    log_stimOnset = log_data.log_stimOnset;
    
   
    % Extract onsets
    cannabis_trial_indices = log_triallist(:, 1) >= 1 & log_triallist(:, 1) <= 30; 
    neutral_trial_indices = log_triallist(:, 1) >= 31 & log_triallist(:, 1) <= 60;
    cannabis_onsets = log_stimOnset(cannabis_trial_indices, 1);
    neutral_onsets = log_stimOnset(neutral_trial_indices, 1);
    
    % Subtract trigger time value from onsets
    cannabis_onsets = floor(((cannabis_onsets) * 1000)+3000);
    neutral_onsets = floor(((neutral_onsets) * 1000)+3000);
    % Create durations with all values set to 4
    durations = {repmat(4,1,30), repmat(4,1,30)};
    
    % Ensure onsets are row vectors before combining
    cannabis_onsets = cannabis_onsets(:).'; 
    neutral_onsets = neutral_onsets(:).'; 

    % Calculate offset times (onset + 4000)
    cannabis_offsets = cannabis_onsets + 4000;
    neutral_offsets = neutral_onsets + 4000;
    
    % Combine onsets and offsets into separate column vectors
    cannabis_results = [cannabis_onsets; cannabis_offsets];
    neutral_results = [neutral_onsets; neutral_offsets];
    
    % Save results to a new text file (results.txt) with header
    outputFilename = strcat('results_', filename, '.prt');
    outputFullpath = fullfile(pathname, outputFilename);
    fid = fopen(outputFullpath, 'w');
if fid > 0
    fprintf(fid, '\n'); 
    fprintf(fid, 'FileVersion:        6\n'); 
    fprintf(fid, '\n'); 
    fprintf(fid, 'ResolutionOfTime:   msec\n');
    fprintf(fid, '\n'); 
    fprintf(fid, 'Experiment:         NFB\n');
    fprintf(fid, '\n'); 
    fprintf(fid, 'BackgroundColor:    0 0 0\n');
    fprintf(fid, 'TextColor:          255 255 255\n');
    fprintf(fid, 'TimeCourseColor:    255 255 30\n');
    fprintf(fid, 'TimeCourseThick:    2\n');
    fprintf(fid, 'ReferenceFuncColor: 30 200 30\n');
    fprintf(fid, 'ReferenceFuncThick: 2\n');
    fprintf(fid, '\n'); 
    fprintf(fid, 'NrOfConditions:  2\n');
    fprintf(fid, '\n'); 
    fprintf(fid, 'Neutral\n');
    fprintf(fid, '30\n');
    
    % Define the column widths
    onset_width = 7; % Width for onset column
    offset_width = 9; % Width for offset column

    % Print neutral results with fixed-width formatting
    for i = 1:length(neutral_onsets)
        fprintf(fid, '%*s%*d%*d\n', 2, '', onset_width, neutral_onsets(i), offset_width, neutral_offsets(i));
    end
    
    fprintf(fid, '\n');
    fprintf(fid, 'Color: 85 0 0\n');
    fprintf(fid, '\n');
    fprintf(fid, 'Cannabis\n');
    fprintf(fid, '30\n');
    
    % Print cannabis results with fixed-width formatting
    for i = 1:length(cannabis_onsets)
        fprintf(fid, '%*s%*d%*d\n', 2, '', onset_width, cannabis_onsets(i), offset_width, cannabis_offsets(i));
    end
    
    fprintf(fid, 'Color: 0 85 0\n');
    fclose(fid);
    fprintf('Results saved to %s\n', outputFullpath);
else
    error('Error creating .PRT file.');
end