function SVL(subjID, randseed)

% function SVL (Subjective Value Localizer)
% written by Emile Bruneau, 2/25/14, updated by Laura Ligouri 4/1/14, updated
% by Emile Bruneau 5/11/14. updated by AES 5/22/14

% localizer to identify regions associated with reward
% 48 numbers ($0.00 - $1.00) appear randomly onscreen indicating
% amount participants is being rewarded as a bonus

% 1 run total

% number presentation: 3 seconds
% jittered isi: average 5 seconds
% 48 trials/run
% Run duration = 12 + (3 + 5)*48 + 12 = 408 seconds (ips = 204) = 6 min 48
% sec

%% Results matrix will be a Nx3 matrix where each column is:
% 1 = money awarded
% 2 = stimulus onsets (in seconds)

%% Basic setup

results = [];
run = 1;            % needed for naming convention
rand('twister',randseed);

PsychJavaTrouble

%% Path Info and Design & Item Stuff
comproot='/Users/amyskerry/';
%comproot='/Users/saxelab/'
rootdir = [comproot, '/Documents/Experiments2/aesscripts/svalue/'];
behavdir = [rootdir, 'behavioural/'];

% Identify attached keyboard devices:
devices=PsychHID('devices');
[dev_names{1:length(devices)}]=deal(devices.usageName);
kbd_devs = find(ismember(dev_names, 'Keyboard')==1);

%% Setup screen

displays = Screen('screens');
[onScreen, screenRect] = Screen('OpenWindow', displays(end), [0 0 0]);
% Just there in case we want to present nice, anti-aliased graphics
Screen('BlendFunction', onScreen, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
Screen('TextSize', onScreen, 40);
Screen(onScreen, 'TextFont', 'Helvetica');
textColor = [255 255 255];
[x0,y0] = RectCenter(screenRect);

%% Counter-balancing

stims =     [0.00 0.00 0.00 0.01 0.01 0.05 0.05 0.10 0.10 0.15 0.15 0.20 0.20 0.25...
             0.25 0.30 0.30 0.35 0.35 0.40 0.40 0.45 0.45 0.50 0.50 0.55 0.55 0.60...
             0.60 0.65 0.65 0.70 0.70 0.75 0.75 0.80 0.80 0.85 0.85 0.90 0.90 0.95...
             0.95 0.99 0.99 1.00 1.00 1.00];
stimsLow =  [0.00 0.00 0.00 0.01 0.01 0.05 0.05 0.10 0.10 0.15 0.15 0.20 0.20 0.25...
             0.25 0.30 0.30 0.35 0.35 0.40 0.40 0.45 0.45 0.50];
stimsHigh = [0.50 0.55 0.55 0.60 0.60 0.65 0.65 0.70 0.70 0.75 0.75 0.80 0.80 0.85...
             0.85 0.90 0.90 0.95 0.95 0.99 0.99 1.00 1.00 1.00];
stimsLow_Shuffled = Shuffle(stimsLow);
stimsHigh_Shuffled = Shuffle(stimsHigh);

trialsPerRun = 48;                  
numConds = 2;                       % high (> $0.50) or low (< $0.50)
cycledNumbers = 10;                 % how many random numbers are cycled through before landing on bonus

% COULD OPTIMIZE DESIGN! (would have to have fewer conditions (e.g. $0.10
% intervals from $0.00 to $1.00))
design =    [1 2 2 2 1 1 2 2 1 2 2 1 2 1 1 2 2 1 1 1 2 2 1 1 1 1 2 2 1 1 1 2 2 1 1 2 1 2 2 1 2 2 1 1 2 2 2 1];

stimDur = 3;                        % total stimulus duration (numbers)
cycledDur = 1;                      % how long random numbers cycle for before landing on bonus
bonusDur = 2;                       % how long bonus remains on screen
fixDur = 12;                        % fixation at beginning and end of study
baseFixDur = 5;                     % average fixation time between stimDur
TR = 2;
jitters = Shuffle([ones(1,16)*(baseFixDur) ones(1,16)*(baseFixDur-TR) ones(1,16)*(baseFixDur+TR)]);     % SHOULD CHANGE THIS TO RANDOM SO ORDER CAN BE RECAPITULATED!
expectedIPS = fixDur + ((stimDur + baseFixDur) * trialsPerRun) + fixDur     % 12 + (3 + 5)*48 + 12 = 408 s = 204 TRs = 6 min 48 sec

onsets = zeros(trialsPerRun,1);

% bring commandwindow to the front, if it isn't already
commandwindow;

%% display opening instructions

instructions = 'Now comes the fun part! In this run, we are going to determine how much bonus money you get for coming in today. To make this a bit more interesting, we will be awarding you money, roulette style. Every few seconds, numbers between $0.00 and $1.00 will flash across the screen, and when the number lands on its final value, it will turn green. Each of these green values will be added up and awarded to you as a cash bonus at the end of the study! Please press the (1) button when each green final value appears.';
DrawFormattedText(onScreen, instructions, 'center', y0-200, textColor, 60, [], [], 1.25);
Screen('Flip', onScreen);

% reset all keys, wait for trigger pulse from the scanner
while 1
    FlushEvents;
    trig = GetChar;
    if trig == '+'
        break
    end
end
DrawFormattedText(onScreen, '+','center','center',[255,255,255],40); %aes added fixation cross
Screen('Flip', onScreen);

%% Calculations during ISI

% stim counters
stimsLow_counter = 0;
stimsHigh_counter = 0;

experimentStart	= GetSecs();
while GetSecs() < experimentStart + fixDur; end

%% Main Trial loop: for each trial, present 10 random numbers, each for 100ms, then present bonus award amount

for thisTrial = 1:trialsPerRun
    % determine 10 random numbers to present for the trial
    randAward = zeros(1,10);
    for i = 1:cycledNumbers
        randomizer = stims(randperm(48));
        randAward(i) = randomizer(i);
    end
    
    % determine 1 bonus amount to present for the trial
    if design(thisTrial) == 1
        thisBonus = stimsLow_Shuffled(stimsLow_counter+1);
        stimsLow_counter = stimsLow_counter + 1;
    else
        thisBonus = stimsHigh_Shuffled(stimsHigh_counter+1);
        stimsHigh_counter = stimsHigh_counter + 1;
    end
    
    trialStart = GetSecs;

    results(thisTrial,1) = thisBonus;
    results(thisTrial,2) = (round(GetSecs-experimentStart)/TR)+1;
    onsets(thisTrial,1) = (round(GetSecs-experimentStart)/TR)+1;    % redundant saving of onsets; also used to calculate spm .ons values
    
    % present 10 random numbers, each for 100 ms
    for cycledAward = 1:cycledNumbers
        instantAward = randAward(cycledAward);
        DrawFormattedText(onScreen,['$ ' num2str(instantAward,'%.2f')], 'center', 'center', textColor, 60, [], [], 1.25);
        Screen('Flip', onScreen);
        % present each number for 100 ms
        while  GetSecs() < (trialStart + ((cycledDur/cycledNumbers)*cycledAward)); end
    end
            
    % present 1 bonus amount for 2 seconds
    DrawFormattedText(onScreen,['$ ' num2str(thisBonus,'%.2f')], 'center', 'center', [0 255 0], 60, [], [], 1.25); %aes replaced y0-200 with 'center'
    Screen('Flip', onScreen);
    while  GetSecs < (trialStart + cycledDur + bonusDur); end
    DrawFormattedText(onScreen, '+','center','center',[255,255,255],40); %aes added fixation cross
    Screen('Flip', onScreen);
    while GetSecs < (trialStart + cycledDur + bonusDur) + jitters(thisTrial); end
end
extra_fix_start = GetSecs;
while GetSecs - extra_fix_start < fixDur;pause(0.01); end
experimentDur = GetSecs - experimentStart;
ips = round(experimentDur/TR);


%% for analysis, save information
condnames = {'1_LowBonus', '2_HighBonus'};
sortedonsets = sortrows([[design]' onsets(:,1)]);

% for straight contrast, high versus low values
spm_inputs1(1).name = condnames{1};
spm_inputs1(1).ons = sortedonsets(find(sortedonsets(:,1)==1),2);
spm_inputs1(1).dur = ones(trialsPerRun / numConds,1) * ((bonusDur) / 2);
spm_inputs1(2).name = condnames{1};
spm_inputs1(2).ons = sortedonsets(find(sortedonsets(:,1)==2),2);
spm_inputs1(2).dur = ones(trialsPerRun / numConds,1) * ((bonusDur) / 2);

% for parametric analysis by bonus value
spm_inputs2(1).name = 'svl';
spm_inputs2(1).ons = sortedonsets(:,2);
spm_inputs2(1).dur = stimDur/TR;
spm_inputs2(1).pmod.name = 'value';
spm_inputs2(1).pmod.param = results(:,1);

% save contrast behavioral file
con_info(1).name = 'High versus Low';
con_info(1).vals = [-1 1] ;
cd(fullfile(rootdir,'behavioural'));
spm_inputs = spm_inputs1;
save ([subjID '.svl.' num2str(run) '.mat'], 'subjID','design','sortedonsets','experimentDur','spm_inputs','ips','con_info','results','jitters');

% save parametric behavioral file
con_info(1).name = 'Parametric';
con_info(1).vals = [0 1 0] ;
spm_inputs = spm_inputs2;
save ([subjID '.svlp.' num2str(run) '.mat'], 'subjID','design','sortedonsets','experimentDur','spm_inputs','ips','results','jitters');

ShowCursor;
Screen('CloseAll')


