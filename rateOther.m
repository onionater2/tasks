function rateOther(subID)
%e.g. 'sax_eib_02'
% Felt Understanding Self-Ratings v.01
%
% This script contains the program for the first session of the Felt
% Understanding study.  It requires a computer with MATLAB 7, PsychToolbox
% 3, and Quicktime 7 installed.

warning off;
PsychJavaTrouble;
KbCheck;



%% Directory management
% Change studyDir to the folder containing all subject folders for the FU
% study; make sure it includes the necessary '\' or '/' at the end of this
% string.  There must also be a folder called 'scale_images' inside this
% directory.  Subject folders must contain the videos used in this task.
startDir = pwd;
studyDir = '/Users/amyskerry/Documents/Experiments2/aesscripts/EA_rating/';
subDir = sprintf('%s%s',studyDir,'results/');
stimuliDir = sprintf('%s%s',studyDir,'stimuli/');
scaleImgDir = sprintf('%sscale_images',studyDir);

cd(stimuliDir);

%% Verify movies
    movs = dir('*.mp4');
    for i=1:size(movs,1)
        movieList{i,1}=movs(i).name;
    end
    numberTrials = size(movieList,1);
    

%% Create the structure for recording responses from the experiment:
subjectStructName=sprintf('subject_%s',subID);

% Overwrite check:
for i = 1:numberTrials
    currentTrial=num2str(i);
    outputFilename = sprintf('subject_%s_trial%s_output.txt',subID,currentTrial);
    if (exist(outputFilename,'file')==2)
        queryOverwriteString = sprintf('\nThe output for subject %s trial %s exists.  Do you wish to OVERWRITE it [y/n]? ',subID,currentTrial);
        queryOverwrite = input(queryOverwriteString,'s');
        if strcmpi(queryOverwrite, 'N') || strcmpi(queryOverwrite, 'NO')
            fprintf('Overwrite permission denied by user.  Closing task...')
            return;
        else
            fprintf('The task will overwrite previous data.\n')
            fprintf('Press any key to continue or Ctrl+C to abort...\n\n')
        end; % if (strcmpi)
    end; % if (exist(outputFilename)==2)
end; % for i = 1:numberTrials



% get screen ready to go
% Identify attached keyboard devices:
devices=PsychHID('devices');
[dev_names{1:length(devices)}]=deal(devices.usageName);
kbd_devs = find(ismember(dev_names, 'Keyboard')==1);

%% Switch KbName into unified mode
% It will use the names of the OS-X platform on all platforms in order to
% make this script portable:
 KbName('UnifyKeyNames')

HideCursor;

% Assign keycodes for inputs
esc=KbName('ESCAPE');
r=KbName('r');
s=KbName('s');
up=KbName('RIGHTARROW');
down=KbName('LEFTARROW');
enter=KbName('Return');
space=KbName('SPACE');

try
    %% Setup Displays
    % Child protection: Make sure we run on the OSX / OpenGL Psychtoolbox.
    % Abort if we don't:
    AssertOpenGL;
    
    % If there are multiple displays guess that one without the menu bar is
    % the best choice.  Dislay 0 has the menu bar.
    screens=Screen('Screens');
    screenNumber=max(screens);
    
    % This will open a screen with default settings, aka black background,
    % fullscreen, double buffered with 32 bits color depth:
    Screen('Resolution', screenNumber, 800, 600);
    win = Screen('OpenWindow', screenNumber); %, [], [0 0 800 600]);
    
    % Give the display a moment to recover from the change of display mode
    % when opening a window. It takes some monitors and LCD scan converters a
    % few seconds to resync.
    WaitSecs(2);
    
    % Hide the mouse cursor:
    HideCursor;
    
    % Disable the keyboard from sending inputs to otherwindows:
    %ListenChar(2);
    
    % Assigning a black background color:
    background=[0, 0, 0];
    
    %% Preloading Images
    % images
    cd(scaleImgDir);
    scale{1}=imread('scale1.png');
    scale{2}=imread('scale2.png');
    scale{3}=imread('scale3.png');
    scale{4}=imread('scale4.png');
    scale{5}=imread('scale5.png');
    scale{6}=imread('scale6.png');
    scale{7}=imread('scale7.png');
    scale{8}=imread('scale8.png');
    scale{9}=imread('scale9.png');
    cd(subDir);
    
    %% Display Instruction Screen
    % Draw clear screen of background color to back buffer (can replace with DrawFormattedText):
    Screen('FillRect', win, background);
    
    % Draw instructions to background buffer:
    tsize=22;
    Screen('TextSize', win, tsize);
    tfont='arial';
    Screen('TextFont', win, tfont);
    Screen('TextColor', win, [255 255 255]);
    instructText1 = 'Judging emotions';  
    instructText2 = 'Please continuosly rate how you think the target was feeling WHILE RECORDING EACH VIDEO. Do NOT rate how they were feeling at the time of the event.';
    instructText3 = 'Use the scale from 1 (very negative) to 9 (very positive) to rate how they were feeling in each moment throughout the entire video.' 
    instructText4 = 'It is especially important that you move the scale EACH TIME the feelings in the video change in a MAJOR WAY.';
    instructText5 = 'Use the scale at the bottom of the video screen to make these ratings by pressing the left or right arrow keys to adjust the scale.  The scale will start at 5 with the beginning of each new video.';
    [x,y] = DrawFormattedText(win, instructText1,20, 20, [], 70, [], [], 1.5);
    [x,y] = DrawFormattedText(win, instructText2,20, y+(2.25*tsize), [], 70, [], [], 1.5);
    [x,y] = DrawFormattedText(win, instructText3,20, y+(3*tsize), [], 70, [], [], 1.5);
    [x,y] = DrawFormattedText(win, instructText4,20, y+(3.5*tsize), [], 70, [], [], 1.5);
    [x,y] = DrawFormattedText(win, instructText5,20, y+(4*tsize), [], 70, [], [], 1.5);
    
    % Flip buffers to display instructions:
    Screen('Flip',win);
    
    % Wait for keypress + release:
 k=99;
 while k==99
k=waitforbuttonpress;
 end

    
    %% Scale Demo
    
    % Set text for demo screen:
    demoText1 = 'Use the practice scale below to familiarize yourself with the actual scale you will use to make the ratings during the videos.  It will continuosly record whatever value the scale is set to at any moment.  Press the left and right arrow keys to navigate the scale.  Press SPACE at any time to end the demo and begin the first video.';
    
    % Populate variables for scale display location:
    scaleValue = 5;
    [wWidth, wHeight] = Screen('WindowSize', win);
    scaleDims = size(scale{1});
    scale_imgh = scaleDims(1);
    scale_imgw = scaleDims(2);
    scaleLocation = [round(wWidth*.1); round(wHeight-(scale_imgh*(wWidth*.8/scale_imgw))); round(wWidth*.90); wHeight];
    pressTimeStamp = 0;
    keyCode = 0;
    demoEnd = false;
    
    % Draw the first scale on the screen:
    while (demoEnd==false)
        DrawFormattedText(win, demoText1, 20, 75, [], 57, [], [], 1.5);
        scaleTexture = Screen('MakeTexture', win, scale{scaleValue});
        Screen('DrawTexture', win, scaleTexture, [], scaleLocation);
        % Flip the display to show the image at next retrace:
        Screen('Flip', win);
        
        % Delete the movie and scale textures. We don't need them anymore:
        Screen('Close', scaleTexture);
        scaleTexture = 0;
        
        % Get a timestamp for the last draw of the scale image:
        checkTimeStamp = GetSecs;
        
        % Done with drawing. Check the keyboard for subjects response:
        [keyIsDown, secs, keyCode]=KbCheck;
        if (keyIsDown==1 && ((checkTimeStamp-pressTimeStamp)>.1) ...
                && (keyCode(space) || ...
                (keyCode(up)&&scaleValue~=9) || ...
                (keyCode(down)&&scaleValue~=1)))
            
            pressTimeStamp = GetSecs;
            
            if keyCode(up) && scaleValue~=9,
                scaleValue=scaleValue+1;
            elseif keyCode(down) && scaleValue~=1,
                scaleValue=scaleValue-1;
            elseif keyCode(space),
                demoEnd=true;
            end; % if (keyCode)
            
            if (demoEnd==true)
                break;
            end; % if (demoEnd==true)
        end; % if (keyIsDown==1)...
        
        if (demoEnd==true)
            break;
        end; % if (demoEnd==true)
    end; % while ~(keyCode(space))
    
    % Show cleared screen:
    Screen('FillRect', win, background);
    Screen('Flip',win);
    
    % Wait a second...
    WaitSecs(1);
    
    %% First Ready Screen
    % Display the first ready screen and wait for button press
    % DrawFormattedText gets additional inputs:
    %   sx - each line of text is horizontally centered in the window
    %   sy - the whole text is vertically centered in the window
    %   color - set color of text via [r g b] or [r g b a], leave out to use
    %           the same color as before
    %   wrapat - set the number of characters to display before making a new line
    Screen('FillRect', win, background);
    firstScreenText= 'Prepare for the first trial.\n\nPress any key when ready.';
    DrawFormattedText(win, firstScreenText, 'center','center', [0 0 255], 40);
    Screen('Flip',win);
    WaitSecs(.3);
    
    KbWait;
    while KbCheck; end;
    
    % Show cleared screen:
    Screen('FillRect', win, background);
    Screen('Flip',win);
    
    % Wait a second:
    WaitSecs(1);
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%
    %%%Begin Trial Loop%%%
    %%%%%%%%%%%%%%%%%%%%%%
    
    i = 1;
    while i<=numberTrials
        % Establish variables for each trial:
        movieTexture=0;     % Texture handle for the current movie frame.
        scaleTexture=0;     % Texture handle for the current scale image.
        movieLocation=[];   % Matrix for movie display location.
        scaleLocation=[];   % Matrix for scale display location.
        scaleValue=5;       % Current value of the scale.
        queryEscape=false;  % Flag for cancelling out of the script.
        queryRestart=false; % Flag for restarting current trial.
        querySkip=false;    % Flag for skipping current trial.
        pressCount=0;       % Variable tracking the number of key presses during the trial.
        pressTimeStamp=0;   % Variable recording time stamp of most recent button press.
        scaleRecord=0;      % Variable recording scale values of key presses.
        oldScaleRecord=0;   % Variable recording old values of scale for each key press.
        responseTime=0;     % Variable recording response time of key press (relative to current trial start).
        
        %% Open Movie and Begin Playback
        % Open the moviefile and query some infos like duration, framerate,
        % width and height of video frames:
        [movie movieDur fps movie_imgw movie_imgh] = Screen('OpenMovie', win, [stimuliDir, movieList{i}]);
        % We estimate framecount instead of querying it - faster:
        framecount = movieDur * fps;
        
        % Play 'movie', at a playbackrate = 1 (normal speed forward),
        % play it once, aka with loopflag = 0,
        % play audio track at volume 1.0  = 100% audio volume.
        Screen('PlayMovie', movie, 1, 0, 1.0);
        
        % Populate variables for movie and scale display locations:
        scaleLocation = [round(wWidth*.1); round(wHeight-(scale_imgh*(wWidth*.8/scale_imgw))); round(wWidth*.90); wHeight];
        movieLocation = [round(wWidth*.1); 0; round(wWidth*.9); round(movie_imgh*(wWidth*.8/movie_imgw))];
        
        % Record a time stamp for the beginning of the movie playback:
        movieStartTime = GetSecs;
        
        % Video playback and key response RT collection loop:
        % This loop repeats until the end of the movie is reached.
        while(movieTexture>=0)
            % Check if a new movie video frame is ready for visual
            % presentation: This call polls for arrival of a new frame. If
            % a new frame is ready, it converts the video frame into a
            % Psychtoolbox texture image and returns a handle in
            % 'movietexture'. 'pts' contains a so called presentation
            % timestamp. If no new texture will become available
            % anymore, because the end of the movie is reached, it will
            % return a handle of -1 to indicate end of playback.
            
            % The 0 - flag means: Don't wait for arrival of new frame, just
            % return a zero or -1 'movieTexture' if none is ready.
            movieTexture = Screen('GetMovieImage', win, movie, 0);
            
            % Is it a valid texture?
            if (movieTexture>0)
                % Yes. Draw the textures into backbuffer:
                scaleTexture = Screen('MakeTexture', win, scale{scaleValue});
                Screen('DrawTextures', win, [movieTexture,scaleTexture], [], [movieLocation,scaleLocation]);
                % Flip the display to show the images at next retrace:
                Screen('Flip', win);
                
                % Delete the movie and scale textures. We don't need them anymore:
                Screen('Close', movieTexture);
                movieTexture=0;
                Screen('Close', scaleTexture);
                scaleTexture=0;
            end; % if (movietexture>0)
            
            checkTimeStamp = GetSecs;
            % Done with drawing. Check the keyboard for subjects response:
            % [keyIsDown, secs, keyCode]=KbCheck(inputDevice);
            [keyIsDown, secs, keyCode]=KbCheck;
            if (keyIsDown==1 && ((checkTimeStamp-pressTimeStamp)>.1) ...
                    && (keyCode(esc) || keyCode(r) || keyCode(s) || ...
                    (keyCode(up)&&scaleValue~=9) || ...
                    (keyCode(down)&&scaleValue~=1)))
                % Increase the button press counter by 1 (this is used when
                % logging data to know where in the recording vector to put
                % this particular input
                pressCount = pressCount+1;
                
                % Record the reaction time and old value of the button press
                pressTimeStamp = GetSecs;
                oldScaleValue=scaleValue;
                
                if keyCode(esc)
                    % Check for Abort
                    queryEscape=true;
                    break; % break out of display loop
                elseif keyCode(r)
                    % Check for Restart Trial
                    queryRestart=true;
                    break; % break out of display loop
                elseif keyCode(s)
                    % Check for Skip Trial
                    querySkip=true;
                    break; % break out of display loop
                elseif keyCode(up) && scaleValue~=9,
                    scaleValue=scaleValue+1;
                elseif keyCode(down) && scaleValue~=1,
                    scaleValue=scaleValue-1;
                end; % if (keyCode)
                
                % Record new and old values of scale and response time:
                oldScaleRecord(pressCount,1) = oldScaleValue;
                scaleRecord(pressCount,1) = scaleValue;
                responseTime(pressCount,1)= pressTimeStamp - movieStartTime;
                
            end; % if (keyIsDown==1...)
        end; % while (movieTexture>=0) ; end of display loop
        
        % Stop movie playback, in case it isn't already stopped. We do this
        % by selection of a playback rate of zero: This will also return
        % the number of frames that had to be dropped to keep audio, video
        % and realtime in sync.
        droppedcount = Screen('PlayMovie', movie, 0, 0, 0);
        
        % Print to command window some simple dropped frame diagnostics:
        droppedFramesPercent = droppedcount/framecount*100;
        fprintf('%f percent of frames dropped in trial %f.\n',droppedFramesPercent,i)
        if (droppedcount > 0.2*framecount)
            fprintf('Warning! Over 20 percent of all frames skipped in trial %f\n',i)
        end;
        
        % Close the moviefile.
        Screen('CloseMovie', movie);
        
        %% Record data for this trial
        % Check if aborted.
        if (queryEscape==true)
            return; % return to desktop
        elseif (queryRestart==true)
            i = i-1;
        elseif (querySkip~=true)
            % If escape, restart, or skip were not used in the trial that just
            % ended, begin recording data into the appropriate file and
            % structure variable.
            
            % Record responses into structure to be saved later:
            subjectStruct(i).oldScaleRecord = oldScaleRecord;
            subjectStruct(i).scaleRecord = scaleRecord;
            subjectStruct(i).responseTime = responseTime;
            subjectStruct(i).subID = subID;
            subjectStruct(i).movieFile = movieList{i};
            subjectStruct(i).pressCount = pressCount;
            
            % Open output file and print header line:
            %currentTrial=num2str(i);
            currentTrial=movieList{i};
            outputFilename = sprintf('subject_%s_trial%s_output.txt',subID,currentTrial(1:2));
            fid = fopen(outputFilename,'wt');
            fprintf(fid,'pressNumber\tscaleValue\toldScaleValue\tresponseTime\ttrialNumber\tmovieFile\tsubID\n');
            
            % Begin allocating data for printing to file:
            for j=1:pressCount
                currentPress = num2str(j);
                fprintf(fid,'%s\t%1.0f\t%1.0f\t%10.3f\t%s\t%s\t%s\n'...
                    ,currentPress,scaleRecord(j),oldScaleRecord(j)...
                    ,responseTime(j),currentTrial,movieList{i},subID);
            end; % for j=1:pressCount
            
        end; % if (queryEscape==true)
        
        %% Finish up the trial and progress to next
        % Add one to the trial counter:
        i = i+1;
        
        % Display ready screens for next trial:
        if i<=size(movieList,1) % not the last trial
            Screen('FillRect', win, background);
            nextTrialText= sprintf('Great job!\n\n Prepare for trial number %s.\n\n\nPress any key when ready.',num2str(i));
            DrawFormattedText(win, nextTrialText, 'center','center', [0 0 255], 40);
            Screen('Flip',win);
            
            WaitSecs(.3);
            KbWait;
            while KbCheck; end;
            
            % Show cleared screen:
            Screen('FillRect', win, background);
            Screen('Flip',win);
            
            % Wait a second:
            WaitSecs(1);
            
        else % special screen for end of last trial
            Screen('FillRect', win, background);
            lastTrialText= 'Great job!\n\n Thank you for participating.\n\n\nPress any key to close this window.';
            DrawFormattedText(win, lastTrialText, 'center','center', [0 0 255], 40);
            Screen('Flip',win);
            
            WaitSecs(.3);
            KbWait;
            while KbCheck; end;
            
            % Show cleared screen:
            Screen('FillRect', win, background);
            Screen('Flip',win);
            
            % Wait a second:
            WaitSecs(1);
        end; %if i<=size
    end; % while i<=numberTrials; Trial done. Next trial...
    
    %% Close up shop
    % Save the structure containing data:
    cd(subDir);
    eval([subjectStructName '=subjectStruct;']);
    eval(['save ' subjectStructName ';']);
    
    % Done with the experiment; close onscreen window and finish:
    ShowCursor;
%    ListenChar;
    Screen('CloseAll');
    cd (startDir);
    return;
catch
    % Error handling: if something fails during 'try', script continues here:
    Screen('CloseAll');
    ShowCursor;
    ListenChar;
    psychrethrow(psychlasterror);
    cd (startDir);
    return;
end;
end