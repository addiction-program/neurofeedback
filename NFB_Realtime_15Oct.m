%%
%Last edited by Amir Dakhili on October 15th, 2024
% latest modifications:
% conditions now include three images each for 10 seconds
% thermometer height reduced to 20 rectangles and one sided
%%
% Please use Backslash for file and folder names in WINDOWS!
% Hemodynamic lag needs to be considered implicitly by participant
% 1st is target ROI and 2nd is confound

warning off; % Suppresses warnings
sca; % Closes all open Psychtoolbox screens
clear all % Clears the workspace

% Declare global variables
global TR windowHeight window scr_rect centreX centreY escapeKey start_time current_TBV_tr ROI_PSC ROI_vals PSC_thresh port_issue imageTextures psc_data FB_timings;

%% Needs Change
TR = 1; % Repetition time in seconds
feedback_dir = 'C:\Users\NFB-user\Documents\NFB\Cue-reactivity latest\3-Current_MR_CRtask_v1_after2ndScan\Current_MR_CRtask_v1\MR_CRtask_v1\NFB'; % Path to the feedback folder
feedback_file_name = 'NFB'; % Prefix for feedback files
run_no = 1; % Run number

%% Optional to change
block_dur_TR = 50; % Duration of the craving block in TRs
rest_dur_TR = 20; % Duration of the rest block in TRs
cue_dur_TR = 5; % Duration of the cue in TRs

%% Needs change 
pp_no = 20;
pp_name = 'Valentina';
num_blocks = 2; % Number of times to repeat the craving task and VAS scale

input('Press Enter to start >>> ','s'); % Wait for user input to start

block_init = 0.5;
block = block_init;

% Initialize variables
MW_blocks = 0;
craving_blocks = 0;
Down_block_timings = [];
rest_block_timings = [];
VAS_block_timings = [];
cue_timings = [];
FB_timings = {}; % Initialize as a cell array
rest_blocks_mean = [];
rest_blocks_TRs = [];
psc_data = [];
ROI_PSC = [];
port_issue = [];
PSC_thresh = 2; % Threshold for PSC calculation
Up_block_timings = [];
Neutral_block_timings = [];
Fix_block_timings = [];


% Open files to write cue and block timings
fileID1 = fopen(fullfile([pwd '\Participant_' num2str(pp_no)],['\' date '_pp_' num2str(pp_no) '_run_' num2str(run_no) '_Text_timing.txt']), 'w');
fileID2 = fopen(fullfile([pwd '\Participant_' num2str(pp_no)],['\' date '_pp_' num2str(pp_no) '_run_' num2str(run_no) '_block_timing.txt']), 'w');
fileID3 = fopen(fullfile([pwd '\Participant_' num2str(pp_no)],['\' date '_pp_' num2str(pp_no) '_run_' num2str(run_no) 'Rest_block_timing.txt']), 'w');
fileID4 = fopen(fullfile([pwd '\Participant_' num2str(pp_no)],['\' date '_pp_' num2str(pp_no) '_run_' num2str(run_no) 'Neutral_block_timing.txt']), 'w');
fileID5 = fopen(fullfile([pwd '\Participant_' num2str(pp_no)],['\' date '_pp_' num2str(pp_no) '_run_' num2str(run_no) 'Upregulation_block_timing.txt']), 'w');
fileID6 = fopen(fullfile([pwd '\Participant_' num2str(pp_no)],['\' date '_pp_' num2str(pp_no) '_run_' num2str(run_no) 'Downregulation_block_timing.txt']), 'w');
fileID7 = fopen(fullfile([pwd '\Participant_' num2str(pp_no)],['\' date '_pp_' num2str(pp_no) '_run_' num2str(run_no) '_VAS_results.txt']), 'w');

% Store file IDs as variables
fileID1_var = fileID1; 
fileID2_var = fileID2;
fileID3_var = fileID3;
fileID4_var = fileID4;
fileID5_var = fileID5;
fileID6_var = fileID6;
fileID7_var = fileID7;

% Write general information to the files
PrintGeneralInfo(fileID1,date,pp_name,run_no,num_blocks,block_dur_TR);
PrintGeneralInfo(fileID2,date,pp_name,run_no,num_blocks,block_dur_TR);
PrintGeneralInfo(fileID3,date,pp_name,run_no,num_blocks,block_dur_TR);
PrintGeneralInfo(fileID4,date,pp_name,run_no,num_blocks,block_dur_TR);
PrintGeneralInfo(fileID5,date,pp_name,run_no,num_blocks,block_dur_TR);
PrintGeneralInfo(fileID6,date,pp_name,run_no,num_blocks,block_dur_TR);
PrintGeneralInfo(fileID7,date,pp_name,run_no,num_blocks,block_dur_TR);

fprintf(fileID1, '\n============================================================================\n');
fprintf(fileID1, '\n\n_____________________________Text timing information:__________________________');
fprintf(fileID2, '\n============================================================================\n');
fprintf(fileID2, '\n\n______________________________Block start timing information:__________________________');
fprintf(fileID3, '\n============================================================================\n');
fprintf(fileID3, '\n\n______________________________Rest Block timing information:__________________________');
fprintf(fileID4, '\n============================================================================\n');
fprintf(fileID4, '\n\n______________________________Neutral Block timing information:__________________________');
fprintf(fileID5, '\n============================================================================\n');
fprintf(fileID5, '\n\n______________________________Upregulation Block timing information:__________________________');
fprintf(fileID6, '\n============================================================================\n');
fprintf(fileID6, '\n\n______________________________Downregulation Block timing information:__________________________');
fprintf(fileID7, '\n============================================================================\n');
fprintf(fileID7, '\n\n______________________________VAS Results:__________________________');


saveroot = [pwd '\Participant_' num2str(pp_no) '\'];

% Create the first dummy feedback file
dlmwrite([feedback_dir '\' feedback_file_name '-1.rtp'],[2,0,0,-1],'delimiter',' ');

try
    % Setup PTB with default value
    PsychDefaultSetup(1);
    
    % COMMENT OUT FOR ACTUAL EXPERIMENT - ONLY ON FOR TESTING
    Screen('Preference', 'SkipSyncTests', 1);
    
    % Get the screen number (primary or secondary)
    getScreens = Screen('Screens');
    ChosenScreen = min(getScreens); 
    full_screen = [];
    
    % Getting screen luminance values
    white = WhiteIndex(ChosenScreen); 
    black = BlackIndex(ChosenScreen); 
    grey = white/2;
    magenta = [255 0 255];
    green = [0 255 0];
    
    % Open the Psychtoolbox window
    TEST=1; 
    if TEST==1
        [window, scr_rect] = PsychImaging('OpenWindow', ChosenScreen, black, [0 0 800 600]);
    else
        [window, scr_rect] = PsychImaging('OpenWindow', ChosenScreen, black, full_screen);
        HideCursor(window); 
    end

    % Get the coordinates of screen centre
    [centreX,centreY] = RectCenter(scr_rect);
    [windowWidth, windowHeight] = Screen('WindowSize', window); 

    % Get a list of all image files in the image directory
    imageDir = fullfile('C:\Users\NFB-user\Documents\NFB\Cue-reactivity latest\3-Current_MR_CRtask_v1_after2ndScan\Current_MR_CRtask_v1\MR_CRtask_v1\NFB_media');
    imageFiles = dir(fullfile(imageDir, 'C*.png')); % Assuming all images start with 'C'

    % Number of images available
    numImages = length(imageFiles);

    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    % Give PTB processing priority 
    Priority(MaxPriority(window));

    % Inter-frame interval
    ifi = Screen('GetFlipInterval',window);

    % Screen refresh rate
    hertz = FrameRate(window);

    % Define the keyboard keys that are listened for
    KbName('UnifyKeyNames');
    escapeKey = KbName('ESCAPE');
    triggerKey = KbName('T'); 

    %----------------------------------------------------------------------
    %Screen before trigger
    % FIRST CUE
%     Text = 'A cross will appear now... \n \n Please look at the cross\n\n Press `t` to start.';
    Text = 'The experiment will start soon... \n \n Please read the instructions carefully!';
    Screen('TextSize', window, round(windowHeight * 0.05));
    Screen('TextFont', window, 'Arial');                    
    Screen('TextStyle', window, 0);  
    DrawFormattedText(window,Text,'center','center',magenta);
    Screen('Flip',window);

    % Reading Trigger
    KbTriggerWait(triggerKey);

    % Creating second feedback file (dummy) after trigger
    dlmwrite([feedback_dir '\' feedback_file_name '-2.rtp'],[2,0,0,-1],'delimiter',' ');

    start_time = GetSecs();
    ROI_vals = [];

    fprintf(fileID1, '\nRun start time (MRI): \t\t%d\n', start_time);
    fprintf(fileID2, '\nRun start time (MRI): \t\t%d \n', start_time);
    fprintf(fileID3, '\nRun start time (MRI): \t\t%d \n', start_time);
    fprintf(fileID4, '\nRun start time (MRI): \t\t%d \n', start_time);
    fprintf(fileID5, '\nRun start time (MRI): \t\t%d \n', start_time);
    fprintf(fileID6, '\nRun start time (MRI): \t\t%d \n', start_time);
    fprintf(fileID7, '\n\n MRI Block End Time     Rating \n\n'); 


    elapsed = GetSecs() - start_time;
    while elapsed < 10 % Proceed at TR=11 (after 10 secs) to accommodate initial TBV lags
        elapsed = GetSecs() - start_time;
        current_TBV_tr = rt_load_BOLD(feedback_dir, feedback_file_name);
    end

    fprintf(fileID1, 'TBV start TR: \t\t%f ', current_TBV_tr);
    fprintf(fileID2, 'TBV start TR: \t\t%f ', current_TBV_tr);
    fprintf(fileID3, 'TBV start TR: \t\t%f ', current_TBV_tr);
    fprintf(fileID4, 'TBV start TR: \t\t%f ', current_TBV_tr);
    fprintf(fileID5, 'TBV start TR: \t\t%f ', current_TBV_tr);
    fprintf(fileID6, 'TBV start TR: \t\t%f ', current_TBV_tr);

    %----------------------------------------------------------------------
    % cue start, cue end, cue duration
    fprintf(fileID1, '\n\n MRI Cue start     MRI Cue end     MRI Cue duration    TBV Cue start TR    TBV Cue end TR    TBV Cue duration TR \n\n');
    % block start, block end, block duration
    fprintf(fileID2, '\n\n MRI Block start     MRI Block end     MRI Block duration   TBV Block start TR    TBV Block end TR   TBV Block duration TR \n\n');
    %----------------------------------------------------------------------
    % block start, block end, block duration
    fprintf(fileID3, '\n\n MRI Block start     MRI Block end     MRI Block duration   TBV Block start TR    TBV Block end TR   TBV Block duration TR \n\n');
    %----------------------------------------------------------------------
    % block start, block end, block duration
    fprintf(fileID4, '\n\n MRI Block start     MRI Block end     MRI Block duration   TBV Block start TR    TBV Block end TR   TBV Block duration TR \n\n');
    %----------------------------------------------------------------------
    % block start, block end, block duration
    fprintf(fileID5, '\n\n MRI Block start     MRI Block end     MRI Block duration   TBV Block start TR    TBV Block end TR   TBV Block duration TR \n\n');
    %----------------------------------------------------------------------
    % block start, block end, block duration
    fprintf(fileID6, '\n\n MRI Block start     MRI Block end     MRI Block duration   TBV Block start TR    TBV Block end TR   TBV Block duration TR \n\n');
    %----------------------------------------------------------------------
    %% Block Switches (Set these to 1 to include the block, 0 to exclude)
    run_neutral_block = 1;
    run_rest_block = 1; 
    run_fixation_block = 1;
    run_upregulation_block = 1;
    run_downregulation_block = 1;
    run_vas_block = 1;
    run_practice_block = 1; % Add this line
        % Define the block order (you can rearrange this as needed)
      % R=rest
      % V=VAS
      % F=fixation cross
      % U=up regulation
      % N=Neutral Pic
      % D=down regulation
      % PR=practice 
      blockOrder = { 'U','N', 'D', 'N'};
%            blockOrder = { 'F', 'N', 'F', 'V', 'F', 'U', 'N', 'F', 'V', 'F', 'D', 'N', 'F', 'V'};
%       blockOrder = { 'R', 'V', 'F', 'U', 'F', 'N', 'F', 'V', 'F', 'D', 'F', 'N', 'F', 'V'};
%     full run  %write number of volumes, runs, total time 
%      blockOrder = { 'F', 'N', 'V', 'F', 'U', 'F', 'N', 'F','U', 'F', 'N', 'F','U', 'F', 'N', 'F','U', 'F', 'N', 'F','U', 'F', 'N', 'F', 'V', 'F', 'D', 'F', 'N', 'F','D', 'F', 'N', 'F','D', 'F', 'N', 'F','D', 'F', 'N', 'F','D', 'F', 'N', 'F', 'V'};
    % Declare cravingImageNumbers before the loop
    cravingImageNumbers = []; % Initialize as empty  
    selectedPrefix = [];
    
    
   % Start of the experiment loop
    for block_num = 1:num_blocks
        allSelectedImages = [];  %  Ensure it resets with every new block_num
        selectedImageIndices = [];
        % Reset firstBlockStartTime and lastBlockEndTime for each block set
        firstBlockStartTime = NaN;  
        lastBlockEndTime = NaN; 
        

        % Iterate through the defined block order
        for p = 1:length(blockOrder)
            currentBlock = blockOrder{p};

            switch currentBlock

                case 'PR' % Practice block
                if run_practice_block && block_num == 1 % Only run at the beginning
                    
                    % Detailed instructions for the whole task
                    Text = 'Welcome to the practice run!\n\nIn this experiment, you will practice different tasks related to your craving. \n\nFirst, you will see images and try to INCREASE your craving. \n\nNext, you will see images and try to DECREASE your craving. \n\nThen, you will simply WATCH images without trying to change your craving. \n\nFinally, you will RATE your craving on a scale.';
                    [~, ~, ~, ~, ~, ~, ~] = WriteInstruction(Text, magenta, cue_dur_TR + 20, feedback_dir, feedback_file_name); 
                    % Instruction after upregulation practice
                    Text = 'Now, you will try to INCREASE your craving when you see the images.';
                    [~, ~, ~, ~, ~, ~, ~] = WriteInstruction(Text, magenta, cue_dur_TR, feedback_dir, feedback_file_name); 
                    % Short practice blocks (adjust durations as needed)
                    [~, ~, ~, ~, ~, ~, ~] = Upregulation_feedback(10, feedback_dir, feedback_file_name, imageTextures, p, selectedImageIndices, allSelectedImages, block_num, blockOrder);
                    
                    % Instruction after upregulation practice
                    Text = 'Now, you will try to DECREASE your craving when you see the images.';
                    [~, ~, ~, ~, ~, ~, ~] = WriteInstruction(Text, magenta, cue_dur_TR, feedback_dir, feedback_file_name); 

                    [~, ~, ~, ~, ~, ~, ~] = Downregulation_feedback(10, feedback_dir, feedback_file_name, imageTextures, p, selectedImageIndices, allSelectedImages, block_num, blockOrder);
                    
                    % Instruction after downregulation practice
                    Text = 'Next, you will simply WATCH the images without trying to change your craving.';
                    [~, ~, ~, ~, ~, ~, ~] = WriteInstruction(Text, magenta, cue_dur_TR, feedback_dir, feedback_file_name); 

                    [~, ~, ~, ~, ~, ~, ~] = Neutral_control(10, feedback_dir, feedback_file_name, imageDir, cravingImageNumbers, p);
                    
                    % Instruction before VAS practice
                    Text = 'Finally, you will RATE your craving on a scale.';
                    [~, ~, ~, ~, ~, ~, ~] = WriteInstruction(Text, magenta, cue_dur_TR, feedback_dir, feedback_file_name); 

                    [~, ~, ~, ~, ~, ~, ~] = VAS_scale(window, scr_rect, 'Practice rating', feedback_dir, feedback_file_name, fileID7, p, num_blocks, block_num, blockOrder);
                    
                    run_practice_block = 0; % Ensure this block runs only once
                    
                    run_practice_block = 0; % Ensure this block runs only once
                end

                case 'R' 
                    if run_rest_block
                        % Baseline Rest period
                        [block_start, block_end, block_dur, block_start_TR, block_end_TR, block_start_TBV_TR, block_end_TBV_TR] = DrawFixationCross(grey, rest_dur_TR+40, feedback_dir, feedback_file_name); 
                        rest_block_timings = [rest_block_timings; block_start, block_end, block_dur, block_start_TBV_TR, block_end_TBV_TR, block_end_TBV_TR - block_start_TBV_TR + 1];
                        fprintf(fileID3, '%f  %f  %f  %f  %f  %f\n', [block_start, block_end, block_dur, block_start_TBV_TR, block_end_TBV_TR, block_end_TBV_TR - block_start_TBV_TR + 1]);
                        rest_blocks_TRs = [rest_blocks_TRs; block_start_TR, block_end_TR]; 

                        trial_history = [];
                        baseline_lag_dur = 12;
                        rest_calc_start_TR = rest_blocks_TRs(end, 1) + 13;

                        if current_TBV_tr > rest_calc_start_TR
                            if current_TBV_tr < rest_blocks_TRs(end, 2)
                                calc_interval = rest_calc_start_TR:current_TBV_tr;
                            else 
                                calc_interval = rest_calc_start_TR:rest_blocks_TRs(end, 2);
                            end

                            all_vals = ROI_vals(baseline_lag_dur:end, 1);
                            all_conf_vals = ROI_vals(baseline_lag_dur:end, 2); 

                            [beta, ~, stats] = glmfit(all_conf_vals - mean(all_conf_vals), all_vals);
                            resid_BOLD = stats.resid + beta(1);
                            rest_mean = mean(resid_BOLD(calc_interval - baseline_lag_dur + 1: end)); 

                        else
                            rest_mean = 0;
                        end
                        rest_blocks_mean = [rest_blocks_mean; rest_mean];
                        
                    end 

                case 'U'
                    if run_upregulation_block
                        % Check for first 'V' and first block
                        if p == find(strcmp(blockOrder, 'U'), 1) && block_num == 1
                   
                            % CUE before craving task
                            Text = 'Soon, you will see an \ninstruction to upregulate your craving on screen.';
                            [cue_start, cue_end, ~, cue_start_TR, cue_end_TR, cue_start_TBV_TR, cue_end_TBV_TR] = WriteInstruction(Text, magenta, cue_dur_TR, feedback_dir, feedback_file_name);
                            cue_dur = cue_end - cue_start;
                            cue_timings = [cue_timings; cue_start, cue_end, cue_dur, cue_start_TBV_TR, cue_end_TBV_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1];
                            fprintf(fileID1, '%f  %f  %f  %f  %f  %f\n\n', [cue_start, cue_end, cue_dur, cue_start_TBV_TR, cue_end_TBV_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1]);
    
                            % Craving neurofeedback task
                            current_TBV_tr = rt_load_BOLD(feedback_dir, feedback_file_name);
                            craving_blocks = craving_blocks + 1;
    
                            % craving CUE
                            Text = 'While you view images, \n try to increase your craving for the cannabis.';
                            [cue_start, ~, ~, cue_start_TR, ~, cue_start_TBV_TR, ~] = WriteInstruction(Text, magenta, cue_dur_TR, feedback_dir, feedback_file_name);
                            Text = 'Score bar will increase with more craving.';
                            WriteInstruction(Text, magenta, cue_dur_TR - 2, feedback_dir, feedback_file_name);
                            Text = 'Start:';
                            WriteInstruction(Text, magenta, cue_dur_TR - 3, feedback_dir, feedback_file_name);
                            for countdown = 3:-1:1
                                Text = num2str(countdown);
                                if countdown > 1
                                    WriteInstruction(Text, magenta, cue_dur_TR - 4, feedback_dir, feedback_file_name);
                                else
                                    [~, cue_end, ~, ~, cue_end_TR, ~, cue_end_TBV_TR] = WriteInstruction(Text, magenta, cue_dur_TR - 4, feedback_dir, feedback_file_name);
                                end
                            end
    
                            cue_dur = cue_end - cue_start;
                            cue_timings = [cue_timings; cue_start, cue_end, cue_dur, cue_start_TBV_TR, cue_end_TBV_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1];
                            fprintf(fileID1, '%f  %f  %f  %f  %f  %f\n\n', [cue_start, cue_end, cue_dur, cue_start_TBV_TR, cue_end_TBV_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1]);
    
                            
                        else
                            % CUE before craving task
                            Text = 'Now try to upregulate your craving to cannabis...';
                            [cue_start, cue_end, ~, cue_start_TR, cue_end_TR, cue_start_TBV_TR, cue_end_TBV_TR] = WriteInstruction(Text, magenta, cue_dur_TR, feedback_dir, feedback_file_name);
                            cue_dur = cue_end - cue_start;
                            cue_timings = [cue_timings; cue_start, cue_end, cue_dur, cue_start_TBV_TR, cue_end_TBV_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1];
                            fprintf(fileID1, '%f  %f  %f  %f  %f  %f\n\n', [cue_start, cue_end, cue_dur, cue_start_TBV_TR, cue_end_TBV_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1]);
    
                            % Craving neurofeedback task
                            current_TBV_tr = rt_load_BOLD(feedback_dir, feedback_file_name);
                            craving_blocks = craving_blocks + 1;
                        end
    
                            
                        % BLANK
                        BlankOut(1, feedback_dir, feedback_file_name);
                            
                        % Upregulation + feedback
                        
                        [block_start, block_end, block_dur, block_start_TR, block_end_TR, block_start_TBV_TR, block_end_TBV_TR, image_onsets, image_durations, image_offsets, cravingImageNumbers, selectedPrefix, selectedImageIndices,allSelectedImages] = Upregulation_feedback(...
                            block_dur_TR, feedback_dir, feedback_file_name, imageTextures, p, selectedImageIndices, allSelectedImages, block_num, blockOrder);
                        fprintf(fileID5, '%f  %f  %f  %f  %f  %f\n', [block_start, block_end, block_dur, block_start_TBV_TR, block_end_TBV_TR, block_end_TBV_TR - block_start_TBV_TR + 1]);
                        Up_block_timings = [Up_block_timings;[block_start, block_end, block_dur, block_start_TBV_TR, block_end_TBV_TR, block_end_TBV_TR - block_start_TBV_TR + 1]];
                       

                        
                    end % End of upregulation block

                case 'F'
                    if run_fixation_block
                        % Fixation block
                        [block_start, block_end, block_dur, block_start_TR, block_end_TR, block_start_TBV_TR, block_end_TBV_TR] = DrawFixationCross(grey, 3, feedback_dir, feedback_file_name); 
                        Fix_block_timings = [Fix_block_timings; block_start, block_end, block_dur, block_start_TBV_TR, block_end_TBV_TR, block_end_TBV_TR - block_start_TBV_TR + 1];
                        fprintf(fileID3, '%f  %f  %f  %f  %f  %f\n', [block_start, block_end, block_dur, block_start_TBV_TR, block_end_TBV_TR, block_end_TBV_TR - block_start_TBV_TR + 1]);
                        
                    end

                case 'N'
                    if run_neutral_block
                        if p == find(strcmp(blockOrder, 'N'), 1) && block_num == 1 
                            % Instruction before neutral block
                            Text = 'Now, Please simply watch the images. \n There is no need to try to regulate or change anything.';
                            [cue_start, cue_end, cue_dur, cue_start_TR, cue_end_TR, cue_start_TBV_TR, cue_end_TBV_TR] = WriteInstruction(Text, magenta, cue_dur_TR, feedback_dir, feedback_file_name);
    
                            Text = 'Start:';
                            WriteInstruction(Text, magenta, cue_dur_TR - 3, feedback_dir, feedback_file_name);
                            for countdown = 3:-1:1
                                Text = num2str(countdown);
                                if countdown > 1
                                    WriteInstruction(Text, magenta, cue_dur_TR - 4, feedback_dir, feedback_file_name);
                                else
                                    [~, cue_end, ~, ~, cue_end_TR, ~, cue_end_TBV_TR] = WriteInstruction(Text, magenta, cue_dur_TR - 4, feedback_dir, feedback_file_name);
                                end
                            end
    
                            cue_dur = cue_end - cue_start;
                            cue_timings = [cue_timings; cue_start, cue_end, cue_dur, cue_start_TBV_TR, cue_end_TBV_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1];
                            fprintf(fileID1, '%f  %f  %f  %f  %f  %f\n\n', [cue_start, cue_end, cue_dur, cue_start_TBV_TR, cue_end_TBV_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1]);
                            
                        else
                            % CUE before craving task
                            Text = 'Now, please simply watch the images. \nThere is no need to try to regulate or change anything.';
                            [cue_start, cue_end, ~, cue_start_TR, cue_end_TR, cue_start_TBV_TR, cue_end_TBV_TR] = WriteInstruction(Text, magenta, cue_dur_TR, feedback_dir, feedback_file_name);
                            cue_dur = cue_end - cue_start;
                            cue_timings = [cue_timings; cue_start, cue_end, cue_dur, cue_start_TBV_TR, cue_end_TBV_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1];
                            fprintf(fileID1, '%f  %f  %f  %f  %f  %f\n\n', [cue_start, cue_end, cue_dur, cue_start_TBV_TR, cue_end_TBV_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1]);
                        end
    


                        % BLANK
                        BlankOut(1, feedback_dir, feedback_file_name);

                        % Neutral Control Condition
                        neutral_block_dur_TR = block_dur_TR; 
                        [block_start, block_end, block_dur, block_start_TR, block_end_TR, block_start_TBV_TR, block_end_TBV_TR] = Neutral_control(neutral_block_dur_TR, feedback_dir, feedback_file_name, imageDir, cravingImageNumbers, selectedPrefix, p);
                        fprintf(fileID4,'%f  %f  %f  %f  %f  %f\n',[block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1]);
                        Neutral_block_timings = [Neutral_block_timings;[block_start, block_end, block_dur, block_start_TBV_TR, block_end_TBV_TR, block_end_TBV_TR - block_start_TBV_TR + 1]];
                       
                    end 

                case 'D'
                    if run_downregulation_block
                        if p == find(strcmp(blockOrder, 'D'), 1) && block_num == 1
                            % Cue before downregulation task
                            cueText = 'Soon, you will see an \ninstruction to downregulate your craving on screen.';
                            [cue_start, cue_end, cue_dur, cue_start_TR, cue_end_TR, cue_start_TBV_TR, cue_end_TBV_TR] = WriteInstruction(cueText, magenta, cue_dur_TR, feedback_dir, feedback_file_name);
                            cue_timings = [cue_timings; cue_start, cue_end, cue_dur, cue_start_TBV_TR, cue_end_TBV_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1];
                            fprintf(fileID1,'%f  %f  %f  %f  %f  %f\n\n',[cue_start,cue_end,cue_dur,cue_start_TR,cue_end_TR,cue_end_TBV_TR-cue_start_TBV_TR+1]);
    
                            % Downregulation neurofeedback task
                            current_TBV_tr = rt_load_BOLD(feedback_dir, feedback_file_name);
                            craving_blocks = craving_blocks + 1;
    
                            % Downregulation CUE
                            Text = 'While you view images, \n try to decrease your craving for the cannabis.';
                            [cue_start, ~, ~, cue_start_TR, ~, cue_start_TBV_TR, ~] = WriteInstruction(Text, magenta, cue_dur_TR, feedback_dir, feedback_file_name);
                            Text = 'Score bar will decrease with less craving.'; 
                            WriteInstruction(Text, magenta, cue_dur_TR - 2, feedback_dir, feedback_file_name);
    
                            Text = 'Start:';
                            WriteInstruction(Text, magenta, cue_dur_TR - 3, feedback_dir, feedback_file_name);
                            for countdown = 3:-1:1
                                Text = num2str(countdown);
                                if countdown > 1
                                    WriteInstruction(Text, magenta, cue_dur_TR - 4, feedback_dir, feedback_file_name);
                                else
                                    [~, cue_end, ~, ~, cue_end_TR, ~, cue_end_TBV_TR] = WriteInstruction(Text, magenta, cue_dur_TR - 4, feedback_dir, feedback_file_name);
                                end
                            end
    
                            cue_dur = cue_end - cue_start;
                            cue_timings = [cue_timings; cue_start, cue_end, cue_dur, cue_start_TBV_TR, cue_end_TBV_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1];
                            fprintf(fileID1, '%f  %f  %f  %f  %f  %f\n\n', [cue_start, cue_end, cue_dur, cue_start_TR, cue_end_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1]);
                            
                        else
                            % CUE before craving task
                            Text = 'Now try to downregulate your craving to cannabis...';
                            [cue_start, cue_end, ~, cue_start_TR, cue_end_TR, cue_start_TBV_TR, cue_end_TBV_TR] = WriteInstruction(Text, magenta, cue_dur_TR, feedback_dir, feedback_file_name);
                            cue_dur = cue_end - cue_start;
                            cue_timings = [cue_timings; cue_start, cue_end, cue_dur, cue_start_TBV_TR, cue_end_TBV_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1];
                            fprintf(fileID1, '%f  %f  %f  %f  %f  %f\n\n', [cue_start, cue_end, cue_dur, cue_start_TBV_TR, cue_end_TBV_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1]);
    
                            % Downregulation neurofeedback task
                            current_TBV_tr = rt_load_BOLD(feedback_dir, feedback_file_name);
                            craving_blocks = craving_blocks + 1;
                        end

                        % BLANK
                        BlankOut(1, feedback_dir, feedback_file_name);

                        
                       

                        [block_start, block_end, block_dur, block_start_TR, block_end_TR, block_start_TBV_TR, block_end_TBV_TR, image_onsets, image_durations, image_offsets, cravingImageNumbers, selectedPrefix, selectedImageIndices,allSelectedImages] = Downregulation_feedback(...
                            block_dur_TR, feedback_dir, feedback_file_name, imageTextures, p, selectedImageIndices, allSelectedImages, block_num, blockOrder);
                        fprintf(fileID6, '%f  %f  %f  %f  %f  %f\n', [block_start, block_end, block_dur, block_start_TBV_TR, block_end_TBV_TR, block_end_TBV_TR - block_start_TBV_TR + 1]);
                        Down_block_timings = [Down_block_timings; [block_start, block_end, block_dur, block_start_TBV_TR, block_end_TBV_TR, block_end_TBV_TR - block_start_TBV_TR + 1]];
                       
                    end  % End of downregulation block

                case 'V'
                    if run_vas_block
                        if p == find(strcmp(blockOrder, 'V'), 1) && block_num == 1
                            % VAS 
                            Text = sprintf(['Soon you will see a scale. \nPlease rate your current craving from 0 to 10: \n\n', ...
                                        '0 (No craving) <---> 10 (High craving) \n\n', ...
                                        'Use button box to rate your craving \n', ...
                                        'When finished, simply release the keys.']);
                            [cue_start, cue_end, cue_dur, cue_start_TR, cue_end_TR, cue_start_TBV_TR, cue_end_TBV_TR] = WriteInstruction(Text, magenta, cue_dur_TR + 10, feedback_dir, feedback_file_name);
                            cue_timings = [cue_timings; cue_start, cue_end, cue_dur, cue_start_TBV_TR, cue_end_TBV_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1];
                            fprintf(fileID1, '%f  %f  %f  %f  %f  %f\n\n', [cue_start, cue_end, cue_dur, cue_start_TBV_TR, cue_end_TBV_TR, cue_end_TBV_TR - cue_start_TBV_TR + 1]);
                            
                            
                        end
    
%                         % BLANK
%                         BlankOut(1, feedback_dir, feedback_file_name);
    
                        % VAS Scale Instruction
                        instructionText = 'Please rate your current craving on the scale from 0 to 10';
                        

                        
                        
                        [block_start, block_end, block_dur, block_start_TR, block_end_TR, block_start_TBV_TR, block_end_TBV_TR] = VAS_scale(window, scr_rect, instructionText, feedback_dir, feedback_file_name, fileID7, p, num_blocks, block_num, blockOrder);
    
                        % Store Ratings
                        VAS_block_timings = [VAS_block_timings; block_start, block_end, block_dur, block_start_TBV_TR, block_end_TBV_TR, block_end_TBV_TR - block_start_TBV_TR + 1];
                    end
                    

            end % End of switch case
            % Capture the first block start time (if not already captured) 
            if isnan(firstBlockStartTime) 
                firstBlockStartTime = block_start;  
            end
    
            % Update the last block end time 
            lastBlockEndTime = block_end; 
      
        end % End of block order loop
        % Write the first and last block timings to fileID2 (after the experiment loop)
        fprintf(fileID2, '%.2f  %.2f  %.2f  %d  %d  %d\n', firstBlockStartTime, lastBlockEndTime, lastBlockEndTime - firstBlockStartTime, ...
        round(firstBlockStartTime / TR) + 1, round(lastBlockEndTime / TR), round(lastBlockEndTime / TR) - round(firstBlockStartTime / TR) + 1);


    end % End of the experiment loop

    %----------------------------------------------------------------------
    %% End of run
    save([saveroot 'run_' num2str(run_no) '_rest_mean_values.mat'],'rest_blocks_mean');
    save([saveroot 'run_' num2str(run_no) '_TR_PSC_values.mat'],'ROI_PSC');
    Total_run_duration = VAS_block_timings(end, 2); %secs
    fprintf(fileID1, '\nTotal MRI run duration (s): \t\t%.2f \n', Total_run_duration); 
    fprintf(fileID2, '\nTotal MRI run duration (s): \t\t%.2f \n', Total_run_duration); 
    fprintf(fileID3, '\nTotal MRI run duration (s): \t\t%.2f \n', Total_run_duration);
    fprintf(fileID4, '\nTotal MRI run duration (s): \t\t%.2f \n', Total_run_duration); 
    fprintf(fileID5, '\nTotal MRI run duration (s): \t\t%.2f \n', Total_run_duration);
    fprintf(fileID6, '\nTotal MRI run duration (s): \t\t%.2f \n', Total_run_duration);
    save([saveroot 'run_' num2str(run_no) '_workspace.mat']);

catch 
    sca;
    ShowCursor; % Show mouse cursor
    psychrethrow(psychlasterror); % Print error message to command window
end

% Close all open files 
fclose(fileID1);
fclose(fileID2);
fclose(fileID3);
fclose(fileID4);
fclose(fileID5);
fclose(fileID6);
fclose(fileID7);
% Close the Psychtoolbox window and show the cursor
sca;
ShowCursor;

%% FUNCTIONS

function PrintGeneralInfo(ID,d,name,rn,nb,bl)
% Writes general info for each participant session into text file
%
%ID - file ID
%d - date
%name - participant's name
%rn - run number
%nb - number of block sets 
%bl - block length (in TR)
fprintf(ID, '\n============================================================================\n');
fprintf(ID, '\n______________________________General info:________________________________');
fprintf(ID, '\nDate of experiment: \t%s', d);
fprintf(ID, '\nParticipant Name: \t\t\t%s', name);
fprintf(ID, '\nRun number: \t\t%d', rn);
fprintf(ID, '\nNumber of Block sets per run: \t\t%d', nb);
fprintf(ID, '\nBlock Length [TR]: \t\t%f', bl);
end

%%%%%%%%%%%%%% Modified WriteInstruction function %%%%%%%%%%%%%%
function [co, ce, cdur, block_start_tr, block_end_tr, block_start_tbv_tr, block_end_tbv_tr] = WriteInstruction(instruction, colour, num_trs, folder_path, file_prefix)
    % Writes instructions on the screen for a specified duration, adjusting font size to fit the window.
    % Global Variables
    global window start_time current_TBV_tr TR windowHeight %%windowheight added
    % Outputs
    co = GetSecs() - start_time;           % Instruction onset time (in seconds)
    block_start_tr = round(co / TR) + 1;   % Instruction onset time (in TRs)
    block_start_tbv_tr = current_TBV_tr;   % Instruction onset TR from TheBrainVoyager
    
    % Text Properties
    Screen('TextSize', window, round(windowHeight * 0.05));  % Dynamic font size (5% of window height)
    Screen('TextFont', window, 'Arial');                    % Set font to Arial
    Screen('TextStyle', window, 0);                         % Normal text style
    
    % Text Wrapping and Display
    wrapAt = 80;                                     % Wrap text at 80 characters 
    vSpacing = 1.5;                                   % Line spacing 
    DrawFormattedText(window, instruction, 'center', 'center', colour, wrapAt, [], [], vSpacing); % Wrap and center text
    Screen('Flip', window);
    % Wait for Instruction Duration
    elapsed = (GetSecs() - start_time) - co;
    while elapsed < (num_trs * TR)
        current_TBV_tr = rt_load_BOLD(folder_path, file_prefix);
        ce = GetSecs() - start_time;                % Instruction end time (in seconds)
        elapsed = ce - co;
    end
    % Outputs
    cdur = elapsed;                            % Instruction duration (in seconds)
    block_end_tr = round(ce / TR);            % Instruction end time (in TRs)
    block_end_tbv_tr = current_TBV_tr;         % Instruction end TR from TheBrainVoyager
end

%%%%%%%%%%%%%%%%%%%%%%
function BlankOut(num_trs,folder_path,file_prefix)
% Shows a blank screen for a specified duration
%INPUTS
%num_trs - duration to display blank screen (in TR)
%folder_path - path to the feedback folder
%file_prefix - name of feedback file
global window current_TBV_tr start_time TR
starting = GetSecs() - start_time;
Screen('Flip',window);
current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
elapsed = (GetSecs() - start_time) - starting;
while elapsed < (num_trs*TR)
    current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
    elapsed = (GetSecs() - start_time) - starting;
end
end

%%%%%%%%%%%%%%%%%%%%%%
function [bo,be,bdur,block_start_tr,block_end_tr,block_start_tbv_tr,block_end_tbv_tr] = DrawFixationCross(colour,num_trs,folder_path,file_prefix)
% Draws a fixation cross for specified duration
%INPUTS
%colour - colour of fixation cross to display
%num_trs - duration to keep the cross on display (in TR)
%folder_path - path to the feedback folder
%file_prefix - name of feedback file
%OUTPUTS
%bo - onset time of fixation block (in s)
%be - end time of fixation block (in s)
%bdur - duration of fixation block (in s)
%block_start_tr - onset of cue on screen (in TR)
%block_vals - fMRI data from block (for each TR)
global TR window scr_rect centreX centreY start_time current_TBV_tr
bo = GetSecs() - start_time;
rect1_size = [0 0 scr_rect(4)/20 scr_rect(3)/4];
rect2_size = [0 0 scr_rect(3)/4 scr_rect(4)/20];
rect_color = colour;
rect1_coords = CenterRectOnPointd(rect1_size, centreX, centreY);
rect2_coords = CenterRectOnPointd(rect2_size, centreX, centreY);
Screen('FillRect',window,repmat(rect_color,[3,2]),[rect1_coords',rect2_coords']);
Screen('Flip',window);
current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
block_start_tbv_tr = current_TBV_tr;
block_start_tr = round(bo/TR)+1;
elapsed = (GetSecs() - start_time) - bo;
while elapsed < (num_trs*TR)
    current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
    be = GetSecs() - start_time;
    elapsed = be - bo;
end
bdur = elapsed;
block_end_tr = round(be/TR);
block_end_tbv_tr = current_TBV_tr;
end

%%%%%%%%%%% Modified Upregulation_feedback function %%%%%%%%%%%
function [bo, be, bdur, block_start_tr, block_end_tr, block_start_tbv_tr, block_end_tbv_tr, image_onsets, image_durations, image_offsets, cravingImageNumbers, selectedPrefix, selectedImageIndices,allSelectedImages] = Upregulation_feedback(num_trs, folder_path, file_prefix, imageTextures, p, selectedImageIndices, allSelectedImages, block_num, blockOrder)  
    global window start_time current_TBV_tr TR windowHeight FB_timings

    bo = GetSecs() - start_time;
    block_start_tr = round(bo / TR) + 1;
    block_start_tbv_tr = current_TBV_tr;
    image_onsets = [];
    image_durations = [];
    image_offsets = [];
    imageDurationSecs = 10; 

    % Get a list of all image files in the image directory
    imageDir = fullfile('C:\Users\NFB-user\Documents\NFB\Cue-reactivity latest\3-Current_MR_CRtask_v1_after2ndScan\Current_MR_CRtask_v1\MR_CRtask_v1\NFB_media');
    imageFiles = dir(fullfile(imageDir, 'C*.png')); 
    numImages = length(imageFiles);
    % Extract filenames into a cell array for easier manipulation
    imageFilenames = {imageFiles.name};
   
    
    % Randomly select 5 unique images for this block, ensuring no repetition within a block_num and between up/downregulation blocks
%     allImageIndices = 1:numImages; 
%     if isempty(selectedImageIndices) 
%         selectedImageIndices = randperm(numImages, 3); 
%     else
%         remainingImageIndices = setdiff(allImageIndices, allSelectedImages); 
%         if numel(remainingImageIndices) < 3
%             warning('Not enough unique images left for this block_num. Reusing some images.');
%             remainingImageIndices = allImageIndices; 
%         end
%         selectedImageIndices = remainingImageIndices(randperm(numel(remainingImageIndices), 3));
%     end
% 
%     allSelectedImages = [allSelectedImages, selectedImageIndices];
allImageIndices = 1:numImages; 


if isempty(selectedImageIndices) 
    % Define the prefixes as strings
    prefixes = {'C11', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9', 'C10'}; 

    % Choose a random prefix
    selectedPrefix = prefixes{randperm(length(prefixes), 1)};

    % Select all images with the selected prefix (adjust this based on your actual image index pattern)
    allMatchingIndices = find(startsWith(imageFilenames, selectedPrefix)); 
    selectedImageIndices = allMatchingIndices(randperm(length(allMatchingIndices), 3));
else
    remainingImageIndices = setdiff(allImageIndices, allSelectedImages); 

    % Get the remaining prefixes (this part might need adjustments depending on how you track remaining images)
    remainingImageFilenames = imageFilenames(remainingImageIndices);
    remainingPrefixes = unique(extractBefore(remainingImageFilenames, 3)); % Extract first 2 characters ('c1', 'c2', etc.)

    % Choose a random prefix from the remaining ones
    selectedPrefix = remainingPrefixes{randperm(length(remainingPrefixes), 1)};

    allMatchingIndices = find(startsWith(imageFilenames, selectedPrefix)); 
    selectedImageIndices = allMatchingIndices(randperm(length(allMatchingIndices), 3)); 
end

allSelectedImages = [allSelectedImages, selectedImageIndices];

   

    disp('Selected image indices for Downregulation block:');
    disp(allSelectedImages);
    disp(selectedImageIndices);

    % Load the selected images dynamically
    imageTextures = [];
    for j = 1:numel(selectedImageIndices)
        imagePath = fullfile(imageDir, imageFiles(selectedImageIndices(j)).name);
        img = imread(imagePath);
        imageTextures(j) = Screen('MakeTexture', window, img);
    end

    % Task loop 
    for imageIndex = 1:numel(imageTextures)
        imageStartTime = GetSecs();
        temp = 0;
        while GetSecs() - imageStartTime < imageDurationSecs
            current_TBV_tr = rt_load_BOLD(folder_path, file_prefix);
            if current_TBV_tr - temp > 0
                feedback_num = calculate_feedback();  
                score = round(feedback_num * 19) + 1;  
                temp = current_TBV_tr;
            end

            if isempty(FB_timings) || floor(GetSecs() - start_time) > floor(FB_timings{end, 1})
                if block_num == 1 && strcmp(blockOrder{p}, 'PR')  % Check for practice block
                    FB_timings{end + 1, 1} = GetSecs() - start_time; 
                    FB_timings{end, 2} = score; 
                    FB_timings{end, 3} = current_TBV_tr; 
                    FB_timings{end, 4} = "Up"; 
                    FB_timings{end, 5} = "Practice"; % Add "Practice" to the 5th column
                else
                    FB_timings{end + 1, 1} = GetSecs() - start_time; 
                    FB_timings{end, 2} = score; 
                    FB_timings{end, 3} = current_TBV_tr; 
                    FB_timings{end, 4} = "Up"; 
                    FB_timings{end, 5} = "Experiment"; % Add "Experiment" to the 5th column 
                end
            end
                
            [windowWidth, windowHeight] = Screen('WindowSize', window);
            newImageWidth = windowWidth * 0.6;  
            newImageHeight = windowHeight * 0.8;
            % Calculate the x-coordinate for the center of the image
            offsetX = windowWidth * 0.1;  % Adjust this value to move the image left or right
            centerX = windowWidth / 2 - offsetX; 
            dstRect = CenterRectOnPoint([0 0 newImageWidth newImageHeight], centerX, windowHeight / 2);

            DrawFeedbackImage(imageTextures, imageIndex, dstRect);
            DrawFeedback(score); 
        end 
        Screen('Flip', window); 
        image_offsets(end+1) = GetSecs() - start_time; 
        image_durations(end+1) = imageDurationSecs;
        image_onsets(end+1) = image_offsets(end) - image_durations(end);
    end 

    be = GetSecs() - start_time;
    bdur = be - bo;
    block_end_tr = round(be / TR);
    block_end_tbv_tr = current_TBV_tr;

    % Extract the numbers from the craving image file names
    cravingImageNumbers = [];
    for i = 1:numel(selectedImageIndices)
        [~, imageName, ~] = fileparts(imageFiles(selectedImageIndices(i)).name);
        cravingImageNumbers(i) = str2double(imageName(2:end)); 
    end
end
%%%%%%%%%%% Downregulation_feedback function %%%%%%%%%%%
function [bo, be, bdur, block_start_tr, block_end_tr, block_start_tbv_tr, block_end_tbv_tr, image_onsets, image_durations, image_offsets, cravingImageNumbers, selectedPrefix, selectedImageIndices,allSelectedImages] = Downregulation_feedback(num_trs, folder_path, file_prefix, imageTextures, p, selectedImageIndices, allSelectedImages, block_num, blockOrder)  
    global window start_time current_TBV_tr TR windowHeight FB_timings 

    bo = GetSecs() - start_time;
    block_start_tr = round(bo / TR) + 1;
    block_start_tbv_tr = current_TBV_tr;
    image_onsets = [];
    image_durations = [];
    image_offsets = [];
    imageDurationSecs = 10; 

    % Get a list of all image files in the image directory
    imageDir = fullfile('C:\Users\NFB-user\Documents\NFB\Cue-reactivity latest\3-Current_MR_CRtask_v1_after2ndScan\Current_MR_CRtask_v1\MR_CRtask_v1\NFB_media');
    imageFiles = dir(fullfile(imageDir, 'C*.png')); 
    numImages = length(imageFiles);
    % Extract filenames into a cell array for easier manipulation
    imageFilenames = {imageFiles.name};

  
    % Randomly select 5 unique images for this block, ensuring no repetition within a block_num and between up/downregulation blocks
%     allImageIndices = 1:numImages; 
%     if isempty(selectedImageIndices) 
%         selectedImageIndices = randperm(numImages, 3); 
%     else
%         remainingImageIndices = setdiff(allImageIndices, allSelectedImages); 
%         if numel(remainingImageIndices) < 3
%             warning('Not enough unique images left for this block_num. Reusing some images.');
%             remainingImageIndices = allImageIndices; 
%         end
%         selectedImageIndices = remainingImageIndices(randperm(numel(remainingImageIndices), 3));
%     end
% 
%     allSelectedImages = [allSelectedImages, selectedImageIndices]; 
allImageIndices = 1:numImages; 


if isempty(selectedImageIndices) 
    % Define the prefixes as strings
    prefixes = {'C11', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9', 'C10'}; 

    % Choose a random prefix
    selectedPrefix = prefixes{randperm(length(prefixes), 1)};

    % Select all images with the selected prefix (adjust this based on your actual image index pattern)
    allMatchingIndices = find(startsWith(imageFilenames, selectedPrefix)); 
    selectedImageIndices = allMatchingIndices(randperm(length(allMatchingIndices), 3));
else
    remainingImageIndices = setdiff(allImageIndices, allSelectedImages); 

    % Get the remaining prefixes (this part might need adjustments depending on how you track remaining images)
    remainingImageFilenames = imageFilenames(remainingImageIndices);
    remainingPrefixes = unique(extractBefore(remainingImageFilenames, 3)); % Extract first 2 characters ('c1', 'c2', etc.)

    % Choose a random prefix from the remaining ones
    selectedPrefix = remainingPrefixes{randperm(length(remainingPrefixes), 1)};

    allMatchingIndices = find(startsWith(imageFilenames, selectedPrefix)); 
    selectedImageIndices = allMatchingIndices(randperm(length(allMatchingIndices), 3)); 
end

allSelectedImages = [allSelectedImages, selectedImageIndices];
    disp('Selected image indices for Downregulation block:');
    disp(allSelectedImages);
    disp(selectedImageIndices);

    % Load the selected images dynamically
    imageTextures = [];
    for j = 1:numel(selectedImageIndices)
        imagePath = fullfile(imageDir, imageFiles(selectedImageIndices(j)).name);
        img = imread(imagePath);
        imageTextures(j) = Screen('MakeTexture', window, img);
    end

    % Task loop 
    for imageIndex = 1:numel(imageTextures)
        imageStartTime = GetSecs();
        temp = 0;
        while GetSecs() - imageStartTime < imageDurationSecs
            current_TBV_tr = rt_load_BOLD(folder_path, file_prefix);
            if current_TBV_tr - temp > 0
                feedback_num = calculate_feedback_downregulation();  
                score = round(feedback_num * 19) + 1; 
                temp = current_TBV_tr;
            end
            
            if isempty(FB_timings) || floor(GetSecs() - start_time) > floor(FB_timings{end, 1})
                if block_num == 1 && strcmp(blockOrder{p}, 'PR')  % Check for practice block
                    FB_timings{end + 1, 1} = GetSecs() - start_time; 
                    FB_timings{end, 2} = score; 
                    FB_timings{end, 3} = current_TBV_tr; 
                    FB_timings{end, 4} = "Down"; 
                    FB_timings{end, 5} = "Practice"; % Add "Practice" to the 5th column
                else
                    FB_timings{end + 1, 1} = GetSecs() - start_time; 
                    FB_timings{end, 2} = score; 
                    FB_timings{end, 3} = current_TBV_tr; 
                    FB_timings{end, 4} = "Down"; 
                    FB_timings{end, 5} = "Experiment"; % Add "Experiment" to the 5th column 
                end
            end

            [windowWidth, windowHeight] = Screen('WindowSize', window);
            newImageWidth = windowWidth * 0.6;  
            newImageHeight = windowHeight * 0.8;
            % Calculate the x-coordinate for the center of the image
            offsetX = windowWidth * 0.1;  % Adjust this value to move the image left or right
            centerX = windowWidth / 2 - offsetX; 
            dstRect = CenterRectOnPoint([0 0 newImageWidth newImageHeight], centerX, windowHeight / 2);

            % Draw Image
            DrawFeedbackImage(imageTextures, imageIndex, dstRect);

            % Draw Score Bar (modified for downregulation)
            DrawFeedbackDownregulation(score);  
        end 

        Screen('Flip', window); 
        image_offsets(end+1) = GetSecs() - start_time; 
        image_durations(end+1) = imageDurationSecs;
        image_onsets(end+1) = image_offsets(end) - image_durations(end);
    end 

    be = GetSecs() - start_time;
    bdur = be - bo;
    block_end_tr = round(be / TR);
    block_end_tbv_tr = current_TBV_tr;

    % Extract the numbers from the craving image file names
    cravingImageNumbers = [];
    for i = 1:numel(selectedImageIndices) 
        [~, imageName, ~] = fileparts(imageFiles(selectedImageIndices(i)).name);
        cravingImageNumbers(i) = str2double(imageName(2:end));
    end
end
%%%%%%%%%%%%%%%%%%%%
function [bo, be, bdur, block_start_tr, block_end_tr, block_start_tbv_tr, block_end_tbv_tr] = Neutral_control(num_trs, folder_path, file_prefix, imageDir, cravingImageNumbers, selectedPrefix, p)
    global window start_time current_TBV_tr TR windowHeight pp_no run_no block_num blockOrder selectedImageIndices selectedNeutralImageIndices allSelectedImages
    bo = GetSecs() - start_time;
    block_start_tr = round(bo / TR) + 1;
    block_start_tbv_tr = current_TBV_tr;
    % Get lists of all craving and neutral image files
    cravingImageFiles = dir(fullfile(imageDir, 'C*.png')); 
    neutralImageFiles = dir(fullfile(imageDir, 'N*.png'));
    numCravingImages = length(cravingImageFiles);
    numNeutralImages = length(neutralImageFiles);
    
    %cravingImageNumbers = cravingImageNumbers;
    
    % Logic to select images based on block order
    if isempty(selectedPrefix)  % If cravingImageNumbers is empty (neutral block first)
        % Select 5 random neutral images, ensuring no repetition within a block_num
        allNeutralImageIndices = 1:numNeutralImages;
        if isempty(selectedNeutralImageIndices)
            selectedNeutralImageIndices = randperm(numNeutralImages, 1);
        else
            remainingNeutralImageIndices = setdiff(allNeutralImageIndices, selectedNeutralImageIndices);
            selectedNeutralImageIndices = remainingNeutralImageIndices(randperm(numel(remainingNeutralImageIndices), 1));
        end
        % Store the numbers from the selected neutral image file names 
        neutralImageNumbers = [];
        for k = 1:numel(selectedNeutralImageIndices)
            [~, imageName, ~] = fileparts(neutralImageFiles(selectedNeutralImageIndices(k)).name);
            neutralImageNumbers(k) = str2double(imageName(2:end));
        end
        selectedImageIndices = selectedNeutralImageIndices; 
%     else  % If cravingImageNumbers is not empty (craving block first)
%         selectedImageIndices = [];
%         for k = 1:numel(selectedPrefix)
%             for j = 1:numNeutralImages
%                 [~, imageName, ~] = fileparts(neutralImageFiles(j).name);
%                 if str2double(imageName(2:end)) == selectedPrefix(k)
%                     selectedImageIndices(k) = j;
    else  % If cravingImageNumbers is not empty (craving block first)
        selectedImageIndices = [];
        
        % Convert the numeric part of the selectedPrefix to match the craving image numbers
        prefixNumber = str2double(selectedPrefix(2:end));  % Extract the numeric part of the selectedPrefix (e.g., 'C5' -> 5)
        
        for j = 1:numNeutralImages
        % Get the neutral image name (without the file extension)
            [~, imageName, ~] = fileparts(neutralImageFiles(j).name);
            
            % Compare the numeric part of the neutral image with the selectedPrefix's number
            if str2double(imageName(2:end)) == prefixNumber  % Match the numeric part with the selectedPrefix
                selectedImageIndices = j;  % Store the index of the first matching neutral image
                break;  % Exit the loop after finding the first match
            end
        end
    end

    % Load the selected neutral images dynamically
    imageTextures = [];
    for k = 1:numel(selectedImageIndices)
        imagePath = fullfile(imageDir, neutralImageFiles(selectedImageIndices(k)).name);
        img = imread(imagePath);
        imageTextures(k) = Screen('MakeTexture', window, img);
    end
    imageDurationSecs = 10;

    % Task loop 
    for imageIndex = 1:numel(imageTextures)
        imageStartTime = GetSecs();
        while GetSecs() - imageStartTime < imageDurationSecs
            current_TBV_tr = rt_load_BOLD(folder_path, file_prefix);
            [windowWidth, windowHeight] = Screen('WindowSize', window);
            newImageWidth = windowWidth * 0.6;
            newImageHeight = windowHeight * 0.8;
            % Calculate the x-coordinate for the center of the image
            offsetX = windowWidth * 0.1;  % Adjust this value to move the image left or right
            centerX = windowWidth / 2 - offsetX; 
            dstRect = CenterRectOnPoint([0 0 newImageWidth newImageHeight], centerX, windowHeight / 2);

            DrawFeedbackImage(imageTextures, imageIndex, dstRect);
            DrawNeutralFeedback();
        end
        Screen('Flip', window);
    end
    be = GetSecs() - start_time;
    bdur = be - bo;
    block_end_tr = round(be / TR);
    block_end_tbv_tr = current_TBV_tr;
end
%%%%%%%%%%%%%%%%%%%%
function DrawNeutralFeedback()
    global window scr_rect centreX centreY windowHeight 

    x_size = scr_rect(3) / 15;
    y_size = scr_rect(4) / 60; 
    rect_size = [0 0 x_size y_size];
    
    % No fill color needed since we don't want any filled rectangles
    
    % Adjust these values to control the bar's position
    barOffsetX = x_size * 5;     
    barOffsetY = 0;    
    all_rect_coords = zeros(4, 20);  % Adjusted for 40 rectangles
    rect_start_pos = -10;  % Adjust for 40 rectangles
    
    for i = 1:20
        rect_coords = CenterRectOnPointd(rect_size, centreX + barOffsetX, centreY + barOffsetY - ((i + rect_start_pos - 1) * y_size)); 
        all_rect_coords(:, i) = rect_coords';
    end
    
    % Removed the line that filled the lowest rectangle

    % Drawing frames for all 40 rectangles
    Screen('FrameRect', window, 255, all_rect_coords, ones(20, 1) * 1.5);
    
    % Center line position (between rectangles 20 and 21)
% %     centre_line_pos = [centreX + barOffsetX - (0.75 * rect_size(3)), centreX + barOffsetX + (0.75 * rect_size(3)); 
%                        centreY + barOffsetY + ((rect_start_pos + 20) * y_size) + (0.5 * rect_size(4)), ...
%                        centreY + barOffsetY + ((rect_start_pos + 20) * y_size) + (0.5 * rect_size(4))];
%    
    % Drawing the center line on the feedback frame
%     Screen('DrawLines', window, centre_line_pos, 2, 200);

       
    % Writing text on screen
    Screen('TextSize', window, round(windowHeight * 0.03));
    Screen('TextFont', window, 'Arial');
    Screen('TextStyle', window, 0);
    
    label_1 = '  High Craving';
    label_2 = '  Low Craving';
    label_1_color = [255 255 255];
    label_2_color = [255 255 255];
    
    % Adjust text positions for the new setup
    label_1_pos = [centreX + barOffsetX - x_size, centreY - ((rect_start_pos+21)*y_size)]; % Adjusted for 40 rectangles
    label_2_pos = [centreX + barOffsetX - x_size, centreY - ((rect_start_pos-3)*y_size)];  % Adjusted for 40 rectangles
    
    DrawFormattedText(window, label_1, label_1_pos(1), label_1_pos(2), label_1_color); 
    DrawFormattedText(window, label_2, label_2_pos(1), label_2_pos(2), label_2_color);

    % Flip the screen to display the changes
    Screen('Flip', window); 
end

%%%%%%%%%%%%%%%%%%%%

function DrawFeedbackImage(imageTextures, imageIndex, dstRect)
    global window 
    % Set opacity to 0.7 
    Screen('DrawTexture', window, imageTextures(imageIndex), [], dstRect, [], [], 0.7); 
end

%%%%%%%%%%%%%%%%%%%%
function rect_num = DrawFeedback(score)
    global window scr_rect centreX centreY windowHeight 

    x_size = scr_rect(3)/15;
    y_size = scr_rect(4)/60; 
    rect_size = [0 0 x_size y_size];
    rect_color = [180 180 180]; 
    rect_color_black = [0 0 0];
    % Adjust these values to control the bar's position relative to the image
    barOffsetX = x_size*5;      % Move the bar right (+) or left (-)
    barOffsetY = 0;             % Move the bar down (+) or up (-)
    
    all_rect_coords = zeros(4,20);  % Adjusted for 40 rectangles
    rect_start_pos = -10;  % Adjust for positioning 40 rectangles
    for i = 1:20
        rect_coords = CenterRectOnPointd(rect_size, centreX + barOffsetX, centreY + barOffsetY - ((i+rect_start_pos-1)*y_size));  % Apply offset
        all_rect_coords(:,i) = rect_coords';
    end
    
    % Fill the first 20 rectangles with magenta (pink) initially
%     Screen('FillRect', window, repmat(rect_color_black', [1, 20]), all_rect_coords(:, 1:20));

    % Fill rectangles 21 to 40 based on the score
    if score > 0
        % Add 20 to the score so it maps correctly to rectangles 21 to 40
        Screen('FillRect', window, repmat(rect_color', [1, score]), all_rect_coords(:, 1:(score)));
    end

    
    % Center line (adjusted for 40 rectangles, centered between rectangle 20 and 21)
%     centre_line_pos = [centreX + barOffsetX - (0.75*rect_size(3)), centreX + barOffsetX + (0.75*rect_size(3)); 
%                        centreY + barOffsetY - ((rect_start_pos+19)*y_size)-(0.5*rect_size(4)), ...
%                        centreY + barOffsetY - ((rect_start_pos+19)*y_size)-(0.5*rect_size(4))];
%     
%     % Drawing frames for all 40 rectangles
    Screen('FrameRect', window, 255, all_rect_coords, ones(20,1)*1.5);
    
    % Drawing the center line on the feedback frame
%     Screen('DrawLines', window, centre_line_pos, 2, 200);
    
    % Writing text on screen
    Screen('TextSize', window, round(windowHeight * 0.03));
    Screen('TextFont', window, 'Arial');
    Screen('TextStyle', window, 0);
    
    label_1 = '  High Craving';
    label_2 = '  Low Craving';
    label_1_color = [255 255 255];
    label_2_color = [255 255 255];
    
    % Adjust text positions for the new setup
    label_1_pos = [centreX + barOffsetX - x_size, centreY - ((rect_start_pos+21)*y_size)]; % Adjusted for 40 rectangles
%     label_2_pos = [centreX + barOffsetX - x_size, centreY - ((rect_start_pos-3)*y_size)];  % Adjusted for 40 rectangles
    
     % Arrow parameters
    arrowBaseX = centreX + barOffsetX + (1.5 * x_size); 
    arrowBaseY = centreY + barOffsetY - ((rect_start_pos) * y_size); 
    arrowHeight = 20 * y_size; 
    arrowHeadSize = scr_rect(3) * 0.03; % 5% of the screen width; 
    arrowColor = [255 255 255]; 
    % Define the arrow line as a rectangle (for thickness)
    arrowLineWidth = scr_rect(3) * 0.02;  % The width of the "line" (thickness)
    arrowLineTopX = arrowBaseX - (arrowLineWidth / 2);  % Left side of the line
    arrowLineBottomX = arrowBaseX + (arrowLineWidth / 2);  % Right side of the line
    arrowLineTopY = arrowBaseY - .9*(arrowHeight);  % Top of the line
    arrowLineBottomY = arrowBaseY;  % Bottom of the line (base of the arrow)
    
    % Create a rectangle for the arrow line
    arrowLineRect = [arrowLineTopX, arrowLineTopY, arrowLineBottomX, arrowLineBottomY];
    
    % Draw the arrow line as a filled rectangle
    Screen('FillRect', window, arrowColor, arrowLineRect);


   
    % Triangle arrowhead coordinates
    arrowHeadPoints = [ arrowBaseX - arrowHeadSize, arrowBaseY - arrowHeight + arrowHeadSize; ... % Left vertex
                        arrowBaseX, arrowBaseY - arrowHeight; ...                               % Tip
                        arrowBaseX + arrowHeadSize, arrowBaseY - arrowHeight + arrowHeadSize; ... % Right vertex
                        arrowBaseX - arrowHeadSize, arrowBaseY - arrowHeight + arrowHeadSize];    % Close the triangle

    
    % Fill the triangle arrowhead
    Screen('FillPoly', window, arrowColor, arrowHeadPoints); 


    DrawFormattedText(window, label_1, label_1_pos(1), label_1_pos(2), label_1_color); 
%     DrawFormattedText(window, label_2, label_2_pos(1), label_2_pos(2), label_2_color);
    
    % Flip the screen to display the changes
    Screen('Flip', window); 
end


%%%%%%%%%%%%%%%%
function rect_num = DrawFeedbackDownregulation(score)  
    global window scr_rect centreX centreY windowHeight 
    
    x_size = scr_rect(3) / 15;
    y_size = scr_rect(4) / 60; 
    rect_size = [0 0 x_size y_size];
    rect_color_white = [180 180 180];  % Initial color (magenta)
    rect_color_black = [0 0 0];        % Fill color (black)
    
    % Adjust these values to control the bar's position relative to the image
    barOffsetX = x_size * 5;  % Move the bar right (+) or left (-)
    barOffsetY = 0;            % Move the bar down (+) or up (-)
    labelOffsetY = scr_rect(4) * 0.01;   % 1% of the screen height

    all_rect_coords = zeros(4, 20);  % Adjusted for 40 rectangles
    rect_start_pos = -10;  % Start position adjusted for 40 rectangles
    
    
    for i = 1:20
        rect_coords = CenterRectOnPointd(rect_size, centreX + barOffsetX, centreY + barOffsetY - ((i+rect_start_pos-1)*y_size));  % Apply offset
        all_rect_coords(:,i) = rect_coords';
    end
    
    
    
    % Fill rectangles 21-40 with black
%     Screen('FillRect', window, rect_color_black', all_rect_coords(:, 21:40));
    
    % Fill the first 20 rectangles (1-20) with magenta initially
    Screen('FillRect', window, rect_color_black', all_rect_coords(:, 1:20));
    
    % Fill the first 'score' number of rectangles (1-20) with black based on the score
    if score > 0 && score <= 20
        Screen('FillRect', window, repmat(rect_color_white', [1, score]), all_rect_coords(:, (20 - score+1):20));
    end

 
    
    % Center line position (between rectangles 20 and 21)
%     centre_line_pos = [centreX + barOffsetX - (0.75 * rect_size(3)), centreX + barOffsetX + (0.75 * rect_size(3)); 
%                        centreY + barOffsetY + ((rect_start_pos + 20) * y_size) + (0.5 * rect_size(4)), ...
%                        centreY + barOffsetY + ((rect_start_pos + 20) * y_size) + (0.5 * rect_size(4))];
%     
    % Drawing frames for all 40 rectangles
    Screen('FrameRect', window, 255, all_rect_coords, ones(20, 1) * 1.5);
    
    % Drawing the center line on the feedback frame
%     Screen('DrawLines', window, centre_line_pos, 2, 200);
    
    % Writing text on screen
    Screen('TextSize', window, round(windowHeight * 0.03));
    Screen('TextFont', window, 'Arial');
    Screen('TextStyle', window, 0);
    
    label_1 = '  High Craving';
    label_2 = '  Low Craving';
    
    label_1_color = [255 255 255];
    label_2_color = [255 255 255];
    
    % Adjust text positions for the new setup
%     label_1_pos = [centreX + barOffsetX - x_size, centreY - ((rect_start_pos + 41) * y_size)]; % Adjusted for 40 rectangles
    label_2_pos = [centreX + barOffsetX - x_size, centreY - ((rect_start_pos - 3) * y_size)];  % Adjusted for 40 rectangles
   
    % Arrow parameters
    arrowBaseX = centreX + barOffsetX + (1.5 * x_size); 
    arrowBaseY = centreY + barOffsetY - ((rect_start_pos + 19) * y_size); 
    arrowHeight = 20 * y_size; 
    arrowHeadSize = scr_rect(3) * 0.03; 
    arrowColor = [255 255 255]; 
    % Define the arrow line as a rectangle (for thickness)
    arrowLineWidth = scr_rect(3) * 0.02;  % The width of the "line" (thickness)
    arrowLineTopX = arrowBaseX - (arrowLineWidth / 2);  % Left side of the line
    arrowLineBottomX = arrowBaseX + (arrowLineWidth / 2);  % Right side of the line
    arrowLineTopY = arrowBaseY;  % Top of the line
    arrowLineBottomY = arrowBaseY + .9*(arrowHeight);  % Bottom of the line (base of the arrow)
    % Create a rectangle for the arrow line
    arrowLineRect = [arrowLineTopX, arrowLineTopY, arrowLineBottomX, arrowLineBottomY];
    
    % Draw the arrow line as a filled rectangle
    Screen('FillRect', window, arrowColor, arrowLineRect);
    
    % Triangle arrowhead coordinates (pointing down)
    arrowHeadPoints = [arrowBaseX - arrowHeadSize, arrowBaseY + arrowHeight - arrowHeadSize; ... % Left vertex
                       arrowBaseX, arrowBaseY + arrowHeight; ...                               % Tip
                       arrowBaseX + arrowHeadSize, arrowBaseY + arrowHeight - arrowHeadSize; ... % Right vertex
                       arrowBaseX - arrowHeadSize, arrowBaseY + arrowHeight - arrowHeadSize];    % Close the triangle
    
   
    % Fill the triangle arrowhead
    Screen('FillPoly', window, arrowColor, arrowHeadPoints); 

%     DrawFormattedText(window, label_1, label_1_pos(1), label_1_pos(2), label_1_color); 
    DrawFormattedText(window, label_2, label_2_pos(1), label_2_pos(2), label_2_color);
    
    % Flip the screen to display the changes
    Screen('Flip', window); 
end


%%%%%%%%%%%%%%%%
function curr_tr = rt_load_BOLD(folder_path,file_prefix)
% Reads the most recent update in the feedback folder and updates the
% current TR (in a real-time scenario)
%For simulation, it just proceeds to the next TR
%INPUTS
%folder_path - path to the feedback folder
%file_prefix - name of feedback file
%OUTPUTS
%curr_tr - the current/present TR in TBV
global ROI_vals start_time TR port_issue baseline_lag_dur all_vals all_conf_vals
curr_time = GetSecs()-start_time;
curr_tr = round(curr_time/TR);
folder_dir = dir(folder_path);
feedback_filenames = {folder_dir(3:end).name}';
file_numbers = regexp(feedback_filenames,'[\d\.]+','match'); %getting all the numbers in filenames as cell array
TBV_tr_values = unique(sort(str2double([file_numbers{:}]'))); %sorted vector
%current TR value based on the most recent TBV feedback file that came in
curr_tbv_tr = TBV_tr_values(end);
prev_tbv_tr = size(ROI_vals,1);
% source flag --> 0 for current upload, 1 for upload from previous TBV TR, 2
% for copying from previous TBV entry (no direct upload)
if (curr_tbv_tr>prev_tbv_tr) && (curr_tbv_tr>0) && (curr_tr>0)
    tic;
    try %loading feedback info into temp1 (based on TBV output updates)
        temp1 = load([folder_path '\' file_prefix '-' num2str(curr_tbv_tr) '.rtp']);
        temp2 = temp1(1,2); %current ROI psc value in temp2
        temp3 = temp1(1,end); %condition
        conf = temp1(1,3); %confound signal PSC
        source_flag = 0;
        % Print the loaded data
            fprintf('Loaded data: temp2 = %f, temp3 = %f, conf = %f\n', temp2, temp3, conf);
        
    catch %storing previous values (based on TBV output updates) due to error in accessing most recent output file
        port_issue = [port_issue;curr_tbv_tr,curr_tr];
        try
            %Re-loading previous feedback file info into temp1
            temp1 = load([folder_path '\' file_prefix '-' num2str(prev_tbv_tr) '.rtp']);
            temp2 = temp1(1,2); %current ROI psc value in temp2
            temp3 = temp1(1,end); %condition
            conf = temp1(1,3); %confound signal PSC
            source_flag = 1;
            
            if curr_tbv_tr>1
                ROI_vals(prev_tbv_tr,1:2) = [temp2,conf]; % Updating previous entry as well
                ROI_vals(prev_tbv_tr,5) = temp3;
            end
            
        catch
            %This is in case the previous file is also not accessible
            temp2 = ROI_vals(prev_tbv_tr,1);
            temp3 = ROI_vals(prev_tbv_tr,5);
            conf = ROI_vals(prev_tbv_tr,2);
            source_flag = 2;
        end
    end
    elapsed = toc;
    % Print the final ROI_vals entry
        fprintf('ROI_vals entry: ');
        disp( [temp2, conf, curr_tbv_tr, curr_time, temp3, elapsed, curr_tr, source_flag] );
        % Print values after updating ROI_vals
        fprintf('After processing: curr_tbv_tr = %d, prev_tbv_tr = %d, size(ROI_vals, 1) = %d\n', ...
            curr_tbv_tr, prev_tbv_tr, size(ROI_vals, 1));
    %Main matrix containing PSC and other values
    ROI_vals(curr_tbv_tr,:) = [temp2,conf,curr_tbv_tr,curr_time,temp3,elapsed,curr_tr,source_flag];
    
end
end

%%%%%%%%%%%
function curr_feedback = calculate_feedback()
% Calculates and returns the feedback value
%INPUTS
%medtrial_start - onset of meditation trial (in MRI TR)
%OUTPUTS
%curr_feedback - feedback value (between 0.1 and 1) for the current TR
global ROI_PSC PSC_thresh ROI_vals current_TBV_tr temp2 conf 
baseline_lag_dur = 12; % all calculations to start after these many TRs at the beginning of run
%ALL BOLD PSC values from dynamic ROI
all_vals = ROI_vals(baseline_lag_dur:end,1); %Taking all the BOLD values so far, for cumulative GLM
%considering the initial lag
%All confound PSC from confound ROI mask
all_conf_vals = ROI_vals(baseline_lag_dur:end,2); %Taking all the confound mask values so far, for cumulative GLM
%Cumulative GLM - Regressing out detrended and demeaned confound from ROI so far
[beta,~,stats] = glmfit(all_conf_vals-mean(all_conf_vals),all_vals);
resid_BOLD = stats.resid + beta(1);
current_psc = resid_BOLD(end);
current_conf = all_conf_vals(end);
%Feedback value:
%Higher negative feedback value implies greater deactivation
%Converting negative feedback value to positive feedback value in the
%barpsc
% 0 and +ve PSC = feedback value of 1
% -ve PSC = feedback value above 1
curr_feedback = round((current_psc/PSC_thresh),2); 
%First term in ROI_PSC is unaffected by changing PSC threshold setting
%(direct from TBV)
%Second term is affected due to changing PSC threshold
ROI_PSC = [ROI_PSC;current_psc,curr_feedback,current_conf,current_TBV_tr]; %first and last TRs used for calculation
if curr_feedback<0.01
    curr_feedback=0.01;
elseif curr_feedback>1
    curr_feedback=1;
end
% Print the score for upregulation
fprintf('Upregulation score: %.2f\n', curr_feedback); 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%
function curr_feedback = calculate_feedback_downregulation()
% Calculates and returns the feedback value for downregulation
global ROI_PSC ROI_vals current_TBV_tr temp2 conf 

baseline_lag_dur = 12; % all calculations to start after these many TRs at the beginning of run

% ALL BOLD PSC values from dynamic ROI
all_vals = ROI_vals(baseline_lag_dur:end,1); 

% All confound PSC from confound ROI mask
all_conf_vals = ROI_vals(baseline_lag_dur:end,2); 

% Cumulative GLM - Regressing out detrended and demeaned confound from ROI so far
[beta,~,stats] = glmfit(all_conf_vals-mean(all_conf_vals),all_vals);
resid_BOLD = stats.resid + beta(1);
current_psc = resid_BOLD(end);
current_conf = all_conf_vals(end);

% Set PSC threshold for downregulation
PSC_thresh_down = -2; 

% Feedback value calculation (adjust as needed based on your specific ROI and task)
curr_feedback = round((current_psc / PSC_thresh_down), 2);

% First term in ROI_PSC is unaffected by changing PSC threshold setting
% Second term is affected due to changing PSC threshold
ROI_PSC = [ROI_PSC; current_psc, curr_feedback, current_conf, current_TBV_tr]; 

% Clamp the feedback value between 0.01 and 1
if curr_feedback < 0.01
    curr_feedback = 0.01;
elseif curr_feedback > 1
    curr_feedback = 1;
end
% Print the score for upregulation
fprintf('Downregulation score: %.2f\n', curr_feedback); 
end
%%%%%%%%%%%%%%%%%%%%%%VAS Function%%%%%%%%%%%%%%
function [block_start, block_end, block_dur, block_start_TR, block_end_TR, block_start_TBV_TR, block_end_TBV_TR, rating] = VAS_scale(window, scr_rect, instructionText, feedback_dir, feedback_file_name, fileID7, p, num_blocks, block_num, blockOrder) 
    global start_time current_TBV_tr TR; 

    % Parameters
    scaleMin = 0;
    scaleMax = 10;
    scaleStep = 1;
    scaleDuration = 10; % Duration in seconds before the scale closes automatically
    markerColor = [255, 0, 0]; % Red marker
    markerWidth = 20;
    scaleColor = [255, 255, 255]; % Scale color is white
    textColor = [255, 255, 255]; % Text color is white
    textSize = scr_rect(4) * 0.03; % Text size as 5% of the screen height
    smallTextSize = textSize; % Smaller text size for numbers and labels
    block_start = GetSecs() - start_time;
    block_start_TR = round(block_start / TR) + 1;
    block_start_TBV_TR = current_TBV_tr;

    % Set the text size ONCE before drawing anything 
    Screen('TextSize', window, round(scr_rect(4) * 0.03)); 

    

    % Scale parameters
    scaleLength = scr_rect(3) * 0.5; 
    scaleHeight = scr_rect(4) * 0.03; 
    scaleX = (scr_rect(3) - scaleLength) / 2; 
    scaleY = scr_rect(4) * 0.6; 

    % Calculate label positions
    labelOffsetX = scr_rect(3) * 0.1; 
    labelOffsetY = -12; 
    label1X = scaleX - labelOffsetX - 2;
    label1Y = scaleY - labelOffsetY;
    label2X = scaleX + scaleLength + 4;
    label2Y = scaleY - labelOffsetY;

    % Draw the scale
    Screen('FillRect', window, scaleColor, [scaleX, scaleY, scaleX + scaleLength, scaleY + scaleHeight]);
    for i = 0:10
        DrawFormattedText(window, num2str(i), scaleX + (i / 10) * scaleLength - 10, scaleY + scaleHeight + scr_rect(4) * 0.06, textColor);
    end

    % Draw the craving labels with smaller text size
    DrawFormattedText(window, 'No Craving', label1X, label1Y, textColor);
    DrawFormattedText(window, 'High Craving', label2X, label2Y, textColor);

    % Initial rating position
    rating = (scaleMin + scaleMax) / 2; 
    ratingPosition = scaleX + ((rating - scaleMin) / (scaleMax - scaleMin)) * scaleLength;

    % Display the VAS scale and capture user responses
    startTime = GetSecs();
    countdownDuration = 10; 
    countdownStartTime = GetSecs();
    
    % Draw the instruction text
    DrawFormattedText(window, instructionText, 'center', scr_rect(4) * 0.3, textColor);
    
    Screen('FillRect', window, scaleColor, [scaleX, scaleY, scaleX + scaleLength, scaleY + scaleHeight]);

    % Draw the rating marker
    Screen('FillRect', window, markerColor, [ratingPosition - markerWidth/2, scaleY - scaleHeight/2, ratingPosition + markerWidth/2, scaleY + scaleHeight * 1.5]);

    

    % Flip the screen
    Screen('Flip', window);


    while GetSecs() - startTime < scaleDuration

        % Check for key presses

        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(1, KbName('c'))
                rating = max(rating - scaleStep, scaleMin);
               
            elseif keyCode(1, KbName('d'))
                rating = min(rating + scaleStep, scaleMax);
                
            end
            % Update rating position
             ratingPosition = scaleX + ((rating - scaleMin) / (scaleMax - scaleMin)) * scaleLength;

            % Draw the scale
           
            % Draw the instruction text
            DrawFormattedText(window, instructionText, 'center', scr_rect(4) * 0.3, textColor);
            
            Screen('FillRect', window, scaleColor, [scaleX, scaleY, scaleX + scaleLength, scaleY + scaleHeight]);

            % Draw the rating marker
            Screen('FillRect', window, markerColor, [ratingPosition - markerWidth/2, scaleY - scaleHeight/2, ratingPosition + markerWidth/2, scaleY + scaleHeight * 1.5]);

            % Draw the numbers and labels again
            for i = 0:10
                DrawFormattedText(window, num2str(i), scaleX + (i / 10) * scaleLength - 10, scaleY + scaleHeight + scr_rect(4) * 0.06, textColor);
            end
            DrawFormattedText(window, 'No Craving', label1X, label1Y, textColor);
            DrawFormattedText(window, 'High Craving', label2X, label2Y, textColor);

          

            % Flip the screen
            WaitSecs(0.1);
            Screen('Flip', window);
        end


    % If no key is pressed, terminate execution
    if ~keyIsDown 
        disp('Experiment finished after the final VAS block.'); 
    end

    % Get the ending time of the block
    block_end = GetSecs() - start_time;
    block_dur = block_end - block_start;
    block_end_TR = round(block_end / TR);
    block_end_TBV_TR = current_TBV_tr;

  
    
    end
    fprintf(fileID7, '%d        %.2f        %d\n', p, block_end, rating);
end