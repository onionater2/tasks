function FGE_main(subjID, run)
%  created by AES 5/1/14
%  % xxx seconds, IPS=xxx
% e.g., FGE_main('SAX_FGE_01', 1)

subjIdNum=str2num(subjID(end-1:end));

rootDir = '/Users/amyskerry/Documents/Experiments2/aesscripts/FGE_main/';
cd(rootDir)

%% define where your behavioral and stim files are
stimdir				= fullfile(rootDir, '/stimfiles/');
behavdir			= fullfile(rootDir, '/behavioural/');
scheddir			= fullfile(rootDir, '/schedules/');
stimfile=[stimdir, '/FGE_stims.mat'];
namesfile=[stimdir, '/names.mat'];

%% get scheduling info
scheduleFile= [scheddir, subjID '_sched_run0' num2str(run) '.mat'];
sched=load(scheduleFile);
idealOnsets=sched.onsets/10;
item_orders=sched.stims;
stimnums=sched.stimnums;
conditions=sched.conds;

%%load up the stims
stims=load(stimfile);
names=load(namesfile);
trialdurs=stims.durs/10;
stimtexts=stims.text;
%%design details
trialsPerRun=size(idealOnsets,2)
TR=2;
responseDur = 2;
ips=500/100;

%names for this trial
names=names.names(trialsPerRun*(run-1)+1:trialsPerRun*(run))

%%to detect fuck-ups: make vector of actual onsets to compare to scheduled timing
actualOnsets=zeros(trialsPerRun,1);

%% some details

warning off;
PsychJavaTrouble;
KbCheck;

triggerKey= '+';
cue='+';

% get screen ready to go
% Identify attached keyboard devices:
devices=PsychHID('devices');
[dev_names{1:length(devices)}]=deal(devices.usageName);
kbd_devs = find(ismember(dev_names, 'Keyboard')==1);

HideCursor;
displays = max(Screen('screens')); %Highest screen number is most likely correct display


[window,screenRect] = Screen('OpenWindow', displays, [0 0 0]);%         
[x0,y0] = RectCenter(screenRect); %sets Center for screenRect (x,y)

% Setting this preference to 1 suppresses the printout of warnings.
%oldEnableFlag = Screen('Preference', 'SuppressAllWarnings', 1);

%% instructions on screen
instructions = ['Please lie as still as possible and concentrate on the stories.'];
Screen(window,'TextSize',30);
DrawFormattedText(window, instructions,'center','center',[255,255,255],40);
Screen('Flip',window);

%% get other stuff ready
RT = zeros(trialsPerRun,1);
key = zeros(trialsPerRun,1);
trialList=[];
actualOnsets=zeros(trialsPerRun,1);
%%get next screen ready
Screen(window, 'TextSize', 34);
DrawFormattedText(window, '+','center','center',[255,255,255],40);
%% wait for the 1st trigger pulse
while 1
    FlushEvents;
    trig = GetChar;
    if trig == triggerKey
        break
    end
end
Screen('Flip',window);
%% this is when the experiment starts
experimentStart = GetSecs;
for trialNum = 1:trialsPerRun
    %figure out what and when we are presenting
    stimnum=stimnums(trialNum);
    stimtext=stimtexts(stimnum,:);
    name=names{trialNum};
    stimtext=strrep(stimtext, 'NAMEVAR', name)
    Screen(window, 'TextSize', 34);
    %get text ready
    DrawFormattedText(window, stimtext,'center','center',[255,255,255],40);
    trialList=[trialList; item_orders(trialNum, :)];
    
    %wait until it's time for trial
    while (GetSecs) - experimentStart < idealOnsets(trialNum)
       % run up clock waiting for onset
    end
    %actualOnsets(trialNum)=GetSecs-experimentStart
    Screen('Flip',window); %flip trial
    actualOnsets(trialNum)=GetSecs-experimentStart;
    
    %get response screen ready
    Screen(window, 'TextSize', 34);
    DrawFormattedText(window, 'Respond','center','center',[255,255,255],40);
    
    %wait until it's time for response
    while (GetSecs) - experimentStart - idealOnsets(trialNum) < trialdurs(trialNum)
       %run up trial
    end
    Screen('Flip',window); %flip response
    cueStart= GetSecs;
    
    %get rest screen ready
    Screen(window, 'TextSize', 34);
    DrawFormattedText(window, '+','center','center',[255,255,255],40);
    
    %wait until it's time for rest 
    while (GetSecs) - experimentStart - idealOnsets(trialNum) - trialdurs(trialNum) < responseDur
        %run up response window
        [keyIsDown,secs,keyCode]=KbCheck(-3); %% -3 for all keyboards and keypads, -1 is just all keyboards, but both should work. KbCheck(end) would get input from last device plugged in, which should also work
        if keyIsDown
        button = find(keyCode); %% figure out which key you found
        thiskey = KbName(button(1)); %% figure out its name (taking only the first button if subjects hit more than one)
        thiskey = str2num(thiskey(1)); %% make it a string, taking only the first (since KbName can return multiple e.g. 1! instead of 1)
        if ~isempty(thiskey) & (RT(trialNum) == 0) & any(thiskey==1:4) %%% %be sure there's a number, and that you haven't already recorded a response, and that it matches your button box. now can match it based on the actual numeric values, none of this 89:92 bullshit!
            RT(trialNum) = GetSecs - cueStart;
            key(trialNum) = thiskey;
        end
       end
    end
    Screen('Flip',window); %flip rest
end
%wait until the exp is over
while (GetSecs) - experimentStart < ips
   %run up until IPS
end

experimentEnd		= GetSecs;
experimentDuration	= experimentEnd - experimentStart;

%make SPM inputs
conds=unique(conditions,rows)
for c=1:length(conds)
    spm_inputs(c).name = conds(c);
    use=find(conditions(:, 1)==c);
    theseonsets(:,c)=onsets(use); %% in seconds
    spm_inputs(c).ons = onsets(use)/TR;  %% in TR     
    spm_inputs(c).dur  = trialdurs(use)/TR;
end;
    
%make con info
con_info(1).name = 'sh>su';
con_info(1).vals = [0 0 0 0 0 -1 0 1];

sorted_RTs=zeros(videosperCond,numConds);
sorted_keys=zeros(videosperCond,numConds);

for c=1:length(conds)
  sorted_RTs(:,c)  = RT(conditionList == c)'; 
  sorted_keys(:,c)  = key(conditionList == c)';
end;

save([behavedir, subjID '.FGE_main.' num2str(run) '.mat'], 'RT', 'key', 'sorted_RTs', 'sorted_keys', 'subjID', 'run', 'item_orders', 'trialsPerRun', 'experimentDuration', 'idealDuration', 'actualOnsets', 'idealOnsets', 'ips','con_info', 'spm_inputs');
ShowCursor;
Screen('CloseAll');
cd(rootDir);
warning on;
clear all;

end