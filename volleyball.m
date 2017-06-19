clc; %clear workspace

%% ========= SET LOGFILES ========= 
subjectID = input('Participant number: ');  %input subject number
DateTime = datestr(now,'yyyymmdd-HHMM');    %get date and time for logfile name

%create a directory called Logfiles if there isn't one already
if ~exist('Logfiles', 'dir')
    mkdir('Logfiles');
end

%store result names 
resultname = fullfile('Logfiles', strcat('Sub',num2str(subjectID),'_', DateTime, '.mat'));                          %for choices
resultnameQuestions = fullfile('Logfiles', strcat('Sub',num2str(subjectID),'questions_', DateTime, '.mat'));        %for end-of-block questions
backupfile = fullfile('Logfiles', strcat('Bckup_Sub',num2str(subjectID), '_', DateTime, '.mat'));                   %backup logfile with the whole workspace, in case of nasty aborts
%% ========= SET CONTINGENCIES & EXPERIMENT STRUCTURE ========= %
T = readtable('ContingencyTableFinal.csv');         %read table that stores contingencies
shuffledT = T(randperm(size(T,1)),:);               %shuffle T rows
rows = shuffledT.Condition;                         %pick rows for indexing

%Create contingency tables for different number of trials
vars4 = {'POA4','POnotA4'};
T4 = shuffledT(rows,vars4);
contTable4 = table2array(T4);

vars5 = {'POA5','POnotA5'};
T5 = shuffledT(rows,vars5);
contTable5 = table2array(T5);

vars6 = {'POA6','POnotA6'};
T6 = shuffledT(rows,vars6);
contTable6 = table2array(T6);

vars38 = {'POA38','POnotA38'};
T38 = shuffledT(rows,vars38);
contTable38 = table2array(T38);

vars40 = {'POA40','POnotA40'};
T40 = shuffledT(rows,vars40);
contTable40 = table2array(T40);

vars42 = {'POA42','POnotA42'};
T42 = shuffledT(rows,vars42);
contTable42 = table2array(T42);

run1 = shuffledT{1:10,'LearnDur'};            %determine the duration (short or long) for each block in run1 (0 short, 1 long)         
run2 = shuffledT{11:20,'LearnDur'};           
run3 = shuffledT{21:30,'LearnDur'};
training = 10;                               %set number of trials in the training run
expStructure = {training, run1, run2, run3};
nruns = numel(expStructure);                                   %count elements in expStructure to determine number of runs

%% ========= PARAMETERS & DATA PREALLOCATION ========= %
%Block structure
shortBlocks = [4 5 6];
longBlocks = [38 40 42];

%contTable = [9 3; 7 1; 8 5; 6 3; 6 6; 4 4; 5 8; 3 6; 3 9; 1 7];   %Contingency table {play, do not play} for each block: 1 = 1/10 ; 2 = 2/10 ; 3 = 3/10 ; 4 = 4/10 ; 5 = 5 / 10; ...
%conTableShuffled = contTable(randperm(10),:);                     %Shuffle contingencies for each block
cond = [0 0 0 0 0 1 1 1 1 1];                                     %for play_pause or pause_play display, changes every block

players = randperm(30+1);                                         %create as many unique "player numbers" as there are blocks, + 1 for the practice run
thisblock = zeros(310,1);                                         %preallocate block nr storage to be recorded for each trial
condition = zeros(310,1);                                         %preallocate condition (play_pause or pause_play) to be recorded for each trial

%% ========= INSTRUCTIONS ========= %
psychExpInit;                                %start PTB
RestrictKeysForKbCheck([32,37,39]);          %restrict key presses to space, right and left arrows
exitInstructions = false;                    %cue determining whether to exit the instructions
pos = 1;                                     %initial position to go back and forth between the slides

Screen('DrawTexture', win, texslide1);       %show first slide      
Screen('Flip',win);                             

while exitInstructions == false              %loop instruction slides until space key is pressed
    [secs, keyCode, deltaSecs] = KbWait([],2);  %waits for key press
    
    %depending on button press, either move pos or exit instructions  
    if keyCode(:,32) == 1 %space
        exitInstructions = true;
    elseif keyCode(:,37) == 1 %leftArrow
           pos = pos-1;
    elseif keyCode(:,39) == 1 %rightArrow
           pos = pos+1;       
    end
    
    %deal with errors if people press <- at the beginning  or -> at the end
    if pos <= 0
        pos = 2;
       continue
    end  
     
    if pos >= 11
        pos = 10;
       continue
    end   
    
    %show instructions slide according to position
    thisSlide=imread(fullfile('Stimfiles', strcat('Slide',num2str(pos),'.bmp'))); 
    texslide = Screen('MakeTexture', win, thisSlide);
    Screen('DrawTexture', win, texslide);
    Screen('Flip',win);
    continue
    
end

%% ========= LOOPS (RUN, BLOCK, TRIAL) ========= %
runnb = 0;   %initial run value
blocknb = 0; %initial block value
trialnb = 0; %initial trial value

%RUN LOOP
for i = 1:nruns
    condOrder = cond(randperm(length(cond)));   %vector of 0s and 1s for play_pause or pause_play conditions
    nblocks = length(expStructure{i});          %determine number of blocks for each run; it will be 1 for training and 10 for the other 3 runs

%BLOCK LOOP
for x = 1:nblocks          
        k=1;
        blocknb = blocknb + 1;
               
        %Determine whether this is going to be a short or a long block
        if expStructure{i}(x,1) == 0 
           pickPlace = randi(length(shortBlocks));
           ntrials = shortBlocks(pickPlace);
        else
           pickPlace = randi(length(longBlocks));
           ntrials = longBlocks(pickPlace);
        end
        
        %Set contingencies
        %For practice trials
        if i == 1
            ntrials = 10;
            trials_P_OA = zeros(10,2);
            P_OA = [5 5];                   %set probability at .5 for the training
        end
        
        %For real trials
        if ntrials == 4
           trials_P_OA = zeros(ntrials,2);
           P_OA = contTable4(blocknb,:);
        elseif ntrials == 5
           trials_P_OA = zeros(ntrials,2);
           P_OA = contTable5(blocknb,:);
        elseif ntrials == 6
           trials_P_OA = zeros(ntrials,2);
           P_OA = contTable6(blocknb,:);
        elseif ntrials == 38
            trials_P_OA = zeros(ntrials,2);
            P_OA = contTable38(blocknb,:);
       elseif ntrials == 40
            trials_P_OA = zeros(ntrials,2);
            P_OA = contTable40(blocknb,:);
       elseif ntrials == 42
            trials_P_OA = zeros(ntrials,2);
            P_OA = contTable42(blocknb,:);
        end
        
        respEndOfBlock = {length(ntrials),4};                      %prealocate responses to end-of-block questions
        %Set pseudo-random sequence of outcomes
        nresp = 2;
        for j=1:nresp                         %Loop over actions
            for z=1:ntrials                   %Loop over trials
                if z < (P_OA(:,j)+1)          %Assign correct and incorrect outcomes (basically overwrite trials_P_OA)
                    trials_P_OA(z,j) = 1;
                else
                end;
            end;
        end;
        trials_P_OA_shuffled = trials_P_OA(randperm(ntrials),:); %Shuffle trials_P_OA
        
        lateTrials = zeros(ntrials,1);  %preallocate late trials occurrences    
        thisblockplayer = players(:,x); %chose this block's "player"
    
        %First screen of the block, indtroduce the "player"
        DrawFormattedText(win,['Stai per simulare una partita della squadra numero  ' num2str(thisblockplayer)],'center','center',white);
        Screen('Flip',win);
        WaitSecs(.1);
    
        %Fixation cross
        Screen('DrawLines',win,crossLines,crossWidth,crossColor,[xc,yc]);
        Screen('Flip',win);
        WaitSecs(.1);
 
        %TRIAL LOOP
        while k <= ntrials                                      %use while instead of for loop to accomodate late trials
            save(backupfile)                                    % backs the entire workspace up just in case we have to do a nasty abort
            trialnb = trialnb + 1;
            thistrial(trialnb,1) = k;                           %store number of trial
            thisblock(trialnb,1) = blocknb;                     %store block nr
            condition(trialnb,1) = condOrder(:,x);              %store condition type (play_pause or pause_play)
            %P_OA(trialnb,1) = P_OA(:,1);                        %store P_OA
            %thisP_OnotA(trialnb,1) = P_OA(:,2);                 %store P_OnotA
            %thisdeltaP(trialnb,1) = deltaP;                     
            RestrictKeysForKbCheck([27,37,39]);                 %restrict key presses to right and left arrows
            
            %Present stimuli
            if condOrder(:,x)==0   
                Screen('DrawTexture', win, texPlay,[],imageRectPlayLeft);
                Screen('DrawTexture', win, texPause,[],imageRectPauseRight);
            elseif condOrder(:,x)==1
                Screen('DrawTexture', win, texPlay,[],imageRectPlayRight);
                Screen('DrawTexture', win, texPause,[],imageRectPauseLeft);
            end
            Screen('Flip',win);
            
            keyIsDown = 0;
            maxStimDuration = GetSecs+3; %set max stim duration
            startTime = GetSecs; %start recording reaction time
            
            %Check which key was pressed
            while ~keyIsDown && GetSecs<maxStimDuration
                [keyIsDown, pressedSecs, keyCode] = KbCheck(-1);  
            end
                
                %Spot late trials & keep track of them for later
                if GetSecs>maxStimDuration
                    if condOrder(:,x)==0   
                        Screen('DrawTexture', win, texPlay,[],imageRectPlayLeft);
                        Screen('DrawTexture', win, texPause,[],imageRectPauseRight);
                    elseif condOrder(:,x)==1
                        Screen('DrawTexture', win, texPlay,[],imageRectPlayRight);
                        Screen('DrawTexture', win, texPause,[],imageRectPauseLeft);
                    end                    
                 DrawFormattedText(win,['?'],xc+30,yc+30,red);    
                 Screen('Flip',win);
                 WaitSecs(.5);
                 lateTrials(trialnb,1) = 1;
                 continue
                end
 
            reactionTime = pressedSecs-startTime; %get reaction time
            
            %Record button response
               if keyCode(:,37) == 1 %leftArrow
                    n = 1;
               elseif keyCode(:,39) == 1 %rightArrow
                    n = 2;
               end
               
            %Set outcomes according to A-O contingencies
                if trials_P_OA_shuffled(trialnb,n) == 1
                    if condOrder(:,x)==0   
                        Screen('DrawTexture', win, texPlay,[],imageRectPlayLeft);
                        Screen('DrawTexture', win, texPause,[],imageRectPauseRight);
                    elseif condOrder(:,x)==1
                        Screen('DrawTexture', win, texPlay,[],imageRectPlayRight);
                        Screen('DrawTexture', win, texPause,[],imageRectPauseLeft);
                    end
                    outcome = 11;    
                    Screen('DrawTexture', win, texWin,[],imageWin);
                else
                    if condOrder(:,x)==0   
                        Screen('DrawTexture', win, texPlay,[],imageRectPlayLeft);
                        Screen('DrawTexture', win, texPause,[],imageRectPauseRight);
                    elseif condOrder(:,x)==1
                        Screen('DrawTexture', win, texPlay,[],imageRectPlayRight);
                        Screen('DrawTexture', win, texPause,[],imageRectPauseLeft);
                    end                    
                    outcome = 12;
                    Screen('DrawTexture', win, texLose,[],imageLose);    
                end;
                    Screen('Flip',win);
                    WaitSecs(.2);
               
            nLateTrials = numel(find(lateTrials(:,1)==1)); %count how many late trials there have been
            nLateTrialsThisBlock(trialnb,1) = nLateTrials; %this is for adding it to data table
            
            %Store iterations
            reactionTimes(trialnb,1) = reactionTime;
            choices(trialnb,1) = n;
            outcomes(trialnb,1) = outcome;
            k=k+1;
        end
              
end
           
%% ========= END-OF-BLOCK QUESTIONS ========= %
        if i >= 2 %skip questions after practice run 
        respQ0=str2num(Ask(win,'hi!',white,black,'GetChar',[800 300 1000 1500],'center',20)); %AskQ is a PTB function modified to accommodate more text, renamed and saved in local directory
        Screen('Flip',win);    
            
        respQ1=str2num(AskQ1(win,'    ',white,black,'GetChar',[800 300 1000 1500],'center',20)); %AskQ is a PTB function modified to accommodate more text, renamed and saved in local directory
        Screen('Flip',win);
        
        respQ2=str2num(AskQ2(win,'    ',white,black,'GetChar',[800 300 1000 1500],'center',20)); %AskQ is a PTB function modified to accommodate more text, renamed and saved in local directory
        Screen('Flip',win);
        
        respQ3=AskQ3(win,'    ',white,black,'GetChar',[800 300 1000 1500],'center',20); %AskQ is a PTB function modified to accommodate more text, renamed and saved in local directory
        Screen('Flip',win);
        
        respQ4=AskQ4(win,'    ',white,black,'GetChar',[800 300 1000 1500],'center',20); %AskQ is a PTB function modified to accommodate more text, renamed and saved in local directory
        Screen('Flip',win);
        
        %Store responses after each block
        respEndOfBlock{blocknb,1}=respQ1;
        respEndOfBlock{blocknb,2}=respQ2;
        respEndOfBlock{blocknb,3}=respQ3;
        respEndOfBlock{blocknb,4}=respQ4;
        end

%Breaks after runs & end message
if i == 1 && x == 1
    RestrictKeysForKbCheck([32]);               %restrict key presses to space
    DrawFormattedText(win,'FINE DEL TRAINING \n \n Premi SPAZIO quando sei pronto per cominciare con l esperimento vero e proprio. \n \n Se qualcosa non ti � chiaro, alza la mano e uno degli sperimentatori verr� a rispondere alle tue domande.','center','center',white);
    Screen('Flip',win);
    [secs, keyCode, deltaSecs] = KbWait([],2);  %wait forkey press (self-paced start after practice session)
elseif i == 4    
    %calculate earning 
    %pickblock = randsample(2:31,1);                                         %pick a random block b/w 2 and 31 (1 is training)
    %score = abs(thisdeltaP(pickblock) - respEndOfBlock{pickblock,1});       %look up that block's respQ1 and subtract it from that block's deltaP
    %earning = 5+(0.1*(10-score).^2);                                        %plug score in payment equation and add 5 show-up fee
    %display earning
    %DrawFormattedText(win,'FINE DEL GIOCO \n \n Grazie della partecipazione. \n \n Hai vinto Euro:','center','center',white);
    %DrawFormattedText(win,num2str(earning),800,800,white);
    %Screen('Flip',win);
    %WaitSecs(3);
else
    RestrictKeysForKbCheck([32]);               %restrict key presses to space
    DrawFormattedText(win,'PAUSA \n \n Premi SPAZIO quando sei pronto a ricominciare.','center','center',white);
    Screen('Flip',win);
    [secs, keyCode, deltaSecs] = KbWait([],2);   %wait forkey press (self-paced break after each run)    
end    

end
       
%% ========= SAVE DATA & CLOSE ========= %
subject(1:trialnb,1) = subjectID;
data = [subject, thisblock, condition, thistrial, choices, outcomes, reactionTimes, nLateTrialsThisBlock];
dataQuestions = (respEndOfBlock);
save(resultnameQuestions, 'dataQuestions');
save(resultname, 'data');

Screen('CloseAll');
