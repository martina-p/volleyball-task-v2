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
%% ========= SET CONTINGENCIES ========= %
T = readtable('ContingencyTableFinal.csv');         %read table that stores the 30 conditions with their contingencies and learning duration
shuffledT = T(randperm(size(T,1)),:);               %shuffle T rows (ie shuffle the 30 conditions)

%Create contingency tables for different number of trials
poa4 = shuffledT.POA4; %4 trials
ponota4 = shuffledT.POnotA4;
contTable4 = [poa4, ponota4];

poa5 = shuffledT.POA5; %5 trials
ponota5 = shuffledT.POnotA5;
contTable5 = [poa5, ponota5];

poa6 = shuffledT.POA6;  %6 trials
ponota6 = shuffledT.POnotA6;
contTable6 = [poa6, ponota6];

poa38 = shuffledT.POA38; %38 trials
ponota38 = shuffledT.POnotA38;
contTable38 = [poa38, ponota38];

poa40 = shuffledT.POA40;  %40 trials
ponota40 = shuffledT.POnotA40;
contTable40 = [poa40, ponota40];

poa42 = shuffledT.POA42;    %42 trials
ponota42 = shuffledT.POnotA42;
contTable42 = [poa42, ponota42];

%% ========= EXPERIMENT STRUCTURE ========= %
run1 = shuffledT{1:10,'LearnDur'};            %determine the duration (short or long) for each block in run1 (0 short, 1 long)         
run2 = shuffledT{11:20,'LearnDur'};           %determine the duration (short or long) for each block in run2 (0 short, 1 long)
run3 = shuffledT{21:30,'LearnDur'};           %determine the duration (short or long) for each block in run3 (0 short, 1 long)
training = 10;                                %determine the duration (10 trials) of training run
expStructure = {training, run1, run2, run3};
nruns = numel(expStructure);                  %count elements in expStructure to determine number of runs

shortBlocks = [4 5 6];
longBlocks = [38 40 42];

cond = [0 0 0 0 0 1 1 1 1 1];                   %for play_pause or pause_play display
players = randperm(30+1);                       %create as many unique "player numbers" as there are blocks, + 1 for the practice run
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
totalCount = 0;     %to count total nr of trials
runnb = 0;          %initial run value     

%RUN LOOP
for i = 1:nruns
    blocknb = 0;
    runnb = runnb + 1;
    condOrder = cond(randperm(length(cond)));   %determine play_pause or pause_play condition sequence
    nblocks = length(expStructure{i});          %determine number of blocks for each run; it will be 1 for training and 10 for the other 3 runs
    
    if i == 2 %if this is the first run, start adding up to blocknb from 0
        blocknb = 0;
    elseif i == 3 %if this is the second run, start adding up to blocknb from 10
        blocknb = 10;
    elseif i == 4 %if this is the third run, start adding up to blocknb from 20
        blocknb = 20;
    end    
    
%BLOCK LOOP
for x = 1:nblocks  
        blocknb = blocknb + 1;
        stimOrder = condOrder(x); %to store stim order (see later: 0 play_pause, 1 pause_play)
                
        %Determine exact number of trials (4, 5, 6 or 38, 40, 42) depending
        %on learning duration of condition
        if expStructure{i}(x,1) == 0 
           pickPlace = randi(length(shortBlocks));
           ntrials = shortBlocks(pickPlace);
        else
           pickPlace = randi(length(longBlocks));
           ntrials = longBlocks(pickPlace);
        end
        
        %Set contingencies, taking into account number of trials:
        %For practice trials
        if i == 1
            ntrials = 10;
            trials_P_OA = zeros(10,2);
            P_OA = [5 5];
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
        
        if i >= 2
           thisConditionT = shuffledT(blocknb, {'Condition'}); %keep track of the condition for this block (after practice run)
           thisCondition = table2array(thisConditionT);
           thisDPTable = shuffledT(blocknb, {'DP'});
           thisDP = table2array(thisDPTable);    %keep track of DP for this block (after practice run)
        end
        
        respEndOfBlock = {length(ntrials),4}; %prealocate responses to end-of-block questions
        
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
        trials_P_OA_shuffled = trials_P_OA(randperm(ntrials),:); %Shuffle sequence of outcomes trials_P_OA
        
        lateTrials = zeros(ntrials,1);  %preallocate late trials occurrences    
        thisblockplayer = players(:,x); %chose this block's "player"
    
        %PTB display:
        %First screen of the block, indtroduce the "player"
        DrawFormattedText(win,['Stai per simulare una partita della squadra numero  ' num2str(thisblockplayer)],'center','center',white);
        Screen('Flip',win);
        WaitSecs(.3);
    
        %Fixation cross
        Screen('DrawLines',win,crossLines,crossWidth,crossColor,[xc,yc]);
        Screen('Flip',win);
        WaitSecs(.2);
        
        k = 0;
 
        %TRIAL LOOP
        while k <= ntrials                                      %use while instead of for loop to accomodate late trials
            trialnb = 0;
            trialnb = trialnb + 1;
            totalCount = totalCount + 1;
            save(backupfile)                                    % backs the entire workspace up just in case we have to do a nasty abort
            RestrictKeysForKbCheck([27,37,39]);                 %restrict key presses to right and left arrows
            
            %Draw stimuli play / do not play
            if condOrder(x)==0   
                Screen('DrawTexture', win, texPlay,[],imageRectPlayLeft);
                Screen('DrawTexture', win, texPause,[],imageRectPauseRight);
            elseif condOrder(x)==1
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
                    if condOrder(x)==0   
                        Screen('DrawTexture', win, texPlay,[],imageRectPlayLeft);
                        Screen('DrawTexture', win, texPause,[],imageRectPauseRight);
                    elseif condOrder(x)==1
                        Screen('DrawTexture', win, texPlay,[],imageRectPlayRight);
                        Screen('DrawTexture', win, texPause,[],imageRectPauseLeft);
                    end                    
                 %DrawFormattedText(win,'?',xc+30,yc+30,red);
                 Screen('DrawTexture', win, texQMark,[],imageQMark);
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
               
            %Show outcome based on pseudorandom sequence
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
            
            k=k+1;
            
            %Store variables to be saved
            data.subjID(totalCount) = subjectID;
            data.run(totalCount) = runnb;
            data.block(totalCount) = blocknb;
            if i >= 2
                data.condition(totalCount) = thisCondition;
                data.DP(totalCount) = thisDP;
            end
            data.blockLenght(totalCount) = ntrials;
            data.trial(totalCount) = totalCount;
            data.stimOrder(totalCount) = stimOrder;
            data.subjChoice(totalCount) = n;
            data.outcome(totalCount) = outcome;
            data.rt(totalCount) = reactionTime;
            
        end
              
%% ========= END-OF-BLOCK QUESTIONS ========= %
        if i >= 2 %skip questions after practice run 
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
end        

%Breaks after runs & end message
if i == 1 && x == 1
    RestrictKeysForKbCheck([32]);               %restrict key presses to space
    DrawFormattedText(win,'FINE DEL TRAINING \n \n Premi SPAZIO quando sei pronto per cominciare con l esperimento vero e proprio. \n \n Se qualcosa non ti è chiaro, alza la mano e uno degli sperimentatori verrà a rispondere alle tue domande.','center','center',white);
    Screen('Flip',win);
    [secs, keyCode, deltaSecs] = KbWait([],2);  %wait forkey press (self-paced start after practice session)
elseif i == 4    
    %calculate earning 
    pickblock = randsample(1:30,1);                                     %pick a random block
    DPpayment = shuffledT(pickblock, {'DP'});                           %determine the DP for that block
    thisDPpayment = table2array(DPpayment);                             %extract it from the table
    score = abs(thisDPpayment - respEndOfBlock{pickblock,1});           %look up that block's respQ1 and subtract it from that block's deltaP
    earning = 5+(0.1*(10-score).^2);                                    %plug score in payment equation and add 5 show-up fee
    %display earning
    DrawFormattedText(win,'FINE DEL GIOCO \n \n Grazie della partecipazione. \n \n Hai vinto Euro:','center','center',white);
    DrawFormattedText(win,num2str(earning),800,800,white);
    Screen('Flip',win);
    WaitSecs(3);
else
    RestrictKeysForKbCheck([32]);               %restrict key presses to space
    DrawFormattedText(win,'PAUSA \n \n Premi SPAZIO quando sei pronto a ricominciare.','center','center',white);
    Screen('Flip',win);
    [secs, keyCode, deltaSecs] = KbWait([],2);   %wait forkey press (self-paced break after each run)    
end    

end
       
%% ========= SAVE DATA & CLOSE ========= %
Data = struct2table(data);
save(resultname, 'Data');
dataQuestions = (respEndOfBlock); %
save(resultnameQuestions, 'dataQuestions');

%Close screen and escape
Screen('CloseAll');
sca;