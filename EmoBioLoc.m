function EmoBioLoc(subjID,this_design,runnum)

%%300 seconds, IPS=150
%%this_design = two numbers 1 through 6 (e.g. [2,4])
     

root_dir='/Users/saxelab/Documents/Experiments2/FSF';
cd(root_dir)
project = 'FSF_mainstims';
randSeed = str2num(subjID(end-1:end)); %% GET RANDSEED FROM ID

this_design=this_design(runnum);
             

%configuration details for this experiment
back=1;
blank_time=[0.5,0.5,0.5,0.5,0.33333333333333,0.33333333333333]; %% for each condition (as ordered in dir_names)
design_config= [0,1,2,3,4,5,6,0,6,5,4,3,2,1,0;
                0,6,5,4,3,2,1,0,1,2,3,4,5,6,0;
                0,2,4,1,5,6,3,0,3,6,5,1,4,2,0;
                0,5,3,6,2,1,4,0,4,1,2,6,3,5,0;
                0,3,1,2,6,4,5,0,5,4,6,2,1,3,0;
                0,4,6,5,1,3,2,0,2,3,1,5,6,4,0];

conds=6;
movs_per_dir=[8,8,8,8,30,30];
file_prefix='sts_emomotion';
fixation_time=12;
between_condition_time=2;
fullscreen=0;
mov_dir='FSF_main_stims';
dir_names={'run_A','run_B','run_C','run_D','run_E','run_F','run_G','run_H'};
repeats=1;
   
    
    % other variables
    KbName('UnifyKeyNames');
    esc=KbName('ESCAPE');
    space=KbName('SPACE');
    fprintf('Starting design: %d\n', this_design);
    design = design_config(this_design, :);
    run_size = size(design, 2);
    block_length=[8,8,8,8,6,6]; %% for each condition (as ordered in dir_names)
    % statistics
    stat_hit = 0;
    stat_fa = 0;
    stat_miss = 0;
    stat_cr = 0;
    mov_length = [2,2,2,2,3,3];
    TR=2;
    overwrite = 1;
    behavpath = 'behavioural';
    condNames={'Bio','ObjectMot', 'Happy','Sad', 'Faces', 'Objects'};
    movienames = {};
    rt = [];
    rbutton = {};
    movieblock = 0; %Number of block, including only those with movies.
    beep off;
    
    %% generate timing
    durs = [];
    onsets = [];
    for r = 1:run_size
        condition=design(r);
        if condition==0
            durs(r) = fixation_time;
        else
            if condition+1==0 %% if block followed by a rest block
            durs(r) = block_length(condition)*(blank_time(condition)+mov_length(condition));
            else %% if block that is not followed by a rest time, add 2 seconds for the delay between blocks
            durs(r) = block_length(condition)*(blank_time(condition)+mov_length(condition)) + between_condition_time;
            end
        end;
        if r==1
            onsets(r)=0;
        else
            onsets(r)=sum(durs(1:(r-1)));
        end;
    end;
    
    actualOnsets=zeros(run_size,1); %% so we can make sure we ain't crazy
    
    %% Generate random value and modify the Mersenne Twister.
    rand('twister',randSeed);
    
    %%
    % generating struct with all directories and the containing files
         
    
    for i=1:conds
        dir_name = dir_names{i};
        if runnum==2       %% this section is ghetto and specific to the fact that movie/trial structure of faces and objects is different from rest of emobioloc
            if i==5
                dir_name=dir_names{7};  % conditions 5 and 6 have separate stimuli for each run, in separate stimuli folders
            else if i==6
                    dir_name=dir_names{8};
                end
            end
                
        end
            dirs(i).name = dir_name;
            dirs(i).files = dir(sprintf(fullfile('%s', '%s', '*.mov'), mov_dir, dir_name));
            dirs(i).size = movs_per_dir(i);
    end;



    %%
    % randomizing movies, adding n-back-task
    conds=unique(design);
    size_array=size(conds);
    num_conds=size_array(2);
    order = zeros(run_size,max(block_length)); %%this is also ghetto... just made matrix big enough to handle conditions with most movies per block
    block_order=zeros(1:max(block_length));
    cond_block=zeros(1,num_conds);
    max_size = max([dirs(:).size]);
    file_order=zeros(num_conds,max_size);

    for block=1:run_size
        condition = design(block); % number of condition, depending on design
        cond_block(condition+1)=cond_block(condition+1)+1;
        if condition ~= 0
                if repeats > 0
                    randomize=randperm(numel(dirs(condition).files));
                        file_order(condition,1:movs_per_dir(condition))= randomize;
             for repeat=1:repeats
                        files_no = block_length(condition)-1;
                        % leprechaun defines the position of the treasure .. eg repeated
                        % stimulus for the n-back task
                        leprechaun = randi(files_no);
                        % new concatination of file-order with doubled stimulus
                        if condition <=4 %% conditions 1-4 repeat same stimuli across blocks
                        start_num = 1;
                        else if condition >4 %% conditions 5 and 6 do not repeat stimuli
                        start_num = (cond_block(condition+1)-1)*files_no+1;
                            end
                        end
                        end_num = start_num+files_no-repeats;
                        firstPart=file_order(condition,start_num:start_num+leprechaun-1+back-1);
                        repeatPart=file_order(condition,start_num+leprechaun-1);
                        thirdPart=file_order(condition,start_num+leprechaun-1+back:end_num);
                        block_order=[firstPart repeatPart thirdPart];
                   
                end;

                    end

                order(block,1:length(block_order)) = block_order;
        else
            order(block,:) = zeros(1,block_length);
        end;    
    end
 
    
    % start general psychtoolbox-stuff
    try
        %AssertOpenGL;

        % Open onscreen window:
        screenNum = max(Screen('Screens'));  %Highest screen number is most likely correct display
        [wPtr, rect] = Screen('OpenWindow', screenNum);
        center = [rect(3)/2 rect(4)/2];
        black = BlackIndex(wPtr);
        white = WhiteIndex(wPtr);
        %HideCursor;

        % Clear screen to background color:
        Screen('FillRect', wPtr, black);
        Screen(wPtr, 'TextSize', 20);
        text = sprintf('Press 1 when a stimulus repeats');
        Screen('DrawText', wPtr, text, center(1)-200,center(2)-20,white);
        Screen(wPtr, 'Flip');
    catch
        % Error handling: Close all windows and movies, release all ressources.
        ShowCursor;
        Screen('Preference', 'SuppressAllWarnings',oldEnableFlag); 
        Screen('CloseAll');
        psychrethrow(psychlasterror);
    end;

    
    
    FlushEvents;
    while 1  % wait for the 1st trigger pulse
        trig = GetChar;
        if trig == '+'
            t_exp_start = GetSecs;
            break
        end;
    end;
    
    
    %%
    % LOOP IT REAL GOOD
    % start experiment
    t_exp_start = GetSecs;
    preloading = 0;
    anim=0;
    conditionList=[];
    for block=1:run_size
        condition = design(block); % number of condition, depending on design
           while GetSecs-t_exp_start < onsets(block)
                1; %% run up clock until specified onset
           end
            blockstart=GetSecs;
            actualOnsets(block)=blockstart-t_exp_start;
        if condition == 0
            % fixation condition
            %fprintf(file, '%4.3f \t\t 0 \t\t\t 0 \t\t\t\t fixation cross \n', GetSecs-t_exp_start);
            Screen(wPtr,'FillRect',black);
            Screen('FillRect',wPtr,128, CenterRect([0 0 16 4],rect));
            Screen('FillRect',wPtr,128,CenterRect([0 0 4 16],rect));
            Screen('Flip', wPtr);
            while GetSecs-blockstart < fixation_time
                % preloading next movie
                if preloading==0 && block+1 <= run_size && design(block+1) ~= 0
                    preloading = 1;
                    next_movieid = order(block+1,1);
                    next_moviename = fullfile(root_dir, mov_dir, dirs(design(block+1)).name, dirs(design(block+1)).files(next_movieid).name);
                    [moviePtr movieDuration movieFps movieWidth movieHeight movieCount] = Screen('OpenMovie', wPtr, next_moviename);   % NOTE: this line sometimes fails inscrutably.
                    %fprintf('fix-preloading %s\n', next_moviename);
                end;
            end;
        else
            files_no = dirs(condition).size;
            movies_no = block_length(condition);
            movieblock = movieblock+1;
            movie_blank_duration= mov_length(condition)+blank_time(condition);

            if files_no > 0
                % fetch every image out of the movie and show it
                % meanwhile catch buttonpresses and save it to file
                for movie=1:movies_no
                    mstart=GetSecs;
                    t_mov_start = mstart-t_exp_start;
                    anim=anim+1;
                    conditionList=[conditionList; condition];
                    try
                        buttonpress = [];
                        t_mov_start = GetSecs;
                        t_reaction = t_mov_start;
                        
                        % Open movie file and retrieve basic info about movie:
                        movieid = order(block, movie);
                        moviename = fullfile(root_dir, mov_dir, dirs(condition).name, dirs(condition).files(movieid).name);
                        [moviePtr movieDuration movieFps movieWidth movieHeight movieCount] = Screen('OpenMovie', wPtr, moviename);
                        Screen('SetMovieTimeIndex', moviePtr, 0);
                        [nDroppedFrames]=Screen('PlayMovie', moviePtr, 1);
                        preloading = 0;
                        
                        
                        while GetSecs-mstart < mov_length(condition)
                            [tex pts] = Screen('GetMovieImage', wPtr, moviePtr, 1);
                            % Valid texture returned?
                            if tex <= 0
                                break;
                            end;
                            
                            % Draw the new texture immediately to screen:
                            if fullscreen == 1
                                Screen('DrawTexture', wPtr, tex, [], rect);
                            else
                                Screen('DrawTexture', wPtr, tex);
                            end;
                            Screen('Flip', wPtr);

%                             % preloading next movie
%                             % within same condition
%                             if ~preloading && movie+1 <= movies_no
%                                 next_movieid = order(block,movie+1);
%                                 if next_movieid ~= 0
%                                     preloading = 1;
%                                     next_moviename = fullfile(root_dir, mov_dir, dirs(condition).name, dirs(condition).files(next_movieid).name);
%                                     Screen('OpenMovie', wPtr, next_moviename, 1);
%                                 else
%                                     movie = movies_no;
%                                 end;
%                             end;
                            
                            % next condition
                            if ~preloading && movie+1 > movies_no && block+1 <= run_size && design(block+1) ~= 0
                                preloading = 1;
                                next_movieid = order(block+1,1);
                                next_moviename = fullfile(root_dir, mov_dir, dirs(design(block+1)).name, dirs(design(block+1)).files(next_movieid).name);
                                Screen('OpenMovie', wPtr, next_moviename, 1);
                            end;
                            
                            % watching for input from user
                                [keyIsDown,secs,keyCode]=KbCheck(-3); %% -3 for all keyboards and keypads, -1 is just all keyboards, but both should work. KbCheck(end) would get input from last device plugged in, which should also work
                                if keyIsDown
                                button = find(keyCode); %% figure out which key you found
                                thiskey = KbName(button(1)); %% figure out its name (taking only the first button if subjects hit more than one)
                                thiskey = str2num(thiskey(1)); %% make it a string, taking only the first (since KbName can return multiple e.g. 1! instead of 1)
                                 if ~isempty(thiskey) & any(thiskey==1:4) %%% %now can match it based on the actual numeric values, none of this 89:92 bullshit!
                                     t_reaction = GetSecs;
                                     buttonpress = thiskey;
                                 end  
                                end
                            
                            Screen('Close', tex);
                        end
                        
                        
                        % save stuff 
                        if length(rt)<anim %% only save if you haven't already recorded an RT and button for this trial
                        rbutton{anim} = buttonpress;
                        rt(anim) = t_reaction-t_mov_start;
                        
                        
                        % do the statistics
                        if movie-back > 0 && back > 0
                            if ~isempty(buttonpress) && order(block,movie-back) == movieid
                                % HIT
                                stat_hit = stat_hit + 1;
                            elseif ~isempty(buttonpress) && order(block,movie-back) ~= movieid
                                % FALSE ALARM
                                stat_fa = stat_fa + 1;
                            elseif isempty(buttonpress) && order(block,movie-back) == movieid
                                % MISS
                                stat_miss = stat_miss + 1;
                            elseif isempty(buttonpress) && order(block,movie-back) ~=movieid
                                % CORRECT REJECTION
                                stat_cr = stat_cr + 1;
                            else
                                
                                %%strcmp(buttonpress, '[]') == 1 && order(block,movie-back) ~=movieid
                                % SOMETHING WENT WRONG
                                fprintf('Warning: Could not process user-response at block %d, movie %d (buttonpress: %d, movieid: %d, lastmovieid: %d)\n', block, movie, buttonpress, movieid, lastmovieid);
                            end;
                        elseif ~isempty(buttonpress)
                            % FALSE ALARM, of course
                            stat_fa = stat_fa + 1;
                        else 
                            % CORRECT REJECTION, obv.
                            stat_cr = stat_cr + 1;
                        end;
                        end
                        movienames{anim} = moviename;
                        
                        % Close moviePtr object:
                        Screen('CloseMovie', moviePtr);
                        % blank the screen
                        Screen(wPtr, 'Flip');
                        bstart=GetSecs;
                        if movie<block_length(condition)
                        while GetSecs - blockstart < movie_blank_duration*movie;
                            
                            % preloading next movie within same condition
                            if ~preloading && movie+1 <= movies_no
                                next_movieid = order(block,movie+1);
                                if next_movieid ~= 0
                                    preloading = 1;
                                    next_moviename = fullfile(root_dir, mov_dir, dirs(condition).name, dirs(condition).files(next_movieid).name);
                                    Screen('OpenMovie', wPtr, next_moviename, 1);
                                else
                                    movie = movies_no;
                                end;
                            end;
  
                        end;
                     
                        end
                            
                    catch
                        % Error handling: Close all windows and movies, release all ressources.
                        ShowCursor;
                       % Screen('Preference', 'SuppressAllWarnings',oldEnableFlag); 
                        Screen('CloseAll');
                        psychrethrow(psychlasterror);
                    end;
                    % ugly hack to stop Matlab to reset the loop-counter
                    if movie == movies_no
                        break;
                    end
                end;
            end;
            
            if design(block+1) ~=0 %%if end of block that is not followed by rest
            wait=GetSecs;
            while GetSecs-wait<between_condition_time %% wait for duration of between_condition_time
            Screen(wPtr,'FillRect',black);
            Screen('FillRect',wPtr,128, CenterRect([0 0 16 4],rect));
            Screen('FillRect',wPtr,128,CenterRect([0 0 4 16],rect));
            Screen('Flip', wPtr);
            end
            end
            
        end;

    end;

    %% 
    % finish and clean up
    t_exp_end = GetSecs;
    Screen('CloseAll');
    Screen('CloseAll');

    accuracy = stat_hit / (stat_hit+stat_miss);
   
    
    % calculating loss of time
    actualDuration = t_exp_end-t_exp_start;
    exptduration = (sum(durs));
    ips=round(exptduration/TR);
    fprintf('design: %5.5f, calc: %5.5f => time-loss: %5.5f \n', actualDuration, exptduration, actualDuration-exptduration);
    %fprintf(file, 'design: %5.5f, calc: %5.5f => time-loss: %5.5f \n', endtime_actual, exptduration, endtime_actual-exptduration);
    %fclose(file);
    
    % Write saxelab behavioral file.
    
    onsets = onsets(design~=0); %% in seconds
    durs = durs(design~=0);
    realrun = design(design~=0);
    
    %% sort your RTs and buttons by cond
    for c=1:length(condNames)
        sorted_RTs{:,c}  = rt(conditionList' == c)'; 
        sorted_buttons{:,c}  = rbutton(conditionList' == c)';
    end;
    
    %%figure out when they saw what so you can tell spm about it
     for c=1:length(condNames)
        spm_inputs(c).name = condNames{c};
        spm_inputs(c).ons  = round(onsets(realrun == c)'/TR+1); %% in TR
        spm_inputs(c).dur  = round(durs(realrun == c)'/TR); %% in TR
    
        fsl_inputs(c).name = condNames{c};
        fsl_inputs(c).regressor = [onsets(realrun == c)' durs(realrun == c)' ones(length(onsets(realrun == c)),1)];
    end;
        
%what could I possibly care about?
con_info(1).name = 'All>Rest';
con_info(1).vals = [1 1 1 1 1 1];
con_info(2).name = 'Bio>ObjMot';
con_info(2).vals = [1 -1 0 0 0 0];
con_info(3).name = 'Emo>Bio';
con_info(3).vals = [-2 0 1 1 0 0];
con_info(4).name = 'Happy>Bio';
con_info(4).vals = [-1 0 1 0 0 0];
con_info(5).name = 'Sad>Bio';
con_info(5).vals = [-1 0 0 1 0 0];
con_info(6).name = 'Happy>Sad';
con_info(6).vals = [0 0 1 -1 0 0];
con_info(7).name = 'Sad>Happy';
con_info(7).vals = [0 0 -1 1 0 0];
con_info(8).name = 'Faces>Objects';
con_info(8).vals = [0 0 0 0 1 -1];
con_info(9).name = 'Objects>Faces';
con_info(9).vals = [0 0 0 0 -1 1];
% con_info(10).name = 'Bio';
% con_info(10).vals = [1 0 0 0 0 0];
% con_info(11).name = 'ObjMot';
% con_info(11).vals = [0 1 0 0 0 0];
% con_info(12).name = 'Happy';
% con_info(12).vals = [0 0 1 0 0 0];
% con_info(13).name = 'Sad';
% con_info(13).vals = [0 0 0 1 0 0];
% con_info(14).name = 'Faces';
% con_info(14).vals = [0 0 0 0 1 0];
% con_info(15).name = 'Objects';
% con_info(15).vals = [0 0 0 0 0 1];


    
    
    behavfile = [behavpath '/' subjID '.EmoBioLoc.' int2str(runnum) '.mat'];
    while ~overwrite
        if exist(behavfile,'file')==2
            behavfile = strrep(behavfile,'.mat','+.mat');
        else
            break;
        end;
    end;
       
    Screen('CloseAll');
    
    save(behavfile,'subjID','this_design','runnum','design','spm_inputs','fsl_inputs','con_info','onsets','actualOnsets','actualDuration','exptduration','ips','accuracy','stat_hit','stat_miss','stat_fa','stat_cr','rbutton','rt','sorted_RTs','sorted_buttons','movienames');
  

    % % restore preferences to the old level.
% Screen('Preference', 'SuppressAllWarnings',oldEnableFlag); 
    ShowCursor;
    Screen('CloseAll'); %% I do this so many times and matlab still tells me I left something open?!?
end