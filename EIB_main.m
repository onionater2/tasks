
function EIB_main(subjID, run)
%  % 566 seconds, IPS=283
% e.g., =  EB_main('SAX_SLOC_01', 1)
% 
% exact presentation schedule must be determined in advance for each subject for each run (stored as e.g. sax_eib_01_sched_run01.mat)
% subjID = MUST END IN TWO NUMBERS (i.e., 01, 02, etc.)
% run = current run
% 
% 8 runs; 6 trials for each of 8 conditions/run; 4 sec video + 2ish sec cue response period per trial



warning off;
PsychJavaTrouble;
KbCheck;

rootDir = '/Users/saxelab/Documents/Experiments2/aesscripts/EIB_main/';
%rootDir = '/Users/amyskerry/Documents/Experiments2/aesscripts/EIB_main/';
cd(rootDir)

%% define where your behavioral and stim files are

stimdir				= fullfile(rootDir, '/stimfiles');
behavdir			= fullfile(rootDir, '/behavioural');
scheddir			= fullfile(rootDir, '/schedules');

%% get sub_num
sub_num = str2num(subjID(end-1:end)); %% GETs NUM FROM ID
sub_num_string=subjID;


numConds = 8;
videosperCond = 6; 
trialsPerRun = numConds*videosperCond;
TR=2;

videoDur = 4;
cueDur = 1.75;
blankDur = 0.25;
firstfixDur = 12;
lastfixDur = 12;
trialDur = videoDur + cueDur + blankDur;
RestTotal=254;

cd(scheddir)
%% get condition orders from file
scheduleFile= [sub_num_string '_sched_run0' num2str(run) '.mat'];
schedule=load(scheduleFile);
thisdesign=schedule.number(:,2);
thistiming=schedule.number(:,1);
s=size(thisdesign);
eventsPerRun=s(1);

%%to detect fuck-ups: make vector of actual onsets to compare to scheduled timing
onsets=zeros(eventsPerRun,1);

RT = zeros(eventsPerRun,1);
key = zeros(eventsPerRun,1);

%% make vector for items (this will be filled in with stimuli names)
item_orders=schedule.number(:,5);


%% some details
acceptableKeys=[30:34]; %% [89:92]
triggerKey= '+';
% Playbackrate defaults to 1:
rate=1;
cue='Respond';


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
oldEnableFlag = Screen('Preference', 'SuppressAllWarnings', 1);

%% instructions on screen
instructions = ['Rate the intensity of the target''s emotion.  neutral = 1  extreme = 4'];
Screen(window,'TextSize',30);
DrawFormattedText(window, instructions,'center','center',[255,255,255],40);

Screen('Flip',window);

cd(stimdir)


% wait for the 1st trigger pulse
while 1
    FlushEvents;
    trig = GetChar;
    if trig == triggerKey
        break
    end
end

% this is when the experiment starts
experimentStart = GetSecs;

% when triggered flip to black.
Screen('Flip',window);

conditionList=[];
for trialNum = 1:(eventsPerRun) 
    thiscond = thisdesign{trialNum};
    trialOnset=thistiming{trialNum};
    conditionList=[conditionList; thiscond];
                 Screen(window, 'TextSize', 34);
                 DrawFormattedText(window, '+','center','center',[255,255,255],40);
                 Screen('Flip',window);
                 
   if thiscond>0    %% if a real stimulus condition
    %%%get ready for movie presentation
    moviename=[stimdir '/' item_orders{trialNum,:} '.mp4'];
    [movie movieduration fps imgw imgh] = Screen('OpenMovie', window, moviename);
   end
                 
         while (GetSecs) < experimentStart + trialOnset
             % run up clock
         end
    onsets(trialNum)=GetSecs-experimentStart; %% for sanity check
 if thiscond>0    %% if a real stimulus condition
    
    %disp(['playing: ' moviename]);
    Screen('PlayMovie', movie, rate, 0, 1.0);
    itemNames{trialNum}=moviename;


    % Playback loop: Runs until end of movie
 while(GetSecs-onsets(trialNum)-experimentStart<videoDur-.2)
    % Wait for next movie frame, retrieve texture handle to it
    tex = Screen('GetMovieImage', window, movie);

    % Valid texture returned? A negative value means end of movie reached:
    if tex<=0
        % done, break
        break;
    end;

    % Draw the new texture immediately to screen:
    Screen('DrawTexture', window, tex);

    % Update display:
    Screen('Flip', window);

    % Release texture:
    Screen('Close', tex);
end
WaitSecs(.2);
Screen('CloseMovie', movie);
        cueStart=GetSecs;
    %print response cue on screen
    Screen(window,'TextSize',38);
    DrawFormattedText(window, cue,'center','center',[255,255,255],40);
    Screen('Flip',window);

while (GetSecs- experimentStart  < onsets(trialNum) + videoDur + cueDur);
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
            
  
    else
        %% if null trial, be boring
    Screen(window, 'TextSize', 34);
    DrawFormattedText(window, '+','center','center',[255,255,255],40);
    Screen('Flip',window);
    %% put something fake for RTs and keys
            RT(trialNum) = 0;
            key(trialNum) = 9999;
                  
 end 
end


%% add time at end
    Screen(window, 'TextSize', 34);
    DrawFormattedText(window, '+','center','center',[255,255,255],40);
    Screen('Flip',window);
stop = GetSecs;

while (GetSecs - stop)<lastfixDur
    % run up clock
end
experimentEnd = GetSecs;
experimentDuration = experimentEnd - experimentStart;
idealDuration=firstfixDur + trialsPerRun*(trialDur) + lastfixDur + RestTotal; %% based on last trial onset
Screen('CloseAll');


%% make yo life easier later

con_info(1).name = 'sh>su';
con_info(1).vals = [0 0 0 0 0 -1 0 1];
con_info(2).name = 'su>sh';
con_info(2).vals = [ 0 0 0 0 0 1 0 -1];
con_info(3).name = 'nh>nu';
con_info(3).vals = [0 0 0 0 -1 0 1 0];
con_info(4).name = 'nu>nh';
con_info(4).vals = [0 0 0 0 1 0 -1 0];
con_info(5).name = 'fh>fu';
con_info(5).vals = [0 -1 0 1 0 0 0 0];
con_info(6).name = 'fu>fh';
con_info(6).vals = [0 1 0 -1 0 0 0 0];
con_info(7).name = 'mh>mu';
con_info(7).vals = [-1 0 1 0 0 0 0 0];
con_info(8).name = 'mu>mh';
con_info(8).vals = [1 0 -1 0 0 0 0 0];
con_info(9).name = 'context_h>context_u';
con_info(9).vals = [0 0 0 0 -1 -1 1 1];
con_info(10).name = 'context_u>context_h';
con_info(10).vals = [0 0 0 0 1 1 -1 -1];
con_info(11).name = 'face_h>face_u';
con_info(11).vals = [-1 -1 1 1 0 0 0 0];
con_info(12).name = 'face_u>face_h';
con_info(12).vals = [1 1 -1 -1 0 0 0 0];
con_info(13).name = 'all_h>all_u';
con_info(13).vals = [-1 -1 1 1 -1 -1 1 1];
con_info(14).name = 'all_u>all_h';
con_info(14).vals = [1 1 -1 -1 1 1 -1 -1];
con_info(15).name = 'face>context';
con_info(15).vals = [1 1 1 1 -1 -1 -1 -1];
con_info(16).name = 'context>face';
con_info(16).vals = [-1 -1 -1 -1 1 1 1 1];
con_info(17).name = 'social>nonsocial';
con_info(17).vals = [0 0 0 0 -1 1 -1 -1];
con_info(18).name = 'nonsocial>social';
con_info(18).vals = [0 0 0 0 1 -1 1 -1];
con_info(19).name = 'male>female';
con_info(19).vals = [1 -1 1 -1 0 0 0 0];
con_info(20).name = 'female>male';
con_info(20).vals = [-1 1 -1 1 0 0 0 0];
% % con_info(21).name = 'mu';
% % con_info(21).vals = [1 0 0 0 0 0 0 0];
% % con_info(22).name = 'fu';
% % con_info(22).vals = [0 1 0 0 0 0 0 0];
% % con_info(23).name = 'mh';
% % con_info(23).vals = [0 0 1 0 0 0 0 0];
% % con_info(24).name = 'fh';
% % con_info(24).vals = [0 0 0 1 0 0 0 0];
% % con_info(25).name = 'nu';
% % con_info(25).vals = [0 0 0 0 1 0 0 0];
% % con_info(26).name = 'su';
% % con_info(26).vals = [0 0 0 0 0 1 0 0];
% % con_info(27).name = 'nh';
% % con_info(27).vals = [0 0 0 0 0 0 1 0];
% % con_info(28).name = 'sh';
% % con_info(28).vals = [0 0 0 0 0 0 0 1];
% 
% con_info(21).name='pos';    
% con_info(21).vals=[0 0 1 1 0 0 1 1];
% con_info(22).name='neg';
% con_info(22).vals=[1 1 0 0 1 1 0 0];
% con_info(23).name='pos_c';
% con_info(23).vals=[0 0 0 0 0 0 1 1];
% con_info(24).name='pos_f';
% con_info(24).vals=[0 0 1 1 0 0 0 0];
% con_info(25).name='neg_c';
% con_info(25).vals=[0 0 0 0 1 1 0 0];
% con_info(26).name='neg_f';
% con_info(26).vals=[1 1 0 0 0 0 0 0];
% con_info(27).name='pos_s';
% con_info(27).vals=[0 0 0 0 0 0 0 1];
% con_info(28).name='pos_n';
% con_info(28).vals=[0 0 0 0 0 0 1 0];
% con_info(29).name='neg_s';
% con_info(29).vals=[0 0 0 0 0 1 0 0];
% con_info(30).name='neg_n';
% con_info(30).vals=[0 0 0 0 1 0 0 0];
% con_info(31).name='pos_male';
% con_info(31).vals=[0 0 1 0 0 0 0 0];
% con_info(32).name='pos_fema';
% con_info(32).vals=[0 0 0 1 0 0 0 0];
% con_info(33).name='neg_male';
% con_info(33).vals=[1 0 0 0 0 0 0 0];
% con_info(34).name='neg_fema';
% con_info(34).vals=[0 1 0 0 0 0 0 0];
% con_info(35).name='social';
% con_info(35).vals=[0 0 0 0 0 1 0 1];
% con_info(36).name='nonsoc';
% con_info(36).vals=[0 0 0 0 1 0 1 0];
% con_info(37).name='face';
% con_info(37).vals=[1 1 1 1 0 0 0 0];
% con_info(38).name='cont';
% con_info(38).vals=[0 0 0 0 1 1 1 1];

    
%label using the selected conditions 
condnames = {'mu', 'fu', 'mh', 'fh', 'nu', 'su', 'nh', 'sh'}; %% order of conditions here must be aligned with column/condition order in eib_stimuli.mat, since that established relationship between condition number and actual condition content
    
%timing stuff

ips = idealDuration/TR; 
videoTR = (videoDur)/TR; 
labeledonsets = [thisdesign thistiming];

sorted_RTs=zeros(videosperCond,numConds);
sorted_keys=zeros(videosperCond,numConds);

 for c=1:numConds
        sorted_RTs(:,c)  = RT(conditionList == c)'; 
        sorted_keys(:,c)  = key(conditionList == c)';
    end;
    


for index = 1:numConds
    spm_inputs(index).name = condnames{index};
        use=find([labeledonsets{:, 1}]==index);
        ons=cell2mat(labeledonsets(:,2));
    spm_inputs(index).ons = ons(use)/TR+1;
    spm_inputs(index).dur = 5.75/TR;

end


actualOnsets=onsets;
idealOnsets=thistiming;



%cd(rootDir);
cd (behavdir);
save([subjID '.EIB_main.' num2str(run) '.mat'], 'RT', 'key', 'sorted_RTs', 'sorted_keys', 'subjID', 'run', 'item_orders', 'trialsPerRun', 'experimentDuration', 'idealDuration', 'actualOnsets', 'idealOnsets', 'ips','con_info', 'spm_inputs');
ShowCursor;
Screen('CloseAll');
cd(rootDir);
warning on;
clear all;

end %main function

