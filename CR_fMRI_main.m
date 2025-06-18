function CR_fMRI_main

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% -- CUE REACTIVITY fMRI TASK --
%%%%%
%%%%%
%%%%% Modified by Amir Hossein Dakhili
%%%%% Email: amirhossein.dakhili@myacu.edu.au
%%%%% Last update: 2-Apr-2025
%%%%%
%%%%% Notes:
%%%%% Use Enter to quit task. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% init matlab
% clear all variables and close all figures
sca;
close all;
clear;
Screen('Preference', 'SkipSyncTests', 1);

fprintf('\nInitialising...\n');
% set the random number generator seed based on the current time
rng('default')

% add the folder in the path
if ismac
    root_path='C:\Users\NFB-user\Documents\NFB\Cue-reactivity latest\3-Current_MR_CRtask_v1_after2ndScan\Current_MR_CRtask_v1\MR_CRtask_v1';
    PTB_path='C:\Users\NFB-user\Documents\Psychtoolbox';
else
    root_path='Z:\TBVData\HumanData\NFB'; % UPDATE THIS WHEN USING ON A NEW COMPUTER!
    PTB_path='C:\Users\bmoffat\Documents\MATLAB\Psychtoolbox';
end

cd(root_path)
addpath(pwd)

% add PTB in the path
if exist('Screen')~=3
    fprintf('\nPsychToolBox is not in the MATLAB path. Trying to add it...')
    addpath(genpath(PTB_path));
end

% Set Keyboard codes
KbName('UnifyKeyNames'); % accepts identical key names on all operating systems
ESC_KEY = KbName('ESCAPE');
SCANNER_KEY = KbName('T');
RETURN_Key=KbName('return'); %define return key (used to end)
DELETE_Key=KbName('DELETE'); %define delete key (used to delete)

KbQueueCreate;
KbQueueStart;

% Initialise subject and experiment details
checkinfo = 0;
answerdebug = input('\nRun debug? \nType 0 (no) or 1 (yes, debug): '); %[ANSWER 0 for testing]
while checkinfo < 1
    % If not debug, enter subject info
    if answerdebug
        participantID   = 'SUBJ000'; 
        participantN    = '000';
        researcherID    = 'debug'; 
        expstart        = datestr(now,'ddmmmyyyy-HHMM');   % string with current date
    else
        participantID   = input('Type in Participant ID (e.g. SUBJOO1):','s'); % TYPE IN full participant ID
        participantN    = input('Type in Participant Number (e.g. 001):','s'); % TYPE IN 3 DIGITS
        researcherID    = input('Type in Researcher Initials running the task (e.g. VL or VL MK for 2 people):','s'); % TYPE IN researcher ID; first list a primary tester
        expstart        = datestr(now,'ddmmmyyyy-HHMM');   % string with current date
    end
    pN=str2double(participantN);
    fprintf('\nCheck session details: \n');
    fprintf('Particpant ID = %s\nParticipant number = %d\nTesting researcher = %s\nDate = %s\n',participantID,pN,researcherID,expstart);
    checkinfo = input('Press enter if details are correct or type 0 to re-enter: '); %[ ANSWER 0 for re-enter all details]
end

TaskInfo.pID=participantID;
TaskInfo.pNum=pN;
TaskInfo.sesNum=1;
TaskInfo.sesVersion='A';
TaskInfo.rID=researcherID;
TaskInfo.randVersion = 1;
TaskInfo.Date=expstart;

%%

% Initialise screen
screenNumbers = Screen('Screens');
if ismac
    numscreen = min(screenNumbers);
    Screen('Preference', 'SkipSyncTests', 1);
else
    numscreen = max(screenNumbers);  %1
    % Hide the mouse cursor
    HideCursor;
    ListenChar(2);
end

% Set Font and other display parameters
InstrFont = 58; 
InstrFontSmall = 44; 
FixCrossFont = 500;

% Define colors

white = WhiteIndex(numscreen);
black = BlackIndex(numscreen);
grey = GrayIndex(numscreen);
red = [white 0 0];
blue = [0 0 white];
magenta = [0 255 255];

% Open an on screen window and color it grey
[window, windowRect] = PsychImaging('OpenWindow', numscreen, black, []);

% Set the blend funciton for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Get the size of the on screen window in pixels
% For help see: help RectCenter
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Get the centre coordinate of the window in pixels
% For help see: help RectCenter
[xCenter, yCenter] = RectCenter(windowRect);

% Show window to particpant
Screen('TextSize',window, InstrFont);
DrawFormattedText(window, 'We are setting up the experiment...', 'center', 'center', black);
Screen('Flip',window);
WaitSecs(1);

% loading images
Screen('TextSize',window, InstrFont);
DrawFormattedText(window, 'Loading stimuli...', 'center', 'center', magenta);
Screen('Flip',window);
% in this code we read in images starting with C (i.e. cannabis) first so the initial order of trials is C1-30 images are trial 1-30, N1-30 (i.e. neurtal) images are trial 31-60

    for nF=1:30
    filename1 = [root_path filesep 'CUE_REACTIVITY_TASK_IMAGES' filesep 'C' num2str(nF) '.png'];
    thispic1=imread(filename1);
    imgetex1=Screen('MakeTexture', window, thispic1);
    pertask_imge_indexes(nF,1)=imgetex1;
    imsizes(nF,1:3)=size(thispic1);
    filename2 = [root_path filesep 'CUE_REACTIVITY_TASK_IMAGES' filesep 'N' num2str(nF) '.png'];
    thispic2=imread(filename2);
    imgetex2=Screen('MakeTexture', window, thispic2);
    pertask_imge_indexes(nF,2)=imgetex2;
    imsizes(nF,4:6)=size(thispic2);
    end

% create vector from image textures
imge_indexes=reshape(pertask_imge_indexes,[],1);
%getting  image sizes
imge_sizes(1:nF,1:3)=imsizes(1:nF,1:3);
imge_sizes(nF+1:nF*2,1:3)=imsizes(1:nF,4:6);
stimDuration = 4; %sec


% Setting up randomization
% Read the CSV file into a table
eprimestimlist = readtable([root_path filesep 'EPRIME_STIM_ORDER.csv']);
% Extract the first column into a vector
all_seq_jitter = (eprimestimlist{:,1}/1000)';
all_seq = eprimestimlist{:,4}';
    
WaitSecs(0.1);
Screen('TextSize',window, InstrFont);
DrawFormattedText(window, 'Stimuli loaded.', 'center', 'center', magenta);
Screen('Flip',window);
% Wait for a key press
CheckTerminateTask;

%%
% Create VAS file
VAS_filename = sprintf('CR_fMRI_%s_%s_VAS_ratings_%s.txt', participantID, participantN, expstart);
VAS_filepath = fullfile([pwd filesep 'LOG_FILES'], VAS_filename);
VAS_file = fopen(VAS_filepath, 'w');
if VAS_file == -1
    error('Could not open file for VAS ratings: %s', VAS_filepath);
end
fprintf(VAS_file, 'Participant ID: %s\nParticipant Number: %s\nDate: %s\n\n', participantID, participantN, expstart);
fprintf(VAS_file, 'Question,Rating\n'); % Header
%%


%%
% VAS section
if answerdebug
    Screen('TextSize',window, InstrFontSmall);
    DrawFormattedText(window, 'Debug run. Skipping questions...', 'center', 'center', magenta);
    Screen('Flip',window);
    WaitSecs(2);
else
    
    CheckTerminateTask;
    initial_vas_questions = {
        'How much do you feel like smoking cannabis right now?',
        'How focused are you right now?',
        'How anxious do you feel right now?'
        };
    initial_vas_responses = displayVAS(window, windowRect, initial_vas_questions, 'Not at all', 'Extremely');
    fprintf(VAS_file, 'Pre-Task Craving,%d\n', initial_vas_responses(1));
    fprintf(VAS_file, 'Pre-Task Focused,%d\n', initial_vas_responses(2));
    fprintf(VAS_file, 'Pre-Task Anxious,%d\n', initial_vas_responses(3));
    TaskInfo.Q0_ans = initial_vas_responses(1);
    TaskInfo.Q1_ans = initial_vas_responses(2);
    TaskInfo.Q2_ans = initial_vas_responses(3);
    Screen('Flip',window); % Still might show a brief black screen
    KbQueueFlush;
end

%% TASK trials

% Draw all the text in one go - Instructions
Instrline1 = 'In this task you will see pictures on the screen.';
Instrline2 = '\n\nPlease try to keep your head still.';
Instrline3 = '\n\nYour task is to look at these pictures closely \nand as attentively as you can.';
Instrline4 = '\n\nThe task will take about 10 minutes.';
Instrline5 = '\n\nWe are about to start. Are you ready?';

Screen('TextSize', window, InstrFont);
DrawFormattedText(window, [Instrline1 Instrline2 Instrline3 Instrline4 Instrline5],'center', 'center', magenta);
Screen('Flip',window);
% Wait for 'e' key press
while true
    [keyIsDown, secs, keyCode] = KbCheck;
    if keyIsDown
        if keyCode(KbName('e'))
            while KbCheck
                WaitSecs(0.01);
            end
            break; % Exit the loop when 'e' is pressed
        end
    end
end
DrawFormattedText(window, 'Waiting for the scanner...','center', 'center', magenta);
Screen('Flip',window);
KbQueueFlush;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Wait for trigger
% while true
%     [keyIsDown, secs, keyCode] = KbCheck;
%     if keyIsDown
%         if keyCode(SCANNER_KEY)
%             break; % recieves trigger when 'T' is pressed
%         end
%     end
% end
while true
    pause(0.001);
    [pressed, pressed_keys] = KbQueueCheck;
    if pressed && pressed_keys(SCANNER_KEY)
        break; % Only break if the trigger key is pressed
    end
end
log_startExperiment=GetSecs;
%%% Initialise task variables
ntrial=1;
log_stimOnset = [];
log_stimDuration = [];
log_crossOnset = [];
log_crossDuration = [];
log_jitterlist = all_seq_jitter';
log_triallist = all_seq';
for i = 1:size(imge_indexes,1)
    CheckTerminateTask;
    this_seq_trial=all_seq(ntrial);
    this_image=imge_indexes(this_seq_trial,1);
    scalingFactor = 0.7;
    maxScaling = (screenYpixels / imge_sizes(this_seq_trial,1)) * scalingFactor;
    dstRects = CenterRectOnPointd([0 0 imge_sizes(this_seq_trial,2) imge_sizes(this_seq_trial,1)] .*maxScaling, xCenter, yCenter);
    Screen('DrawTexture', window, this_image, [], dstRects);
    stimOnset=Screen('Flip',window);
    log_stimOnset = [log_stimOnset; stimOnset-log_startExperiment];
    WaitSecs(stimDuration);
    log_stimDuration = [log_stimDuration; stimDuration];
    CheckTerminateTask;
    this_seq_jitter=all_seq_jitter(ntrial);
    crossColor = [128 128 128];  % Grey
    lineWidth = windowRect(4) / 20;     % thickness of cross
    lineLength = windowRect(3) / 4;     % length of cross arms
    
    % Horizontal line rectangle
    x1_h = xCenter - lineLength / 2;
    x2_h = xCenter + lineLength / 2;
    y1_h = yCenter - lineWidth / 2;
    y2_h = yCenter + lineWidth / 2;
    
    % Vertical line rectangle
    x1_v = xCenter - lineWidth / 2;
    x2_v = xCenter + lineWidth / 2;
    y1_v = yCenter - lineLength / 2;
    y2_v = yCenter + lineLength / 2;
    
    % Draw cross
    Screen('FillRect', window, crossColor, [x1_h y1_h x2_h y2_h]);  % horizontal bar
    Screen('FillRect', window, crossColor, [x1_v y1_v x2_v y2_v]);  % vertical bar
    crossOnset=Screen('Flip',window);
    log_crossOnset = [log_crossOnset; crossOnset-log_startExperiment];
    WaitSecs(this_seq_jitter);
    log_crossDuration = [log_crossDuration; this_seq_jitter];
    ntrial = ntrial + 1;
    CheckTerminateTask;
end

% Saving log file
log_endExperiment=GetSecs;
log_endExperiment=log_endExperiment-log_startExperiment;

%%%%postavs
if answerdebug
    Screen('TextSize',window, InstrFontSmall);
    DrawFormattedText(window, 'Debug run. Skipping questions...', 'center', 'center', magenta);
    Screen('Flip',window);
    WaitSecs(2);
else
    CheckTerminateTask;
    final_vas_questions = {
        'How much do you feel like smoking cannabis right now?',
        'How focused are you right now?',
        'How anxious do you feel right now?'
        };
    final_vas_responses = displayVAS(window, windowRect, final_vas_questions, 'Not at all', 'Extremely');
     fprintf(VAS_file, 'Post-Task Craving,%d\n', final_vas_responses(1));
    fprintf(VAS_file, 'Post-Task Focused,%d\n', final_vas_responses(2));
    fprintf(VAS_file, 'Post-Task Anxious,%d\n', final_vas_responses(3));
    TaskInfo.Q0_end = final_vas_responses(1);
    TaskInfo.Q1_end = final_vas_responses(2);
    TaskInfo.Q2_end = final_vas_responses(3);
    Screen('Flip',window); % Still might show a brief black screen
    KbQueueFlush;
end
Screen('TextSize',window, InstrFont);
DrawFormattedText(window, 'We are done. Thank you!', 'center', 'center', magenta);
Screen('Flip',window);
% Wait for ENTER key press to exit
while true
    [keyIsDown, secs, keyCode] = KbCheck;
    if keyIsDown
        if keyCode(KbName('e'))
            break; % Exit when 'E' is pressed
        end
    end
end

ShowCursor;
ListenChar(0); % Restore keyboard output to Matlab 

save_path=[pwd filesep 'LOG_FILES/'];
savetime        = datestr(now,'ddmmmyyyy-HHMM');   % string with current date
save(sprintf('%sCR_fMRI_%s%d%s_%s_log',save_path,participantID,1,'A',savetime),'TaskInfo','log_*');
varNames = who('log*');
logStruct = struct();
for ij = 1:length(varNames)
    varName = varNames{ij};
    logStruct.(varName) = eval(varName);
end

% Combine structures
fields = fieldnames(logStruct);
for i = 1:length(fields)
    TaskInfo.(fields{i}) = logStruct.(fields{i});
end

saveT = struct2table(TaskInfo, 'AsArray', true);
% Write data to text file
writetable(saveT, sprintf('%sCR_fMRI_%s%d%s_%s_log.txt',save_path,participantID,1,'A',savetime));

sca;


%% Nested Functions
   function WaitForTrigger
    pressed = false;
    while ~pressed
        pause(0.001);
        [pressed, pressed_keys] = KbQueueCheck;
    end
    
    if pressed_keys(SCANNER_KEY)
        return; % Exit the function after receiving the trigger
    end
end




function CheckTerminateTask
            [~, pressed_keys] = KbQueueCheck;
            if pressed_keys(ESC_KEY) && exist('log_stimOnset',"var")>0
                ShowCursor;
                ListenChar(0); % Restore keyboard output to Matlab 
                save_path=[pwd filesep 'LOG_FILES/'];
                savetime        = datestr(now,'ddmmmyyyy-HHMM');   % string with current date
                save(sprintf('%sCR_fMRI_%s%d%s_%s_TERMINATED_log',save_path,participantID,sN,sessionVers,savetime),'TaskInfo','log_*');
                % Create a table with the data and variable names
                % Get a list of variables that start with 'log'
                varNames = who('log*');
                % Initialize an empty structure
                logStruct = struct();
                % Iterate over each variable name and add it to the structure
                for ij = 1:length(varNames)
                    varName = varNames{ij};
                    logStruct.(varName) = eval(varName);
                end
                TaskInfo = mergestruct(TaskInfo,logStruct);
                saveT = struct2table(TaskInfo, 'AsArray', true);
                % Write data to text file
                writetable(saveT, sprintf('%sCR_fMRI_%s%d%s_%s_TERMINATED_log',save_path,participantID,sN,sessionVers,savetime));
                Screen('TextSize',window, InstrFont);
                DrawFormattedText(window, 'Task terminated...','center', 'center', magenta);
                Screen('Flip',window);
                fprintf('\nTASK TEMINATED!\n');
                sca;
            elseif pressed_keys(ESC_KEY) && exist('log_stimOnset',"var")==0
                ShowCursor;
                ListenChar(0); % Restore keyboard output to Matlab 
                Screen('TextSize',window, InstrFont);
                DrawFormattedText(window, 'Task terminated...','center', 'center', magenta);
                Screen('Flip',window);
                fprintf('\nTASK TEMINATED!\n');
                sca;
            end
end
%%%%%%%%%%%%%%%%%%
function responses = displayVAS(window, windowRect, questions, label1, label2)
    % displayVAS  Displays a series of visual analog scale (VAS) questions
    %             and returns the user's ratings.
    %
    %   Inputs:
    %       window          - The Psychtoolbox window pointer.
    %       windowRect      - The screen dimensions [x1, y1, x2, y2].
    %       questions       - A cell array of question strings (instructionTexts).
    %       label1          - The label for the left end of the scale (vasLabels{1}{1}).
    %       label2          - The label for the right end of the scale (vasLabels{1}{2}).
    %
    %   Output:
    %       responses       - A numeric array of the user's ratings (1-10),
    %                         where each element corresponds to a question.
    % Parameters
    scaleMin = 1;
    scaleMax = 10;
    scaleStep = 1;
    scaleDuration = 10; % Duration in seconds before the scale closes automatically
    markerColor = [255, 0, 0]; % Red marker
    markerWidth = 20;
    scaleColor = [255, 255, 255]; % Scale color is white
    textColor = [255, 255, 255]; % Text color is white
    textSize = windowRect(4) * 0.03; % Text size as 5% of the screen height
    smallTextSize = textSize; % Smaller text size for numbers and labels
    [centerX, centerY] = RectCenter(windowRect); % centreX, centrey
    % Scale parameters
    scaleLength = windowRect(3) * 0.5; % scr_rect(3)
    scaleHeight = windowRect(4) * 0.03; % scr_rect(4)
    scaleX = (windowRect(3) - scaleLength) / 2; % scr_rect(3)
    scaleY = windowRect(4) * 0.6;
    % Calculate label positions
    labelOffsetX = windowRect(3) * 0.1; % scr_rect(3)
    labelOffsetY = -12;
    label1X = scaleX - labelOffsetX - 2;
    label1Y = scaleY - labelOffsetY;
    label2X = scaleX + scaleLength + 24;
    label2Y = scaleY - labelOffsetY;
    % Define the labels for each question (assumed to be the same for all)
    vasLabels = {
        {label1, label2},
        {label1, label2},
        {label1, label2}
        };
    % Initialize ratings array
    responses = zeros(1, length(questions)); % ratings
    % Loop through the questions
    for questionNum = 1:length(questions) % questionNum = 1:3
        % Display the current question
        instructionText = questions{questionNum}; % instructionText
        currentLabels = vasLabels{questionNum}; % currentLabels
        % Initial rating position
        rating = 5;
        ratingPosition = scaleX + ((rating - scaleMin) / (scaleMax - scaleMin)) * scaleLength;
        ratingPosition = round((ratingPosition - scaleX) / (scaleLength / (scaleMax - scaleMin))) * (scaleLength / (scaleMax - scaleMin)) + scaleX;
        % Display the VAS scale and capture user responses
        VASstartTime = GetSecs();
        % Draw the instruction text
        % Set the text size ONCE before drawing anything
        Screen('TextSize', window, round(windowRect(4) * 0.05)); % scr_rect(4)
        DrawFormattedText(window, instructionText, 'center', windowRect(4) * 0.3, [0 255 255]); % [0 255 255]
        Screen('FillRect', window, scaleColor, [scaleX, scaleY, scaleX + scaleLength, scaleY + scaleHeight]);
        % Draw the rating marker
        Screen('FillRect', window, markerColor, [ratingPosition - markerWidth / 2, scaleY - scaleHeight / 2, ratingPosition + markerWidth / 2, scaleY + scaleHeight * 1.5]);
        % Draw the numbers and labels again
        Screen('TextSize', window, round(windowRect(4) * 0.035)); % scr_rect(4)
        for i = 1:10
            DrawFormattedText(window, num2str(i), scaleX + ((i - 1) / (scaleMax - scaleMin)) * scaleLength - 10, scaleY + scaleHeight + windowRect(4) * 0.06, textColor); % scr_rect(4)
        end
        % Draw the labels for the current question
        DrawFormattedText(window, currentLabels{1}, label1X, label1Y, textColor);
        DrawFormattedText(window, currentLabels{2}, label2X, label2Y, textColor);
        % Flip the screen
        Screen('Flip', window);
        while GetSecs() - VASstartTime < scaleDuration
            % Check for key presses (same as before)
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(1, KbName('c'))
                    rating = max(rating - scaleStep, scaleMin);
                elseif keyCode(1, KbName('d'))
                    rating = min(rating + scaleStep, scaleMax);
                end
                % Update rating position (corrected calculation)
                ratingPosition = scaleX + ((rating - scaleMin) / (scaleMax - scaleMin)) * scaleLength;
                ratingPosition = round((ratingPosition - scaleX) / (scaleLength / (scaleMax - scaleMin))) * (scaleLength / (scaleMax - scaleMin)) + scaleX;
                % Draw the scale and marker (same as before)
                Screen('TextSize', window, round(windowRect(4) * 0.05)); % scr_rect(4)
                DrawFormattedText(window, instructionText, 'center', windowRect(4) * 0.3, [0 255 255]); % [0 255 255]
                Screen('FillRect', window, scaleColor, [scaleX, scaleY, scaleX + scaleLength, scaleY + scaleHeight]);
                Screen('FillRect', window, markerColor, [ratingPosition - markerWidth / 2, scaleY - scaleHeight / 2, ratingPosition + markerWidth / 2, scaleY + scaleHeight * 1.5]);
                % Draw the numbers and labels again
                Screen('TextSize', window, round(windowRect(4) * 0.035)); % scr_rect(4)
                for i = 1:10
                    DrawFormattedText(window, num2str(i), scaleX + ((i - 1) / (scaleMax - scaleMin)) * scaleLength - 10, scaleY + scaleHeight + windowRect(4) * 0.06, textColor); % scr_rect(4)
                end
                DrawFormattedText(window, currentLabels{1}, label1X, label1Y, textColor);
                DrawFormattedText(window, currentLabels{2}, label2X, label2Y, textColor);
                % Flip the screen
                WaitSecs(0.1);
                Screen('Flip', window);
            end
        end
        % Store the rating for this question
        responses(questionNum) = str2double(sprintf('%.0f', rating)); % ratings
        % Optionally add a short delay between questions
        WaitSecs(0.5);
    end
    % Draw fixation cross directly
    crossColor = [128 128 128]; % Grey
    lineWidth = windowRect(4) / 20; % Thickness, scr_rect(4)
    lineLength = windowRect(3) / 4; % Length of cross arms, scr_rect(3)
    % Horizontal line
    x1_h = centerX - lineLength / 2;
    x2_h = centerX + lineLength / 2;
    y_h = [centerY - lineWidth / 2, centerY + lineWidth / 2];
    % Vertical line
    y1_v = centerY - lineLength / 2;
    y2_v = centerY + lineLength / 2;
    x_v = [centerX - lineWidth / 2, centerX + lineWidth / 2];
    Screen('FillRect', window, crossColor, [x1_h y_h(1) x2_h y_h(2)]);
    Screen('FillRect', window, crossColor, [x_v(1) y1_v x_v(2) y2_v]);
    Screen('Flip', window);
    % Wait for 'E' key press
    while true
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(1, KbName('e'))
                while KbCheck
                    WaitSecs(0.01);
                end
                break; % Exit the loop when 'E' is pressed
            end
        end
    end
end
end
