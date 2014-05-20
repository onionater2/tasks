function tom_localizer(subjID, run, this_design, randSeed)

%% subjID= "SAX_TOM_01"
%% run = 1,2
%% this_design = 1,2

%% 272 seconds, IPS=136

%%modified by Amy Skerry, 11/27/2012
% added spm_inputs, ideal and real time onsets, stim randomization and
% design counterbalancing, and made story onsets locked to ideal onsets
% vector
%__________________________________________________________________________
%
% This script will localize theory-of-mind network areas by contrasting
% activation during false-belief tasks, in which characters have incorrect
% beliefs about the state of the world, and false-photograph tasks, in
% which a photograph depicts a world state that is no longer the case.
%
% There are blocks of false belief stories, in which a story is told
% involving a false belief, which is presented for 10 seconds, then a
% probe question about the story presented for 4 seconds. In
% between each block, there is a fixation period of 12 seconds. 
%
% To run this script, you need Matlab and the PsychToolbox, which is available
% as a free download. 
%
%__________________________________________________________________________
%
%							INPUTS
%
% - subjID: STRING The string you wish to use to identify the participant. 
%			"PI name"_"study name"_"participant number" is a common
%			convention. This will be the name used to save the files.
% - run   : NUMBER The current run number. (e.g., 1) 
%
% Example usage: 
%					tom_localizer("SAX_TOM_01",1)
%
%__________________________________________________________________________
%
%							OUTPUTS
%	The script outputs a behavioural file into the behavioural directory.
%	This contains information about the IPS of the scan, when stories were
%	presented, reaction time, and response info. It also contains
%	information necessary to perform the analysis with SPM. The file is
%	saved as subjectID.tom_localizer.run#.m
%
%	In the event of a crash, the script creates a running behavioural file
%	of partial data after each trial. 
%__________________________________________________________________________
%
%						  CONDITIONS 
%
%				1 - Belief (stimuli  1b to 10b)
%				2 - Photo  (stimuli  1p to 10p)
%
%__________________________________________________________________________
%
%							TIMING
%
% The run length can be calculated according to the following:
%
% (trials per run)*(fixation duration + story duration)+(fixation duration)
% 
% The phrases used above are related to the variable values according to
% the following:
%
% trials per run = trialsPerRun
% fixation duration = fixDur
% story duration = storyDur
%
% The default configuration is:
%
% (10 trials per run) * (12 sec fixation + 14 sec story) + (12 sec
% fixation) =
%
% 10 * (12 + 14) + 12 = 272 seconds, 136 ips (given 2 sec TR)
%__________________________________________________________________________
%
%							NOTES
%
%	Note 1
%		Make sure to change the inputs in the 'Variables unique to scanner/
%		computer' section of the script. 
%
%	Note 2
%		The use of intersect(89:92, find(keyCode)) determines if the
%		keystroke found by KbCheck is one of the proper response set. Of
%		course, these intersection values are a consequence of the workings
%		of our MRI response button. Your response button may differ. 
%		Use KbCheck() to determine which button pushes from the response box
%		correspond to numbers 1:4. Otherwise, you may not retain any 
%		behavioural data.
%
%	Note 3
%		For simplicity, we have set up the experiment so that the order of
%		items and conditions is identical for every subject - they see
%		design 1 in run 1, with stimuli 1 - 5 form each condition, in that 
%		order. In our own research, we typically counterbalance the order 
%		of items within a run, and the order of designs across runs, across
%		subjects (so half of our participants see design 1 in run 2). If 
%		you are comfortable enough with matlab, we encourage you to add 
%		this counterbalancing back into the experiment - and make sure to 
%		save separate variables for each subject tracking the order of 
%		items and conditions across runs.
%__________________________________________________________________________
%
%					ADVICE FOR ANALYSIS
%	We analyze this experiment by modelling each trial as a block with a
%	boxcar lasting 14 seconds, during the whole period from the initial
%	presentation of the story to the end of the question presentation.
%	These boxcars are flanked by non-jittered rest periods of 12 seconds
%	each (the fixation duration in the script). While we have analyzed the
%	statement and question periods separately, we have found that the
%	outcomes are nearly identical, due to the BOLD signal being
%	predominantly due to participants reading and encoding the text,
%	rather than answering the questions. 
%
%	Analysis consists of five primary steps:
%		1. Motion correction by rigid rotation and translation about the 6 
%		   orthogonal axes of motion.
%		2. (optional) Normalization to the SPM template. 
%		3. Smoothing, FWHM, 5 mm smoothing kernel if normalization has been
%		   performed, 8 mm otherwise.
%		4. Modeling
%				- Each condition in each run gets a parameter, a boxcar
%				  plot convolved with the standard HRF.
%				- The data is high pass filtered (filter frequency is 128
%				  seconds per cycle)
%		5. A simple contrast and a map of t-test t values is produced for 
%		   analysis in each subject. We look for activations thresholded at
%		   p < 0.001 (voxelwise) with a minimum extent threshold of 5
%		   contiguous voxels. 
%
%	Random effects analyses show significant results with n > 10
%	participants, though it should be evident that the experiment is
%	working after 3 - 5 individuals.
%__________________________________________________________________________
%
%					SPM Parameters
%
%	If using scripts to automate data analysis, these parameters are set in
%	the SPM.mat file prior to modeling or design matrix configuration. 
%
%	SPM.xGX.iGXcalc    = {'Scaling'}		global normalization: OPTIONS:'Scaling'|'None'
%	SPM.xX.K.HParam    = filter_frequency   high-pass filter cutoff (secs) [Inf = no filtering]
%	SPM.xVi.form       = 'none'             intrinsic autocorrelations: OPTIONS: 'none'|'AR(1) + w'
%	SPM.xBF.name       = 'hrf'				Basis function name 
%	SPM.xBF.T0         = 1                 	reference time bin
%	SPM.xBF.UNITS      = 'scans'			OPTIONS: 'scans'|'secs' for onsets
%	SPM.xBF.Volterra   = 1					OPTIONS: 1|2 = order of convolution; 1 = no Volterra
%__________________________________________________________________________
%
%	Created by Rebecca Saxe & David Dodell-Feder
%	Modified by Nick Dufour (ndufour@mit.edu), December 2010
%__________________________________________________________________________
%
%					Changelog
%	01.18.11 : Fixed a bug that caused the same stimuli to be loaded during
%			   both runs.
%   09.07.11 : Fixed a bug the erroneously eliminated the final fixation
%			   period. 
%__________________________________________________________________________
%
%% Variables unique to scanner / computer

[rootdir b c]		= fileparts(mfilename('fullpath'));			% path to the directory containing the behavioural / stimuli directories. If this script is not in that directory, this line must be changed. 
triggerKey			= '+';										% this is the value of the key the scanner sends to the presentation computer

%% Set up necessary variables
orig_dir			= pwd;
textdir				= fullfile(rootdir, 'text_files');
behavdir			= fullfile(rootdir, 'behavioural');
designs				= [ 1 2 2 1 2 1 2 1 1 2 ;
					    2 1 2 1 1 2 2 1 2 1 ; ];
design				= designs(this_design,:);
conds				= {'belief','photo'};
stims               = [1 2 3 4 5 6 7 8 9 10];

if run==1
    orderedStims       =stims(randperm(numel(stims(1:5))))
else if run==2
    orderedStims       =stims(randperm(numel(stims(6:10))))
    end
end

acceptableKeys=[30:34]; %% [89:92];

condPrefs			= {'b','p'};								% stimuli textfile prefixes, used in loading stimuli content
fixDur				= 12;										% fixation duration
storyDur			= 10;										% story duration
questDur			= 4; % probe duration
trialsPerRun		=  length(design);
numConds            =  2;
key					= zeros(trialsPerRun,1);
RT					= key;
items				= key;
ips					= ((trialsPerRun) * (fixDur + storyDur + questDur) + (fixDur))/2;
TR=2;

  %% Generate random value and modify the Mersenne Twister.
    rand('twister',randSeed);

    % calculate ideal onsets (in seconds)
    
    durs = [];
    onsets = zeros(trialsPerRun/numConds,1);
    totalDur=storyDur + questDur + fixDur;
    for condition = 1:length(design)
            durs(condition) = totalDur;
    end;
    thistiming=[fixDur];
    for x=1:trialsPerRun-1
        thistiming=[thistiming thistiming(end)+totalDur];
    end;
    labeledonsets = [design; thistiming]';  %%this is ideal
    
    % set up to calculate actual onsets (in seconds)

whatHappened=zeros(trialsPerRun,2);

%% Verify that all necessary files and folders are in place. 
if isempty(dir(textdir))
	uiwait(warndlg(sprintf('Your stimuli directory is missing! Please create directory %s and populate it with stimuli. When Directory is created, hit ''Okay''',textdir),'Missing Directory','modal'));
end
if isempty(dir(behavdir))
	outcome = questdlg(sprintf('Your behavioral directory is missing! Please create directory %s.',behavdir),'Missing Directory','Okay','Do it for me','Do it for me');
	if strcmpi(outcome,'Do it for me')
		mkdir(behavdir);
		if isempty(dir(behavdir))
			warndlg(sprintf('Couldn''t create directory %s!',behavdir),'Missing Directory');
			return
		end
	else
		if isempty(dir(behavdir))
			return
		end
	end
end

%% Psychtoolbox
%  Here, all necessary PsychToolBox functions are initiated and the
%  instruction screens are set up.
try
	PsychJavaTrouble;
	cd(textdir);
	HideCursor;
	displays    = Screen('screens');
	[w, wRect]  = Screen('OpenWindow',displays(end),0);
	scrnRes     = Screen('Resolution',displays(end));               % Get Screen resolution
	[x0 y0]		= RectCenter([0 0 scrnRes.width scrnRes.height]);   % Screen center.
    %[x0 y0]		= RectCenter(wRect);   % Screen center.
	Screen(   'Preference', 'SkipSyncTests', 1);                       
	Screen(w, 'TextFont', 'Helvetica');                         
	Screen(w, 'TextSize', 30);
	task		= sprintf('True or False');
	instr_1		= sprintf('Press left button (1) for "True"');
	instr_2		= sprintf('Press right button (2) for "False"');
	Screen(w, 'DrawText', task, x0-125, y0-60, [255]);
	Screen(w, 'DrawText', instr_1, x0-300, y0, [255]);
	Screen(w, 'DrawText', instr_2, x0-300, y0+60, [255]);
	Screen(w, 'Flip');												% Instructional screen is presented.
catch exception
	ShowCursor;
	sca;
	warndlg(sprintf('PsychToolBox has encountered the following error: %s',exception.message),'Error');
	return
end

%% Wait for the trigger.
%  If your scanner does not use a '+' as a trigger pulse, change the value 
%  of triggerKey accordingly. 

while 1  
    FlushEvents;
    trig = GetChar;
    if strcmp(trig, triggerKey);
        break
    end
end

%% Main Experimental Loop
counter				= zeros(1,2);
experimentStart		= GetSecs;
Screen(w, 'TextSize', 32);
try
	for trial = 1:trialsPerRun
		cd(textdir);
		trialStart		= GetSecs;
		empty_text		= ' ';
		Screen(w, 'DrawText', empty_text,x0,y0);
		Screen(w, 'Flip');
		counter(1,design(trial)) = counter(1,design(trial)) + 1;

		%%%%%%%%% Determine stimuli filenames %%%%%%%%%
		trialT			= design(trial);							% trial type. 1 = false belief, 2 = false photograph
		numbeT			= counter(1,trialT);					% the number of the trial for the condition
        numStim         = orderedStims(numbeT);
		storyname		= sprintf('%d%s_story.txt',numStim,condPrefs{trialT});
		questname		= sprintf('%d%s_question.txt',numStim,condPrefs{trialT});
		items(trial,1)	= numStim;

		%%%%%%%%% Open Story %%%%%%%%%
		textfid			= fopen(storyname);
		lCounter		= 1;										% line counter
		while 1
			tline		= fgetl(textfid);							% read line from text file.
			if ~ischar(tline), break, end
			Screen(w, 'DrawText',tline,x0-360,y0-160+lCounter*45,[255]);
			lCounter	= lCounter + 1;
		end
		fclose(textfid);

		while GetSecs - experimentStart < thistiming(trial); end					% wait until specified onset to elapse
        
        storyStart=GetSecs;
        whatHappened(trial,1)=trialT;
        whatHappened(trial,2)=storyStart-experimentStart;
        
		%%%%%%%%% Display Story %%%%%%%%%
		Screen(w, 'Flip');										

		%%%%%%%%% Open Question %%%%%%%%%
		textfid			= fopen(questname);
		lCounter		= 1; 
		while 1
			tline		= fgetl(textfid);							% read line from text file.
			if ~ischar(tline), break, end
			Screen(w, 'DrawText',tline,x0-330,y0-160+lCounter*45,[255]);
			lCounter	= lCounter + 1;
		end

		while GetSecs - trialStart < fixDur + storyDur; end			% wait for story presentation period

		%%%%%%%%% Display Question %%%%%%%%%
		Screen(w, 'Flip');

		responseStart	= GetSecs;

		%%%%%%%%% Collect Response %%%%%%%%%
		while ( GetSecs - responseStart ) < questDur
			[keyIsDown,secs,keyCode]	= KbCheck;					% check to see if a key is being pressed
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			%--------------------------SEE NOTE 2-----------------------------%
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        button						= intersect(acceptableKeys, find(keyCode));   

			if(RT(trial,1) == 0) & ~isempty(button)
				RT(trial,1)				= GetSecs - responseStart;
                buttonName=KbName(button);
				key(trial,1)			= str2num(buttonName(1));
			end
		end

		%%%%%%%%% Save information in the event of a crash %%%%%%%%%
		%cd(behavdir);
		%save([subjID '.tom_localizer.' num2str(run) '.mat'],'subjID','run','this_design','design', 'orderedStims','items','key','RT');
	end
catch exception
	ShowCursor;
	sca
	warndlg(sprintf('The experiment has encountered the following error during the main experimental loop: %s',exception.message),'Error');
	return
end

%% Final fixation, save information
Screen(w, 'Flip');
trials_end			= GetSecs;
while GetSecs - trials_end < fixDur; end;

experimentEnd		= GetSecs;
experimentDuration	= experimentEnd - experimentStart;
numconds			= 2;
    

%%SPM stuff 

    for c=1:length(conds)
        spm_inputs(c).name = conds{c};
        use=find(labeledonsets(:, 1)==c);
        ons=labeledonsets(:,2);
        onsets(:,c)=ons(use); %% in seconds
        spm_inputs(c).ons = ons(use)/TR;  %% in TR     
        spm_inputs(c).dur  = durs(condition)/TR;

    end;
    
    con_info(1).name = 'All > Rest';
    con_info(1).vals = [1 1];
    con_info(2).name = 'belief > photo';
    con_info(2).vals = [1 -1];
    con_info(3).name = 'photo > belief';
    con_info(3).vals = [-1 1];


try
	sca
	responses = sortrows([design' items key RT]);
    cd (behavdir);
	save([subjID '.tom_localizer.' num2str(run) '.mat'],'subjID','run','this_design','design', 'orderedStims','labeledonsets','onsets','spm_inputs', 'con_info', 'whatHappened','key','RT','responses','experimentDuration','ips');
    
ShowCursor;
Screen('CloseAll');
cd(rootdir);
%warning on;
clear all;
    
    
    
catch exception
	sca
	ShowCursor;
	warndlg(sprintf('The experiment has encountered the following error while saving the behavioral data: %s',exception.message),'Error');
	cd(orig_dir);
end					% end main function