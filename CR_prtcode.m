function extractOnsetsAndDurations()
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
    cannabis_onsets = floor((cannabis_onsets) * 1000);
    neutral_onsets = floor((neutral_onsets) * 1000);
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