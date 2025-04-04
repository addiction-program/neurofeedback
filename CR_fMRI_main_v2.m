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
    root_path='C:\Users\NFB-user\Documents\NFB\Cue-reactivity latest\3-Current_MR_CRtask_v1_after2ndScan\Current_MR_CRtask_v1\MR_CRtask_v1'; % UPDATE THIS WHEN USING ON A NEW COMPUTER!
    PTB_path='C:\Users\NFB-user\Documents\Psychtoolbox';
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
    filename1 = [root_path filesep 'TRIGGER_A_Media' filesep 'C' num2str(nF) '.png'];
    thispic1=imread(filename1);
    imgetex1=Screen('MakeTexture', window, thispic1);
    pertask_imge_indexes(nF,1)=imgetex1;
    imsizes(nF,1:3)=size(thispic1);
    filename2 = [root_path filesep 'TRIGGER_A_Media' filesep 'N' num2str(nF) '.png'];
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
KbStrokeWait(-1);


%%
% VAS section
if answerdebug
    Screen('TextSize',window, InstrFontSmall);
    DrawFormattedText(window, 'Debug run. Skipping questions...', 'center', 'center', magenta);
    Screen('Flip',window);
    WaitSecs(2);
else
    redo = 0;
    while redo < 1
    % VAS questions
    Screen('TextSize',window, InstrFont);
    DrawFormattedText(window, 'Please respond to \nthe following questions.', 'center', 'center', magenta);
    Screen('Flip',window);
    CheckTerminateTask;
    % Wait for a key press
    KbStrokeWait(-1);

    TaskInfo.Q0_ans = displayVAS(window, windowRect, screenYpixels, 'How much do you feel like smoking cannabis right now?', 'Not at all', 'Extremely');
    TaskInfo.Q1_ans = displayVAS(window, windowRect, screenYpixels, 'How focused are you right now?', 'Not at all', 'Extremely');
    TaskInfo.Q2_ans = displayVAS(window, windowRect, screenYpixels, 'How anxious do you feel right now?', 'Not at all', 'Extremely');

    Screen('Flip',window);
    KbQueueFlush;
    pressed = false;
        while ~pressed
            pause(0.005);
            [pressed, pressed_keys] = KbQueueCheck;
        
        if any(pressed_keys(RETURN_Key))
            redo = 1;
            break;
        end
    end
    end
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
% Wait for a key press
CheckTerminateTask;
KbStrokeWait(-1);

DrawFormattedText(window, 'Waiting for the scanner...','center', 'center', magenta);
Screen('Flip',window);
KbQueueFlush;

% Wait for trigger
pressed = false;
while ~pressed
    pause(0.001);
    [pressed, pressed_keys] = KbQueueCheck;
end
if pressed_keys(SCANNER_KEY)
else
    pressed = false;
    while ~pressed
        pause(0.001);
        [pressed, pressed_keys] = KbQueueCheck;
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
    Screen('TextSize',window, FixCrossFont);
    DrawFormattedText(window, '+','center', 'center', grey);
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
    redo = 0;
    while redo < 1
    % VAS questions
    Screen('TextSize',window, InstrFont);
    DrawFormattedText(window, 'Please respond to \nthe following questions.', 'center', 'center', magenta);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window, 'Press any key to continue','center', screenYpixels * 0.7, grey);
    Screen('Flip',window);
    CheckTerminateTask;
    % Wait for a key press
    KbStrokeWait(-1);

TaskInfo.Q0_ans = displayVAS(window, windowRect, screenYpixels, 'How much do you feel like smoking cannabis right now?', 'Not at all', 'Extremely');
TaskInfo.Q1_ans = displayVAS(window, windowRect, screenYpixels, 'How focused are you right now?', 'Not at all', 'Extremely');
TaskInfo.Q2_ans = displayVAS(window, windowRect, screenYpixels, 'How anxious do you feel right now?', 'Not at all', 'Extremely');

    Screen('Flip',window);
    KbQueueFlush;
    pressed = false;
        while ~pressed
            pause(0.005);
            [pressed, pressed_keys] = KbQueueCheck;
        
        if any(pressed_keys(RETURN_Key))
            redo = 1;
            break;
        end
    end
    end
end




Screen('TextSize',window, InstrFont);
DrawFormattedText(window, 'We are done. Thank you!', 'center', 'center', magenta);
Screen('Flip',window);

% Wait for ENTER key press to exit
pressed = false;
while ~pressed
    pause(0.005);
    [pressed, pressed_keys] = KbQueueCheck;
    if any(pressed_keys(RETURN_Key))
        break;
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
    function rating=displayVAS(window, windowRect, screenYpixels, question, label1, label2)
       
   
    scaleColor = [255, 255, 255]; 
    textColor = [255, 255, 255];
    Cylian = [0 255 255];
    textSize = round(windowRect(4) * 0.04); 
    smallTextSize = textSize; 
    largerTextSize = round(windowRect(4) * 0.05);
   
    % Initial rating position
    rating = 5; 
    % --- Display the question ---
    Screen('TextSize', window, largerTextSize); 
    DrawFormattedText(window, question, 'center', 'center', Cylian);
    
    Screen('Flip', window);

   
    % ---  Response loop ---
    
    while true
        % Check for key presses
         [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
             keyCode(KbName('Return'))
             break;
                
            end

        end
        
                WaitSecs(0.1);             
end     
end


