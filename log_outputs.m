% Ask user for input file
[inputFilename, inputPath] = uigetfile('*.xlsx', 'Select the input Excel file');
if isequal(inputFilename,0) || isequal(inputPath,0)
   disp('User selected Cancel')
   return;
end
inputFullFilename = fullfile(inputPath, inputFilename);

% Ask user for output directory
outputDir = uigetdir(pwd, 'Select the output directory');
if isequal(outputDir,0)
   disp('User selected Cancel')
   return;
end

% Read the first column from the Excel file
data = readcell(inputFullFilename, 'Range', 'A:A');

% Initialize arrays to store numeric values
fullVolTimeValues = [];
readVolTimeValues = [];

% Loop through each cell in the data
for i = 1:length(data)
  cellContent = data{i}; 
  
  % Check if the cell is a char array (text) before using contains
  if ischar(cellContent) 
      if contains(cellContent, 'FullVolTime:')
          % Extract the value after 'FullVolTime:'
          strValue = extractAfter(cellContent, 'FullVolTime:');
          
          % Remove 'ms' and any extra spaces
          strValue = strrep(strValue, 'ms', '');
          strValue = strtrim(strValue);
          
          % Try converting the string to a number
          numValue = str2double(strValue);
          
          % If the conversion is successful, add it to the array
          if ~isnan(numValue)
              fullVolTimeValues = [fullVolTimeValues; numValue];
          end
          
      elseif contains(cellContent, 'ReadVolTime:')
          % Extract the value after 'ReadVolTime:'
          strValue = extractAfter(cellContent, 'ReadVolTime:');
          
          % Remove 'ms' and any extra spaces
          strValue = strrep(strValue, 'ms', '');
          strValue = strtrim(strValue);
          
          % Try converting the string to a number
          numValue = str2double(strValue);
          
          % If the conversion is successful, add it to the array
          if ~isnan(numValue)
              readVolTimeValues = [readVolTimeValues; numValue]; 
          end
      end
  end
end

% Ensure both arrays have the same size (in case of missing values)
minLen = min(length(fullVolTimeValues), length(readVolTimeValues));
fullVolTimeValues = fullVolTimeValues(1:minLen);
readVolTimeValues = readVolTimeValues(1:minLen);

% Calculate the difference
timeDifference = fullVolTimeValues - readVolTimeValues;

% Create a table 
outputTable = table(fullVolTimeValues, readVolTimeValues, timeDifference, ...
    'VariableNames', {'Full Vol Time', 'Read Vol Time', 'Difference'});

% Construct the full output filename
outputFilename = fullfile(outputDir, 'volume_time_analysis.xlsx');

% Write the table to a new Excel file
writetable(outputTable, outputFilename);
disp(['Values extracted and saved to: ', outputFilename]);