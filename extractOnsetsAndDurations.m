function extractOnsetsAndDurations()
    % Select input log.mat file
    [filename, pathname] = uigetfile('*.mat', 'Select the input log.mat file');
    
    % Check if a file was selected
    if isequal(filename,0) || isequal(pathname,0)
       disp('User pressed cancel')
    else
       disp(['User selected ', fullfile(pathname, filename)])
       fullpath = fullfile(pathname, filename);
       
       % Load data from the selected file
       load(fullpath); 

       % Extract timings for each condition (in milliseconds)
       %rest_timings = rest_block_timings(:, [1 2]) * 1000;  % MRI block start and end times
       upregulation_timings = Up_block_timings(:, [1 2]) * 1000; 
       downregulation_timings = Down_block_timings(:, [1 2]) * 1000;
       neutral_timings = Neutral_block_timings(:, [1 2]) * 1000;

       % Sort timings in ascending order
       %rest_timings = sortrows(rest_timings);
       upregulation_timings = sortrows(upregulation_timings);
       downregulation_timings = sortrows(downregulation_timings);
       neutral_timings = sortrows(neutral_timings);

       % Create output PRT file
       output_filename = 'NFB_timing.prt'; 
       fileID = fopen(output_filename, 'w');
       fprintf(fileID, '\n'); 
       fprintf(fileID, 'FileVersion:        6\n'); 
       fprintf(fileID, '\n'); 
       fprintf(fileID, 'ResolutionOfTime:   msec\n');
       fprintf(fileID, '\n'); 
       fprintf(fileID, 'Experiment:         NFB\n');
       fprintf(fileID, '\n'); 
       fprintf(fileID, 'BackgroundColor:    0 0 0\n');
       fprintf(fileID, 'TextColor:          255 255 255\n');
       fprintf(fileID, 'TimeCourseColor:    255 255 30\n');
       fprintf(fileID, 'TimeCourseThick:    2\n');
       fprintf(fileID, 'ReferenceFuncColor: 30 200 30\n');
       fprintf(fileID, 'ReferenceFuncThick: 2\n');
       fprintf(fileID, '\n'); 
       fprintf(fileID, 'NrOfConditions:  3\n'); 

       % Write Rest condition information
%        fprintf(fileID, 'Rest\n');
%        fprintf(fileID, '%d\n', size(rest_timings, 1)); 
%        for i = 1:size(rest_timings, 1)
%            fprintf(fileID, '%d %d\n', round(rest_timings(i, 1)), round(rest_timings(i, 2))); 
%        end
%        fprintf(fileID, 'Color: 85 0 0\n\n');

       % Write Neutral condition information
       fprintf(fileID, 'Neutral\n'); 
       fprintf(fileID, '%d\n', size(neutral_timings, 1));
       for i = 1:size(neutral_timings, 1)
           fprintf(fileID, '%d %d\n', round(neutral_timings(i, 1)), round(neutral_timings(i, 2))); 
       end
       fprintf(fileID, 'Color: 85 85 0\n\n'); 

       % Write Upregulation condition information
       fprintf(fileID, 'Upregulation\n'); 
       fprintf(fileID, '%d\n', size(upregulation_timings, 1));
       for i = 1:size(upregulation_timings, 1)
           fprintf(fileID, '%d %d\n', round(upregulation_timings(i, 1)), round(upregulation_timings(i, 2))); 
       end
       fprintf(fileID, 'Color: 0 85 0\n\n'); 

       % Write Downregulation condition information
       fprintf(fileID, 'Downregulation\n'); 
       fprintf(fileID, '%d\n', size(downregulation_timings, 1)); 
       for i = 1:size(downregulation_timings, 1)
           fprintf(fileID, '%d %d\n', round(downregulation_timings(i, 1)), round(downregulation_timings(i, 2))); 
       end
       fprintf(fileID, 'Color: 0 0 85\n\n'); 

       

       fprintf(fileID, 'ResponseConditions: \t 0\n');

       % Close the file
       fclose(fileID);
       disp(['Timing information saved to: ' output_filename]);
    end
end