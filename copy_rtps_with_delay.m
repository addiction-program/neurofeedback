function copy_rtps_with_delay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % copy_rtps_with_delay
    % Developed by Amir Hossein Dakhili
    % amirhossein.dakhili@myacu.edu.au
    % Australian Catholic University
    % Created: April 2024
    % Last Modified: June 2025
    %
    % This function simulates the real-time data flow in a neurofeedback
    % experiment by copying Real-Time Protocol (RTP) files from a source
    % directory to a destination directory with a simulated, random delay
    % between each copy operation. This is particularly useful for testing
    % neurofeedback scripts offline that rely on the sequential arrival of
    % RTP files (e.g., from BrainVoyager).
    %
    % Key Features:
    % - **Interactive Folder Selection**: Uses `uigetdir` to allow the user
    %   to graphically select both the source (input) folder containing the
    %   RTP files and the target (output) folder where the copies will be placed.
    % - **User-Defined Delay**: Prompts the user to input a maximum delay
    %   value in seconds. This allows for flexible simulation of different
    %   data transfer latencies.
    % - **Randomized Delay**: Introduces a random delay (between 1 second and
    %   the user-specified maximum delay) before copying each subsequent RTP file.
    %   This helps simulate more realistic, variable network or system delays.
    % - **Natural Sort Order**: Ensures that RTP files are copied in their
    %   natural numerical order (e.g., file-1.rtp, file-2.rtp, file-10.rtp)
    %   rather than alphabetical order, which is crucial for maintaining
    %   the chronological integrity of real-time data.
    % - **File Copy Operation**: Utilizes the `copyfile` command to perform
    %   the actual file transfer, providing console output for each successful
    %   copy.
    % - **Robustness**: Includes checks for user cancellation during folder
    %   selection, preventing errors if no folders are chosen.
    %
    % Important Considerations:
    % - **RTP File Naming Convention**: This script assumes RTP files are named
    %   with a numeric sequence (e.g., `NFB-1.rtp`, `NFB-2.rtp`). The `regexp`
    %   function relies on this convention to extract and sort the file numbers.
    % - **Purpose of Delay**: The simulated delay is intended to mimic the
    %   time it takes for fMRI data to be processed and made available as an
    %   RTP file in a real-time neurofeedback setup. Adjust the `delay` input
    %   based on the typical TR (Repetition Time) and processing latency of
    %   your fMRI system.
    % - **Testing Environment**: This function is primarily for offline testing
    %   and simulation. It does not connect to actual fMRI scanners or
    %   BrainVoyager directly.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Open a dialog to select the input folder
input_folder_path = uigetdir(pwd, 'Select the input folder containing RTP files'); 

% Check if a folder was selected
if isequal(input_folder_path,0)
   disp('No folder was selected. Exiting...');
   return;
else
   disp(['Selected input folder: ', input_folder_path]);
end

% Open a dialog to select the output folder
output_folder_path = uigetdir(pwd, 'Select the output folder');

% Check if a folder was selected
if isequal(output_folder_path,0)
   disp('No folder was selected. Exiting...');
   return;
else
   disp(['Selected output folder: ', output_folder_path]);
end

% Get delay from user input
delay = input('Enter the maximum delay in seconds between copy operations: ');

% Get a list of all RTP files in the input folder
rtp_files = dir(fullfile(input_folder_path, '*.rtp')); 

% Extract numeric parts from filenames and sort
[~, file_order] = sort(cellfun(@(x) str2double(regexp(x, '\d+', 'match')), {rtp_files.name}));

% Iterate through sorted RTP files and copy with delay
for i = 1:length(file_order)
    source_file = fullfile(input_folder_path, rtp_files(file_order(i)).name);
    destination_file = fullfile(output_folder_path, rtp_files(file_order(i)).name);
    copyfile(source_file, destination_file);
    fprintf('Copied %s to %s\n', source_file, destination_file);
    r = 1 + (delay - 1)*rand(1,1);
    pause(r); 
end

end