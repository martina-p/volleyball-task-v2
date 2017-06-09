%clear workspace
clc;

%% ========= SET LOGFILES ========= 
subjectID = input('Participant number: ');
DateTime = datestr(now,'yyyymmdd-HHMM');

%create a directory called Logfiles if there isn't one already
if ~exist('Logfiles', 'dir')
    mkdir('Logfiles');
end

%store result names 
resultname = fullfile('Logfiles', strcat('Sub',num2str(subjectID),'_', DateTime, '.mat'));                          %for choices
resultnameQuestions = fullfile('Logfiles', strcat('Sub',num2str(subjectID),'questions_', DateTime, '.mat'));        %for end-of-block questions
backupfile = fullfile('Logfiles', strcat('Bckup_Sub',num2str(subjectID), '_', DateTime, '.mat'));                    %backup result file
%% ========= EXPERIMENT STRUCTURE ========= %
training = 10;                                                     %set number of trials in the training run
trialsPerBlock = [40 40 40 40 20 20 20 10 10 10];                  %4x40, 3x30, 3x10 
run1 = trialsPerBlock(randperm(length(trialsPerBlock)));           %shuffle to create run1
run2 = trialsPerBlock(randperm(length(trialsPerBlock)));           %shuffle to create run2 
run3 = trialsPerBlock(randperm(length(trialsPerBlock)));           %shuffle to create run3 
expStructure = {training, run1, run2, run3};
nruns = numel(expStructure);                                       %count elements in cell array expStructure to determine number of runs

%% ========= PARAMETERS & DATA PREALLOCATION ========= %
contTable = [9 3; 7 1; 8 5; 6 3; 6 6; 4 4; 5 8; 3 6; 3 9; 1 7];   %Contingency table {play, do not play} for each block: 1 = 1/10 ; 2 = 2/10 ; 3 = 3/10 ; 4 = 4/10 ; 5 = 5 / 10; ...
conTableShuffled = contTable(randperm(10),:);                     %Shuffle contingencies for each block
cond = [0 0 0 0 0 1 1 1 1 1];                                     %for play_pause or pause_play display, changes every block

players = randperm(30+1);                                         %create as many unique "player numbers" as there are blocks, + 1 for the practice run
thisblock = zeros(310,1);                                         %preallocate block nr storage to be recorded for each trial
condition = zeros(310,1);                                         %preallocate condition (play_pause or pause_play) to be recorded for each trial
respEndOfBlock = {length(trialsPerBlock),4};                      %prealocate responses to end-of-block questions

%% ========= INSTRUCTIONS ========= %
psychExpInit;                                %start PTB
RestrictKeysForKbCheck([32,37,39]);          %restrict key presses to space, right and left arrows
exitInstructions = false;                    %cue determining whether to exit the instructions
pos = 1;                                     %initial position to go back and forth between the slides

Screen('DrawTexture', win, texslide1);       %show first slide      
Screen('Flip',win);                             

while exitInstructions == false                 %loop instruction slides until space key is pressed
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

for i = 1:nruns
    condOrder = cond(randperm(length(cond)));   %vector of 0s and 1s for play_pause or pause_play conditions
    nblocks = length(expStructure{i});          %determine number of blocks; it will be 1 for training and 10 for the other 3 runs
    
for x = 1:nblocks
          
        k=1;
        blocknb = blocknb + 1;
        
        if i == 1
            P_OA = [5 5];                   %set probability at .5 for the training
            deltaP = 0;
        else
            P_OA = conTableShuffled(x,:);       %set P_OA = {play, do not play} for this block
            deltaP = P_OA(:,1) - P_OA(:,2);     %define deltaP
        end
        
        ntrials = expStructure{i}(1,x); %set ntrials for each block between 40, 20 and 10
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
 
        while k <= ntrials %use while instead of for loop to accomodate late trials
            save(backupfile)                                    % backs the entire workspace up just in case we have to do a nasty abort
            trialnb = trialnb + 1;
            thistrial(trialnb,1) = k;                           %store number of trial
            thisblock(trialnb,1) = blocknb;                     %store block nr
            condition(trialnb,1) = condOrder(:,x);              %store condition type (play_pause or pause_play)
            thisP_OA(trialnb,1) = P_OA(:,1);                    %store P_OA
            thisP_OnotA(trialnb,1) = P_OA(:,2);                 %store P_OnotA
            thisdeltaP(trialnb,1) = deltaP;                     
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
            
            %Set outcomes
               if keyCode(:,37) == 1 %leftArrow
                    n = 1;
               elseif keyCode(:,39) == 1 %rightArrow
                    n = 2;
               end
            
            condizione = 1;
            outcome = (rand > P_OA(condizione,n)/10);
            
            %Show win/lose cues
            if outcome == 1
               if condOrder(:,x)==0   
                   Screen('DrawTexture', win, texPlay,[],imageRectPlayLeft);
                   Screen('DrawTexture', win, texPause,[],imageRectPauseRight);
               elseif condOrder(:,x)==1
                   Screen('DrawTexture', win, texPlay,[],imageRectPlayRight);
                   Screen('DrawTexture', win, texPause,[],imageRectPauseLeft);
               end
                  Screen('DrawTexture', win, texWin,[],imageWin);
            else
              if condOrder(:,x)==0   
                    Screen('DrawTexture', win, texPlay,[],imageRectPlayLeft);
                    Screen('DrawTexture', win, texPause,[],imageRectPauseRight);
               elseif condOrder(:,x)==1
                    Screen('DrawTexture', win, texPlay,[],imageRectPlayRight);
                    Screen('DrawTexture', win, texPause,[],imageRectPauseLeft);
              end
                    Screen('DrawTexture', win, texLose,[],imageLose);
            end      
                Screen('Flip',win);
                WaitSecs(.1);   
            
            nLateTrials = numel(find(lateTrials(:,1)==1)); %count how many late trials there have been
            nLateTrialsThisBlock(trialnb,1) = nLateTrials; %this is for adding it to data table
            
            %Store iterations
            reactionTimes(trialnb,1) = reactionTime;
            choices(trialnb,1) = n;
            outcomes(trialnb,1) = outcome;
            k=k+1;
              
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
end

%Breaks after runs & end message
if i == 1 && x == 1
    RestrictKeysForKbCheck([32]);               %restrict key presses to space
    DrawFormattedText(win,'FINE DEL TRAINING \n \n Premi SPAZIO quando sei pronto per cominciare con l esperimento vero e proprio. \n \n Se qualcosa non ti è chiaro, alza la mano e uno degli sperimentatori verrà a rispondere alle tue domande.','center','center',white);
    Screen('Flip',win);
    [secs, keyCode, deltaSecs] = KbWait([],2);  %wait forkey press (self-paced start after practice session)
elseif i == 4    
    %calculate earning 
    pickblock = randsample(2:31,1);                                         %pick a random block b/w 2 and 31 (1 is training)
    score = abs(thisdeltaP(pickblock) - respEndOfBlock{pickblock,1});       %look up that block's respQ1 and subtract it from that block's deltaP
    earning = 5+(0.1*(10-score).^2);                                        %plug score in payment equation and add 5 show-up fee
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
subject(1:trialnb,1) = subjectID;
data = [subject, thisblock, thisP_OA, thisP_OnotA, thisdeltaP, condition, thistrial, choices, outcomes, reactionTimes, nLateTrialsThisBlock];
dataQuestions = (respEndOfBlock);
save(resultnameQuestions, 'dataQuestions');
save(resultname, 'data');

Screen('CloseAll');
