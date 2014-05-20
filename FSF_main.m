
function FSF_main(subjID, run)
%  created by AES 10/6/13
%  % 512 seconds, IPS=256
% e.g., FSF_main('SAX_FSF_01', 1)
% 
subjIdNum=str2num(subjID(end-1:end));
runlabels=['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']; % within stimdir there should be 8 dirs (one for each run) called run_a, run_b etc. each should contain the 4 movies that appear together in that run
%%%counterbalancing
runindexes={
[1 2 3 4 5 6 7 8]    
[4 1 5 2 3 6 7 8];
[8 5 3 6 4 1 7 2];
[3 7 2 6 1 8 4 5];
[1 2 4 5 6 7 8 3];
[5 7 8 2 6 4 3 1];
[7 6 5 2 3 1 8 4];
[2 5 3 1 8 6 4 7];
[6 2 4 1 5 3 7 8];
[3 8 4 6 2 5 1 7]; 
[2 3 7 1 5 4 8 6];  
[6 7 2 3 1 4 8 5];
[4 2 5 3 7 1 8 6];
[7 4 8 1 6 5 2 3];
[5 6 1 3 8 2 7 4];
[1 8 3 7 4 5 6 2];
[8 4 1 7 6 3 2 5];
[7 5 2 3 4 6 8 1];
[1 8 5 2 6 4 7 3];
[4 1 5 2 8 7 3 6];
[8 2 5 6 7 4 3 1];
[5 7 2 8 3 1 6 4];
[2 6 3 5 1 4 8 7];
[3 1 2 5 4 7 6 8];
[6 5 8 1 4 3 7 2];
};

thissubjrundesign=runindexes{subjIdNum,:};
thisrundesign=runlabels(thissubjrundesign);
thisrun=thisrundesign(run);

warning off;
PsychJavaTrouble;
KbCheck;

%rootDir = '/Users/saxelab/Documents/Experiments2/FSF_main/';
rootDir = '/Users/amyskerry/Documents/Experiments2/FSF_main/';
cd(rootDir)

%% define where your behavioral and stim files are
rundir=['/stimfiles/run_' thisrun];
stimdir				= fullfile(rootDir, rundir);
behavdir			= fullfile(rootDir, '/behavioural');


vidsPerRun = 4;
videonames=dir([stimdir '/FSF*.mp4']);
thisdesign=shuffle(videonames); %order of 4 videos within a run is just shuffled randomly
TR=2;

videoDur = 120;
blankDur = 2;
firstfixDur = 12;
lastfixDur = 12;
trialDur = videoDur + blankDur;
idealOnsets=firstfixDur;
for v=1:vidsPerRun-1
idealOnsets(v+1,1)=[idealOnsets(v)+trialDur];    
end


eventsPerRun=size(thisdesign,1);

%%to detect fuck-ups: make vector of actual onsets to compare to scheduled timing
actualOnsets=zeros(eventsPerRun,1);


%% some details

triggerKey= '+';
cue='+';
% Playbackrate defaults to 1:
rate=1;
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
instructions = ['Please lie as still as possible and concentrate on the video clips.'];
Screen(window,'TextSize',30);
DrawFormattedText(window, instructions,'center','center',[255,255,255],40);

Screen('Flip',window);
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
% when triggered flip .
Screen('Flip',window);

eventList=[];
for trialNum = 1:eventsPerRun
    moviename = thisdesign(trialNum,:).name;
    thisevent=moviename(1:end-4);
    spm_inputs(trialNum).name=thisevent;
    trialOnset=idealOnsets(trialNum);
    spm_inputs(trialNum).ons=trialOnset/2+1;
    spm_inputs(trialNum).dur=videoDur;
    eventList=[eventList; thisevent];
    Screen(window, 'TextSize', 34);
    DrawFormattedText(window, '+','center','center',[255,255,255],40);
    Screen('Flip',window);
                 
   %%%get ready for movie presentation
    moviefile=[stimdir '/' moviename]
    [movie movieduration fps imgw imgh] = Screen('OpenMovie', window, moviefile);
              
         while (GetSecs) < experimentStart + trialOnset
             % run up clock
         end
    actualOnsets(trialNum)=GetSecs-experimentStart; %% for sanity check
   
    %disp(['playing: ' moviename]);
    Screen('PlayMovie', movie, rate, 0, 1.0);
    itemNames{trialNum}=moviename;

    % Playback loop: Runs until end of movie
 while(GetSecs-idealOnsets(trialNum)-experimentStart<videoDur)
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
%WaitSecs(.2);
Screen('CloseMovie', movie);
        cueStart=GetSecs;
    %print response cue on screen
    Screen(window,'TextSize',34);
    DrawFormattedText(window, '+','center','center',[255,255,255],40);
    Screen('Flip',window);

while (GetSecs- experimentStart  < idealOnsets(trialNum) + videoDur + blankDur -.2); % -.2 because prepping next event is nonnegligable
 %waiting
end
                         
 end 



%% add time at end
    Screen(window, 'TextSize', 34);
    DrawFormattedText(window, '+','center','center',[255,255,255],40);
    Screen('Flip',window);
    stop = GetSecs;

while (GetSecs - stop)<lastfixDur +.2
    % run up clock
end
experimentEnd = GetSecs;
experimentDuration = experimentEnd - experimentStart;
idealDuration=firstfixDur + vidsPerRun*(trialDur) + lastfixDur; %% based on last trial onset
Screen('CloseAll');


%timing stuff

ips = idealDuration/TR; 
videoTR = (videoDur)/TR; 
labeledonsets = [eventList idealOnsets];


%cd(rootDir);
cd (behavdir);
save([subjID '.FSF_main.' num2str(run) '.mat'], 'subjID', 'run', 'vidsPerRun', 'eventList', 'experimentDuration', 'idealDuration', 'actualOnsets', 'idealOnsets', 'ips', 'spm_inputs');
ShowCursor;
Screen('CloseAll');
cd(rootDir);
warning on;
clear all;

end %main function

