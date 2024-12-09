function CR_fMRI_main_v2

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% -- CUE REACTIVITY fMRI TASK --
%%%%%
%%%%%
%%%%% Written by Aniko Kusztor
%%%%% Email: aniko.kusztor@monash.edu
%%%%% Last update: 21-Jan-2024
%%%%%
%%%%% Notes: To use the code copy MR_CRtask_v1 folder to the computer and update 'root_path' at line 33
%%%%% After updating the root path, the code can be run typing CR_fMRI_main_v2 into Command Window or click on Run
%%%%% For more details and tips on debugging, check the readme.txt
%%%%% Use ESC to quit task. 
%%%%%
%%%%% v2:
%%%%% - Task optimised for duplicated screen set-up
%%%%% - Implemented two randomise methods: Classic E-prime version (1) VS real randomise version a.k.a "new" (2)
%%%%% - Make the full size of image (quality and size)
%%%%% - Keyboard inputs for the VAS questions before scanning
%%%%% - Text log file
%%%%% - Checking if the instruction is off the field of view. 
%%%%% - Changed trigger code to "T"
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
        sessionN        = '0'; % session number
        sessionVers     = 'A'; %  task version for testing
        researcherID    = 'debug'; 
        trialrandVers   =  '2'; % real randomisation
        expstart        = datestr(now,'ddmmmyyyy-HHMM');   % string with current date
    else
        participantID   = input('Type in Participant ID (e.g. SUBJOO1):','s'); % TYPE IN full participant ID
        participantN    = input('Type in Participant Number (e.g. 001):','s'); % TYPE IN 3 DIGITS
        sessionN        = input('Type in Session Number (1 for baseline, 2 for follow up):', 's'); % TYPE IN session number
        sessionVers     = input('Type in Task Version (A or B):', 's'); % TYPE IN session number
        trialrandVers   = input('Type in Randomisation Protocol Version (1 for EPrime or 2 for new):', 's'); % Select trial randomisation version 1 for old EPrime protocol, 2 for new real random protocol
        researcherID    = input('Type in Researcher Initials running the task (e.g. VL or VL MK for 2 people):','s'); % TYPE IN researcher ID; first list a primary tester
        expstart        = datestr(now,'ddmmmyyyy-HHMM');   % string with current date
    end
    pN=str2double(participantN);
    sN=str2double(sessionN);
    rV=str2double(trialrandVers);
    fprintf('\nCheck session details: \n');
    fprintf('Particpant ID = %s\nParticipant number = %d\nSession number = %d\nTask version = %s\nRandomisation = %d\nTesting researcher = %s\nDate = %s\n',participantID,pN,sN,sessionVers,rV,researcherID,expstart);
    checkinfo = input('Press enter if details are correct or type 0 to re-enter: '); %[ ANSWER 0 for re-enter all details]
end

TaskInfo.pID=participantID;
TaskInfo.pNum=pN;
TaskInfo.sesNum=sN;
TaskInfo.sesVersion=sessionVers;
TaskInfo.rID=researcherID;
TaskInfo.randVersion = rV;
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
% For help see: Screen WindowSize?
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


if strcmp(TaskInfo.sesVersion, 'A')
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
elseif strcmp(TaskInfo.sesVersion, 'B')
    for nF=1:30
    filename1 = [root_path filesep 'TRIGGER_B_Media' filesep 'C' num2str(nF) '.png'];
    thispic1=imread(filename1);
    imgetex1=Screen('MakeTexture', window, thispic1);
    pertask_imge_indexes(nF,1)=imgetex1;
    imsizes(nF,1:3)=size(thispic1);
    filename2 = [root_path filesep 'TRIGGER_B_Media' filesep 'N' num2str(nF) '.png'];
    thispic2=imread(filename2);
    imgetex2=Screen('MakeTexture', window, thispic2);
    pertask_imge_indexes(nF,2)=imgetex2;
    imsizes(nF,4:6)=size(thispic2);
    end
else
    ShowCursor;
    ListenChar(0); % Restore keyboard output to Matlab 
    Screen('TextSize',window, InstrFontSmall);
    DrawFormattedText(window, 'Images cannot be loaded! Check session version.', 'center', 'center', magenta);
    Screen('Flip',window);
    WaitSecs(3);
    Screen('TextSize',window, InstrFont);
    DrawFormattedText(window, 'TASK TEMINATED!', 'center', 'center', magenta);
    Screen('Flip',window);
    WaitSecs(2);
    sca;
end

% create vector from image textures
imge_indexes=reshape(pertask_imge_indexes,[],1);
%getting  image sizes
imge_sizes(1:nF,1:3)=imsizes(1:nF,1:3);
imge_sizes(nF+1:nF*2,1:3)=imsizes(1:nF,4:6);
stimDuration = 4; %sec


% Setting up randomization
if TaskInfo.randVersion==1 % EPRIME version
    if strcmp(TaskInfo.sesVersion, 'A')
        % Read the CSV file into a table
        eprimestimlist = readtable([root_path filesep 'EPRIME_STIM_ORDER.csv']);
        % Extract the first column into a vector
        all_seq_jitter = (eprimestimlist{:,1}/1000)';
        all_seq = eprimestimlist{:,4}';
    elseif strcmp(TaskInfo.sesVersion, 'B')
        % Read the CSV file into a table
        eprimestimlist = readtable([root_path filesep 'EPRIME_STIM_ORDER.csv']);
        % Extract the first column into a vector
        all_seq_jitter = (eprimestimlist{:,5}/1000)';
        all_seq = eprimestimlist{:,8}';
    end

elseif TaskInfo.randVersion==2 % real randomisation
    %randomise
    % needs to be pseudo-randomised to avoid more then 3 consecutive instance of the same valence
    all_seq_jitter=2 + 4 * rand(1, nF*2); % between 2-6 sec; avr 4 sec
    redolist = false;
    while ~redolist
    all_seq=[];
    % Create a pool of numbers from 1 to 60
    availableNumbers = 1:60;

    % Continue until the list contains 60 elements
        while length(all_seq) < nF*2
            % check if it is possible for the last 4 elements to follow the rule 
            if length(availableNumbers) == 4 && (all(availableNumbers < 31)) || (all(availableNumbers > 30))
                break; % Exit the inner loop to restart
            end
            % Randomly select a number from the available numbers
            idx = randi(length(availableNumbers));
            num = availableNumbers(idx);
            % Check the rule
            if length(all_seq) >= 3
                % Check the last 3 numbers in the list
                last3 = all_seq(end-2:end);
                % Apply the rule:
                % If the last two numbers are both <31 and the new number is <31, or
                % If the last two numbers are both >30 and the new number is >30, skip this iteration
                if (all(last3 < 31) && num < 31) || (all(last3 > 30) && num > 30)
                    continue;
                end
            end
            % Append the number to the list
            all_seq(end+1) = num;
            % Remove the used number from the available numbers
            availableNumbers(idx) = [];
        end
        % Check if the list was successfully completed
        if length(all_seq) == 60
            redolist = true;
        end
    end
else
    ShowCursor;
    ListenChar(0); % Restore keyboard output to Matlab 
    Screen('TextSize',window, InstrFontSmall);
    DrawFormattedText(window, 'Incorrect input for randomisation! Check randomisation version.', 'center', 'center', magenta);
    Screen('Flip',window);
    WaitSecs(3);
    Screen('TextSize',window, InstrFont);
    DrawFormattedText(window, 'TASK TEMINATED!', 'center', 'center', magenta);
    Screen('Flip',window);
    WaitSecs(2);
    sca;
end

 
WaitSecs(0.1);
Screen('TextSize',window, InstrFont);
DrawFormattedText(window, 'Stimuli loaded.', 'center', 'center', magenta);
% Screen('TextSize',window, InstrFontSmall);
% DrawFormattedText(window, 'Press any key to continue','center', screenYpixels * 0.7, grey);
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
    DrawFormattedText(window, 'Please respond to \nthe following questions', 'center', 'center', magenta);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window, 'Press any key to continue','center', screenYpixels * 0.7, grey);
    Screen('Flip',window);
    CheckTerminateTask;
    % Wait for a key press
    KbStrokeWait(-1);

    
%     % Q0
%     Q0_q = 'How much do you feel like smoking cannabis \non a scale of 1 = Not at all to 10 = Extremely?';
%     Q_num = '1     2     3     4     5     6     7     8     9     10';
%     Q0_end1 = 'Not at all';
%     Q0_end2 = 'Extremely';
%     
%     
%     % Draw all the text in one go
%     Screen('TextSize', window, InstrFont);
%     DrawFormattedText(window, Q0_q,'center', screenYpixels * 0.3, magenta);
%     DrawFormattedText(window, Q_num,'center', screenYpixels * 0.6, magenta);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window, Q0_end1,screenXpixels * 0.13, screenYpixels * 0.69, grey);
%     DrawFormattedText(window, Q0_end2,screenXpixels * 0.74, screenYpixels * 0.69, grey);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window,'Press RETURN to confirm','center', screenYpixels * 0.9,grey); 
%     Screen('TextSize', window, InstrFont);
%     TaskInfo.Q0_ans = GetEchoNumber(window, 'RESPONSE: ', screenXpixels * 0.4, screenYpixels * 0.79, magenta);
%     % Flip to the screen
%     Screen('Flip', window);
%     % Wait for a key press
%     CheckTerminateTask;
% 
%     
%     % Q1
%     Q1_q = 'How strong is your urge to smoke cannabis right now \non a scale of \n1 = Not at all to 10 = Very severe urge?';
%     Q1_end1 = 'Not at all';
%     Q1_end2 = 'Very severe urge';
%     
%     % Draw all the text in one go
%     Screen('TextSize', window, InstrFont);
%     DrawFormattedText(window, Q1_q,'center', screenYpixels * 0.3, magenta);
%     DrawFormattedText(window, Q_num,'center', screenYpixels * 0.6, magenta);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window, Q1_end1,screenXpixels * 0.13, screenYpixels * 0.69, grey);
%     DrawFormattedText(window, Q1_end2,screenXpixels * 0.64, screenYpixels * 0.69, grey);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window,'Press RETURN to confirm','center', screenYpixels * 0.9,grey); 
%     Screen('TextSize', window, InstrFont);
%     TaskInfo.Q1_ans = GetEchoNumber(window, 'RESPONSE: ', screenXpixels * 0.4, screenYpixels * 0.79, magenta);
%     
%     % Flip to the screen
%     Screen('Flip', window);
%     % Wait for a key press
%     CheckTerminateTask;
% 
% 
%     % Q2
%     Q2_q = 'What is your level of relaxation-tension \non a scale of \n1 = Absolutely no tension to 10 = Extremely tense?';
%     Q2_end1 = 'Absolutely no tension';
%     Q2_end2 = 'Extremely tense';
%     
%     % Draw all the text in one go
%     Screen('TextSize', window, InstrFont);
%     DrawFormattedText(window, Q2_q,'center', screenYpixels * 0.3, magenta);
%     DrawFormattedText(window, Q_num,'center', screenYpixels * 0.6, magenta);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window, Q2_end1,screenXpixels * 0.13, screenYpixels * 0.69, grey);
%     DrawFormattedText(window, Q2_end2,screenXpixels * 0.66, screenYpixels * 0.69, grey);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window,'Press RETURN to confirm','center', screenYpixels * 0.9,grey); 
%     Screen('TextSize', window, InstrFont);
%     TaskInfo.Q2_ans = GetEchoNumber(window, 'RESPONSE: ', screenXpixels * 0.4, screenYpixels * 0.79, magenta);
%     % Flip to the screen
%     Screen('Flip', window);
%     % Wait for a key press
%     CheckTerminateTask;
% 
%     % Q3
%     Q3_q = 'How distracted or focused are you \non a scale of \n1 = Very distracted to 10 = Very focused?';
%     Q3_end1 = 'Very distracted';
%     Q3_end2 = 'Very focused';
%     
%     % Draw all the text in one go
%     Screen('TextSize', window, InstrFont);
%     DrawFormattedText(window, Q3_q,'center', screenYpixels * 0.3, magenta);
%     DrawFormattedText(window, Q_num,'center', screenYpixels * 0.6, magenta);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window, Q3_end1,screenXpixels * 0.13, screenYpixels * 0.69, grey);
%     DrawFormattedText(window, Q3_end2,screenXpixels * 0.71, screenYpixels * 0.69, grey);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window,'Press RETURN to confirm','center', screenYpixels * 0.9,grey); 
%     Screen('TextSize', window, InstrFont);
%     TaskInfo.Q3_ans = GetEchoNumber(window, 'RESPONSE: ', screenXpixels * 0.4, screenYpixels * 0.79, magenta);
%     % Flip to the screen
%     Screen('Flip', window);
%     % Wait for a key press
%     CheckTerminateTask;
% 
%     % Q4
%     Q4_q = 'How aware are you of whatever arises \nin your moment to moment awareness on a scale of \n1 = Not aware to 10 = Very aware?';
%     Q4_end1 = 'Not aware';
%     Q4_end2 = 'Very aware';
%     
%     % Draw all the text in one go
%     Screen('TextSize', window, InstrFont);
%     DrawFormattedText(window, Q4_q,'center', screenYpixels * 0.3, magenta);
%     DrawFormattedText(window, Q_num,'center', screenYpixels * 0.6, magenta);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window, Q4_end1,screenXpixels * 0.13, screenYpixels * 0.69, grey);
%     DrawFormattedText(window, Q4_end2,screenXpixels * 0.72, screenYpixels * 0.69, grey);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window,'Press RETURN to confirm','center', screenYpixels * 0.9,grey); 
%     Screen('TextSize', window, InstrFont);
%     TaskInfo.Q4_ans = GetEchoNumber(window, 'RESPONSE: ', screenXpixels * 0.4, screenYpixels * 0.79, magenta);
%     % Flip to the screen
%     Screen('Flip', window);
%     % Wait for a key press
%     CheckTerminateTask;
%     % Q5
%     Q5_q = ' How vivid is your experience \non a scale of \n1 = Not vivid, dull, hazy to 10 = Vivid, sharp, clear?';
%     Q5_end1 = 'Not vivid, dull, hazy';
%     Q5_end2 = 'Vivid, sharp, clear';
%     
%     % Draw all the text in one go
%     Screen('TextSize', window, InstrFont);
%     DrawFormattedText(window, Q5_q,'center', screenYpixels * 0.3, magenta);
%     DrawFormattedText(window, Q_num,'center', screenYpixels * 0.6, magenta);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window, Q5_end1,screenXpixels * 0.13, screenYpixels * 0.69, grey);
%     DrawFormattedText(window, Q5_end2,screenXpixels * 0.63, screenYpixels * 0.69, grey);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window,'Press RETURN to confirm','center', screenYpixels * 0.9,grey); 
%     Screen('TextSize', window, InstrFont);
%     TaskInfo.Q5_ans = GetEchoNumber(window, 'RESPONSE: ', screenXpixels * 0.4, screenYpixels * 0.79, magenta);
%     % Flip to the screen
%     Screen('Flip', window);
%     % Wait for a key press
%     CheckTerminateTask;
% 
%     % Q6
%     Q6_q = 'How is your mental state \non a scale of \n1 = Sluggish/drowsy to 10 = Agitated/racing/restless?';
%     Q6_end1 = 'Sluggish/drowsy';
%     Q6_end2 = 'Agitated/racing/restless';
%     
%     % Draw all the text in one go
%     Screen('TextSize', window, InstrFont);
%     DrawFormattedText(window, Q6_q,'center', screenYpixels * 0.3, magenta);
%     DrawFormattedText(window, Q_num,'center', screenYpixels * 0.6, magenta);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window, Q6_end1,screenXpixels * 0.13, screenYpixels * 0.69, grey);
%     DrawFormattedText(window, Q6_end2,screenXpixels * 0.57, screenYpixels * 0.69, grey);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window,'Press RETURN to confirm','center', screenYpixels * 0.9,grey); 
%     Screen('TextSize', window, InstrFont);
%     TaskInfo.Q6_ans = GetEchoNumber(window, 'RESPONSE: ', screenXpixels * 0.4, screenYpixels * 0.79, magenta);
%     % Flip to the screen
%     Screen('Flip', window);
%     % Wait for a key press
%     CheckTerminateTask;
% 
%     % Q7
%     Q7_q = 'How is your mental effort \non a scale of \n1 = Effortless to 10 = Forced?';
%     Q7_end1 = 'Effortless';
%     Q7_end2 = 'Forced';
%     
%     % Draw all the text in one go
%     Screen('TextSize', window, InstrFont);
%     DrawFormattedText(window, Q7_q,'center', screenYpixels * 0.3, magenta);
%     DrawFormattedText(window, Q_num,'center', screenYpixels * 0.6, magenta);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window, Q7_end1,screenXpixels * 0.13, screenYpixels * 0.69, grey);
%     DrawFormattedText(window, Q7_end2,screenXpixels * 0.78, screenYpixels * 0.69, grey);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window,'Press RETURN to confirm','center', screenYpixels * 0.9,grey); 
%     Screen('TextSize', window, InstrFont);
%     TaskInfo.Q7_ans = GetEchoNumber(window, 'RESPONSE: ', screenXpixels * 0.4, screenYpixels * 0.79, magenta);
%     % Flip to the screen
%     Screen('Flip', window);
%     % Wait for a key press
%     CheckTerminateTask;

% Q0
    TaskInfo.Q0_ans = displayVAS(window, windowRect, screenYpixels, 'How much do you feel like smoking cannabis right now?', 'Not at all', 'Extremely')

    % Q1
    TaskInfo.Q1_ans = displayVAS(window, windowRect, screenYpixels, 'How focused are you right now?', 'Not at all', 'Extremely')

    
    % Q2
    TaskInfo.Q2_ans = displayVAS(window, windowRect, screenYpixels, 'How anxious do you feel right now?', 'Not at all', 'Extremely')

    
%     % Q3
%     TaskInfo.Q3_ans = displayVAS(window, windowRect, screenYpixels, 'How distracted or focused are you \non a scale of \n0 = Very distracted to 10 = Very focused?', 'Very \ndistracted', 'Very focused')
% 
%     
% 
%     % Q4
%     TaskInfo.Q4_ans = displayVAS(window, windowRect, screenYpixels, 'How aware are you of whatever arises \nin your moment to moment awareness on a scale of \n0 = Not aware to 10 = Very aware?', 'Not aware', 'Very aware')
% 
%    
%     % Q5
%     TaskInfo.Q5_ans = displayVAS(window, windowRect, screenYpixels, ' How vivid is your experience \non a scale of \n0 = Not vivid, dull, hazy to 10 = Vivid, sharp, clear?', 'Not vivid, \ndull, hazy', 'Vivid, \nsharp, clear')
% 
%     
%     % Q6
%     TaskInfo.Q6_ans = displayVAS(window, windowRect, screenYpixels, 'How is your mental state \non a scale of \n0 = Sluggish/drowsy to 10 = Agitated/racing/restless?', 'Sluggish/\ndrowsy', 'Agitated/racing/restless')
% 
%    
%     % Q7
%     TaskInfo.Q7_ans = displayVAS(window, windowRect, screenYpixels, 'How is your mental effort \non a scale of \n0 = Effortless to 10 = Forced?', 'Effortless', 'Forced')

    Screen('TextSize', window, InstrFont);
    DrawFormattedText(window, ['Recorded responses:\n\n', sprintf('\n%d',TaskInfo.Q0_ans), sprintf('\n%d',TaskInfo.Q1_ans), sprintf('\n%d',TaskInfo.Q2_ans)],'center', 'center', magenta);
    Screen('TextSize',window, InstrFontSmall);
    DrawFormattedText(window, 'Press RETURN to confirm or any other key \nto re-do this section','center', screenYpixels * 0.9, grey);
    Screen('Flip',window);
    KbQueueFlush;
    pressed = false;
        while ~pressed
            pause(0.005);
            [pressed, pressed_keys] = KbQueueCheck;
        end
        if any(pressed_keys(RETURN_Key))
            redo = 1;
        else
            redo = 0;
        end
    end

end


%% TASK trials

% Draw all the text in one go - Instructions
Instrline1 = 'In this task you will see pictures on screen';
Instrline2 = '\n\nPlease try to keep your head still.';
Instrline3 = '\n\nYour task is to look as these pictures closely \nand as attentively as you can.';
Instrline4 = '\n\nThe task will take about 10 minutes.';
Instrline5 = '\n\nWe are about to start. Are you ready?';

Screen('TextSize', window, InstrFont);
DrawFormattedText(window, [Instrline1 Instrline2 Instrline3 Instrline4 Instrline5],'center', 'center', magenta);
Screen('TextSize',window, InstrFontSmall);
DrawFormattedText(window, 'Press any key to continue','center', screenYpixels * 0.9, grey);
Screen('Flip',window);
% Wait for a key press
KbStrokeWait(-1);
CheckTerminateTask;
%start logging experiment start time
log_startExperiment=GetSecs;

DrawFormattedText(window, 'Waiting for the scanner...','center', 'center', magenta);
Screen('Flip',window);
curr_trigger = 0;
log_triggertimes = [];
KbQueueFlush;
WaitForTrigger;

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
    % Determine the scaling needed to make the image fill the whole
    scalingFactor = 0.7;  % For 80% of the original size
    % screen in the y dimension
    maxScaling = (screenYpixels / imge_sizes(this_seq_trial,1)) * scalingFactor;
    % Set the based rectangle size for drawing to the screen
    dstRects = CenterRectOnPointd([0 0 imge_sizes(this_seq_trial,2) imge_sizes(this_seq_trial,1)] .*maxScaling, xCenter, yCenter);
    % Draw the image to the screen, unless otherwise specified PTB will draw
    % the texture full size in the center of the screen.
    Screen('DrawTexture', window, this_image, [], dstRects);
    stimOnset=Screen('Flip',window);
    log_stimOnset = [log_stimOnset; stimOnset-log_startExperiment];
    WaitSecs(stimDuration);
    log_stimDuration = [log_stimDuration; stimDuration];
    
    % Start of fixation cross
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
    DrawFormattedText(window, 'Please respond to \nthe following questions', 'center', 'center', magenta);
%     Screen('TextSize',window, InstrFontSmall);
%     DrawFormattedText(window, 'Press any key to continue','center', screenYpixels * 0.7, grey);
    Screen('Flip',window);
    CheckTerminateTask;
    % Wait for a key press
    KbStrokeWait(-1);
% Q0
    TaskInfo.Q0_ans = displayVAS(window, windowRect, screenYpixels, 'How much do you feel like smoking cannabis right now?', 'Not at all', 'Extremely')

    % Q1
    TaskInfo.Q1_ans = displayVAS(window, windowRect, screenYpixels, 'How focused are you right now?', 'Not at all', 'Extremely')

    
    % Q2
    TaskInfo.Q2_ans = displayVAS(window, windowRect, screenYpixels, 'How anxious do you feel right now?', 'Not at all', 'Extremely')

    Screen('TextSize', window, InstrFont);
    DrawFormattedText(window, ['Recorded responses:\n\n', sprintf('\n%d',TaskInfo.Q0_ans), sprintf('\n%d',TaskInfo.Q1_ans), sprintf('\n%d',TaskInfo.Q2_ans)],'center', 'center', magenta);
    Screen('TextSize',window, InstrFontSmall);
    DrawFormattedText(window, 'Press RETURN to confirm or any other key \nto re-do this section','center', screenYpixels * 0.9, grey);
    Screen('Flip',window);
    KbQueueFlush;
    pressed = false;
        while ~pressed
            pause(0.005);
            [pressed, pressed_keys] = KbQueueCheck;
        end
        if any(pressed_keys(RETURN_Key))
            redo = 1;
        else
            redo = 0;
        end
    end

end




Screen('TextSize',window, InstrFont);
DrawFormattedText(window, 'We are done. Thank you!', 'center', 'center', magenta);
Screen('Flip',window);
ShowCursor;
ListenChar(0); % Restore keyboard output to Matlab 

% Saving log file 
log_endExperiment=GetSecs;
log_endExperiment=log_endExperiment-log_startExperiment;
save_path=[pwd filesep 'LOG_FILES/'];
savetime        = datestr(now,'ddmmmyyyy-HHMM');   % string with current date
save(sprintf('%sCR_fMRI_%s%d%s_%s_log',save_path,participantID,sN,sessionVers,savetime),'TaskInfo','log_*');
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
writetable(saveT, sprintf('%sCR_fMRI_%s%d%s_%s_log.txt',save_path,participantID,sN,sessionVers,savetime));

WaitSecs(2);
sca;


%% Nested Functions
function WaitForTrigger
    while curr_trigger < 5
            pressed = false;
            while ~pressed
                pause(0.001);
                [pressed, pressed_keys] = KbQueueCheck;
            end
%             disp(KbName(find(pressed_keys))); % for debugging
            if pressed_keys(SCANNER_KEY)
                this_trgtime = GetSecs;
                this_trgtime = this_trgtime-log_startExperiment;
                log_triggertimes = [log_triggertimes; this_trgtime];
                curr_trigger = curr_trigger + 1;
                countdowntracker = 6 - curr_trigger;
                DrawFormattedText(window, sprintf('Starting in: %d',countdowntracker),'center', 'center', magenta);
                Screen('Flip',window);
            end
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
       
    % displayVAS  Displays a visual analog scale (VAS) and returns the user's rating.
    %
    %   rating = displayVAS(window, windowRect, screenYpixels, question, label1, label2)
    %
    %   Inputs:
    %       window          - The Psychtoolbox window pointer.
    %       windowRect      - The screen dimensions [x1, y1, x2, y2].
    %       screenYpixels   - The vertical resolution of the screen.
    %       question        - The question string to display.
    %       label1          - The label for the left end of the scale.
    %       label2          - The label for the right end of the scale.
    %
    %   Output:
    %       rating          - The user's rating on the VAS.

    % Scale parameters
    scaleMin = 1;
    scaleMax = 10;
    scaleStep = 1;
    scaleDuration = 15; 
    markerColor = [255, 0, 0]; 
    markerWidth = 20;
    scaleColor = [255, 255, 255]; 
    textColor = [255, 255, 255];
    Cylian = [0 255 255]
    textSize = round(windowRect(4) * 0.04); 
    smallTextSize = textSize; 
    largerTextSize = round(windowRect(4) * 0.05)
    scaleLength = windowRect(3) * 0.5; 
    scaleHeight = windowRect(4) * 0.03; 
    scaleX = (windowRect(3) - scaleLength) / 2; 
    scaleY = windowRect(4) * 0.6; 
    
    labelOffsetX = windowRect(3) * 0.1; 
    labelOffsetY = -12; 
    label1X = scaleX - labelOffsetX - 2;
    label1Y = scaleY - labelOffsetY;
    label2X = scaleX + scaleLength + 24;
    label2Y = scaleY - labelOffsetY;
    
    % Initial rating position
    rating = 5; 
    ratingPosition = scaleX + ((rating - scaleMin) / (scaleMax - scaleMin)) * scaleLength;
    ratingPosition = round((ratingPosition - scaleX) / (scaleLength / (scaleMax - scaleMin))) * (scaleLength / (scaleMax - scaleMin)) + scaleX;

    % --- Display the question ---
    Screen('TextSize', window, largerTextSize); 
    DrawFormattedText(window, question, 'center', screenYpixels * 0.3, Cylian);
    
    Screen('TextSize', window, smallTextSize); 
    % --- Draw the scale ---
    Screen('FillRect', window, scaleColor, [scaleX, scaleY, scaleX + scaleLength, scaleY + scaleHeight]);
    
    % Draw the numbers
    for i = 1:10
        DrawFormattedText(window, num2str(i), scaleX + ((i-1) / (scaleMax-scaleMin)) * scaleLength - 10, scaleY + scaleHeight + windowRect(4) * 0.06, textColor);
    end
    
    % Draw the labels
    
    DrawFormattedText(window, label1, label1X, label1Y, textColor);
    DrawFormattedText(window, label2, label2X, label2Y, textColor);
    
    % ---  Response loop ---
    startTime = GetSecs();
    
    while true
        % Check for key presses
         [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(KbName('c')) 
                rating = max(rating - scaleStep, scaleMin);
            elseif keyCode(KbName('d')) 
                rating = min(rating + scaleStep, scaleMax);
            end
    
            % Update rating position
            % Update rating position (corrected calculation)
                ratingPosition = scaleX + ((rating - scaleMin) / (scaleMax - scaleMin)) * scaleLength;
                ratingPosition = round((ratingPosition - scaleX) / (scaleLength / (scaleMax - scaleMin))) * (scaleLength / (scaleMax - scaleMin)) + scaleX;

            % Redraw the scale and marker
            Screen('FillRect', window, scaleColor, [scaleX, scaleY, scaleX + scaleLength, scaleY + scaleHeight]);
            Screen('FillRect', window, markerColor, [ratingPosition - markerWidth/2, scaleY - scaleHeight/2, ratingPosition + markerWidth/2, scaleY + scaleHeight * 1.5]);
            
            % Redraw the numbers and labels (for clarity)
            for i = 1:10
                DrawFormattedText(window, num2str(i), scaleX + ((i-1) / (scaleMax-scaleMin)) * scaleLength - 10, scaleY + scaleHeight + windowRect(4) * 0.06, textColor);
            end
            Screen('TextSize', window, largerTextSize); 
            DrawFormattedText(window, question, 'center', screenYpixels * 0.3, Cylian);
            Screen('TextSize', window, smallTextSize); 
            DrawFormattedText(window, label1, label1X, label1Y, textColor);
            DrawFormattedText(window, label2, label2X, label2Y, textColor);

            % Flip the screen
            
            Screen('Flip', window);  
            WaitSecs(0.1);
        end
        % Separate check for 'Return' ONLY for confirmation
            [~, ~, keyCode] = KbCheck; % Check again for key releases
            if keyCode(KbName('Return'))
                WaitSecs(0.1);
                break; 
            end
    end
end 
    

end


