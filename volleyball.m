clc
clear

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
backupfile = fullfile('Logfiles', strcat('Backup_Sub',num2str(subjectID), '_', DateTime, '.mat'));                   %backup logfile with the whole workspace, in case of nasty aborts
%% ========= SET CONTINGENCIES ========= %
T = readtable('ContingencyTableFinal.csv');         %read table that stores the 30 conditions with their contingencies and learning duration
shuffledT = T(randperm(size(T,1)),:);               %shuffle T rows (ie shuffle the 30 conditions)

%Create contingency tables for different number of trials
A = shuffledT.NOA;
C = shuffledT.NonA;
contTable = [A C];

%% ========= EXPERIMENT STRUCTURE ========= %
run1 = shuffledT{1:15,'LearnDur'};            %determine the duration (short or long) for each block in run1 (0 short, 1 long)         
run2 = shuffledT{16:30,'LearnDur'};           %determine the duration (short or long) for each block in run2 (0 short, 1 long)
run3 = shuffledT{31:45,'LearnDur'};           %determine the duration (short or long) for each block in run3 (0 short, 1 long)
training = 10;                                %determine the duration (10 trials) of training run
expStructure = {training, run1, run2, run3};
nruns = numel(expStructure);                  %count elements in expStructure to determine number of runs


shortBlocks = [4 5 6];
longBlocks = [38 40 42];

cond = [0 0 0 0 0 1 1 1 1 1 0 0 1 1 1];                   %for play_pause or pause_play display
players = randperm(45+1);                       %create as many unique "player numbers" as there are blocks, + 1 for the practice run
respEndOfBlock = zeros(45,4);                        %preallocate respEndOfBlock answers
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
     
    if pos >= 10
        pos = 9;
       continue
    end   
    
    %show instructions slide according to position
    thisSlide=imread(fullfile('Stimfiles', strcat('Diapositive',num2str(pos),'.png'))); 
    texslide = Screen('MakeTexture', win, thisSlide);
    Screen('DrawTexture', win, texslide);
    Screen('Flip',win);
    continue
    
end

%% ========= LOOPS (RUN, BLOCK, TRIAL) ========= %
runnb = 0;          %initial run value     
ntotal_exp = 0;
%RUN LOOP
 for i = 1:nruns
    blocknb = 0;
    runnb = runnb + 1;
    condOrder = cond(randperm(length(cond)));   %determine play_pause or pause_play condition sequence
    nblocks = length(expStructure{i});          %determine number of blocks for each run; it will be 1 for training and 10 for the other 3 runs
    
    if i == 2 %if this is the first run, start adding up to blocknb from 0
        blocknb = 0;
    elseif i == 3 %if this is the second run, start adding up to blocknb from 15
        blocknb = 15;
    elseif i == 4 %if this is the third run, start adding up to blocknb from 30
        blocknb = 30;
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
        elseif expStructure{i}(x,1) == 1
            pickPlace = randi(length(longBlocks));
            ntrials = longBlocks(pickPlace);
        end
        
        %Set contingencies, taking into account number of trials:
        %For practice trials, we can use a random sequence of outcomes
        clear trials_P_OA_shuffled
        if i == 1 
            ntrials = 10;
            trials_P_OA = [zeros(5,2) ; ones(5,2)];
            for na = 1:2
                trials_P_OA_shuffled(:,na) = trials_P_OA(randperm(ntrials),na);
            end
        else
            % For real experiment, set pseudo-random sequence of outcomes
            % Get an arbitrary large number of repetitions
            % (100). Blocks are in 4 actions because probs are 0, 0.25, 0.5,
            % 0.75 and 1
            nrep = 100;
            trials_P_OA = zeros(4,nrep,2);
            % For actions
            for na = 1:2
                % Fills in with ones
                trials_P_OA(1:contTable(blocknb,na),:,na) = ones(contTable(blocknb,na),nrep); %genera matrice di mini blocchi di 4 che nelle righe successive appende reshpae e mette uno dietro l'altro
                % Permute
                for nr = 1:nrep
                    trials_P_OA(:,nr,na) = trials_P_OA(randperm(4),nr,na);
                end
            end
            % Reshape
            trials_P_OA = reshape(trials_P_OA, [ 4*nrep 2 ]);
            % Cut to ntrials
            trials_P_OA_shuffled = trials_P_OA(1:ntrials,:); %taglia in base al numero di trials
            
            % Set conditions
            thisConditionT = shuffledT(blocknb, {'condition'}); %keep track of the condition for this block (after practice run)
            thisCondition = table2array(thisConditionT);
            thisDPTable = shuffledT(blocknb, {'DP'});
            thisDP = table2array(thisDPTable);    %keep track of DP for this block (after practice run)
        end
         
        % Set late trials
        thisblockplayer = players(:,x); %chose this block's "player"
        
        %PTB display:
        %First screen of the block, introduce the "player"
        if i == 1 
            DrawFormattedText(win,['Fai qualche prova...'],'center','center',white);
            Screen('Flip',win);
            WaitSecs(2);
        else
            DrawFormattedText(win,['Stai per simulare delle partite della squadra numero  ' num2str(thisblockplayer)],'center','center',white);
            Screen('Flip',win);
            WaitSecs(3);
        end
        
        
        % Reverse play and notplay accoding to position of buttons
        if condOrder(x)==1
            trials_P_OA_shuffled = trials_P_OA_shuffled(:,[2 1]);
        end
                    
        %TRIAL LOOP
        nc = 1; % number of correctly executed trials
        nl = 0; % number of late trials
        nt = nc + nl; % number of correctly executed and late trials
        ntrials_total = ntrials;
        while nt <= ntrials_total                                      %use while instead of for loop to accomodate late trials
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
                Screen('DrawTexture', win, texQMark,[],imageQMark);
                Screen('Flip',win);
                WaitSecs(0.5);
                % Update late trials
                nl = nl + 1;
                % Update total number of performed trials
                ntrials_total = ntrials_total + 1;
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
            if trials_P_OA_shuffled(nc,n) == 1
                if condOrder(:,x)==0
                    Screen('DrawTexture', win, texPlay,[],imageRectPlayLeft);
                    Screen('DrawTexture', win, texPause,[],imageRectPauseRight);
                elseif condOrder(:,x)==1
                    Screen('DrawTexture', win, texPlay,[],imageRectPlayRight);
                    Screen('DrawTexture', win, texPause,[],imageRectPauseLeft);
                end
                outcome = 11;
                Screen('DrawTexture', win, texWin,[],imageWin);
                Screen('Flip',win);
                WaitSecs(0.5);
                % Update number of correct trials
                nc = nc + 1;
                % Total number of trials
                ntotal_exp = ntotal_exp + 1;
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
                Screen('Flip',win);
                WaitSecs(0.5);
                % Update number of correct trials
                nc = nc + 1;
                % Total number of trials
                ntotal_exp = ntotal_exp + 1;
            end;
            
            %this is for adding it to data table
            nLateTrialsThisBlock(nt,1) = nl;
            
            %Store variables to be saved
            data.subjID(ntotal_exp,1) = subjectID;
            data.run(ntotal_exp,1) = runnb;
            data.block(ntotal_exp,1) = blocknb;
            if i >= 2
                data.condition(ntotal_exp,1) = thisCondition;
                data.DP(ntotal_exp,1) = thisDP;
            end
            data.blockLenght(ntotal_exp,1) = ntrials;
            data.trial(ntotal_exp,1) = ntotal_exp;
            data.stimOrder(ntotal_exp,1) = stimOrder;
            data.subjChoice(ntotal_exp,1) = n;
            data.outcome(ntotal_exp,1) = outcome;
            data.rt(ntotal_exp,1) = reactionTime;
            
            % Update total number of trials
            nt = nc + nl;
        end
              
%% ========= END-OF-BLOCK QUESTIONS ========= %
        if i >= 2 %skip questions after practice run 
        respQ1=str2num(AskQ1(win,'    ',white,black,'GetChar',[800 300 800 950],'center',20)); %PTB function modified to accommodate more text, renamed and saved in local directory
        Screen('Flip',win);
        while isempty(respQ1) | isnumeric(respQ1)==0
            DrawFormattedText(win,'La tua risposta non è stata registrata correttamente. Riprova.','center','center',white);
            Screen('Flip',win);
            WaitSecs(1);  
            respQ1=str2num(AskQ1(win,'    ',white,black,'GetChar',[800 300 800 950],'center',20)); %PTB function modified to accommodate more text, renamed and saved in local directory
        end
        
        respQ2=str2num(AskQ2(win,'    ',white,black,'GetChar',[800 300 800 950],'center',20)); %PTB function modified to accommodate more text, renamed and saved in local directory
        Screen('Flip',win);
        while isempty(respQ2) | isnumeric(respQ2)==0
            DrawFormattedText(win,'La tua risposta non è stata registrata correttamente. Riprova.','center','center',white);
            Screen('Flip',win);
            WaitSecs(2);
            respQ2=str2num(AskQ2(win,'    ',white,black,'GetChar',[800 300 800 950],'center',20)); %PTB function modified to accommodate more text, renamed and saved in local directory
        end
        
        respQ3=str2num(AskQ3(win,'    ',white,black,'GetChar',[800 300 800 950],'center',20)); %PTB function modified to accommodate more text, renamed and saved in local directory
        Screen('Flip',win);
        while isempty(respQ3) | isnumeric(respQ3)==0
            DrawFormattedText(win,'La tua risposta non è stata registrata correttamente. Riprova.','center','center',white);
            Screen('Flip',win);
            WaitSecs(2);
            respQ3=str2num(AskQ3(win,'    ',white,black,'GetChar',[800 300 800 950],'center',20)); %PTB function modified to accommodate more text, renamed and saved in local directory
        end
        
        respQ4=str2num(AskQ4(win,'    ',white,black,'GetChar',[800 300 800 950],'center',20)); %PTB function modified to accommodate more text, renamed and saved in local directory
        Screen('Flip',win);
        while isempty(respQ4) | isnumeric(respQ4)==0
            DrawFormattedText(win,'La tua risposta non è stata registrata correttamente. Riprova.','center','center',white);
            Screen('Flip',win);
            WaitSecs(2);
            respQ4=str2num(AskQ4(win,'    ',white,black,'GetChar',[800 300 800 950],'center',20)); %PTB function modified to accommodate more text, renamed and saved in local directory
        end
        
        respEndOfBlock(blocknb,1)=respQ1;
        respEndOfBlock(blocknb,2)=respQ2;
        respEndOfBlock(blocknb,3)=respQ3;
        respEndOfBlock(blocknb,4)=respQ4;
        end
end        

%Breaks after runs & end message
if i == 1 && x == 1
    RestrictKeysForKbCheck([32]);               %restrict key presses to space
    DrawFormattedText(win,'FINE DELLA FASE DI PROVA \n \n Premi SPAZIO quando sei pronto per cominciare con l esperimento vero e proprio. \n \n Se qualcosa non ti è chiaro, alza la mano e uno degli sperimentatori verrà a rispondere alle tue domande.','center','center',white);
    Screen('Flip',win);
    [secs, keyCode, deltaSecs] = KbWait([],2);  %wait forkey press (self-paced start after practice session)
elseif i == 4    
    %calculate earning 
    pickblock = randi([1 45],1);                                     %pick a random block
    DPpayment = shuffledT(pickblock, {'DP'});                           %determine the DP for that block
    thisDPpayment = table2array(DPpayment);                             %extract it from the table
    score = abs(thisDPpayment - respEndOfBlock(pickblock,1));           %look up that block's respQ1 and subtract it from that block's deltaP
    earning = 5+(0.1*(10-score).^2);                                    %plug score in payment equation and add 5 show-up fee
    %display earning
    DrawFormattedText(win,'FINE DEL GIOCO \n \n Grazie della partecipazione! \n \n Hai vinto Euro:','center','center',white);
    DrawFormattedText(win,num2str(earning),800,800,white);
    Screen('Flip',win);
    WaitSecs(6);
else
    RestrictKeysForKbCheck([32]);               %restrict key presses to space
    DrawFormattedText(win,'PAUSA \n \n Premi SPAZIO quando sei pronto a ricominciare.','center','center',white);
    Screen('Flip',win);
    [secs, keyCode, deltaSecs] = KbWait([],2);   %wait forkey press (self-paced break after each run)    
end    

end
       
%% ========= SAVE DATA & CLOSE ========= %
SingleTrialData = struct2table(data);
% Add shuffled contTable
SingleRunData = shuffledT;
% Add questionnaire
SingleRunData.Q1 = respEndOfBlock(:,1);
SingleRunData.Q2 = respEndOfBlock(:,2);
SingleRunData.Q3 = respEndOfBlock(:,3);
SingleRunData.Q4 = respEndOfBlock(:,4);
% Save
save(resultname, 'SingleTrialData', 'SingleRunData');
dataQuestions = (respEndOfBlock); %
save(resultnameQuestions, 'dataQuestions');

%Close screen and escape
Screen('CloseAll');
sca;